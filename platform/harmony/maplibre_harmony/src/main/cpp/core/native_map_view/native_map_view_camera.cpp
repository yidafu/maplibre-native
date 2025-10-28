#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "camera/camera_position_harmony.hpp"
#include "rendering/harmony_renderer.hpp"
#include <mbgl/style/style.hpp>
#include <mbgl/map/camera.hpp>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

napi_value NativeMapView::resizeView(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取参数
    size_t argc = 2;
    napi_value args[2];
    
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get resizeView arguments");
        return undefined;
    }
    
    if (argc < 2) {
        Logger::error("NativeMapView", "resizeView requires 2 arguments");
        return undefined;
    }
    
    // 解析宽度和高度
    int32_t newWidth, newHeight;
    if (napi_get_value_int32(env, args[0], &newWidth) != napi_ok ||
        napi_get_value_int32(env, args[1], &newHeight) != napi_ok) {
        Logger::error("NativeMapView", "Failed to parse resizeView arguments");
        return undefined;
    }
    
    Logger::info("NativeMapView", "🔍 [DPI] resizeView called: %dx%d (logical)", newWidth, newHeight);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "Failed to unwrap instance");
        return undefined;
    }
    
    // 更新尺寸
    instance->width = newWidth;
    instance->height = newHeight;
    
    Logger::info("NativeMapView", "Resize details:");
    Logger::info("NativeMapView", "  - New size: %dx%d (logical pixels)", instance->width, instance->height);
    Logger::info("NativeMapView", "  - PixelRatio: %.2f", instance->pixelRatio);
    
    // 如果渲染器已初始化，调整尺寸
    if (instance->harmonyRenderer) {
        instance->harmonyRenderer->resize(instance->width, instance->height);
    }
    
    Logger::info("NativeMapView", "View resized to %d x %d", instance->width, instance->height);
    
    return undefined;
}

// Note: getStyleUrl, setStyleUrl, getStyleJson, setStyleJson, and setLatLngBounds are now defined in native_map_view_style.cpp

napi_value NativeMapView::cancelTransitions(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "cancelTransitions() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "cancelTransitions: Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "cancelTransitions: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "cancelTransitions: Map not initialized");
        return undefined;
    }
    
    try {
        Logger::info("NativeMapView", "🔵 BEFORE map->cancelTransitions()");
        instance->map->cancelTransitions();
        Logger::info("NativeMapView", "✅ map->cancelTransitions() returned");
        
        // 触发相机移动取消事件（通过 CallbackManager）
        if (instance->callbackManager_) {
            instance->callbackManager_->InvokeCallbackEmpty("onCameraMoveCanceled");
            instance->callbackManager_->InvokeCallbackEmpty("onCameraIdle");
        }
        
        // 🔧 触发重绘以确保状态更新
        Logger::info("NativeMapView", "🔵 BEFORE triggerRepaint() after cancelTransitions");
        instance->map->triggerRepaint();
        Logger::info("NativeMapView", "✅ triggerRepaint() completed after cancelTransitions");
        
        Logger::debug("NativeMapView", "cancelTransitions: Transitions cancelled successfully, repaint triggered");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "cancelTransitions: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setGestureInProgress(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setGestureInProgress() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setGestureInProgress: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setGestureInProgress: Missing inProgress argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setGestureInProgress: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "setGestureInProgress: Map not initialized");
        return undefined;
    }
    
    // 获取布尔参数
    bool inProgress = false;
    if (napi_get_value_bool(env, args[0], &inProgress) != napi_ok) {
        Logger::error("NativeMapView", "setGestureInProgress: Failed to get boolean value");
        return undefined;
    }
    
    try {
        instance->map->setGestureInProgress(inProgress);
        Logger::debug("NativeMapView", "setGestureInProgress: Set to %s", inProgress ? "true" : "false");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setGestureInProgress: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::moveBy(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "moveBy() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    size_t argc = 3;  // 支持可选的 duration 参数
    napi_value args[3];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "moveBy: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 2) {
        Logger::error("NativeMapView", "moveBy: Missing dx/dy arguments");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "moveBy: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "moveBy: Map not initialized");
        return undefined;
    }
    
    // 获取移动距离
    double dx = 0, dy = 0;
    if (napi_get_value_double(env, args[0], &dx) != napi_ok ||
        napi_get_value_double(env, args[1], &dy) != napi_ok) {
        Logger::error("NativeMapView", "moveBy: Failed to get dx/dy values");
        return undefined;
    }
    
    // 获取动画时长（可选，默认 0 表示立即执行）
    uint64_t duration = 0;
    if (argc >= 3) {
        double durationValue;
        if (napi_get_value_double(env, args[2], &durationValue) == napi_ok) {
            duration = static_cast<uint64_t>(durationValue);
            Logger::debug("NativeMapView", "moveBy: with animation duration = %lu ms", (unsigned long)duration);
        }
    }
    
    try {
        // 再次检查 map 是否有效（防止竞态条件）
        if (!instance->map) {
            Logger::warn("NativeMapView", "moveBy: Map became null before execution");
            return undefined;
        }
        
        // 触发相机移动开始事件
        if (instance->callbackManager_) {
            instance->callbackManager_->InvokeCallbackEmpty("onCameraMoveStarted");
        }
        
        if (duration > 0) {
            // 带动画的移动
            instance->map->moveBy(
                mbgl::ScreenCoordinate{dx, dy},
                mbgl::AnimationOptions(std::chrono::milliseconds(duration))
            );
            Logger::debug("NativeMapView", "moveBy: Animated move by (%.2f, %.2f) over %lu ms", dx, dy, (unsigned long)duration);
        } else {
            // 立即移动
            instance->map->moveBy(mbgl::ScreenCoordinate{dx, dy});
            Logger::debug("NativeMapView", "moveBy: Instant move by (%.2f, %.2f)", dx, dy);
            
            // 立即移动完成后触发 idle
            if (instance->callbackManager_) {
                instance->callbackManager_->InvokeCallbackEmpty("onCameraIdle");
            }
        }
        
        // 再次检查 map 是否有效
        if (instance->map) {
            instance->map->triggerRepaint();
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "moveBy: Failed - %s", e.what());
    } catch (...) {
        Logger::error("NativeMapView", "moveBy: Unknown exception");
    }
    
    return undefined;
}

