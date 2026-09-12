#include "custom_geometry_source_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "core/thread_safe_callback.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "geojson/geojson_converter.hpp"
#include "geojson/util.hpp"
#include "style/filter_conversion.hpp"
#include "style/conversion/harmony_conversion.hpp"
#include <mbgl/style/conversion/custom_geometry_source_options.hpp>
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/util/geo.hpp>

#include <mutex>
#include "napi/core/napi_wrap_instance.hpp"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;
using ThreadSafeCallback = mbgl::harmony::ThreadSafeCallback;

namespace mbgl {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

using namespace mbgl::harmony::geojson;

// Static member initialization
napi_ref CustomGeometrySourceNAPI::constructor = nullptr;
napi_env CustomGeometrySourceNAPI::constructorEnv = nullptr;

namespace {
// Renderer query hook + its owner (see the header for the ownership rules).
std::mutex s_queryHookMutex;
CustomGeometrySourceNAPI::QuerySourceFeaturesFn s_queryHook;
void* s_queryHookOwner = nullptr;
} // anonymous namespace

void CustomGeometrySourceNAPI::setQuerySourceFeaturesFn(QuerySourceFeaturesFn fn, void* owner) {
    std::lock_guard<std::mutex> lock(s_queryHookMutex);
    s_queryHook = std::move(fn);
    s_queryHookOwner = owner;
}

void CustomGeometrySourceNAPI::clearQuerySourceFeaturesFn(void* owner) {
    std::lock_guard<std::mutex> lock(s_queryHookMutex);
    if (s_queryHookOwner != owner) {
        return;
    }
    s_queryHook = nullptr;
    s_queryHookOwner = nullptr;
}

CustomGeometrySourceNAPI::QuerySourceFeaturesFn CustomGeometrySourceNAPI::querySourceFeaturesFn() {
    std::lock_guard<std::mutex> lock(s_queryHookMutex);
    return s_queryHook;
}

CustomGeometrySourceNAPI::CustomGeometrySourceNAPI(const std::string& id,
                                                   std::unique_ptr<mbgl::style::CustomGeometrySource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource instance created: %s", id.c_str());
}

CustomGeometrySourceNAPI::CustomGeometrySourceNAPI(mbgl::style::CustomGeometrySource* sourcePtr)
    : ownsSource(false) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        weakSource = sourcePtr->makeWeakPtr();
        Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource created from existing source (WeakPtr): %s",
                     id.c_str());
    }
}

CustomGeometrySourceNAPI::~CustomGeometrySourceNAPI() {
    Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource instance destroyed: %s", id.c_str());
}

void CustomGeometrySourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    CustomGeometrySourceNAPI* sourceNapi = static_cast<CustomGeometrySourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value CustomGeometrySourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("CustomGeometrySourceNAPI", "Initializing CustomGeometrySource NAPI class");

    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTileData", nullptr, SetTileData, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "invalidateTile", nullptr, InvalidateTile, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "invalidateRegion", nullptr, InvalidateRegion, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "querySourceFeatures", nullptr, QuerySourceFeatures, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_value cons;
    napi_status status = napi_define_class(env, "CustomGeometrySource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);

    if (status != napi_ok) {
        Logger::error("CustomGeometrySourceNAPI", "Failed to define CustomGeometrySource class");
        return nullptr;
    }

    status = mbgl::harmony::RefreshConstructorRef(env, cons, constructor, constructorEnv);
    if (status != napi_ok) {
        Logger::error("CustomGeometrySourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }

    status = napi_set_named_property(env, exports, "CustomGeometrySource", cons);
    if (status != napi_ok) {
        Logger::error("CustomGeometrySourceNAPI", "Failed to set CustomGeometrySource property");
        return nullptr;
    }

    Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource NAPI class initialized successfully");
    return exports;
}

napi_value CustomGeometrySourceNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }

    try {
        mbgl::style::CustomGeometrySource::Options options;

        if (args.Count() >= 2) {
            napi_value optionsObj = args.GetObject(1, "options");
            if (!args.HasError() && optionsObj) {
                // Convert minzoom/maxzoom/buffer/tolerance/wrap/clip through the
                // core converter (same keys as Android CustomGeometrySourceOptions)
                mbgl::style::conversion::Error error;
                mbgl::style::conversion::Convertible convertible(mbgl::harmony::NapiValue(env, optionsObj));
                auto converted =
                    mbgl::style::conversion::convert<mbgl::style::CustomGeometrySource::Options>(convertible, error);
                if (converted) {
                    options = std::move(*converted);
                } else {
                    Logger::warn("CustomGeometrySourceNAPI", "Options conversion warning: %s", error.message.c_str());
                }

                // fetchTile / cancelTile callbacks are marshalled to the JS
                // thread; core invokes them from tile worker threads.
                napi_value fetchFn = nullptr;
                napi_get_named_property(env, optionsObj, "fetchTile", &fetchFn);
                napi_valuetype fetchType = napi_undefined;
                if (fetchFn) napi_typeof(env, fetchFn, &fetchType);
                if (fetchType == napi_function) {
                    auto cb = ThreadSafeCallback::Create(env, fetchFn, "CustomGeometrySource.fetchTile");
                    if (cb) {
                        auto sharedCb = std::shared_ptr<ThreadSafeCallback>(cb.release());
                        options.fetchTileFunction = [sharedCb](const mbgl::CanonicalTileID& tileID) {
                            const uint32_t z = tileID.z, x = tileID.x, y = tileID.y;
                            sharedCb->Call([z, x, y](napi_env env) -> napi_value {
                                napi_value result;
                                napi_create_object(env, &result);
                                napi_value zv, xv, yv;
                                napi_create_uint32(env, z, &zv);
                                napi_create_uint32(env, x, &xv);
                                napi_create_uint32(env, y, &yv);
                                napi_set_named_property(env, result, "z", zv);
                                napi_set_named_property(env, result, "x", xv);
                                napi_set_named_property(env, result, "y", yv);
                                return result;
                            });
                        };
                    }
                }

                napi_value cancelFn = nullptr;
                napi_get_named_property(env, optionsObj, "cancelTile", &cancelFn);
                napi_valuetype cancelType = napi_undefined;
                if (cancelFn) napi_typeof(env, cancelFn, &cancelType);
                if (cancelType == napi_function) {
                    auto cb = ThreadSafeCallback::Create(env, cancelFn, "CustomGeometrySource.cancelTile");
                    if (cb) {
                        auto sharedCb = std::shared_ptr<ThreadSafeCallback>(cb.release());
                        options.cancelTileFunction = [sharedCb](const mbgl::CanonicalTileID& tileID) {
                            const uint32_t z = tileID.z, x = tileID.x, y = tileID.y;
                            sharedCb->Call([z, x, y](napi_env env) -> napi_value {
                                napi_value result;
                                napi_create_object(env, &result);
                                napi_value zv, xv, yv;
                                napi_create_uint32(env, z, &zv);
                                napi_create_uint32(env, x, &xv);
                                napi_create_uint32(env, y, &yv);
                                napi_set_named_property(env, result, "z", zv);
                                napi_set_named_property(env, result, "x", xv);
                                napi_set_named_property(env, result, "y", yv);
                                return result;
                            });
                        };
                    }
                }
            }
        }

        auto source = std::make_unique<mbgl::style::CustomGeometrySource>(sourceId, std::move(options));

        CustomGeometrySourceNAPI* sourceNapi = new CustomGeometrySourceNAPI(sourceId, std::move(source));

        napi_status status = napi_wrap(env, args.This(), sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap CustomGeometrySource object");
            return nullptr;
        }

        // Add the _TYPE_ property for ETS type detection
        napi_value typeValue;
        napi_create_string_utf8(env, "CustomGeometrySource", NAPI_AUTO_LENGTH, &typeValue);
        napi_set_named_property(env, args.This(), "_TYPE_", typeValue);

        Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource created: %s", sourceId.c_str());
        return args.This();
    } catch (const std::exception& e) {
        Logger::error("CustomGeometrySourceNAPI", "Failed to create CustomGeometrySource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value CustomGeometrySourceNAPI::CreateInstance(napi_env env, mbgl::style::CustomGeometrySource* sourcePtr) {
    return mbgl::harmony::WrapExistingInstance(env, constructor, Destructor, "CustomGeometrySource",
                                sourcePtr ? new CustomGeometrySourceNAPI(sourcePtr) : nullptr);
}

napi_value CustomGeometrySourceNAPI::GetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    CustomGeometrySourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }

    return CreateStringValue(env, sourceNapi->id);
}

