#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"
#include "geojson/geojson_converter.hpp"
#include "style/filter_conversion.hpp"
#include "style/value_conversion.hpp"
#include "rendering/harmony_renderer.hpp"
#include <mln/map/map.hpp>
#include <mln/util/geo.hpp>
#include <mln/style/filter.hpp>
#include <mln/renderer/query.hpp>

using mln::harmony::Logger;
using mln::harmony::napi::NapiArgs;
using mln::harmony::geojson::GeoJsonConverter;

namespace mln {
namespace harmony {

namespace {

// Read a NAPI array of strings into `out`. On the first non-string element it
// throws a JS error (notStringMessage / readFailedMessage) and returns false,
// in which case the caller must bail out.
bool ReadStringArrayArg(napi_env env, napi_value arrayValue,
                        const char* notStringMessage,
                        const char* readFailedMessage,
                        std::vector<std::string>& out) {
    uint32_t length;
    napi_get_array_length(env, arrayValue, &length);

    out.clear();
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, arrayValue, i, &element);

        size_t strLength = 0;
        if (napi_get_value_string_utf8(env, element, nullptr, 0, &strLength) != napi_ok) {
            napi_throw_error(env, nullptr, notStringMessage);
            return false;
        }
        std::string str(strLength, '\0');
        if (strLength > 0 &&
            napi_get_value_string_utf8(env, element, &str[0], strLength + 1, nullptr) != napi_ok) {
            napi_throw_error(env, nullptr, readFailedMessage);
            return false;
        }

        out.push_back(std::move(str));
    }
    return true;
}

// Shared tail of the rendered-feature queries: parse the optional layerIds
// argument (layerIdsArgIndex) and filter expression argument (filterArgIndex)
// into `options`. Returns false (with a pending JS exception) when a layer id
// element cannot be read.
bool ParseRenderedQueryOptions(napi_env env, NapiArgs& args,
                               size_t layerIdsArgIndex, size_t filterArgIndex,
                               mln::RenderedQueryOptions& options) {
    // Parse optional layerIds parameter
    if (args.Count() >= layerIdsArgIndex + 1) {
        napi_value layerIdsValue = args.GetValue(layerIdsArgIndex);
        napi_valuetype type;
        napi_typeof(env, layerIdsValue, &type);

        if (type == napi_object) {
            bool isArray;
            napi_is_array(env, layerIdsValue, &isArray);

            if (isArray) {
                std::vector<std::string> layerIds;
                if (!ReadStringArrayArg(env, layerIdsValue,
                                        "layerIds must be an array of strings",
                                        "Failed to read layerIds element", layerIds)) {
                    return false;
                }

                if (!layerIds.empty()) {
                    options.layerIDs = layerIds;
                }
            }
        }
    }

    // Parse optional filter parameter
    if (args.Count() >= filterArgIndex + 1) {
        napi_value filterValue = args.GetValue(filterArgIndex);
        napi_valuetype type;
        napi_typeof(env, filterValue, &type);

        if (type == napi_object) {
            bool isArray;
            napi_is_array(env, filterValue, &isArray);

            if (isArray) {
                auto filter = mln::harmony::napiArrayToFilter(env, filterValue);
                if (filter) {
                    options.filter = *filter;
                }
            }
        }
    }

    return true;
}

/**
 * Honor the declared `fn(input, output)` out-parameter contract: when a
 * second array argument was passed, copy the populated result array into it
 * and return that array; otherwise return the populated array itself.
 */
napi_value WriteIntoOutputArray(napi_env env, NapiArgs& args,
                                napi_value populatedArray) {
    if (args.Count() < 2) {
        return populatedArray;
    }
    napi_value outputArg = args.GetValue(1);
    bool isArray = false;
    if (napi_is_array(env, outputArg, &isArray) != napi_ok || !isArray) {
        return populatedArray;
    }

    uint32_t length = 0;
    napi_get_array_length(env, populatedArray, &length);
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, populatedArray, i, &element);
        napi_set_element(env, outputArg, i, element);
    }
    return outputArg;
}

} // namespace