napi_value NativeMapView::jumpTo(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== jumpTo() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象和参数
    napi_value thisObj;
    size_t argc = 6;  // 最多6个参数（5个必需 + 1个可选的padding）
    napi_value args[6];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "jumpTo: Failed to get arguments");
        return undefined;
    }
    
    // 检查参数数量（至少需要5个参数）
    if (argc < 5) {
        Logger::error("NativeMapView", "jumpTo: Requires at least 5 arguments (angle, latitude, longitude, pitch, zoom), got %zu", argc);
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "jumpTo: Failed to unwrap instance or instance is null");
        return undefined;
    }
    
    Logger::debug("NativeMapView", "jumpTo: instance=%p", instance);
    Logger::debug("NativeMapView", "jumpTo: Current state - map=%s, harmonyRenderer=%s, nativeWindow=%s",
                  instance->map ? "exists" : "null",
                  instance->harmonyRenderer ? "exists" : "null",
                  instance->nativeWindow ? "exists" : "null");
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "jumpTo: Map not initialized yet, will skip jumpTo");
        return undefined;
    }
    
    // 解析参数：angle, latitude, longitude, pitch, zoom
    double angle, latitude, longitude, pitch, zoom;
    
    if (napi_get_value_double(env, args[0], &angle) != napi_ok ||
        napi_get_value_double(env, args[1], &latitude) != napi_ok ||
        napi_get_value_double(env, args[2], &longitude) != napi_ok ||
        napi_get_value_double(env, args[3], &pitch) != napi_ok ||
        napi_get_value_double(env, args[4], &zoom) != napi_ok) {
        Logger::error("NativeMapView", "jumpTo: Failed to parse numeric arguments");
        return undefined;
    }
    
    Logger::info("NativeMapView", "jumpTo: angle=%f, lat=%f, lng=%f, pitch=%f, zoom=%f", 
                  angle, latitude, longitude, pitch, zoom);
    
    // 构建 CameraOptions
    CameraOptions cameraOptions;
    cameraOptions.center = LatLng{latitude, longitude};
    cameraOptions.zoom = zoom;
    cameraOptions.bearing = angle;
    cameraOptions.pitch = pitch;
    
    // TODO: 解析可选的 padding 参数（如果提供）
    // if (argc >= 6) { ... }
    
    // 执行相机跳转
    try {
        // 再次检查 map 是否有效（防止竞态条件）
        if (!instance->map) {
            Logger::error("NativeMapView", "jumpTo: Map became null before execution");
            return undefined;
        }
        
        // 触发相机移动开始事件
        if (instance->callbackManager_) {
            instance->callbackManager_->InvokeCallbackEmpty("onCameraMoveStarted");
        }
        
        Logger::debug("NativeMapView", "jumpTo: Executing map->jumpTo()...");
        instance->map->jumpTo(cameraOptions);
        
        Logger::debug("NativeMapView", "jumpTo: Executing map->triggerRepaint()...");
        instance->map->triggerRepaint();  // Trigger rendering
        
        // jumpTo 是立即执行的，所以立即触发 idle 事件
        if (instance->callbackManager_) {
            instance->callbackManager_->InvokeCallbackEmpty("onCameraIdle");
        }
        
        Logger::info("NativeMapView", "jumpTo: Camera jump executed successfully");
        Logger::info("NativeMapView", "========== jumpTo() END - SUCCESS ==========");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "jumpTo: Failed to jump camera: %s", e.what());
        Logger::error("NativeMapView", "========== jumpTo() END - FAILED ==========");
    } catch (...) {
        Logger::error("NativeMapView", "jumpTo: Unknown exception occurred");
        Logger::error("NativeMapView", "========== jumpTo() END - UNKNOWN ERROR ==========");
    }
    
    return undefined;
}

