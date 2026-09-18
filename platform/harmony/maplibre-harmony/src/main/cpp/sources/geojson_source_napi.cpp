#include "geojson_source_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "geojson/geojson_converter.hpp"
#include "geojson/util.hpp"
#include "style/filter_conversion.hpp"
#include "style/conversion/harmony_conversion.hpp"
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/style/conversion/geojson_options.hpp>
#include <mbgl/style/expression/dsl.hpp>
#include <mbgl/util/geojson.hpp>

#include <mutex>
#include <sstream>
#include "napi/core/napi_wrap_instance.hpp"

#include "source_napi_utils.hpp"
#include "query_source_features.hpp"
#include "geojson/napi_geojson_value.hpp"
using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;
using namespace mbgl::harmony::geojson;

namespace mbgl {
namespace harmony {

namespace {

// Convert one JS expression of a clusterProperties entry into an mbgl
// expression. `role` ("map" / "reduce") is used for logging only.
std::unique_ptr<mbgl::style::expression::Expression> convertClusterExpression(
    napi_env env, napi_value exprValue, const std::string& propertyName, const char* role) {
    mbgl::style::conversion::Convertible convertible(mbgl::harmony::NapiValue(env, exprValue));
    auto parsed = mbgl::style::expression::dsl::createExpression(convertible);
    if (!parsed) {
        Logger::error("GeoJsonSourceNAPI",
                      "clusterProperties[\"%s\"]: failed to convert %s expression",
                      propertyName.c_str(), role);
    }
    return parsed;
}

} // namespace

// Static member initialization
napi_ref GeoJsonSourceNAPI::constructor = nullptr;
napi_env GeoJsonSourceNAPI::constructorEnv = nullptr;

namespace {
// Renderer query hooks + their owner. All access happens on the JS thread,
// but the mutex documents the invariant and keeps future callers honest.
std::mutex s_hooksMutex;
GeoJsonSourceNAPI::QueryFeatureExtensionsFn s_featureExtensionsFn;
GeoJsonSourceNAPI::QuerySourceFeaturesFn s_sourceFeaturesFn;
void* s_hooksOwner = nullptr;
} // anonymous namespace

GeoJsonSourceNAPI::GeoJsonSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::GeoJSONSource> source)
    : SourceNapiBase(id, std::move(source)) {
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource instance created: %s", id.c_str());
}

GeoJsonSourceNAPI::GeoJsonSourceNAPI(mbgl::style::GeoJSONSource* sourcePtr)
    : SourceNapiBase(sourcePtr) {
    if (sourcePtr) {
        if (weakSource) {
            Logger::info("GeoJsonSourceNAPI", "GeoJsonSource created from existing source (WeakPtr): %s", id.c_str());
        } else {
            // Do NOT keep the raw pointer: once the source is removed from the
            // style it would dangle. getSource() returns nullptr instead.
            Logger::error("GeoJsonSourceNAPI", "GeoJsonSource created from existing source but WeakPtr initialization failed; source access disabled: %s", id.c_str());
        }
    }
}

mbgl::style::GeoJSONSource* GeoJsonSourceNAPI::getSource() const {
    if (source) {
        return source.get();
    }
    if (weakSource) {
        return static_cast<mbgl::style::GeoJSONSource*>(weakSource.get());
    }
    // No owned source and no live weak reference: the source was removed from
    // the style (or WeakPtr init failed). Returning nullptr is the only safe
    // answer — a stale raw pointer would dangle.
    return nullptr;
}

void GeoJsonSourceNAPI::attachToStyle(mbgl::style::GeoJSONSource* sourcePtr) {
    if (!sourcePtr) {
        Logger::warn("GeoJsonSourceNAPI", "attachToStyle called with null source pointer");
        return;
    }

    auto weak = sourcePtr->makeWeakPtr();
    if (weak) {
        weakSource = std::move(weak);
        Logger::info("GeoJsonSourceNAPI", "attachToStyle: WeakPtr initialized successfully for source %s", id.c_str());
    } else {
        // Do NOT keep the raw pointer: once the source is removed from the
        // style it would dangle. getSource() returns nullptr instead.
        Logger::error("GeoJsonSourceNAPI", "attachToStyle: WeakPtr initialization failed; source access disabled for %s", id.c_str());
    }
}

GeoJsonSourceNAPI::~GeoJsonSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource instance destroyed: %s", id.c_str());
}