napi_value NativeMapView::getMetersPerPixelAtLatitude(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);

    napi_value result;
    napi_create_double(env, 0.0, &result);

    if (args.HasError()) {
        return result;
    }

    double latitude = args.GetDouble(0, "latitude");
    double zoom = args.GetDouble(1, "zoom");
    if (args.HasError()) {
        return result;
    }

    try {
        double metersPerPixel = mln::Projection::getMetersPerPixelAtLatitude(latitude, zoom);
        napi_create_double(env, metersPerPixel, &result);
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "getMetersPerPixelAtLatitude: Failed - %s", e.what());
    }

    return result;
}

napi_value NativeMapView::projectedMetersForLatLng(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return args.Undefined();
    }

    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    if (args.HasError()) {
        return args.Undefined();
    }

    try {
        mln::ProjectedMeters projectedMeters =
            mln::Projection::projectedMetersForLatLng(mln::LatLng(latitude, longitude));

        napi_value result = ProjectedMetersHarmony::CreateProjectedMetersObject(env, projectedMeters);
        return result;
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "projectedMetersForLatLng: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::pixelForLatLng(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return args.Undefined();
    }

    // Get NativeMapView instance
    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance || !instance->map) {
        Logger::error("NativeMapView", "pixelForLatLng: Map not initialized");
        return args.Undefined();
    }

    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    if (args.HasError()) {
        return args.Undefined();
    }

    try {
        mln::ScreenCoordinate pixel = instance->invokeOnMapThreadSync(
            [&](mln::Map *m) { return m->pixelForLatLng(mln::LatLng(latitude, longitude)); },
            mln::ScreenCoordinate{});
        napi_value result = PointHarmony::CreatePointObject(env, pixel);
        return result;
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "pixelForLatLng: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::pixelsForLatLngs(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);

    napi_value undefined;
    napi_get_undefined(env, &undefined);

    if (args.HasError()) {
        Logger::error("NativeMapView", "pixelsForLatLngs: Invalid arguments");
        return undefined;
    }

    // Get NativeMapView instance
    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance || !instance->map) {
        Logger::error("NativeMapView", "pixelsForLatLngs: Map not initialized");
        return undefined;
    }

    try {
        // Parse input array [lat1, lng1, lat2, lng2, ...]
        napi_value inputArray = args.GetValue(0);
        bool isArray;
        napi_is_array(env, inputArray, &isArray);

        if (!isArray) {
            Logger::error("NativeMapView", "pixelsForLatLngs: Input must be an array");
            return undefined;
        }

        uint32_t length;
        napi_get_array_length(env, inputArray, &length);

        if (length % 2 != 0) {
            Logger::error("NativeMapView", "pixelsForLatLngs: Array length must be even (lat/lng pairs)");
            return undefined;
        }

        // Build LatLng vector
        std::vector<mln::LatLng> latLngs;
        latLngs.reserve(length / 2);

        for (uint32_t i = 0; i < length; i += 2) {
            napi_value latValue, lngValue;
            napi_get_element(env, inputArray, i, &latValue);
            napi_get_element(env, inputArray, i + 1, &lngValue);

            double lat, lng;
            napi_get_value_double(env, latValue, &lat);
            napi_get_value_double(env, lngValue, &lng);

            latLngs.emplace_back(lat, lng);
        }

        // Invoke Map API for batch conversion
        std::vector<mln::ScreenCoordinate> coordinates = instance->invokeOnMapThreadSync(
            [&](mln::Map *m) { return m->pixelsForLatLngs(latLngs); }, std::vector<mln::ScreenCoordinate>{});

        // Create output array
        napi_value outputArray;
        napi_create_array_with_length(env, length, &outputArray);

        // Populate output array [x1, y1, x2, y2, ...]
        for (size_t i = 0; i < coordinates.size(); i++) {
            napi_value xValue, yValue;
            napi_create_double(env, coordinates[i].x, &xValue);
            napi_create_double(env, coordinates[i].y, &yValue);

            napi_set_element(env, outputArray, i * 2, xValue);
            napi_set_element(env, outputArray, i * 2 + 1, yValue);
        }

        Logger::info("NativeMapView", "pixelsForLatLngs: Converted %zu coordinates", coordinates.size());
        return WriteIntoOutputArray(env, args, outputArray);

    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "pixelsForLatLngs: Exception - %s", e.what());
        return undefined;
    }
}