napi_value NativeMapView::easeTo(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== easeTo() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    size_t argc = 2;
    napi_value args[2];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "easeTo: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "easeTo: Missing camera options argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "easeTo: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::error("NativeMapView", "easeTo: Map not initialized");
        return undefined;
    }
    
    // 解析相机选项对象
    napi_value cameraObj = args[0];
    
    CameraOptions cameraOptions;
    
    // 获取 center (LatLng)
    napi_value centerValue;
    if (napi_get_named_property(env, cameraObj, "center", &centerValue) == napi_ok) {
        napi_value latValue, lngValue;
        if (napi_get_named_property(env, centerValue, "latitude", &latValue) == napi_ok &&
            napi_get_named_property(env, centerValue, "longitude", &lngValue) == napi_ok) {
            double lat, lng;
            if (napi_get_value_double(env, latValue, &lat) == napi_ok &&
                napi_get_value_double(env, lngValue, &lng) == napi_ok) {
                cameraOptions.center = LatLng{lat, lng};
                Logger::debug("NativeMapView", "easeTo: center = (%f, %f)", lat, lng);
            }
        }
    }
    
    // 获取 zoom
    napi_value zoomValue;
    if (napi_get_named_property(env, cameraObj, "zoom", &zoomValue) == napi_ok) {
        double zoom;
        if (napi_get_value_double(env, zoomValue, &zoom) == napi_ok) {
            cameraOptions.zoom = zoom;
            Logger::debug("NativeMapView", "easeTo: zoom = %f", zoom);
        }
    }
    
    // 获取 bearing
    napi_value bearingValue;
    if (napi_get_named_property(env, cameraObj, "bearing", &bearingValue) == napi_ok) {
        double bearing;
        if (napi_get_value_double(env, bearingValue, &bearing) == napi_ok) {
            cameraOptions.bearing = bearing;
            Logger::debug("NativeMapView", "easeTo: bearing = %f", bearing);
        }
    }
    
    // 获取 pitch
    napi_value pitchValue;
    if (napi_get_named_property(env, cameraObj, "pitch", &pitchValue) == napi_ok) {
        double pitch;
        if (napi_get_value_double(env, pitchValue, &pitch) == napi_ok) {
            cameraOptions.pitch = pitch;
            Logger::debug("NativeMapView", "easeTo: pitch = %f", pitch);
        }
    }
    
    // 获取 anchor (可选)
    napi_value anchorValue;
    if (napi_get_named_property(env, cameraObj, "anchor", &anchorValue) == napi_ok) {
        napi_value anchorX, anchorY;
        if (napi_get_named_property(env, anchorValue, "x", &anchorX) == napi_ok &&
            napi_get_named_property(env, anchorValue, "y", &anchorY) == napi_ok) {
            double x, y;
            if (napi_get_value_double(env, anchorX, &x) == napi_ok &&
                napi_get_value_double(env, anchorY, &y) == napi_ok) {
                cameraOptions.anchor = mbgl::ScreenCoordinate{x, y};
                Logger::debug("NativeMapView", "easeTo: anchor = (%f, %f)", x, y);
            }
        }
    }
    
    // 获取动画时长（可选，默认 300ms）
    uint64_t duration = 300;
    if (argc >= 2) {
        double durationValue;
        if (napi_get_value_double(env, args[1], &durationValue) == napi_ok) {
            duration = static_cast<uint64_t>(durationValue);
            Logger::debug("NativeMapView", "easeTo: duration = %lu ms", (unsigned long)duration);
        }
    }
    
    // 执行 easeTo 相机动画
    try {
        // 触发相机移动开始事件
        if (instance->callbackManager_) {
            instance->callbackManager_->InvokeCallbackEmpty("onCameraMoveStarted");
        }
        
        instance->map->easeTo(cameraOptions, 
                             mbgl::AnimationOptions(std::chrono::milliseconds(duration)));
        instance->map->triggerRepaint();
        
        // TODO: 动画完成后应触发 idle 事件，需要监听动画完成回调
        
        Logger::info("NativeMapView", "easeTo: Camera animation started successfully");
        Logger::info("NativeMapView", "========== easeTo() END - SUCCESS ==========");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "easeTo: Failed - %s", e.what());
        Logger::error("NativeMapView", "========== easeTo() END - FAILED ==========");
    }
    
    return undefined;
}