DEFINE_SOURCE_DESTRUCTOR(GeoJsonSourceNAPI)

void GeoJsonSourceNAPI::setQueryFeatureExtensionsFn(QueryFeatureExtensionsFn fn, void* owner) {
    std::lock_guard<std::mutex> lock(s_hooksMutex);
    s_featureExtensionsFn = std::move(fn);
    s_hooksOwner = owner;
}

void GeoJsonSourceNAPI::setQuerySourceFeaturesFn(QuerySourceFeaturesFn fn, void* owner) {
    std::lock_guard<std::mutex> lock(s_hooksMutex);
    s_sourceFeaturesFn = std::move(fn);
    s_hooksOwner = owner;
}

void GeoJsonSourceNAPI::clearRendererHooks(void* owner) {
    std::lock_guard<std::mutex> lock(s_hooksMutex);
    if (s_hooksOwner != owner) {
        // A newer instance owns the hooks; leave them alone.
        return;
    }
    s_featureExtensionsFn = nullptr;
    s_sourceFeaturesFn = nullptr;
    s_hooksOwner = nullptr;
}

GeoJsonSourceNAPI::QueryFeatureExtensionsFn GeoJsonSourceNAPI::queryFeatureExtensionsFn() {
    std::lock_guard<std::mutex> lock(s_hooksMutex);
    return s_featureExtensionsFn;
}

GeoJsonSourceNAPI::QuerySourceFeaturesFn GeoJsonSourceNAPI::querySourceFeaturesFn() {
    std::lock_guard<std::mutex> lock(s_hooksMutex);
    return s_sourceFeaturesFn;
}