napi_value NativeMapView::latLngForProjectedMeters(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return args.Undefined();
    }

    double northing = args.GetDouble(0, "northing");
    double easting = args.GetDouble(1, "easting");
    if (args.HasError()) {
        return args.Undefined();
    }

    try {
        mln::LatLng latLng = mln::Projection::latLngForProjectedMeters(mln::ProjectedMeters(northing, easting));

        napi_value result = LatLngHarmony::CreateLatLngObject(env, latLng);
        return result;
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "latLngForProjectedMeters: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::latLngForPixel(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return args.Undefined();
    }

    // Get NativeMapView instance
    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance || !instance->map) {
        Logger::error("NativeMapView", "latLngForPixel: Map not initialized");
        return args.Undefined();
    }

    double x = args.GetDouble(0, "x");
    double y = args.GetDouble(1, "y");
    if (args.HasError()) {
        return args.Undefined();
    }

    try {
        mln::LatLng latLng = instance->invokeOnMapThreadSync(
            [&](mln::Map *m) { return m->latLngForPixel(mln::ScreenCoordinate(x, y)); }, mln::LatLng{});
        napi_value result = LatLngHarmony::CreateLatLngObject(env, latLng);
        return result;
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "latLngForPixel: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::latLngsForPixels(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);

    napi_value undefined;
    napi_get_undefined(env, &undefined);

    if (args.HasError()) {
        Logger::error("NativeMapView", "latLngsForPixels: Invalid arguments");
        return undefined;
    }

    // Get NativeMapView instance
    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance || !instance->map) {
        Logger::error("NativeMapView", "latLngsForPixels: Map not initialized");
        return undefined;
    }

    try {
        // Parse input array [x1, y1, x2, y2, ...]
        napi_value inputArray = args.GetValue(0);
        bool isArray;
        napi_is_array(env, inputArray, &isArray);

        if (!isArray) {
            Logger::error("NativeMapView", "latLngsForPixels: Input must be an array");
            return undefined;
        }

        uint32_t length;
        napi_get_array_length(env, inputArray, &length);

        if (length % 2 != 0) {
            Logger::error("NativeMapView", "latLngsForPixels: Array length must be even (x/y pairs)");
            return undefined;
        }

        // Build ScreenCoordinate vector
        std::vector<mln::ScreenCoordinate> coordinates;
        coordinates.reserve(length / 2);

        for (uint32_t i = 0; i < length; i += 2) {
            napi_value xValue, yValue;
            napi_get_element(env, inputArray, i, &xValue);
            napi_get_element(env, inputArray, i + 1, &yValue);

            double x, y;
            napi_get_value_double(env, xValue, &x);
            napi_get_value_double(env, yValue, &y);

            coordinates.emplace_back(x, y);
        }

        // Invoke Map API for batch conversion
        std::vector<mln::LatLng> latLngs = instance->invokeOnMapThreadSync(
            [&](mln::Map *m) { return m->latLngsForPixels(coordinates); }, std::vector<mln::LatLng>{});

        // Create output array
        napi_value outputArray;
        napi_create_array_with_length(env, length, &outputArray);

        // Populate output array [lat1, lng1, lat2, lng2, ...]
        for (size_t i = 0; i < latLngs.size(); i++) {
            napi_value latValue, lngValue;
            napi_create_double(env, latLngs[i].latitude(), &latValue);
            napi_create_double(env, latLngs[i].longitude(), &lngValue);

            napi_set_element(env, outputArray, i * 2, latValue);
            napi_set_element(env, outputArray, i * 2 + 1, lngValue);
        }

        Logger::info("NativeMapView", "latLngsForPixels: Converted %zu coordinates", latLngs.size());
        return WriteIntoOutputArray(env, args, outputArray);

    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "latLngsForPixels: Exception - %s", e.what());
        return undefined;
    }
}

