#include "geojson_source_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "geojson/geojson_converter.hpp"
#include "geojson/util.hpp"
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/style/conversion/geojson_options.hpp>
#include <mbgl/util/geojson.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;
using namespace maplibre::harmony::geojson;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref GeoJsonSourceNAPI::constructor = nullptr;
GeoJsonSourceNAPI::QueryFeatureExtensionsFn GeoJsonSourceNAPI::queryFeatureExtensionsFn_ = nullptr;

GeoJsonSourceNAPI::GeoJsonSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::GeoJSONSource> source)
    : id(id), source(std::move(source)), ownsSource(true), rawSourceFallback(nullptr) {
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource instance created: %s", id.c_str());
}

GeoJsonSourceNAPI::GeoJsonSourceNAPI(mbgl::style::GeoJSONSource* sourcePtr)
    : ownsSource(false), rawSourceFallback(nullptr) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        auto weak = sourcePtr->makeWeakPtr();
        if (weak) {
            weakSource = std::move(weak);
            Logger::info("GeoJsonSourceNAPI", "GeoJsonSource created from existing source (WeakPtr): %s", id.c_str());
        } else {
            rawSourceFallback = sourcePtr;
            Logger::warn("GeoJsonSourceNAPI", "GeoJsonSource created from existing source but WeakPtr initialization failed: %s", id.c_str());
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
    return rawSourceFallback;
}

void GeoJsonSourceNAPI::attachToStyle(mbgl::style::GeoJSONSource* sourcePtr) {
    if (!sourcePtr) {
        Logger::warn("GeoJsonSourceNAPI", "attachToStyle called with null source pointer");
        return;
    }

    auto weak = sourcePtr->makeWeakPtr();
    if (weak) {
        weakSource = std::move(weak);
        rawSourceFallback = nullptr;
        Logger::info("GeoJsonSourceNAPI", "attachToStyle: WeakPtr initialized successfully for source %s", id.c_str());
    } else {
        rawSourceFallback = sourcePtr;
        Logger::warn("GeoJsonSourceNAPI", "attachToStyle: WeakPtr initialization failed, storing raw pointer temporarily for source %s", id.c_str());
    }
}

GeoJsonSourceNAPI::~GeoJsonSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource instance destroyed: %s", id.c_str());
}

void GeoJsonSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    GeoJsonSourceNAPI* sourceNapi = static_cast<GeoJsonSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