napi_value GeoJsonSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("GeoJsonSourceNAPI", "Initializing GeoJsonSource NAPI class");
    
    napi_property_descriptor properties[] = {
        // Getters
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Data management
        { "setGeoJson", nullptr, SetGeoJson, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setGeoJsonSync", nullptr, SetGeoJsonSync, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Query features
        { "querySourceFeatures", nullptr, QuerySourceFeatures, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Clustering utilities
        { "getClusterChildren", nullptr, GetClusterChildren, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getClusterLeaves", nullptr, GetClusterLeaves, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getClusterExpansionZoom", nullptr, GetClusterExpansionZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "GeoJsonSource", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "GeoJsonSourceNAPI");
    if (!cons) return nullptr;

    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource NAPI class initialized successfully");
    return exports;
}

napi_value GeoJsonSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GeoJsonSource requires sourceId argument");
        return nullptr;
    }
    
    // Parse arguments
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // Parse options
        mbgl::style::GeoJSONOptions options;
        
        if (argc >= 2) {
            // Parse the options object
            napi_value optionsObj = args[1];
            napi_valuetype type;
            napi_typeof(env, optionsObj, &type);
            
            if (type == napi_object) {
                // Parse simple scalar options; a missing or mistyped property
                // yields the historical default via the NapiArgs helpers.
                options.cluster = napiArgs.GetBoolProperty(optionsObj, "cluster", false);
                options.clusterRadius = static_cast<uint16_t>(napiArgs.GetInt32Property(optionsObj, "clusterRadius", 50));
                // clusterMaxZoom keeps the guarded form: the GeoJSONOptions
                // default (17) differs from the historical local fallback (16),
                // so the field must stay untouched when the property is absent.
                if (HasProperty(env, optionsObj, "clusterMaxZoom")) {
                    options.clusterMaxZoom = static_cast<uint8_t>(
                        napiArgs.GetInt32Property(optionsObj, "clusterMaxZoom", 16));
                }
                options.minzoom = static_cast<uint8_t>(napiArgs.GetInt32Property(optionsObj, "minzoom", 0));
                options.maxzoom = static_cast<uint8_t>(napiArgs.GetInt32Property(optionsObj, "maxzoom", 18));
                options.buffer = static_cast<uint16_t>(napiArgs.GetInt32Property(optionsObj, "buffer", 128));
                options.tolerance = napiArgs.GetDoubleProperty(optionsObj, "tolerance", 0.375);
                options.lineMetrics = napiArgs.GetBoolProperty(optionsObj, "lineMetrics", false);

                // Parse clusterProperties
                if (HasProperty(env, optionsObj, "clusterProperties")) {
                    napi_value clusterPropsValue;
                    napi_get_named_property(env, optionsObj, "clusterProperties", &clusterPropsValue);
                    
                    napi_valuetype clusterPropsType;
                    napi_typeof(env, clusterPropsValue, &clusterPropsType);
                    
                    if (clusterPropsType == napi_object) {
                        // clusterProperties is an object with the shape:
                        // { propertyName: [mapExpr, reduceExpr], ... }
                        napi_value propertyNames;
                        napi_get_property_names(env, clusterPropsValue, &propertyNames);
                        
                        uint32_t propertyCount = 0;
                        napi_get_array_length(env, propertyNames, &propertyCount);
                        
                        for (uint32_t i = 0; i < propertyCount; i++) {
                            napi_value propertyNameValue;
                            napi_get_element(env, propertyNames, i, &propertyNameValue);
                            
                            std::string propertyName;
                            size_t nameLen = 0;
                            napi_get_value_string_utf8(env, propertyNameValue, nullptr, 0, &nameLen);
                            propertyName.resize(nameLen);
                            napi_get_value_string_utf8(env, propertyNameValue, &propertyName[0], nameLen + 1, &nameLen);
                            
                            // Retrieve the expression array [reduceExpr, mapExpr] for this property
                            napi_value expressionArray;
                            napi_get_property(env, clusterPropsValue, propertyNameValue, &expressionArray);

                            bool isArray = false;
                            napi_is_array(env, expressionArray, &isArray);

                            if (isArray) {
                                uint32_t arrayLength = 0;
                                napi_get_array_length(env, expressionArray, &arrayLength);

                                if (arrayLength >= 2) {
                                    // Follow the style JSON convention: element 0 is the
                                    // reduce expression, element 1 the per-feature map
                                    // expression
                                    napi_value reduceExprValue, mapExprValue;
                                    napi_get_element(env, expressionArray, 0, &reduceExprValue);
                                    napi_get_element(env, expressionArray, 1, &mapExprValue);

                                    std::unique_ptr<mbgl::style::expression::Expression> reduce;
                                    napi_valuetype reduceType = napi_undefined;
                                    napi_typeof(env, reduceExprValue, &reduceType);

                                    if (reduceType == napi_string) {
                                        // Expand the operator shorthand (e.g. "sum") into
                                        // [operator, ["accumulated"], ["get", key]], the
                                        // same reformulation the style JSON conversion applies
                                        std::string reduceOp = GetStringFromValue(env, reduceExprValue);
                                        std::stringstream ss;
                                        ss << R"([")" << reduceOp << R"(", ["accumulated"], ["get", ")"
                                           << propertyName << R"("]])";
                                        reduce = mbgl::style::expression::dsl::createExpression(ss.str().c_str());
                                        if (!reduce) {
                                            Logger::error("GeoJsonSourceNAPI",
                                                          "clusterProperties[\"%s\"]: failed to convert reduce operator \"%s\"",
                                                          propertyName.c_str(), reduceOp.c_str());
                                        }
                                    } else {
                                        reduce = convertClusterExpression(env, reduceExprValue, propertyName, "reduce");
                                    }

                                    auto map = convertClusterExpression(env, mapExprValue, propertyName, "map");

                                    if (reduce && map) {
                                        options.clusterProperties.emplace(
                                            propertyName,
                                            std::make_pair(std::move(map), std::move(reduce)));
                                    } else {
                                        Logger::error("GeoJsonSourceNAPI",
                                                      "clusterProperties[\"%s\"]: skipped due to conversion failure",
                                                      propertyName.c_str());
                                    }
                                } else {
                                    Logger::warn("GeoJsonSourceNAPI",
                                                 "clusterProperties[\"%s\"]: expected an array with 2 elements, got %u",
                                                 propertyName.c_str(), arrayLength);
                                }
                            } else {
                                Logger::warn("GeoJsonSourceNAPI",
                                             "clusterProperties[\"%s\"]: value must be a [reduce, map] array",
                                             propertyName.c_str());
                            }
                        }
                        
                    }
                }
            }
        }
        
        // Create the GeoJSONSource
        auto immutableOptions = mbgl::makeMutable<mbgl::style::GeoJSONOptions>(std::move(options));
        auto source = std::make_unique<mbgl::style::GeoJSONSource>(sourceId, std::move(immutableOptions));
        
        // Create the C++ NAPI object
        GeoJsonSourceNAPI* sourceNapi = new GeoJsonSourceNAPI(sourceId, std::move(source));
        
        // Wrap into the JS object
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap GeoJsonSource object");
            return nullptr;
        }
        
        Logger::info("GeoJsonSourceNAPI", "GeoJsonSource created: %s", sourceId.c_str());
    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "GeoJsonSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, jsThis, "_TYPE_", typeValue);
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "Failed to create GeoJsonSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