napi_value NativeMapView::queryRenderedFeaturesForPoint(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);

    napi_value undefined;
    napi_get_undefined(env, &undefined);

    if (args.HasError()) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: Invalid arguments");
        return undefined;
    }

    // Get NativeMapView instance
    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: Failed to unwrap instance");
        return undefined;
    }

    // Check whether destruction is in progress
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "queryRenderedFeaturesForPoint: Instance is being destroyed");
        return undefined;
    }

    // Verify renderer existence
    if (!instance->harmonyRenderer) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: HarmonyRenderer not initialized");
        return undefined;
    }

    try {
        // 1. Parse parameters: x, y
        double x = args.GetDouble(0, "x");
        double y = args.GetDouble(1, "y");

        if (args.HasError()) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: Failed to parse x, y");
            return undefined;
        }

        // 2. Build ScreenCoordinate
        mln::ScreenCoordinate point(x, y);

        // 3. Build query options
        mln::RenderedQueryOptions options;

        // 4. Parse optional layerIds parameter and
        // 5. parse optional filter parameter
        if (!ParseRenderedQueryOptions(env, args, 2, 3, options)) {
            return nullptr;
        }

        // 6. Invoke HarmonyRenderer query functionality
        if (!instance->harmonyRenderer) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: HarmonyRenderer is null");
            return undefined;
        }

        std::vector<mln::Feature> features = instance->harmonyRenderer->queryRenderedFeatures(point, options);

        Logger::info("NativeMapView", "queryRenderedFeaturesForPoint: Found %zu features", features.size());

        // 7. Convert result to NAPI array
        napi_value result = mln::harmony::geojson::GeoJsonConverter::FeatureArrayToJsArray(env, features);

        return result;

    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: Exception - %s", e.what());
        return undefined;
    }
}

napi_value NativeMapView::queryRenderedFeaturesForBox(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);

    napi_value undefined;
    napi_get_undefined(env, &undefined);

    if (args.HasError()) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Invalid arguments");
        return undefined;
    }

    // Get NativeMapView instance
    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Failed to unwrap instance");
        return undefined;
    }

    // Check whether destruction is in progress
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "queryRenderedFeaturesForBox: Instance is being destroyed");
        return undefined;
    }

    // Verify renderer existence
    if (!instance->harmonyRenderer) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: HarmonyRenderer not initialized");
        return undefined;
    }

    try {
        // 1. Parse parameters: left, top, right, bottom
        double left = args.GetDouble(0, "left");
        double top = args.GetDouble(1, "top");
        double right = args.GetDouble(2, "right");
        double bottom = args.GetDouble(3, "bottom");

        if (args.HasError()) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Failed to parse box coordinates");
            return undefined;
        }

        // 2. Build ScreenBox
        mln::ScreenBox box{mln::ScreenCoordinate{left, top}, mln::ScreenCoordinate{right, bottom}};

        // 3. Build query options
        mln::RenderedQueryOptions options;

        // 4. Parse optional layerIds parameter and
        // 5. parse optional filter parameter
        if (!ParseRenderedQueryOptions(env, args, 4, 5, options)) {
            return nullptr;
        }

        // 6. Invoke HarmonyRenderer query functionality
        if (!instance->harmonyRenderer) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForBox: HarmonyRenderer is null");
            return undefined;
        }

        std::vector<mln::Feature> features = instance->harmonyRenderer->queryRenderedFeatures(box, options);

        Logger::info("NativeMapView", "queryRenderedFeaturesForBox: Found %zu features", features.size());

        // 7. Convert result to NAPI array
        napi_value result = mln::harmony::geojson::GeoJsonConverter::FeatureArrayToJsArray(env, features);

        return result;

    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Exception - %s", e.what());
        return undefined;
    }
}