void GeoJsonSourceNAPI::setQueryFeatureExtensionsFn(QueryFeatureExtensionsFn fn) {
    queryFeatureExtensionsFn_ = std::move(fn);
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
    
    napi_value cons;
    napi_status status = napi_define_class(env, "GeoJsonSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to define GeoJsonSource class");
        return nullptr;
    }
    
    // Create the constructor reference
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    // Add the constructor to exports
    status = napi_set_named_property(env, exports, "GeoJsonSource", cons);
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to set GeoJsonSource property");
        return nullptr;
    }
    
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
                // Parse cluster option
                if (HasProperty(env, optionsObj, "cluster")) {
                    bool cluster = false;
                    napi_value clusterValue;
                    napi_get_named_property(env, optionsObj, "cluster", &clusterValue);
                    napi_get_value_bool(env, clusterValue, &cluster);
                    options.cluster = cluster;
                }
                
                // Parse clusterRadius
                if (HasProperty(env, optionsObj, "clusterRadius")) {
                    int32_t radius = 50;
                    napi_value radiusValue;
                    napi_get_named_property(env, optionsObj, "clusterRadius", &radiusValue);
                    napi_get_value_int32(env, radiusValue, &radius);
                    options.clusterRadius = static_cast<uint16_t>(radius);
                }
                
                // Parse clusterMaxZoom
                if (HasProperty(env, optionsObj, "clusterMaxZoom")) {
                    int32_t maxZoom = 16;
                    napi_value maxZoomValue;
                    napi_get_named_property(env, optionsObj, "clusterMaxZoom", &maxZoomValue);
                    napi_get_value_int32(env, maxZoomValue, &maxZoom);
                    options.clusterMaxZoom = static_cast<uint8_t>(maxZoom);
                }
                
                // Parse minzoom
                if (HasProperty(env, optionsObj, "minzoom")) {
                    int32_t minzoom = 0;
                    napi_value minzoomValue;
                    napi_get_named_property(env, optionsObj, "minzoom", &minzoomValue);
                    napi_get_value_int32(env, minzoomValue, &minzoom);
                    options.minzoom = static_cast<uint8_t>(minzoom);
                }
                
                // Parse maxzoom
                if (HasProperty(env, optionsObj, "maxzoom")) {
                    int32_t maxzoom = 18;
                    napi_value maxzoomValue;
                    napi_get_named_property(env, optionsObj, "maxzoom", &maxzoomValue);
                    napi_get_value_int32(env, maxzoomValue, &maxzoom);
                    options.maxzoom = static_cast<uint8_t>(maxzoom);
                }
                
                // Parse buffer
                if (HasProperty(env, optionsObj, "buffer")) {
                    int32_t buffer = 128;
                    napi_value bufferValue;
                    napi_get_named_property(env, optionsObj, "buffer", &bufferValue);
                    napi_get_value_int32(env, bufferValue, &buffer);
                    options.buffer = static_cast<uint16_t>(buffer);
                }
                
                // Parse tolerance
                if (HasProperty(env, optionsObj, "tolerance")) {
                    double tolerance = 0.375;
                    napi_value toleranceValue;
                    napi_get_named_property(env, optionsObj, "tolerance", &toleranceValue);
                    napi_get_value_double(env, toleranceValue, &tolerance);
                    options.tolerance = tolerance;
                }
                
                // Parse lineMetrics
                if (HasProperty(env, optionsObj, "lineMetrics")) {
                    bool lineMetrics = false;
                    napi_value lineMetricsValue;
                    napi_get_named_property(env, optionsObj, "lineMetrics", &lineMetricsValue);
                    napi_get_value_bool(env, lineMetricsValue, &lineMetrics);
                    options.lineMetrics = lineMetrics;
                }
                
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
                            
                            // Retrieve the expression array [mapExpr, reduceExpr] for this property
                            napi_value expressionArray;
                            napi_get_property(env, clusterPropsValue, propertyNameValue, &expressionArray);
                            
                            bool isArray = false;
                            napi_is_array(env, expressionArray, &isArray);
                            
                            if (isArray) {
                                uint32_t arrayLength = 0;
                                napi_get_array_length(env, expressionArray, &arrayLength);
                                
                                if (arrayLength >= 2) {
                                    // Retrieve the map and reduce expressions
                                    napi_value mapExprValue, reduceExprValue;
                                    napi_get_element(env, expressionArray, 0, &mapExprValue);
                                    napi_get_element(env, expressionArray, 1, &reduceExprValue);
                                    
                                    // Convert to mbgl Expression
                                    // TODO: clusterProperties require specialized expression conversion
                                    // Currently we skip parsing clusterProperties
                                    // A future version could transmit them as JSON strings
                                    Logger::warn("GeoJsonSourceNAPI", 
                                                "clusterProperties[\"%s\"]: Expression conversion not yet implemented", 
                                                propertyName.c_str());
                                }
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

napi_value GeoJsonSourceNAPI::CreateInstance(napi_env env, mbgl::style::GeoJSONSource* sourcePtr) {
    if (!sourcePtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create a plain object and set its prototype (avoid invoking the JS constructor)
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor prototype
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Set the object's prototype
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create the NAPI wrapper (using the WeakPtr constructor)
    GeoJsonSourceNAPI* napiObj = new GeoJsonSourceNAPI(sourcePtr);
    
    // Wrap into the JS object
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("GeoJsonSourceNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Add the _TYPE_ property
    napi_value typeValue;
    napi_create_string_utf8(env, "GeoJsonSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}

// ==================== Getters ====================

napi_value GeoJsonSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

// ==================== Data management ====================

napi_value GeoJsonSourceNAPI::SetGeoJson(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetGeoJson requires data argument");
        return nullptr;
    }
    
    try {
        // Detect the argument type
        if (IsString(env, args[0])) {
            // String type: parse JSON
            NapiArgs napiArgs(env, info);
            std::string geoJsonString = napiArgs.GetString(0, "geoJson");
            
            if (napiArgs.HasError()) {
                return nullptr;
            }
            
            mbgl::style::conversion::Error error;
            auto geoJson = mbgl::style::conversion::convertJSON<mbgl::GeoJSON>(geoJsonString, error);
            
            if (geoJson) {
                source->setGeoJSON(std::move(*geoJson));
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (string): %s", sourceNapi->id.c_str());
            } else {
                napi_throw_error(env, nullptr, error.message.c_str());
            }
        } else if (IsObject(env, args[0])) {
            // Object type: inspect the type property
            std::string type;
            if (HasProperty(env, args[0], "type")) {
                type = GetStringProperty(env, args[0], "type");
            }
            
            if (type == "FeatureCollection") {
                // FeatureCollection object
                auto collection = GeoJsonConverter::JsObjectToFeatureCollection(env, args[0]);
                source->setGeoJSON(mbgl::GeoJSON(std::move(collection)));
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (FeatureCollection): %s", sourceNapi->id.c_str());
            } else if (type == "Feature") {
                // Feature object
                auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
                // Convert to GeoJSONFeature
                mbgl::GeoJSONFeature geoJsonFeature;
                geoJsonFeature.geometry = feature.geometry;
                geoJsonFeature.properties = feature.properties;
                geoJsonFeature.id = feature.id;
                source->setGeoJSON(mbgl::GeoJSON(std::move(geoJsonFeature)));
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (Feature): %s", sourceNapi->id.c_str());
            } else {
                // Geometry object
                auto geometry = GeoJsonConverter::JsObjectToGeometry(env, args[0]);
                source->setGeoJSON(mbgl::GeoJSON(std::move(geometry)));
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (Geometry): %s, type: %s", 
                           sourceNapi->id.c_str(), type.c_str());
            }
        } else {
            napi_throw_error(env, nullptr, "GeoJson data must be a string or object");
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
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
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

napi_value GeoJsonSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        return CreateStringValue(env, "");
    }
    
    try {
        auto url = source->getURL();
        if (url) {
            return CreateStringValue(env, *url);
        }
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

// ==================== Query features ====================

napi_value GeoJsonSourceNAPI::QuerySourceFeatures(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        // TODO: requires accessing the rendererFrontend to query features
        // Similar to the Android implementation:
        // features = rendererFrontend->querySourceFeatures(source.getID(), {{}, filter});
        
        // Return an empty array for now
        Logger::warn("GeoJsonSourceNAPI", "QuerySourceFeatures: rendererFrontend access not yet implemented");
        
        std::vector<mbgl::Feature> features;
        // Here we should obtain features from the rendererFrontend
        
        // Convert the results into a NAPI array
        return GeoJsonConverter::FeatureArrayToJsArray(env, features);
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "QuerySourceFeatures failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

// ==================== Clustering utilities ====================

napi_value GeoJsonSourceNAPI::GetClusterChildren(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetClusterChildren requires clusterId or feature argument");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        if (!queryFeatureExtensionsFn_) {
            Logger::error("GeoJsonSourceNAPI", "GetClusterChildren: queryFeatureExtensions callback not set");
            napi_throw_error(env, nullptr, "Renderer not initialized - cluster query callback not set");
            napi_value result;
            napi_create_array(env, &result);
            return result;
        }
        
        // Parse clusterId
        uint64_t clusterId = 0;
        if (IsNumber(env, args[0])) {
            double value = 0;
            napi_get_value_double(env, args[0], &value);
            clusterId = static_cast<uint64_t>(value);
        } else if (IsObject(env, args[0])) {
            auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
            if (feature.properties.count("cluster_id")) {
                auto& idValue = feature.properties["cluster_id"];
                if (idValue.is<double>()) {
                    clusterId = static_cast<uint64_t>(idValue.get<double>());
                } else if (idValue.is<uint64_t>()) {
                    clusterId = idValue.get<uint64_t>();
                }
            }
        }
        
        // Build a Feature with cluster_id property
        mbgl::Feature clusterFeature;
        clusterFeature.properties["cluster_id"] = static_cast<uint64_t>(clusterId);
        
        // Query the extension
        auto extResult = queryFeatureExtensionsFn_(
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
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "GetClusterLeaves requires clusterId, limit, and offset arguments");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        if (!queryFeatureExtensionsFn_) {
            Logger::error("GeoJsonSourceNAPI", "GetClusterLeaves: queryFeatureExtensions callback not set");
            napi_throw_error(env, nullptr, "Renderer not initialized - cluster query callback not set");
            napi_value result;
            napi_create_array(env, &result);
            return result;
        }
        
        // Parse clusterId
        uint64_t clusterId = 0;
        if (IsNumber(env, args[0])) {
            double value = 0;
            napi_get_value_double(env, args[0], &value);
            clusterId = static_cast<uint64_t>(value);
        } else if (IsObject(env, args[0])) {
            auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
            if (feature.properties.count("cluster_id")) {
                auto& idValue = feature.properties["cluster_id"];
                if (idValue.is<double>()) {
                    clusterId = static_cast<uint64_t>(idValue.get<double>());
                } else if (idValue.is<uint64_t>()) {
                    clusterId = idValue.get<uint64_t>();
                }
            }
        }
        
        // Parse limit and offset
        double limitValue = 10, offsetValue = 0;
        napi_get_value_double(env, args[1], &limitValue);
        napi_get_value_double(env, args[2], &offsetValue);
        
        uint64_t limit = static_cast<uint64_t>(limitValue);
        uint64_t offset = static_cast<uint64_t>(offsetValue);
        
        // Build a Feature with cluster_id property
        mbgl::Feature clusterFeature;
        clusterFeature.properties["cluster_id"] = static_cast<uint64_t>(clusterId);
        
        // Build args map (must use uint64_t for getProperty<uint64_t> in render_geojson_source.cpp)
        std::map<std::string, mbgl::Value> queryArgs;
        queryArgs["limit"] = static_cast<uint64_t>(limit);
        queryArgs["offset"] = static_cast<uint64_t>(offset);
        
        // Query the extension
        auto extResult = queryFeatureExtensionsFn_(
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
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateDoubleValue(env, 0.0);
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        return CreateDoubleValue(env, 0.0);
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetClusterExpansionZoom requires clusterId or feature argument");
        return CreateDoubleValue(env, 0.0);
    }
    
    try {
        if (!queryFeatureExtensionsFn_) {
            Logger::error("GeoJsonSourceNAPI", "GetClusterExpansionZoom: queryFeatureExtensions callback not set");
            napi_throw_error(env, nullptr, "Renderer not initialized - cluster query callback not set");
            return CreateDoubleValue(env, 0.0);
        }
        
        // Parse clusterId
        uint64_t clusterId = 0;
        if (IsNumber(env, args[0])) {
            double value = 0;
            napi_get_value_double(env, args[0], &value);
            clusterId = static_cast<uint64_t>(value);
        } else if (IsObject(env, args[0])) {
            auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
            if (feature.properties.count("cluster_id")) {
                auto& idValue = feature.properties["cluster_id"];
                if (idValue.is<double>()) {
                    clusterId = static_cast<uint64_t>(idValue.get<double>());
                } else if (idValue.is<uint64_t>()) {
                    clusterId = idValue.get<uint64_t>();
                }
            }
        }
        
        // Build a Feature with cluster_id property
        mbgl::Feature clusterFeature;
        clusterFeature.properties["cluster_id"] = static_cast<uint64_t>(clusterId);
        
        // Query the extension
        auto extResult = queryFeatureExtensionsFn_(
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
} // namespace maplibre

