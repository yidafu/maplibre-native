#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/bindings/marker/marker_napi.hpp"
#include "napi/bindings/style/style_napi.hpp"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"
#include "utils/logger.h"
#include <mbgl/util/projection.hpp>
#include <mbgl/style/style.hpp>
#include <napi/native_api.h>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using maplibre::harmony::MarkerNAPI;
using maplibre::harmony::StyleNAPI;

namespace mbgl {
namespace harmony {

napi_value NativeMapView::updateMarker(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== updateMarker() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "updateMarker: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "updateMarker: Requires 1 argument (Marker object)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "updateMarker: Failed to unwrap NativeMapView instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "updateMarker: Map not initialized");
        return undefined;
    }
    
    // Unwrap Marker NAPI 对象
    maplibre::harmony::MarkerNAPI* marker = nullptr;
    if (napi_unwrap(env, args[0], reinterpret_cast<void**>(&marker)) != napi_ok || !marker) {
        Logger::error("NativeMapView", "updateMarker: Failed to unwrap Marker object");
        return undefined;
    }
    
    // 从 Marker 获取数据
    auto annotationId = marker->getAnnotationId();
    if (annotationId == static_cast<mbgl::AnnotationID>(-1)) {
        Logger::error("NativeMapView", "updateMarker: Marker has invalid ID (not added to map yet)");
        return undefined;
    }
    
    auto position = marker->getPositionPoint();
    auto iconId = marker->getIconId();
    
    Logger::info("NativeMapView", "[MarkerDebug] updateMarker: ID=%lu, lat=%f, lon=%f, icon=\"%s\"", 
                  annotationId, position.y, position.x, iconId.c_str());
    
    try {
        // 更新 Marker (使用 SymbolAnnotation)
        mbgl::SymbolAnnotation annotation(position, iconId);
        instance->invokeOnMapThread([annotationId, annotation](mbgl::Map* m){
            m->updateAnnotation(annotationId, annotation);
            m->triggerRepaint();
        });
        
        Logger::info("NativeMapView", "[MarkerDebug] updateMarker: Marker updated successfully");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "[MarkerDebug] updateMarker: Failed - %s", e.what());
    }
    
    Logger::info("NativeMapView", "========== updateMarker() END ==========");
    return undefined;
}

napi_value NativeMapView::addMarkers(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== addMarkers() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "addMarkers: Requires 1 argument (markers array)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addMarkers: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addMarkers: Map not initialized");
        return undefined;
    }
    
    // 检查参数是否是数组
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "addMarkers: First argument must be an array");
        return undefined;
    }
    
    // 获取数组长度
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to get array length");
        return undefined;
    }
    
    Logger::info("NativeMapView", "addMarkers: Processing %u markers", length);
    
    // 存储生成的 annotation IDs
    std::vector<mbgl::AnnotationID> ids;
    ids.reserve(length);
    
    // 遍历 Marker 数组（现在是 MarkerNAPI 对象）
    for (uint32_t i = 0; i < length; i++) {
        napi_value markerObj;
        if (napi_get_element(env, args[0], i, &markerObj) != napi_ok) {
            Logger::error("NativeMapView", "addMarkers: Failed to get marker at index %u", i);
            continue;
        }
        
        // Unwrap MarkerNAPI 对象
        maplibre::harmony::MarkerNAPI* marker = nullptr;
        if (napi_unwrap(env, markerObj, reinterpret_cast<void**>(&marker)) != napi_ok || !marker) {
            Logger::error("NativeMapView", "[MarkerDebug] NAPI-Error: Failed to unwrap Marker at index %u", i);
            continue;
        }
        
        // 直接从 MarkerNAPI 对象获取数据
        auto position = marker->getPositionPoint();
        auto iconId = marker->getIconId();
        
        // [MarkerDebug] 记录输入
        if (iconId.empty()) {
            Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Input: marker[%u] has EMPTY icon, may not be visible!", i);
            Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Warning: Use addAnnotationIcon() to add custom icon or ensure style has default marker icon");
        }
        
        Logger::info("NativeMapView", "[MarkerDebug] NAPI-Input: marker[%u] lat=%f, lon=%f, icon=\"%s\"", 
                     i, position.y, position.x, iconId.empty() ? "(empty)" : iconId.c_str());
        
        try {
            // 创建 SymbolAnnotation
            mbgl::SymbolAnnotation annotation(position, iconId);
            
            // 添加到地图并获取 ID
            mbgl::AnnotationID annotationId = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->addAnnotation(annotation); }, mbgl::AnnotationID{});
            ids.push_back(annotationId);
            
            // 设置 annotation ID 回 Marker
            marker->setAnnotationId(annotationId);
            
            Logger::info("NativeMapView", "[MarkerDebug] NAPI-Result: marker[%u] created with ID=%lu", i, annotationId);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "[MarkerDebug] NAPI-Error: marker[%u] failed to add - %s", i, e.what());
        }
    }
    
    // [MarkerDebug] 统计添加结果
    Logger::info("NativeMapView", "[MarkerDebug] NAPI-Summary: Added %zu/%u markers successfully", ids.size(), length);
    if (ids.size() < length) {
        Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Summary: ⚠️ %u markers failed to add", length - static_cast<uint32_t>(ids.size()));
    }
    
    // 触发重绘
    if (!ids.empty()) {
        instance->invokeOnMapThread([](mbgl::Map* m){ m->triggerRepaint(); });
        Logger::info("NativeMapView", "[MarkerDebug] NAPI-Repaint: Repaint triggered for %zu markers", ids.size());
    } else {
        Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Repaint: ⚠️ No markers added, skipping repaint");
    }
    
    // 创建返回的 ID 数组
    napi_value resultArray;
    if (napi_create_array_with_length(env, ids.size(), &resultArray) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to create result array");
        return undefined;
    }
    
    // 填充 ID 数组
    for (size_t i = 0; i < ids.size(); i++) {
        napi_value idValue;
        if (napi_create_int64(env, static_cast<int64_t>(ids[i]), &idValue) == napi_ok) {
            napi_set_element(env, resultArray, i, idValue);
        }
    }
    
    Logger::info("NativeMapView", "========== addMarkers() END - SUCCESS ==========");
    return resultArray;
}