DEFINE_SOURCE_CREATE_INSTANCE(GeoJsonSourceNAPI, "GeoJsonSource", mbgl::style::GeoJSONSource)

// ==================== Getters ====================

DEFINE_SOURCE_GET_ID(GeoJsonSourceNAPI)

// ==================== Data management ====================

napi_value GeoJsonSourceNAPI::SetGeoJson(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, jsThis, &sourceNapi, true);
    if (!source) {
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetGeoJson requires data argument");
        return nullptr;
    }
    
    try {
        // Detect the argument type and convert (string or object payload)
        GeoJSONValueConversion conversion;
        if (!NapiValueToGeoJSON(env, args[0], conversion, "GeoJson data must be a string or object")) {
            return nullptr;
        }

        source->setGeoJSON(std::move(conversion.value));

        // Preserve the per-branch success logs of the original dispatch
        const std::string& type = conversion.kind;
        if (type == "string") {
            Logger::info("GeoJsonSourceNAPI", "SetGeoJson (string): %s", sourceNapi->id.c_str());
        } else if (type == "FeatureCollection") {
            Logger::info("GeoJsonSourceNAPI", "SetGeoJson (FeatureCollection): %s", sourceNapi->id.c_str());
        } else if (type == "Feature") {
            Logger::info("GeoJsonSourceNAPI", "SetGeoJson (Feature): %s", sourceNapi->id.c_str());
        } else {
            Logger::info("GeoJsonSourceNAPI", "SetGeoJson (Geometry): %s, type: %s",
                       sourceNapi->id.c_str(), type.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "SetGeoJson failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value GeoJsonSourceNAPI::SetGeoJsonSync(napi_env env, napi_callback_info info) {
    // The synchronous version mirrors the asynchronous implementation
    return SetGeoJson(env, info);
}

napi_value GeoJsonSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, jsThis, &sourceNapi, true);
    if (!source) {
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string url = args.GetString(0, "url");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    try {
        source->setURL(url);
        Logger::info("GeoJsonSourceNAPI", "SetUrl: %s -> %s", sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

DEFINE_SOURCE_GET_URL(GeoJsonSourceNAPI)

// ==================== Query features ====================

napi_value GeoJsonSourceNAPI::QuerySourceFeatures(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);

    GeoJsonSourceNAPI* sourceNapi = NapiArgs::Unwrap<GeoJsonSourceNAPI>(env, jsThis);
    if (!sourceNapi) {
        return CreateEmptyArray(env);
    }

    auto* source = sourceNapi->getSource();
    if (!source) {
        return CreateEmptyArray(env);
    }

    // Shared with CustomGeometrySourceNAPI; the trailing strings keep the
    // historical per-wrapper log wording.
    return QuerySourceFeaturesImpl(env, info, source, querySourceFeaturesFn(),
                                   "GeoJsonSourceNAPI",
                                   "querySourceFeatures callback not set - renderer not ready",
                                   "Failed to parse filter expression");
}

// ==================== Clustering utilities ====================

// Parse a cluster id given as a number or as a feature object carrying
// "cluster_id" (shared by GetClusterChildren/Leaves/ExpansionZoom).
static uint64_t ParseClusterId(napi_env env, napi_value value) {
    uint64_t clusterId = 0;
    if (IsNumber(env, value)) {
        double number = 0;
        napi_get_value_double(env, value, &number);
        clusterId = static_cast<uint64_t>(number);
    } else if (IsObject(env, value)) {
        auto feature = GeoJsonConverter::JsObjectToFeature(env, value);
        if (feature.properties.count("cluster_id")) {
            auto& idValue = feature.properties["cluster_id"];
            if (idValue.is<double>()) {
                clusterId = static_cast<uint64_t>(idValue.get<double>());
            } else if (idValue.is<uint64_t>()) {
                clusterId = idValue.get<uint64_t>();
            }
        }
    }
    return clusterId;
}

// Build the synthetic feature that carries the cluster id into the
// supercluster extension query.
static mbgl::Feature MakeClusterFeature(uint64_t clusterId) {
    mbgl::Feature feature;
    feature.properties["cluster_id"] = clusterId;
    return feature;
}

napi_value GeoJsonSourceNAPI::GetClusterChildren(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, jsThis, &sourceNapi, false);
    if (!source) {
        return CreateEmptyArray(env);
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetClusterChildren requires clusterId or feature argument");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        if (!queryFeatureExtensionsFn()) {
            Logger::error("GeoJsonSourceNAPI", "GetClusterChildren: queryFeatureExtensions callback not set");
            napi_throw_error(env, nullptr, "Renderer not initialized - cluster query callback not set");
            napi_value result;
            napi_create_array(env, &result);
            return result;
        }
        
        // Parse clusterId (number or feature object carrying "cluster_id")
        uint64_t clusterId = ParseClusterId(env, args[0]);
        
        mbgl::Feature clusterFeature = MakeClusterFeature(clusterId);
        
        // Query the extension
        auto extResult = queryFeatureExtensionsFn()(
            source->getID(),
            clusterFeature,
            "supercluster",
            "children",
            std::nullopt);
        
        // The result is either a FeatureCollection or a Value
        if (extResult.is<mbgl::FeatureCollection>()) {
            auto& collection = extResult.get<mbgl::FeatureCollection>();
            Logger::info("GeoJsonSourceNAPI", "GetClusterChildren: %zu children for cluster %llu",
                        collection.size(), clusterId);
            // Convert FeatureCollection to vector<Feature> for the converter
            std::vector<mbgl::Feature> features(collection.begin(), collection.end());
            return GeoJsonConverter::FeatureArrayToJsArray(env, features);
        }
        
        Logger::warn("GeoJsonSourceNAPI", "GetClusterChildren: unexpected result type for cluster %llu", clusterId);
        napi_value result;
        napi_create_array(env, &result);
        return result;
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "GetClusterChildren failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

napi_value GeoJsonSourceNAPI::GetClusterLeaves(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, jsThis, &sourceNapi, false);
    if (!source) {
        return CreateEmptyArray(env);
    }
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "GetClusterLeaves requires clusterId, limit, and offset arguments");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        if (!queryFeatureExtensionsFn()) {
            Logger::error("GeoJsonSourceNAPI", "GetClusterLeaves: queryFeatureExtensions callback not set");
            napi_throw_error(env, nullptr, "Renderer not initialized - cluster query callback not set");
            napi_value result;
            napi_create_array(env, &result);
            return result;
        }
        
        // Parse clusterId (number or feature object carrying "cluster_id")
        uint64_t clusterId = ParseClusterId(env, args[0]);
        
        // Parse limit and offset
        double limitValue = 10, offsetValue = 0;
        napi_get_value_double(env, args[1], &limitValue);
        napi_get_value_double(env, args[2], &offsetValue);
        
        uint64_t limit = static_cast<uint64_t>(limitValue);
        uint64_t offset = static_cast<uint64_t>(offsetValue);
        
        mbgl::Feature clusterFeature = MakeClusterFeature(clusterId);
        
        // Build args map (must use uint64_t for getProperty<uint64_t> in render_geojson_source.cpp)
        std::map<std::string, mbgl::Value> queryArgs;
        queryArgs["limit"] = static_cast<uint64_t>(limit);
        queryArgs["offset"] = static_cast<uint64_t>(offset);
        
        // Query the extension
        auto extResult = queryFeatureExtensionsFn()(
            source->getID(),
            clusterFeature,
            "supercluster",
            "leaves",
            std::make_optional(std::move(queryArgs)));
        
        // The result is either a FeatureCollection or a Value
        if (extResult.is<mbgl::FeatureCollection>()) {
            auto& collection = extResult.get<mbgl::FeatureCollection>();
            Logger::info("GeoJsonSourceNAPI", "GetClusterLeaves: %zu leaves for cluster %llu (limit=%llu, offset=%llu)",
                        collection.size(), clusterId, limit, offset);
            // Convert FeatureCollection to vector<Feature> for the converter
            std::vector<mbgl::Feature> features(collection.begin(), collection.end());
            return GeoJsonConverter::FeatureArrayToJsArray(env, features);
        }
        
        Logger::warn("GeoJsonSourceNAPI", "GetClusterLeaves: unexpected result type for cluster %llu", clusterId);
        napi_value result;
        napi_create_array(env, &result);
        return result;
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "GetClusterLeaves failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

napi_value GeoJsonSourceNAPI::GetClusterExpansionZoom(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, jsThis, &sourceNapi, false);
    if (!source) {
        return CreateDoubleValue(env, 0.0);
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetClusterExpansionZoom requires clusterId or feature argument");
        return CreateDoubleValue(env, 0.0);
    }
    
    try {
        if (!queryFeatureExtensionsFn()) {
            Logger::error("GeoJsonSourceNAPI", "GetClusterExpansionZoom: queryFeatureExtensions callback not set");
            napi_throw_error(env, nullptr, "Renderer not initialized - cluster query callback not set");
            return CreateDoubleValue(env, 0.0);
        }
        
        // Parse clusterId (number or feature object carrying "cluster_id")
        uint64_t clusterId = ParseClusterId(env, args[0]);
        
        mbgl::Feature clusterFeature = MakeClusterFeature(clusterId);
        
        // Query the extension
        auto extResult = queryFeatureExtensionsFn()(
            source->getID(),
            clusterFeature,
            "supercluster",
            "expansion-zoom",
            std::nullopt);
        
        // The result is either a Value (number) or a FeatureCollection
        if (extResult.is<mbgl::Value>()) {
            auto& val = extResult.get<mbgl::Value>();
            if (val.is<double>()) {
                double zoom = val.get<double>();
                Logger::info("GeoJsonSourceNAPI", "GetClusterExpansionZoom: cluster %llu -> zoom %.2f", 
                            clusterId, zoom);
                return CreateDoubleValue(env, zoom);
            } else if (val.is<uint64_t>()) {
                double zoom = static_cast<double>(val.get<uint64_t>());
                Logger::info("GeoJsonSourceNAPI", "GetClusterExpansionZoom: cluster %llu -> zoom %.0f", 
                            clusterId, zoom);
                return CreateDoubleValue(env, zoom);
            } else if (val.is<int64_t>()) {
                double zoom = static_cast<double>(val.get<int64_t>());
                Logger::info("GeoJsonSourceNAPI", "GetClusterExpansionZoom: cluster %llu -> zoom %.0f", 
                            clusterId, zoom);
                return CreateDoubleValue(env, zoom);
            }
        }
        
        Logger::warn("GeoJsonSourceNAPI", "GetClusterExpansionZoom: unexpected result type for cluster %llu", clusterId);
        return CreateDoubleValue(env, 0.0);
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "GetClusterExpansionZoom failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return CreateDoubleValue(env, 0.0);
    }
}

} // namespace harmony
} // namespace mbgl

