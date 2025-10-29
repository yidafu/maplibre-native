#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"

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
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Feature 的 NAPI 包装类和渲染器前端支持
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:977-993
    Logger::warn("NativeMapView", "queryRenderedFeaturesForPoint: Not implemented - requires Feature wrapper class and renderer support");
    
    return undefined;
}

napi_value NativeMapView::queryRenderedFeaturesForBox(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "queryRenderedFeaturesForBox() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Feature 的 NAPI 包装类和渲染器前端支持
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:995-1014
    Logger::warn("NativeMapView", "queryRenderedFeaturesForBox: Not implemented - requires Feature wrapper class and renderer support");
    
    return undefined;
}


} // namespace harmony
} // namespace mbgl
