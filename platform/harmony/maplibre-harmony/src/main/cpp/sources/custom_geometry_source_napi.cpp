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
#include <mln/style/conversion/custom_geometry_source_options.hpp>
#include <mln/style/conversion/json.hpp>
#include <mln/util/geo.hpp>

#include <mutex>
#include "napi/core/napi_wrap_instance.hpp"

#include "source_napi_utils.hpp"
#include "query_source_features.hpp"
#include "geojson/napi_geojson_value.hpp"
using namespace mln::harmony::napi;
using mln::harmony::Logger;
using ThreadSafeCallback = mln::harmony::ThreadSafeCallback;

namespace mln {

using mln::harmony::napi::NapiArgs;
namespace harmony {

using namespace mln::harmony::geojson;

namespace {

// Build the {z, x, y} object handed to the JS fetchTile/cancelTile callbacks
// (shared by both callbacks).
napi_value MakeTileIDObject(napi_env env, uint32_t z, uint32_t x, uint32_t y) {
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
}

} // namespace

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
                                                   std::unique_ptr<mln::style::CustomGeometrySource> source)
    : SourceNapiBase(id, std::move(source)) {
    Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource instance created: %s", id.c_str());
}

CustomGeometrySourceNAPI::CustomGeometrySourceNAPI(mln::style::CustomGeometrySource* sourcePtr)
    : SourceNapiBase(sourcePtr) {
    if (sourcePtr) {
        Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource created from existing source (WeakPtr): %s",
                     id.c_str());
    }
}

CustomGeometrySourceNAPI::~CustomGeometrySourceNAPI() {
    Logger::info("CustomGeometrySourceNAPI", "CustomGeometrySource instance destroyed: %s", id.c_str());
}

DEFINE_SOURCE_DESTRUCTOR(CustomGeometrySourceNAPI)

napi_value CustomGeometrySourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("CustomGeometrySourceNAPI", "Initializing CustomGeometrySource NAPI class");

    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTileData", nullptr, SetTileData, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "invalidateTile", nullptr, InvalidateTile, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "invalidateRegion", nullptr, InvalidateRegion, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "querySourceFeatures", nullptr, QuerySourceFeatures, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_value cons = RegisterNapiClass(env, exports, "CustomGeometrySource", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "CustomGeometrySourceNAPI");
    if (!cons) return nullptr;

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
        mln::style::CustomGeometrySource::Options options;

        if (args.Count() >= 2) {
            napi_value optionsObj = args.GetObject(1, "options");
            if (!args.HasError() && optionsObj) {
                // Convert minzoom/maxzoom/buffer/tolerance/wrap/clip through the
                // core converter (same keys as Android CustomGeometrySourceOptions)
                mln::style::conversion::Error error;
                mln::style::conversion::Convertible convertible(mln::harmony::NapiValue(env, optionsObj));
                auto converted =
                    mln::style::conversion::convert<mln::style::CustomGeometrySource::Options>(convertible, error);
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
                        options.fetchTileFunction = [sharedCb](const mln::CanonicalTileID& tileID) {
                            const uint32_t z = tileID.z, x = tileID.x, y = tileID.y;
                            sharedCb->Call([z, x, y](napi_env env) -> napi_value {
                                return MakeTileIDObject(env, z, x, y);
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
                        options.cancelTileFunction = [sharedCb](const mln::CanonicalTileID& tileID) {
                            const uint32_t z = tileID.z, x = tileID.x, y = tileID.y;
                            sharedCb->Call([z, x, y](napi_env env) -> napi_value {
                                return MakeTileIDObject(env, z, x, y);
                            });
                        };
                    }
                }
            }
        }

        auto source = std::make_unique<mln::style::CustomGeometrySource>(sourceId, std::move(options));

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

DEFINE_SOURCE_CREATE_INSTANCE(CustomGeometrySourceNAPI, "CustomGeometrySource", mln::style::CustomGeometrySource)

DEFINE_SOURCE_GET_ID(CustomGeometrySourceNAPI)

napi_value CustomGeometrySourceNAPI::SetTileData(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    if (args.HasError()) return nullptr;

    CustomGeometrySourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, args.This(), &sourceNapi, true);
    if (!source) {
        return nullptr;
    }

    const uint32_t z = args.GetUint32(0, "zoomLevel");
    const uint32_t x = args.GetUint32(1, "x");
    const uint32_t y = args.GetUint32(2, "y");
    if (args.HasError()) return nullptr;

    napi_value dataValue = args.GetValue(3);

    try {
        GeoJSONValueConversion conversion;
        if (!NapiValueToGeoJSON(env, dataValue, conversion, "Tile data must be a GeoJSON string or object")) {
            return nullptr;
        }
        mln::GeoJSON geoJson = std::move(conversion.value);

        source->setTileData(mln::CanonicalTileID(static_cast<uint8_t>(z),
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
    auto* source = ResolveSource(env, args.This(), &sourceNapi, true);
    if (!source) {
        return nullptr;
    }

    const uint32_t z = args.GetUint32(0, "zoomLevel");
    const uint32_t x = args.GetUint32(1, "x");
    const uint32_t y = args.GetUint32(2, "y");
    if (args.HasError()) return nullptr;

    try {
        source->invalidateTile(mln::CanonicalTileID(static_cast<uint8_t>(z),
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
    auto* source = ResolveSource(env, args.This(), &sourceNapi, true);
    if (!source) {
        return nullptr;
    }

    napi_value boundsObj = args.GetObject(0, "bounds");
    if (args.HasError()) return nullptr;

    mln::LatLngBounds bounds;
    if (!mln::harmony::LatLngBoundsHarmony::ParseLatLngBounds(env, boundsObj, bounds)) {
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
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);

    CustomGeometrySourceNAPI* sourceNapi = NapiArgs::Unwrap<CustomGeometrySourceNAPI>(env, jsThis);
    if (!sourceNapi) {
        return CreateEmptyArray(env);
    }

    auto* source = sourceNapi->getSource();
    if (!source) {
        return CreateEmptyArray(env);
    }

    // Shared with GeoJsonSourceNAPI; the trailing strings keep the historical
    // per-wrapper log wording.
    return QuerySourceFeaturesImpl(env, info, source, querySourceFeaturesFn(),
                                   "CustomGeometrySourceNAPI",
                                   "query callback not set - renderer not ready",
                                   "Failed to parse filter");
}

} // namespace harmony
} // namespace mln
