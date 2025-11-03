#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"
#include "geojson/geojson_converter.hpp"
#include "style/filter_conversion.hpp"
#include "rendering/harmony_renderer.hpp"
#include <mbgl/map/map.hpp>
#include <mbgl/util/geo.hpp>
#include <mbgl/style/filter.hpp>
#include <mbgl/renderer/query.hpp>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using maplibre::harmony::geojson::GeoJsonConverter;

namespace mbgl {
namespace harmony {

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
        double metersPerPixel = mbgl::Projection::getMetersPerPixelAtLatitude(latitude, zoom);
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
        mbgl::ProjectedMeters projectedMeters =
            mbgl::Projection::projectedMetersForLatLng(mbgl::LatLng(latitude, longitude));

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

    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView *instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void **>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "pixelForLatLng: Map not initialized");
        return args.Undefined();
    }

    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    if (args.HasError()) {
        return args.Undefined();
    }

    try {
        mbgl::ScreenCoordinate pixel = instance->invokeOnMapThreadSync(
            [&](mbgl::Map *m) { return m->pixelForLatLng(mbgl::LatLng(latitude, longitude)); },
            mbgl::ScreenCoordinate{});
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

    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView *instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void **>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "pixelsForLatLngs: Map not initialized");
        return undefined;
    }

    try {
        // 解析输入数组 [lat1, lng1, lat2, lng2, ...]
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

        // 构建 LatLng 向量
        std::vector<mbgl::LatLng> latLngs;
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

        // 调用 Map API 进行批量转换
        std::vector<mbgl::ScreenCoordinate> coordinates = instance->invokeOnMapThreadSync(
            [&](mbgl::Map *m) { return m->pixelsForLatLngs(latLngs); }, std::vector<mbgl::ScreenCoordinate>{});

        // 创建输出数组
        napi_value outputArray;
        napi_create_array_with_length(env, length, &outputArray);

        // 填充输出数组 [x1, y1, x2, y2, ...]
        for (size_t i = 0; i < coordinates.size(); i++) {
            napi_value xValue, yValue;
            napi_create_double(env, coordinates[i].x, &xValue);
            napi_create_double(env, coordinates[i].y, &yValue);

            napi_set_element(env, outputArray, i * 2, xValue);
            napi_set_element(env, outputArray, i * 2 + 1, yValue);
        }

        Logger::info("NativeMapView", "pixelsForLatLngs: Converted %zu coordinates", coordinates.size());
        return outputArray;

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
        mbgl::LatLng latLng = mbgl::Projection::latLngForProjectedMeters(mbgl::ProjectedMeters(northing, easting));

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

    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView *instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void **>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "latLngForPixel: Map not initialized");
        return args.Undefined();
    }

    double x = args.GetDouble(0, "x");
    double y = args.GetDouble(1, "y");
    if (args.HasError()) {
        return args.Undefined();
    }

    try {
        mbgl::LatLng latLng = instance->invokeOnMapThreadSync(
            [&](mbgl::Map *m) { return m->latLngForPixel(mbgl::ScreenCoordinate(x, y)); }, mbgl::LatLng{});
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

    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView *instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void **>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "latLngsForPixels: Map not initialized");
        return undefined;
    }

    try {
        // 解析输入数组 [x1, y1, x2, y2, ...]
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

        // 构建 ScreenCoordinate 向量
        std::vector<mbgl::ScreenCoordinate> coordinates;
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

        // 调用 Map API 进行批量转换
        std::vector<mbgl::LatLng> latLngs = instance->invokeOnMapThreadSync(
            [&](mbgl::Map *m) { return m->latLngsForPixels(coordinates); }, std::vector<mbgl::LatLng>{});

        // 创建输出数组
        napi_value outputArray;
        napi_create_array_with_length(env, length, &outputArray);

        // 填充输出数组 [lat1, lng1, lat2, lng2, ...]
        for (size_t i = 0; i < latLngs.size(); i++) {
            napi_value latValue, lngValue;
            napi_create_double(env, latLngs[i].latitude(), &latValue);
            napi_create_double(env, latLngs[i].longitude(), &lngValue);

            napi_set_element(env, outputArray, i * 2, latValue);
            napi_set_element(env, outputArray, i * 2 + 1, lngValue);
        }

        Logger::info("NativeMapView", "latLngsForPixels: Converted %zu coordinates", latLngs.size());
        return outputArray;

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

    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView *instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void **>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: Failed to unwrap instance");
        return undefined;
    }

    // 检查是否正在销毁
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "queryRenderedFeaturesForPoint: Instance is being destroyed");
        return undefined;
    }

    // 检查渲染器是否存在
    if (!instance->harmonyRenderer) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: HarmonyRenderer not initialized");
        return undefined;
    }

    try {
        // 1. 解析参数：x, y
        double x = args.GetDouble(0, "x");
        double y = args.GetDouble(1, "y");

        if (args.HasError()) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: Failed to parse x, y");
            return undefined;
        }

        // 2. 构造 ScreenCoordinate
        mbgl::ScreenCoordinate point(x, y);

        // 3. 构造查询选项
        mbgl::RenderedQueryOptions options;

        // 4. 解析可选的 layerIds 参数
        if (args.Count() >= 3) {
            napi_value layerIdsValue = args.GetValue(2);
            napi_valuetype type;
            napi_typeof(env, layerIdsValue, &type);

            if (type == napi_object) {
                bool isArray;
                napi_is_array(env, layerIdsValue, &isArray);

                if (isArray) {
                    uint32_t length;
                    napi_get_array_length(env, layerIdsValue, &length);

                    std::vector<std::string> layerIds;
                    for (uint32_t i = 0; i < length; i++) {
                        napi_value element;
                        napi_get_element(env, layerIdsValue, i, &element);

                        size_t strLength;
                        napi_get_value_string_utf8(env, element, nullptr, 0, &strLength);
                        std::string str(strLength, '\0');
                        napi_get_value_string_utf8(env, element, &str[0], strLength + 1, &strLength);

                        layerIds.push_back(str);
                    }

                    if (!layerIds.empty()) {
                        options.layerIDs = layerIds;
                    }
                }
            }
        }

        // 5. 解析可选的 filter 参数
        if (args.Count() >= 4) {
            napi_value filterValue = args.GetValue(3);
            napi_valuetype type;
            napi_typeof(env, filterValue, &type);

            if (type == napi_object) {
                bool isArray;
                napi_is_array(env, filterValue, &isArray);

                if (isArray) {
                    auto filter = mbgl::harmony::napiArrayToFilter(env, filterValue);
                    if (filter) {
                        options.filter = *filter;
                    }
                }
            }
        }

        // 6. 调用 HarmonyRenderer 查询功能
        if (!instance->harmonyRenderer) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: HarmonyRenderer is null");
            return undefined;
        }

        std::vector<mbgl::Feature> features = instance->harmonyRenderer->queryRenderedFeatures(point, options);

        Logger::info("NativeMapView", "queryRenderedFeaturesForPoint: Found %zu features", features.size());

        // 7. 转换结果为 NAPI 数组
        napi_value result = maplibre::harmony::geojson::GeoJsonConverter::FeatureArrayToJsArray(env, features);

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

    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView *instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void **>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Failed to unwrap instance");
        return undefined;
    }

    // 检查是否正在销毁
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "queryRenderedFeaturesForBox: Instance is being destroyed");
        return undefined;
    }

    // 检查渲染器是否存在
    if (!instance->harmonyRenderer) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: HarmonyRenderer not initialized");
        return undefined;
    }

    try {
        // 1. 解析参数：left, top, right, bottom
        double left = args.GetDouble(0, "left");
        double top = args.GetDouble(1, "top");
        double right = args.GetDouble(2, "right");
        double bottom = args.GetDouble(3, "bottom");

        if (args.HasError()) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Failed to parse box coordinates");
            return undefined;
        }

        // 2. 构造 ScreenBox
        mbgl::ScreenBox box{mbgl::ScreenCoordinate{left, top}, mbgl::ScreenCoordinate{right, bottom}};

        // 3. 构造查询选项
        mbgl::RenderedQueryOptions options;

        // 4. 解析可选的 layerIds 参数
        if (args.Count() >= 5) {
            napi_value layerIdsValue = args.GetValue(4);
            napi_valuetype type;
            napi_typeof(env, layerIdsValue, &type);

            if (type == napi_object) {
                bool isArray;
                napi_is_array(env, layerIdsValue, &isArray);

                if (isArray) {
                    uint32_t length;
                    napi_get_array_length(env, layerIdsValue, &length);

                    std::vector<std::string> layerIds;
                    for (uint32_t i = 0; i < length; i++) {
                        napi_value element;
                        napi_get_element(env, layerIdsValue, i, &element);

                        size_t strLength;
                        napi_get_value_string_utf8(env, element, nullptr, 0, &strLength);
                        std::string str(strLength, '\0');
                        napi_get_value_string_utf8(env, element, &str[0], strLength + 1, &strLength);

                        layerIds.push_back(str);
                    }

                    if (!layerIds.empty()) {
                        options.layerIDs = layerIds;
                    }
                }
            }
        }

        // 5. 解析可选的 filter 参数
        if (args.Count() >= 6) {
            napi_value filterValue = args.GetValue(5);
            napi_valuetype type;
            napi_typeof(env, filterValue, &type);

            if (type == napi_object) {
                bool isArray;
                napi_is_array(env, filterValue, &isArray);

                if (isArray) {
                    auto filter = mbgl::harmony::napiArrayToFilter(env, filterValue);
                    if (filter) {
                        options.filter = *filter;
                    }
                }
            }
        }

        // 6. 调用 HarmonyRenderer 查询功能
        if (!instance->harmonyRenderer) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForBox: HarmonyRenderer is null");
            return undefined;
        }

        std::vector<mbgl::Feature> features = instance->harmonyRenderer->queryRenderedFeatures(box, options);

        Logger::info("NativeMapView", "queryRenderedFeaturesForBox: Found %zu features", features.size());

        // 7. 转换结果为 NAPI 数组
        napi_value result = maplibre::harmony::geojson::GeoJsonConverter::FeatureArrayToJsArray(env, features);

        return result;

    } catch (const std::exception &e) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Exception - %s", e.what());
        return undefined;
    }
}


} // namespace harmony
} // namespace mbgl