napi_value CustomGeometrySourceNAPI::SetTileData(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    if (args.HasError()) return nullptr;

    CustomGeometrySourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }

    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }

    const uint32_t z = args.GetUint32(0, "zoomLevel");
    const uint32_t x = args.GetUint32(1, "x");
    const uint32_t y = args.GetUint32(2, "y");
    if (args.HasError()) return nullptr;

    napi_value dataValue = args.GetValue(3);

    try {
        mbgl::GeoJSON geoJson;
        napi_valuetype dataType = napi_undefined;
        napi_typeof(env, dataValue, &dataType);

        if (dataType == napi_string) {
            std::string geoJsonString = args.GetString(3, "data");
            if (args.HasError()) return nullptr;

            mbgl::style::conversion::Error error;
            auto parsed = mbgl::style::conversion::convertJSON<mbgl::GeoJSON>(geoJsonString, error);
            if (!parsed) {
                napi_throw_error(env, nullptr, error.message.c_str());
                return nullptr;
            }
            geoJson = std::move(*parsed);
        } else if (dataType == napi_object) {
            // Object payload: FeatureCollection, Feature, or Geometry
            std::string type;
            if (HasProperty(env, dataValue, "type")) {
                type = GetStringProperty(env, dataValue, "type");
            }

            if (type == "Feature") {
                auto feature = GeoJsonConverter::JsObjectToFeature(env, dataValue);
                mbgl::GeoJSONFeature geoJsonFeature;
                geoJsonFeature.geometry = feature.geometry;
                geoJsonFeature.properties = feature.properties;
                geoJsonFeature.id = feature.id;
                geoJson = mbgl::GeoJSON(std::move(geoJsonFeature));
            } else if (type == "FeatureCollection") {
                geoJson = mbgl::GeoJSON(GeoJsonConverter::JsObjectToFeatureCollection(env, dataValue));
            } else {
                geoJson = mbgl::GeoJSON(GeoJsonConverter::JsObjectToGeometry(env, dataValue));
            }
        } else {
            napi_throw_error(env, nullptr, "Tile data must be a GeoJSON string or object");
            return nullptr;
        }

        source->setTileData(mbgl::CanonicalTileID(static_cast<uint8_t>(z),
                                                  static_cast<uint32_t>(x),
                                                  static_cast<uint32_t>(y)),
                            geoJson);
    } catch (const std::exception& e) {
        Logger::error("CustomGeometrySourceNAPI", "SetTileData failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

    return nullptr;
}

napi_value CustomGeometrySourceNAPI::InvalidateTile(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(3);
    if (args.HasError()) return nullptr;

    CustomGeometrySourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }

    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }

    const uint32_t z = args.GetUint32(0, "zoomLevel");
    const uint32_t x = args.GetUint32(1, "x");
    const uint32_t y = args.GetUint32(2, "y");
    if (args.HasError()) return nullptr;

    try {
        source->invalidateTile(mbgl::CanonicalTileID(static_cast<uint8_t>(z),
                                                     static_cast<uint32_t>(x),
                                                     static_cast<uint32_t>(y)));
    } catch (const std::exception& e) {
        Logger::error("CustomGeometrySourceNAPI", "InvalidateTile failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }

    return nullptr;
}

napi_value CustomGeometrySourceNAPI::InvalidateRegion(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    CustomGeometrySourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }

    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }

    napi_value boundsObj = args.GetObject(0, "bounds");
    if (args.HasError()) return nullptr;

    mbgl::LatLngBounds bounds;
    if (!mbgl::harmony::LatLngBoundsHarmony::ParseLatLngBounds(env, boundsObj, bounds)) {
        napi_throw_error(env, nullptr, "Failed to parse LatLngBounds");
        return nullptr;
    }

    try {
        source->invalidateRegion(bounds);
    } catch (const std::exception& e) {
        Logger::error("CustomGeometrySourceNAPI", "InvalidateRegion failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }

    return nullptr;
}

napi_value CustomGeometrySourceNAPI::QuerySourceFeatures(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    CustomGeometrySourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

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
        if (!querySourceFeaturesFn()) {
            Logger::warn("CustomGeometrySourceNAPI",
                         "QuerySourceFeatures: query callback not set - renderer not ready");
            napi_value result;
            napi_create_array(env, &result);
            return result;
        }

        mbgl::SourceQueryOptions options;
        if (args.Count() >= 1) {
            napi_value filterValue = args.GetValue(0);
            napi_valuetype type = napi_undefined;
            napi_typeof(env, filterValue, &type);
            if (type == napi_object) {
                bool isArray = false;
                napi_is_array(env, filterValue, &isArray);
                if (isArray) {
                    auto filter = mbgl::harmony::napiArrayToFilter(env, filterValue);
                    if (filter.has_value()) {
                        options.filter = std::move(*filter);
                    } else {
                        Logger::warn("CustomGeometrySourceNAPI", "QuerySourceFeatures: Failed to parse filter");
                    }
                }
            }
        }

        std::vector<mbgl::Feature> features = querySourceFeaturesFn()(source->getID(), options);

        Logger::info("CustomGeometrySourceNAPI", "QuerySourceFeatures: %zu features from source '%s'",
                     features.size(), source->getID().c_str());

        return GeoJsonConverter::FeatureArrayToJsArray(env, features);
    } catch (const std::exception& e) {
        Logger::error("CustomGeometrySourceNAPI", "QuerySourceFeatures failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

} // namespace harmony
} // namespace mbgl