napi_value NativeMapView::flyTo(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== flyTo() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象和参数
    napi_value thisObj;
    size_t argc = 2;  // CameraOptions object + duration
    napi_value args[2];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "flyTo: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "flyTo: Missing camera options argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "flyTo: Failed to get instance or map not initialized");
        return undefined;
    }
    
    // 解析相机选项对象
    napi_value cameraObj = args[0];
    
    CameraOptions cameraOptions;
    
    // 获取 center (LatLng)
    napi_value centerValue;
    if (napi_get_named_property(env, cameraObj, "center", &centerValue) == napi_ok) {
        napi_value latValue, lngValue;
        if (napi_get_named_property(env, centerValue, "latitude", &latValue) == napi_ok &&
            napi_get_named_property(env, centerValue, "longitude", &lngValue) == napi_ok) {
            double lat, lng;
            if (napi_get_value_double(env, latValue, &lat) == napi_ok &&
                napi_get_value_double(env, lngValue, &lng) == napi_ok) {
                cameraOptions.center = LatLng{lat, lng};
                Logger::debug("NativeMapView", "flyTo: center = (%f, %f)", lat, lng);
            }
        }
    }
    
    // 获取 zoom
    napi_value zoomValue;
    if (napi_get_named_property(env, cameraObj, "zoom", &zoomValue) == napi_ok) {
        double zoom;
        if (napi_get_value_double(env, zoomValue, &zoom) == napi_ok) {
            cameraOptions.zoom = zoom;
            Logger::debug("NativeMapView", "flyTo: zoom = %f", zoom);
        }
    }
    
    // 获取 bearing
    napi_value bearingValue;
    if (napi_get_named_property(env, cameraObj, "bearing", &bearingValue) == napi_ok) {
        double bearing;
        if (napi_get_value_double(env, bearingValue, &bearing) == napi_ok) {
            cameraOptions.bearing = bearing;
            Logger::debug("NativeMapView", "flyTo: bearing = %f", bearing);
        }
    }
    
    // 获取 pitch
    napi_value pitchValue;
    if (napi_get_named_property(env, cameraObj, "pitch", &pitchValue) == napi_ok) {
        double pitch;
        if (napi_get_value_double(env, pitchValue, &pitch) == napi_ok) {
            cameraOptions.pitch = pitch;
            Logger::debug("NativeMapView", "flyTo: pitch = %f", pitch);
        }
    }
    
    // 获取动画时长（可选，默认使用 flyTo 自动时长）
    uint64_t duration = 0;
    if (argc >= 2) {
        double durationValue;
        if (napi_get_value_double(env, args[1], &durationValue) == napi_ok) {
            duration = static_cast<uint64_t>(durationValue);
            Logger::debug("NativeMapView", "flyTo: duration = %lu ms", (unsigned long)duration);
        }
    }
    
    // 执行 flyTo 相机动画
    try {
        Logger::info("NativeMapView", "🔵 BEFORE creating AnimationOptions, duration=%lu", (unsigned long)duration);
        mbgl::AnimationOptions animationOptions;
        if (duration > 0) {
            animationOptions.duration.emplace(mbgl::Milliseconds(duration));
            Logger::info("NativeMapView", "✅ AnimationOptions.duration set to %lu ms", (unsigned long)duration);
        } else {
            Logger::warn("NativeMapView", "⚠️ Using default duration (no duration specified)");
        }
        
        Logger::info("NativeMapView", "🔵 BEFORE map->flyTo() call");
        Logger::info("NativeMapView", "  → CameraOptions: center=(%f, %f), zoom=%f, bearing=%f, pitch=%f",
            cameraOptions.center ? cameraOptions.center->latitude() : -999,
            cameraOptions.center ? cameraOptions.center->longitude() : -999,
            cameraOptions.zoom ? *cameraOptions.zoom : -999,
            cameraOptions.bearing ? *cameraOptions.bearing : -999,
            cameraOptions.pitch ? *cameraOptions.pitch : -999);
        
        instance->map->flyTo(cameraOptions, animationOptions);
        Logger::info("NativeMapView", "✅ map->flyTo() returned successfully");
        
        Logger::info("NativeMapView", "🔵 BEFORE triggerRepaint()");
        instance->map->triggerRepaint();
        Logger::info("NativeMapView", "✅ triggerRepaint() completed");
        
        Logger::info("NativeMapView", "flyTo: Camera flight started successfully");
        Logger::info("NativeMapView", "========== flyTo() END - SUCCESS ==========");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "flyTo: Failed - %s", e.what());
        Logger::error("NativeMapView", "========== flyTo() END - FAILED ==========");
    }
    
    return undefined;
}