napi_value NativeMapView::onLowMemory(napi_env env, napi_callback_info info) {
    // 低内存处理由 Harmony 系统管理
    // Low memory handling delegated to Harmony system
    Logger::debug("NativeMapView", "onLowMemory: Low memory handling delegated to Harmony system");
    
    NapiArgs args(env, info);
    return args.Undefined();
}

napi_value NativeMapView::addPolylines(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "addPolylines() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polyline 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/annotation/polyline.cpp
    Logger::warn("NativeMapView", "addPolylines: Not implemented - requires Polyline wrapper class");
    
    return undefined;
}

napi_value NativeMapView::addPolygons(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "addPolygons() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polygon 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/annotation/polygon.cpp
    Logger::warn("NativeMapView", "addPolygons: Not implemented - requires Polygon wrapper class");
    
    return undefined;
}

napi_value NativeMapView::updatePolyline(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "updatePolyline() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polyline 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:866-869
    Logger::warn("NativeMapView", "updatePolyline: Not implemented - requires Polyline wrapper class");
    
    return undefined;
}

napi_value NativeMapView::updatePolygon(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "updatePolygon() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polygon 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:871-874
    Logger::warn("NativeMapView", "updatePolygon: Not implemented - requires Polygon wrapper class");
    
    return undefined;
}

napi_value NativeMapView::removeAnnotations(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== removeAnnotations() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "removeAnnotations: Requires 1 argument (annotation IDs array)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "removeAnnotations: Map not initialized");
        return undefined;
    }
    
    // 检查参数是否是数组
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "removeAnnotations: First argument must be an array");
        return undefined;
    }
    
    // 获取数组长度
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to get array length");
        return undefined;
    }
    
    Logger::info("NativeMapView", "removeAnnotations: Removing %u annotations", length);
    
    // 遍历 ID 数组并删除
    for (uint32_t i = 0; i < length; i++) {
        napi_value idValue;
        if (napi_get_element(env, args[0], i, &idValue) != napi_ok) {
            Logger::error("NativeMapView", "removeAnnotations: Failed to get ID at index %u", i);
            continue;
        }
        
        int64_t annotationId;
        if (napi_get_value_int64(env, idValue, &annotationId) != napi_ok) {
            Logger::error("NativeMapView", "removeAnnotations: Failed to parse ID at index %u", i);
            continue;
        }
        
        if (annotationId == -1) {
            continue; // 跳过无效 ID
        }
        
        try {
            instance->invokeOnMapThread([annotationId](mbgl::Map* m){ m->removeAnnotation(static_cast<mbgl::AnnotationID>(annotationId)); });
            Logger::debug("NativeMapView", "removeAnnotations[%u]: Removed annotation ID=%ld", i, annotationId);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "removeAnnotations[%u]: Failed to remove ID=%ld - %s", i, annotationId, e.what());
        }
    }
    
    // 触发重绘
    if (length > 0) {
        instance->invokeOnMapThread([](mbgl::Map* m){ m->triggerRepaint(); });
        Logger::debug("NativeMapView", "removeAnnotations: Repaint triggered");
    }
    
    Logger::info("NativeMapView", "========== removeAnnotations() END ==========");
    return undefined;
}

