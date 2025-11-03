#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "rendering/harmony_renderer.hpp"
#include "core/thread_safe_callback.hpp"

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using mbgl::harmony::ThreadSafeCallback;

namespace mbgl {
namespace harmony {

napi_value NativeMapView::setMaximumFps(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "setMaximumFps: Invalid arguments");
        return args.Undefined();
    }
    
    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setMaximumFps: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // 检查是否正在销毁
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "setMaximumFps: Instance is being destroyed");
        return args.Undefined();
    }
    
    try {
        // 获取 FPS 参数
        int fps = args.GetInt32(0, "maximumFps");
        if (args.HasError() || fps <= 0) {
            Logger::error("NativeMapView", "setMaximumFps: Invalid FPS value %d", fps);
            return args.Undefined();
        }
        
        // 保存配置
        instance->maximumFps_ = fps;
        
        Logger::info("NativeMapView", "setMaximumFps: Set maximum FPS to %d", fps);
        
        // 参考 Android MapRenderer.setMaximumFps()
        // 实际的 FPS 限制是在渲染循环中通过 sleep 实现的
        // 这里只是保存配置值，实际限制需要在 HarmonyMapRenderThread 的渲染循环中实现
        // TODO: 在渲染循环中实现 FPS 限制（需要修改 HarmonyMapRenderThread）
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMaximumFps: Exception - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setRenderingRefreshMode(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "setRenderingRefreshMode: Invalid arguments");
        return args.Undefined();
    }
    
    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setRenderingRefreshMode: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // 检查是否正在销毁
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "setRenderingRefreshMode: Instance is being destroyed");
        return args.Undefined();
    }
    
    try {
        // 获取渲染模式参数（0=CONTINUOUS, 1=WHEN_DIRTY）
        int mode = args.GetInt32(0, "mode");
        if (args.HasError() || (mode != 0 && mode != 1)) {
            Logger::error("NativeMapView", "setRenderingRefreshMode: Invalid mode %d", mode);
            return args.Undefined();
        }
        
        // 保存配置
        instance->renderingRefreshMode_ = mode;
        
        const char* modeName = (mode == 0) ? "CONTINUOUS" : "WHEN_DIRTY";
        Logger::info("NativeMapView", "setRenderingRefreshMode: Set rendering mode to %s (%d)", modeName, mode);
        
        // 参考 Android MapRenderer.setRenderingRefreshMode()
        // CONTINUOUS 模式: 持续渲染每一帧
        // WHEN_DIRTY 模式: 只在需要时渲染（默认模式，节省电量）
        
        // 设置 HarmonyRenderer 的渲染模式
        if (instance->harmonyRenderer) {
            // 将渲染模式传递给 HarmonyRenderer
            // CONTINUOUS (0) -> RenderMode::Full (持续渲染每一帧)
            // WHEN_DIRTY (1) -> RenderMode::Full (只在需要时渲染，默认模式)
            // 注意：MapObserver::RenderMode 只有 Partial 和 Full
            // 实际的持续渲染控制需要通过其他方式实现（如 requestRender）
            mbgl::MapObserver::RenderMode renderMode = mbgl::MapObserver::RenderMode::Full;
            instance->harmonyRenderer->setRenderingMode(renderMode);
            
            // TODO: 实现真正的 CONTINUOUS vs WHEN_DIRTY 控制
            // CONTINUOUS 模式应该持续调用 requestRender()
            // WHEN_DIRTY 模式只在地图变化时才调用 requestRender()
        } else {
            Logger::warn("NativeMapView", "setRenderingRefreshMode: HarmonyRenderer not initialized");
        }
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setRenderingRefreshMode: Exception - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getRenderingRefreshMode(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "getRenderingRefreshMode: Failed to unwrap instance");
        // 返回默认值 WHEN_DIRTY (1)
        napi_value result;
        napi_create_int32(env, 1, &result);
        return result;
    }
    
    // 检查是否正在销毁
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "getRenderingRefreshMode: Instance is being destroyed");
        napi_value result;
        napi_create_int32(env, instance->renderingRefreshMode_, &result);
        return result;
    }
    
    try {
        int mode = instance->renderingRefreshMode_;
        const char* modeName = (mode == 0) ? "CONTINUOUS" : "WHEN_DIRTY";
        Logger::info("NativeMapView", "getRenderingRefreshMode: Current mode is %s (%d)", modeName, mode);
        
        napi_value result;
        napi_create_int32(env, mode, &result);
        return result;
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getRenderingRefreshMode: Exception - %s", e.what());
        // 返回默认值
        napi_value result;
        napi_create_int32(env, 1, &result);
        return result;
    }
}

napi_value NativeMapView::setOnFpsChangedListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "setOnFpsChangedListener: Invalid arguments");
        return args.Undefined();
    }
    
    // 获取 NativeMapView 实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setOnFpsChangedListener: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // 检查是否正在销毁
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "setOnFpsChangedListener: Instance is being destroyed");
        return args.Undefined();
    }
    
    try {
        // 获取回调函数
        napi_value callback = args.GetValue(0);
        
        // 检查是否为 null（移除监听器）
        napi_valuetype type;
        napi_typeof(env, callback, &type);
        
        if (type == napi_null || type == napi_undefined) {
            // 移除监听器
            instance->fpsChangedCallback_.reset();
            if (instance->harmonyRenderer) {
                instance->harmonyRenderer->setOnFpsChangedCallback(nullptr);
            }
            Logger::info("NativeMapView", "setOnFpsChangedListener: Listener removed");
        } else if (type == napi_function) {
            // 创建 ThreadSafeCallback（参考 Android NativeMapView::setOnFpsChangedListener）
            auto callback_ptr = ThreadSafeCallback::Create(env, callback, "OnFpsChanged");
            if (!callback_ptr) {
                Logger::error("NativeMapView", "setOnFpsChangedListener: Failed to create ThreadSafeCallback");
                return args.Undefined();
            }
            
            instance->fpsChangedCallback_ = std::move(callback_ptr);
            
            if (instance->harmonyRenderer) {
                // 设置回调
                auto callbackPtr = instance->fpsChangedCallback_.get();
                instance->harmonyRenderer->setOnFpsChangedCallback([callbackPtr](double fps) {
                    if (callbackPtr && callbackPtr->IsValid()) {
                        // 使用 ThreadSafeCallback 安全地回调到 ETS 层
                        callbackPtr->Call([fps](napi_env env) -> napi_value {
                            napi_value fpsValue;
                            napi_create_double(env, fps, &fpsValue);
                            return fpsValue;
                        });
                    }
                });
                
                Logger::info("NativeMapView", "setOnFpsChangedListener: Listener set successfully");
            } else {
                Logger::warn("NativeMapView", "setOnFpsChangedListener: HarmonyRenderer not initialized");
            }
        } else {
            Logger::error("NativeMapView", "setOnFpsChangedListener: Invalid callback type");
        }
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setOnFpsChangedListener: Exception - %s", e.what());
    }
    
    return args.Undefined();
}

} // namespace harmony
} // namespace mbgl