napi_value NativeMapView::getLatLng(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getLatLng() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getLatLng: Failed to get instance or map not initialized");
        return undefined;
    }
    
    try {
        auto cameraOptions = instance->map->getCameraOptions();
        if (cameraOptions.center) {
            const auto& center = *cameraOptions.center;
            
            // 创建返回对象 { latitude: number, longitude: number }
            napi_value result;
            napi_create_object(env, &result);
            
            napi_value latValue, lngValue;
            napi_create_double(env, center.latitude(), &latValue);
            napi_create_double(env, center.longitude(), &lngValue);
            
            napi_set_named_property(env, result, "latitude", latValue);
            napi_set_named_property(env, result, "longitude", lngValue);
            
            Logger::debug("NativeMapView", "getLatLng: lat=%.6f, lng=%.6f", center.latitude(), center.longitude());
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getLatLng: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setLatLng(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setLatLng() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setLatLng: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取参数：latitude, longitude, padding (可选), duration (可选)
    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    double duration = args.GetDoubleOr(3, 0.0);
    
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::CameraOptions cameraOptions;
        cameraOptions.center = mbgl::LatLng(latitude, longitude);
        
        // TODO: 处理 padding 参数（args[2]）
        
        instance->map->easeTo(cameraOptions, mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))});
        Logger::info("NativeMapView", "setLatLng: lat=%.6f, lng=%.6f, duration=%.0fms", latitude, longitude, duration);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setLatLng: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getCameraForLatLngBounds(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getCameraForLatLngBounds() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getCameraForLatLngBounds: Map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 解析 LatLngBounds
    napi_value boundsObj = args.GetObject(0, "bounds");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::LatLngBounds bounds;
    if (!LatLngBoundsHarmony::ParseLatLngBounds(env, boundsObj, bounds)) {
        Logger::error("NativeMapView", "getCameraForLatLngBounds: Failed to parse bounds");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 解析 padding (top, left, bottom, right)
    double top = args.GetDoubleOr(1, 0.0);
    double left = args.GetDoubleOr(2, 0.0);
    double bottom = args.GetDoubleOr(3, 0.0);
    double right = args.GetDoubleOr(4, 0.0);
    mbgl::EdgeInsets padding{top, left, bottom, right};
    
    // 解析 bearing 和 tilt（可选）
    double bearing = args.GetDoubleOr(5, 0.0);
    double tilt = args.GetDoubleOr(6, 0.0);
    
    try {
        mbgl::CameraOptions cameraOptions = instance->map->cameraForLatLngBounds(bounds, padding, bearing, tilt);
        
        napi_value result = CameraPositionHarmony::CreateCameraPositionObject(env, cameraOptions, instance->pixelRatio);
        Logger::debug("NativeMapView", "getCameraForLatLngBounds: Calculated camera position");
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getCameraForLatLngBounds: Failed - %s", e.what());
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
}

napi_value NativeMapView::getCameraForGeometry(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getCameraForGeometry() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Geometry 和 CameraPosition 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/geojson/geometry.cpp
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/map/camera_position.cpp
    Logger::warn("NativeMapView", "getCameraForGeometry: Not implemented - requires Geometry and CameraPosition wrapper classes");
    
    return undefined;
}

napi_value NativeMapView::setReachability(napi_env env, napi_callback_info info) {
    // 网络可达性由 Harmony 网络管理器处理，不需要手动设置
    // Network reachability handled by Harmony network manager
    Logger::debug("NativeMapView", "setReachability: Network reachability handled by Harmony system");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::resetPosition(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "resetPosition() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "resetPosition: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        instance->map->jumpTo(mbgl::CameraOptions()
            .withCenter(mbgl::LatLng{0.0, 0.0})
            .withZoom(0.0)
            .withBearing(0.0)
            .withPitch(0.0));
        Logger::info("NativeMapView", "resetPosition: Reset to origin (0,0) zoom 0");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "resetPosition: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getPitch(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getPitch() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "getPitch: Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getPitch: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "getPitch: Map not initialized");
        return undefined;
    }
    
    try {
        auto cameraOptions = instance->map->getCameraOptions();
        if (cameraOptions.pitch) {
            napi_value result;
            napi_create_double(env, *cameraOptions.pitch, &result);
            Logger::debug("NativeMapView", "getPitch: Current pitch = %.2f", *cameraOptions.pitch);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getPitch: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setPitch(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setPitch() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象和参数
    size_t argc = 2;
    napi_value args[2];
    napi_value thisObj;
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setPitch: Failed to get callback info");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setPitch: Missing pitch argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setPitch: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "setPitch: Map not initialized");
        return undefined;
    }
    
    // 获取 pitch 值
    double pitch;
    if (napi_get_value_double(env, args[0], &pitch) != napi_ok) {
        Logger::error("NativeMapView", "setPitch: Failed to get pitch value");
        return undefined;
    }
    
    // 获取可选的动画时长参数（毫秒）
    uint32_t duration = 0;
    if (argc >= 2) {
        napi_get_value_uint32(env, args[1], &duration);
    }
    
    try {
        mbgl::CameraOptions options;
        options.pitch = pitch;
        
        if (duration > 0) {
            mbgl::AnimationOptions animationOptions;
            animationOptions.duration = std::chrono::milliseconds(duration);
            instance->map->easeTo(options, animationOptions);
            Logger::debug("NativeMapView", "setPitch: Animating to pitch %.2f over %u ms", pitch, duration);
        } else {
            instance->map->jumpTo(options);
            Logger::debug("NativeMapView", "setPitch: Set pitch to %.2f", pitch);
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setPitch: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setZoom(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setZoom() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setZoom: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取参数：zoom, cx (可选), cy (可选), duration (可选)
    double zoom = args.GetDouble(0, "zoom");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double cx = args.GetDoubleOr(1, 0.0);
    double cy = args.GetDoubleOr(2, 0.0);
    double duration = args.GetDoubleOr(3, 0.0);
    bool hasAnchor = args.Count() >= 3;
    
    try {
        mbgl::CameraOptions cameraOptions;
        cameraOptions.zoom = zoom;
        
        if (hasAnchor) {
            cameraOptions.anchor = mbgl::ScreenCoordinate{cx, cy};
            Logger::info("NativeMapView", "setZoom: zoom=%.2f, anchor=(%.2f, %.2f), duration=%.0fms", 
                        zoom, cx, cy, duration);
        } else {
            Logger::info("NativeMapView", "setZoom: zoom=%.2f, duration=%.0fms", zoom, duration);
        }
        
        instance->map->easeTo(cameraOptions, mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))});
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setZoom: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getZoom(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getZoom() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "getZoom: Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getZoom: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "getZoom: Map not initialized");
        return undefined;
    }
    
    try {
        auto cameraOptions = instance->map->getCameraOptions();
        if (cameraOptions.zoom) {
            napi_value result;
            napi_create_double(env, *cameraOptions.zoom, &result);
            Logger::debug("NativeMapView", "getZoom: Current zoom = %.2f", *cameraOptions.zoom);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getZoom: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::resetZoom(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "resetZoom() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "resetZoom: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        instance->map->jumpTo(mbgl::CameraOptions().withZoom(0.0));
        Logger::info("NativeMapView", "resetZoom: Reset zoom to 0");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "resetZoom: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMinZoom(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setMinZoom() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMinZoom: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double zoom = args.GetDouble(0, "zoom");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        instance->map->setBounds(mbgl::BoundOptions().withMinZoom(zoom));
        Logger::info("NativeMapView", "setMinZoom: Set min zoom to %.2f", zoom);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMinZoom: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMinZoom(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getMinZoom() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMinZoom: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        auto bounds = instance->map->getBounds();
        if (bounds.minZoom) {
            napi_value result;
            napi_create_double(env, *bounds.minZoom, &result);
            Logger::debug("NativeMapView", "getMinZoom: Current min zoom = %.2f", *bounds.minZoom);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMinZoom: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMaxZoom(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setMaxZoom() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMaxZoom: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double zoom = args.GetDouble(0, "zoom");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        instance->map->setBounds(mbgl::BoundOptions().withMaxZoom(zoom));
        Logger::info("NativeMapView", "setMaxZoom: Set max zoom to %.2f", zoom);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMaxZoom: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMaxZoom(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getMaxZoom() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMaxZoom: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        auto bounds = instance->map->getBounds();
        if (bounds.maxZoom) {
            napi_value result;
            napi_create_double(env, *bounds.maxZoom, &result);
            Logger::debug("NativeMapView", "getMaxZoom: Current max zoom = %.2f", *bounds.maxZoom);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMaxZoom: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMinPitch(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setMinPitch() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMinPitch: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double pitch = args.GetDouble(0, "pitch");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        instance->map->setBounds(mbgl::BoundOptions().withMinPitch(pitch));
        Logger::info("NativeMapView", "setMinPitch: Set min pitch to %.2f", pitch);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMinPitch: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMinPitch(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getMinPitch() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMinPitch: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        auto bounds = instance->map->getBounds();
        if (bounds.minPitch) {
            napi_value result;
            napi_create_double(env, *bounds.minPitch, &result);
            Logger::debug("NativeMapView", "getMinPitch: Current min pitch = %.2f", *bounds.minPitch);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMinPitch: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMaxPitch(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setMaxPitch() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMaxPitch: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double pitch = args.GetDouble(0, "pitch");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        instance->map->setBounds(mbgl::BoundOptions().withMaxPitch(pitch));
        Logger::info("NativeMapView", "setMaxPitch: Set max pitch to %.2f", pitch);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMaxPitch: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMaxPitch(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getMaxPitch() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMaxPitch: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        auto bounds = instance->map->getBounds();
        if (bounds.maxPitch) {
            napi_value result;
            napi_create_double(env, *bounds.maxPitch, &result);
            Logger::debug("NativeMapView", "getMaxPitch: Current max pitch = %.2f", *bounds.maxPitch);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMaxPitch: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::rotateBy(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "rotateBy() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "rotateBy: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取参数：sx, sy, ex, ey, duration (可选)
    double sx = args.GetDouble(0, "sx");
    double sy = args.GetDouble(1, "sy");
    double ex = args.GetDouble(2, "ex");
    double ey = args.GetDouble(3, "ey");
    double duration = args.GetDoubleOr(4, 0.0);
    
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::ScreenCoordinate first(sx, sy);
        mbgl::ScreenCoordinate second(ex, ey);
        instance->map->rotateBy(first, second, mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))});
        Logger::info("NativeMapView", "rotateBy: (%.2f, %.2f) -> (%.2f, %.2f), duration=%.0fms", sx, sy, ex, ey, duration);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "rotateBy: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setBearing(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setBearing() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setBearing: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setBearing: Missing bearing argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setBearing: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "setBearing: Map not initialized");
        return undefined;
    }
    
    // 获取bearing值
    double bearing;
    if (napi_get_value_double(env, args[0], &bearing) != napi_ok) {
        Logger::error("NativeMapView", "setBearing: Failed to get bearing value");
        return undefined;
    }
    
    try {
        instance->map->jumpTo(mbgl::CameraOptions().withBearing(bearing));
        instance->map->triggerRepaint();
        Logger::debug("NativeMapView", "setBearing: Set bearing to %.2f", bearing);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setBearing: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setBearingXY(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setBearingXY() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(3);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setBearingXY: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取参数：degrees, cx, cy, duration (可选)
    double degrees = args.GetDouble(0, "degrees");
    double cx = args.GetDouble(1, "cx");
    double cy = args.GetDouble(2, "cy");
    double duration = args.GetDoubleOr(3, 0.0);
    
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::ScreenCoordinate anchor(cx, cy);
        instance->map->easeTo(
            mbgl::CameraOptions().withBearing(degrees).withAnchor(anchor),
            mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))}
        );
        Logger::info("NativeMapView", "setBearingXY: bearing=%.2f, anchor=(%.2f, %.2f), duration=%.0fms", 
                    degrees, cx, cy, duration);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setBearingXY: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getBearing(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getBearing() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "getBearing: Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getBearing: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "getBearing: Map not initialized");
        return undefined;
    }
    
    try {
        auto cameraOptions = instance->map->getCameraOptions();
        if (cameraOptions.bearing) {
            napi_value result;
            napi_create_double(env, *cameraOptions.bearing, &result);
            Logger::debug("NativeMapView", "getBearing: Current bearing = %.2f", *cameraOptions.bearing);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getBearing: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::resetNorth(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "resetNorth() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "resetNorth: Failed to get instance or map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        // 使用 easeTo 将 bearing 设为 0，动画时长 500ms
        instance->map->easeTo(
            mbgl::CameraOptions().withBearing(0.0),
            mbgl::AnimationOptions{mbgl::Milliseconds(500)}
        );
        Logger::info("NativeMapView", "resetNorth: Reset bearing to 0 with 500ms animation");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "resetNorth: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setVisibleCoordinateBounds(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setVisibleCoordinateBounds() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 LatLng 数组和 RectF 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:583-615
    Logger::warn("NativeMapView", "setVisibleCoordinateBounds: Not implemented - requires LatLng array and RectF wrapper classes");
    
    return undefined;
}

napi_value NativeMapView::getVisibleCoordinateBounds(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getVisibleCoordinateBounds() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取NativeMapView实例
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "getVisibleCoordinateBounds: Failed to get this object");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getVisibleCoordinateBounds: Map not initialized");
        return undefined;
    }
    
    try {
        auto latLngBounds = instance->map->latLngBoundsForCameraUnwrapped(instance->map->getCameraOptions(std::nullopt));
        
        napi_value result = LatLngBoundsHarmony::CreateLatLngBoundsObject(env, latLngBounds);
        Logger::debug("NativeMapView", "getVisibleCoordinateBounds: N=%f, E=%f, S=%f, W=%f", 
                      latLngBounds.north(), latLngBounds.east(), 
                      latLngBounds.south(), latLngBounds.west());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getVisibleCoordinateBounds: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::scheduleSnapshot(napi_env env, napi_callback_info info) {
    // 快照功能需要渲染器回调支持
    // Snapshot functionality requires renderer callback support
    Logger::debug("NativeMapView", "scheduleSnapshot: Snapshot functionality requires renderer callback support");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getCameraPosition(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getCameraPosition() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "getCameraPosition: Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getCameraPosition: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::warn("NativeMapView", "getCameraPosition: Map not initialized");
        return undefined;
    }
    
    try {
        auto cameraOptions = instance->map->getCameraOptions();
        
        // 创建返回对象
        napi_value result;
        napi_create_object(env, &result);
        
        // 添加 zoom
        if (cameraOptions.zoom) {
            napi_value zoomValue;
            napi_create_double(env, *cameraOptions.zoom, &zoomValue);
            napi_set_named_property(env, result, "zoom", zoomValue);
        }
        
        // 添加 bearing
        if (cameraOptions.bearing) {
            napi_value bearingValue;
            napi_create_double(env, *cameraOptions.bearing, &bearingValue);
            napi_set_named_property(env, result, "bearing", bearingValue);
        }
        
        // 添加 pitch (tilt)
        if (cameraOptions.pitch) {
            napi_value pitchValue;
            napi_create_double(env, *cameraOptions.pitch, &pitchValue);
            napi_set_named_property(env, result, "tilt", pitchValue);
        }
        
        // 添加 center (target)
        if (cameraOptions.center) {
            napi_value targetObj;
            napi_create_object(env, &targetObj);
            
            napi_value latValue, lngValue;
            napi_create_double(env, cameraOptions.center->latitude(), &latValue);
            napi_create_double(env, cameraOptions.center->longitude(), &lngValue);
            
            napi_set_named_property(env, targetObj, "latitude", latValue);
            napi_set_named_property(env, targetObj, "longitude", lngValue);
            napi_set_named_property(env, result, "target", targetObj);
        }
        
        Logger::debug("NativeMapView", "getCameraPosition: Returned camera position");
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getCameraPosition: Failed - %s", e.what());
    }
    
    return undefined;
}


} // namespace harmony
} // namespace mbgl