napi_value NativeMapView::addAnnotationIcon(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== addAnnotationIcon() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 5;
    napi_value args[5];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 5) {
        Logger::error("NativeMapView", "addAnnotationIcon: Requires 5 arguments (symbol, width, height, scale, pixels)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addAnnotationIcon: Map not initialized");
        return undefined;
    }
    
    // 解析参数：symbol (string), width, height, scale, pixels (Uint8Array)
    // 获取 symbol 字符串
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbol;
    if (symbolLength > 0) {
        symbol.resize(symbolLength);
        napi_get_value_string_utf8(env, args[0], &symbol[0], symbolLength + 1, &symbolLength);
    }
    
    // 获取尺寸和缩放比例
    int32_t width, height;
    double scale;
    if (napi_get_value_int32(env, args[1], &width) != napi_ok ||
        napi_get_value_int32(env, args[2], &height) != napi_ok ||
        napi_get_value_double(env, args[3], &scale) != napi_ok) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to parse numeric arguments");
        return undefined;
    }
    
    // 获取 Uint8Array 像素数据
    void* pixelData = nullptr;
    size_t pixelLength = 0;
    napi_value arrayBuffer;
    
    // 尝试获取 TypedArray 的 ArrayBuffer
    if (napi_get_typedarray_info(env, args[4], nullptr, &pixelLength, &pixelData, &arrayBuffer, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to get pixel data");
        return undefined;
    }
    
    Logger::info("NativeMapView", "addAnnotationIcon: symbol=%s, width=%d, height=%d, scale=%f, pixelLength=%zu", 
                  symbol.c_str(), width, height, scale, pixelLength);
    
    // 在渲染线程构造并添加图片，避免跨线程移动 unique_ptr
    {
        size_t expectedSize = static_cast<size_t>(width) * static_cast<size_t>(height) * 4; // RGBA
        if (pixelLength >= expectedSize && pixelData) {
            std::vector<uint8_t> pixels(expectedSize);
            std::memcpy(pixels.data(), pixelData, expectedSize);
            std::string symbolCopy = symbol;
            float scaleCopy = static_cast<float>(scale);
            int w = width, h = height;
            instance->invokeOnMapThread([symbolCopy, scaleCopy, w, h, pixels = std::move(pixels)](mbgl::Map* m) {
                mbgl::PremultipliedImage image({static_cast<uint32_t>(w), static_cast<uint32_t>(h)});
                std::memcpy(image.data.get(), pixels.data(), pixels.size());
                auto styleImage = std::make_unique<mbgl::style::Image>(symbolCopy, std::move(image), scaleCopy);
                m->getStyle().addImage(std::move(styleImage));
            });
            Logger::info("NativeMapView", "addAnnotationIcon: Icon '%s' scheduled to add", symbol.c_str());
        } else {
            Logger::error("NativeMapView", "addAnnotationIcon: Invalid pixel data size (expected %zu, got %zu)", 
                         expectedSize, pixelLength);
        }
    }
    
    Logger::info("NativeMapView", "========== addAnnotationIcon() END ==========");
    return undefined;
}

napi_value NativeMapView::removeAnnotationIcon(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== removeAnnotationIcon() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Requires 1 argument (symbol)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Map not initialized");
        return undefined;
    }
    
    // 获取 symbol 字符串
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbol;
    if (symbolLength > 0) {
        symbol.resize(symbolLength);
        napi_get_value_string_utf8(env, args[0], &symbol[0], symbolLength + 1, &symbolLength);
    }
    
    Logger::info("NativeMapView", "removeAnnotationIcon: symbol=%s", symbol.c_str());
    
    try {
        instance->invokeOnMapThread([symbol](mbgl::Map* m){ m->getStyle().removeImage(symbol); });
        Logger::info("NativeMapView", "removeAnnotationIcon: Icon '%s' removed successfully", symbol.c_str());
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed - %s", e.what());
    }
    
    Logger::info("NativeMapView", "========== removeAnnotationIcon() END ==========");
    return undefined;
}

napi_value NativeMapView::getTopOffsetPixelsForAnnotationSymbol(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol() called");
    
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    // 获取NativeMapView实例和参数
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::warn("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Missing symbol name argument, returning 0.0");
        return result;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Map not initialized, returning 0.0");
        return result;
    }
    
    // 获取 symbol 名称
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbolName(symbolLength, '\0');
    napi_get_value_string_utf8(env, args[0], &symbolName[0], symbolLength + 1, &symbolLength);
    symbolName.resize(symbolLength);
    
    try {
        double offset = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getTopOffsetPixelsForAnnotationImage(symbolName); }, 0.0);
        napi_create_double(env, offset, &result);
        Logger::debug("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: symbol=%s, offset=%f", symbolName.c_str(), offset);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Failed - %s", e.what());
    }
    
    return result;
}


} // namespace harmony
} // namespace mbgl