napi_value NativeMapView::querySourceFeatures(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);

    napi_value undefined;
    napi_get_undefined(env, &undefined);

    if (args.HasError()) {
        Logger::error("NativeMapView", "querySourceFeatures: Invalid arguments");
        return undefined;
    }

    // Get NativeMapView instance
    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance) {
        Logger::error("NativeMapView", "querySourceFeatures: Failed to unwrap instance");
        return undefined;
    }

    // Check whether destruction is in progress
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "querySourceFeatures: Instance is being destroyed");
        return undefined;
    }

    // Verify renderer existence
    if (!instance->harmonyRenderer) {
        Logger::error("NativeMapView", "querySourceFeatures: HarmonyRenderer not initialized");
        return undefined;
    }

    try {
        // 1. Parse parameter: sourceId
        std::string sourceId = args.GetString(0, "sourceId");

        if (args.HasError()) {
            Logger::error("NativeMapView", "querySourceFeatures: Failed to parse sourceId");
            return undefined;
        }

        // 2. Build query options
        mln::SourceQueryOptions options;

        // 3. Parse optional sourceLayerIds parameter
        if (args.Count() >= 2) {
            napi_value sourceLayerIdsValue = args.GetValue(1);
            napi_valuetype type;
            napi_typeof(env, sourceLayerIdsValue, &type);

            if (type == napi_object) {
                bool isArray;
                napi_is_array(env, sourceLayerIdsValue, &isArray);

                if (isArray) {
                    std::vector<std::string> sourceLayerIds;
                    if (!ReadStringArrayArg(env, sourceLayerIdsValue,
                                            "sourceLayerIds must be an array of strings",
                                            "Failed to read sourceLayerIds element",
                                            sourceLayerIds)) {
                        return nullptr;
                    }

                    options.sourceLayers = sourceLayerIds;
                    Logger::info("NativeMapView", "querySourceFeatures: Using %zu source layer IDs", sourceLayerIds.size());
                }
            }
        }

        // 4. Parse optional filter parameter
        if (args.Count() >= 3) {
            napi_value filterValue = args.GetValue(2);
            napi_valuetype type;
            napi_typeof(env, filterValue, &type);

            if (type == napi_object) {
                // Parse filter expression
                auto filterOpt = napiArrayToFilter(env, filterValue);
                if (filterOpt.has_value()) {
                    options.filter = std::move(filterOpt.value());
                    Logger::info("NativeMapView", "querySourceFeatures: Filter applied");
                } else {
                    Logger::warn("NativeMapView", "querySourceFeatures: Failed to parse filter expression");
                }
            }
        }

        // 5. Invoke HarmonyRenderer query functionality
        if (!instance->harmonyRenderer) {
            Logger::error("NativeMapView", "querySourceFeatures: HarmonyRenderer is null");
            return undefined;
        }

        std::vector<mln::Feature> features = instance->harmonyRenderer->querySourceFeatures(sourceId, options);

        Logger::info("NativeMapView", "querySourceFeatures: Found %zu features from source '%s'", 
                    features.size(), sourceId.c_str());

        // 6. Convert result to NAPI array
        napi_value result = mln::harmony::geojson::GeoJsonConverter::FeatureArrayToJsArray(env, features);

        return result;

    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "querySourceFeatures: Exception - %s", e.what());
        return undefined;
    }
}

namespace {
// Read an optional string argument: null/undefined maps to std::nullopt.
std::optional<std::string> readOptionalString(napi_env env, napi_value value) {
    napi_valuetype type = napi_undefined;
    napi_typeof(env, value, &type);
    if (type == napi_null || type == napi_undefined) {
        return std::nullopt;
    }
    if (type != napi_string) {
        return std::nullopt;
    }
    size_t len = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &len);
    std::string result(len, '\0');
    napi_get_value_string_utf8(env, value, result.data(), len + 1, nullptr);
    return result;
}
} // namespace

