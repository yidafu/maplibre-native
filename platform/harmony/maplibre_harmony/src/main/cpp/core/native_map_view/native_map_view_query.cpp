#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"
#include "geojson/feature_napi.hpp"
#include "style/filter_conversion.hpp"
#include "rendering/harmony_renderer.hpp"
#include "rendering/harmony_renderer_frontend.hpp"
#include <mbgl/map/map.hpp>
#include <mbgl/util/geo.hpp>
#include <mbgl/style/filter.hpp>
#include <mbgl/renderer/query.hpp>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

napi_value NativeMapView::getMetersPerPixelAtLatitude(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getMetersPerPixelAtLatitude() called");
    
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
        Logger::debug("NativeMapView", "getMetersPerPixelAtLatitude: lat=%f, zoom=%f, result=%f", latitude, zoom, metersPerPixel);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMetersPerPixelAtLatitude: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::projectedMetersForLatLng(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "projectedMetersForLatLng() called");
    
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
        mbgl::ProjectedMeters projectedMeters = mbgl::Projection::projectedMetersForLatLng(
            mbgl::LatLng(latitude, longitude)
        );
        
        napi_value result = ProjectedMetersHarmony::CreateProjectedMetersObject(env, projectedMeters);
        Logger::debug("NativeMapView", "projectedMetersForLatLng: lat=%f, lng=%f -> northing=%f, easting=%f", 
                      latitude, longitude, projectedMeters.northing(), projectedMeters.easting());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "projectedMetersForLatLng: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::pixelForLatLng(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "pixelForLatLng() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "pixelForLatLng: Map not initialized");
        return args.Undefined();
    }
    
    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    if (args.HasError()) {
        return args.Undefined();
    }
    
    try {
        mbgl::ScreenCoordinate pixel = instance->map->pixelForLatLng(mbgl::LatLng(latitude, longitude));
        napi_value result = PointHarmony::CreatePointObject(env, pixel);
        Logger::debug("NativeMapView", "pixelForLatLng: lat=%f, lng=%f -> x=%f, y=%f", 
                      latitude, longitude, pixel.x, pixel.y);
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "pixelForLatLng: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::pixelsForLatLngs(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "pixelsForLatLngs() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现数组参数解析和结果数组返回
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:772-796
    Logger::warn("NativeMapView", "pixelsForLatLngs: Not implemented - requires array parameter parsing");
    
    return undefined;
}

napi_value NativeMapView::latLngForProjectedMeters(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "latLngForProjectedMeters() called");
    
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
        mbgl::LatLng latLng = mbgl::Projection::latLngForProjectedMeters(
            mbgl::ProjectedMeters(northing, easting)
        );
        
        napi_value result = LatLngHarmony::CreateLatLngObject(env, latLng);
        Logger::debug("NativeMapView", "latLngForProjectedMeters: northing=%f, easting=%f -> lat=%f, lng=%f", 
                      northing, easting, latLng.latitude(), latLng.longitude());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "latLngForProjectedMeters: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::latLngForPixel(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "latLngForPixel() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "latLngForPixel: Map not initialized");
        return args.Undefined();
    }
    
    double x = args.GetDouble(0, "x");
    double y = args.GetDouble(1, "y");
    if (args.HasError()) {
        return args.Undefined();
    }
    
    try {
        mbgl::LatLng latLng = instance->map->latLngForPixel(mbgl::ScreenCoordinate(x, y));
        napi_value result = LatLngHarmony::CreateLatLngObject(env, latLng);
        Logger::debug("NativeMapView", "latLngForPixel: x=%f, y=%f -> lat=%f, lng=%f", 
                      x, y, latLng.latitude(), latLng.longitude());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "latLngForPixel: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::latLngsForPixels(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "latLngsForPixels() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现数组参数解析和结果数组返回
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:802-826
    Logger::warn("NativeMapView", "latLngsForPixels: Not implemented - requires array parameter parsing");
    
    return undefined;
}

napi_value NativeMapView::queryPointAnnotations(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "queryPointAnnotations() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要渲染器前端支持 queryPointAnnotations
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:936-955
    Logger::warn("NativeMapView", "queryPointAnnotations: Not implemented - requires renderer frontend support");
    
    return undefined;
}

napi_value NativeMapView::queryShapeAnnotations(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "queryShapeAnnotations() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要渲染器前端支持 queryShapeAnnotations
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:957-975
    Logger::warn("NativeMapView", "queryShapeAnnotations: Not implemented - requires renderer frontend support");
    
    return undefined;
}

napi_value NativeMapView::queryRenderedFeaturesForPoint(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "queryRenderedFeaturesForPoint() called");
    
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
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
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
        
        Logger::debug("NativeMapView", "queryRenderedFeaturesForPoint: x=%.2f, y=%.2f", x, y);
        
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
                        Logger::debug("NativeMapView", "queryRenderedFeaturesForPoint: layerIds count=%zu", layerIds.size());
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
                        Logger::debug("NativeMapView", "queryRenderedFeaturesForPoint: filter applied");
                    }
                }
            }
        }
        
        // 6. 调用渲染器前端查询
        auto rendererFrontend = instance->harmonyRenderer->getRendererFrontend();
        if (!rendererFrontend) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: RendererFrontend is null");
            return undefined;
        }
        
        std::vector<mbgl::Feature> features = rendererFrontend->queryRenderedFeatures(point, options);
        
        Logger::info("NativeMapView", "queryRenderedFeaturesForPoint: Found %zu features", features.size());
        
        // 7. 转换结果为 NAPI 数组
        napi_value result = maplibre::harmony::geojson::FeatureNAPI::NewArray(env, features);
        
        return result;
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForPoint: Exception - %s", e.what());
        return undefined;
    }
}

napi_value NativeMapView::queryRenderedFeaturesForBox(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "queryRenderedFeaturesForBox() called");
    
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
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
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
        
        Logger::debug("NativeMapView", "queryRenderedFeaturesForBox: left=%.2f, top=%.2f, right=%.2f, bottom=%.2f", 
                      left, top, right, bottom);
        
        // 2. 构造 ScreenBox
        mbgl::ScreenBox box{
            mbgl::ScreenCoordinate{left, top},
            mbgl::ScreenCoordinate{right, bottom}
        };
        
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
                        Logger::debug("NativeMapView", "queryRenderedFeaturesForBox: layerIds count=%zu", layerIds.size());
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
                        Logger::debug("NativeMapView", "queryRenderedFeaturesForBox: filter applied");
                    }
                }
            }
        }
        
        // 6. 调用渲染器前端查询
        auto rendererFrontend = instance->harmonyRenderer->getRendererFrontend();
        if (!rendererFrontend) {
            Logger::error("NativeMapView", "queryRenderedFeaturesForBox: RendererFrontend is null");
            return undefined;
        }
        
        std::vector<mbgl::Feature> features = rendererFrontend->queryRenderedFeatures(box, options);
        
        Logger::info("NativeMapView", "queryRenderedFeaturesForBox: Found %zu features", features.size());
        
        // 7. 转换结果为 NAPI 数组
        napi_value result = maplibre::harmony::geojson::FeatureNAPI::NewArray(env, features);
        
        return result;
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "queryRenderedFeaturesForBox: Exception - %s", e.what());
        return undefined;
    }
}


} // namespace harmony
} // namespace mbgl