napi_value NativeMapView::setFeatureState(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value falseValue;
    napi_get_boolean(env, false, &falseValue);

    args.RequireMinArgs(4);
    if (args.HasError()) {
        return falseValue;
    }

    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance || instance->isDestroying.load() || !instance->harmonyRenderer) {
        Logger::error("NativeMapView", "setFeatureState: Invalid instance or renderer not initialized");
        return falseValue;
    }

    try {
        std::string sourceId = args.GetString(0, "sourceId");
        if (args.HasError()) {
            return falseValue;
        }

        std::optional<std::string> sourceLayerId = readOptionalString(env, args.GetValue(1));
        std::string featureId = args.GetString(2, "featureId");
        if (args.HasError()) {
            return falseValue;
        }

        napi_value stateValue = args.GetValue(3);
        napi_valuetype stateType = napi_undefined;
        napi_typeof(env, stateValue, &stateType);
        if (stateType != napi_object) {
            Logger::error("NativeMapView", "setFeatureState: state must be an object");
            return falseValue;
        }

        mln::FeatureState state = mln::harmony::napiObjectToValueMap(env, stateValue);

        instance->harmonyRenderer->setFeatureState(sourceId, sourceLayerId, featureId, state);
        napi_value trueValue;
        napi_get_boolean(env, true, &trueValue);
        return trueValue;
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "setFeatureState: Exception - %s", e.what());
        return falseValue;
    }
}

napi_value NativeMapView::getFeatureState(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value undefined;
    napi_get_undefined(env, &undefined);

    args.RequireMinArgs(3);
    if (args.HasError()) {
        return undefined;
    }

    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance || instance->isDestroying.load() || !instance->harmonyRenderer) {
        Logger::error("NativeMapView", "getFeatureState: Invalid instance or renderer not initialized");
        return undefined;
    }

    try {
        std::string sourceId = args.GetString(0, "sourceId");
        if (args.HasError()) {
            return undefined;
        }

        std::optional<std::string> sourceLayerId = readOptionalString(env, args.GetValue(1));
        std::string featureId = args.GetString(2, "featureId");
        if (args.HasError()) {
            return undefined;
        }

        mln::FeatureState state = instance->harmonyRenderer->getFeatureState(sourceId, sourceLayerId, featureId);
        if (state.empty()) {
            return undefined;
        }

        return mln::harmony::valueMapToNapiObject(env, state);
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "getFeatureState: Exception - %s", e.what());
        return undefined;
    }
}

napi_value NativeMapView::removeFeatureState(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value falseValue;
    napi_get_boolean(env, false, &falseValue);

    args.RequireMinArgs(4);
    if (args.HasError()) {
        return falseValue;
    }

    NativeMapView* instance = NativeMapView::FromInfo(env, info);
    if (!instance || instance->isDestroying.load() || !instance->harmonyRenderer) {
        Logger::error("NativeMapView", "removeFeatureState: Invalid instance or renderer not initialized");
        return falseValue;
    }

    try {
        std::string sourceId = args.GetString(0, "sourceId");
        if (args.HasError()) {
            return falseValue;
        }

        std::optional<std::string> sourceLayerId = readOptionalString(env, args.GetValue(1));
        std::optional<std::string> featureId = readOptionalString(env, args.GetValue(2));
        std::optional<std::string> stateKey = readOptionalString(env, args.GetValue(3));

        instance->harmonyRenderer->removeFeatureState(sourceId, sourceLayerId, featureId, stateKey);
        napi_value trueValue;
        napi_get_boolean(env, true, &trueValue);
        return trueValue;
    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "removeFeatureState: Exception - %s", e.what());
        return falseValue;
    }
}

} // namespace harmony
} // namespace mln
