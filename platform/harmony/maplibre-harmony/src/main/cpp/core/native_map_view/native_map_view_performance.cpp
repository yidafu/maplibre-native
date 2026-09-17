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
    
    // Get NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setMaximumFps: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Check whether destruction is in progress
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "setMaximumFps: Instance is being destroyed");
        return args.Undefined();
    }
    
    try {
        // Retrieve FPS parameter (0 disables the limit: render at display refresh rate)
        int fps = args.GetInt32(0, "maximumFps");
        if (args.HasError() || fps < 0) {
            Logger::error("NativeMapView", "setMaximumFps: Invalid FPS value %d", fps);
            return args.Undefined();
        }

        // Save configuration
        instance->maximumFps_ = fps;

        // Forward to the render loop: frames arriving sooner than 1/fps are
        // skipped in HarmonyMapRenderThread::onVSyncFrame(), mirroring Android
        // MapRenderer.setMaximumFps()
        if (instance->harmonyRenderer) {
            instance->harmonyRenderer->setMaximumFps(fps);
        }

        Logger::info("NativeMapView", "setMaximumFps: Set maximum FPS to %d", fps);

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
    
    // Get NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setRenderingRefreshMode: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Check whether destruction is in progress
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "setRenderingRefreshMode: Instance is being destroyed");
        return args.Undefined();
    }
    
    try {
        // Retrieve rendering mode parameter (0=CONTINUOUS, 1=WHEN_DIRTY)
        int mode = args.GetInt32(0, "mode");
        if (args.HasError() || (mode != 0 && mode != 1)) {
            Logger::error("NativeMapView", "setRenderingRefreshMode: Invalid mode %d", mode);
            return args.Undefined();
        }
        
        // Save configuration
        instance->renderingRefreshMode_ = mode;
        
        const char* modeName = (mode == 0) ? "CONTINUOUS" : "WHEN_DIRTY";
        Logger::info("NativeMapView", "setRenderingRefreshMode: Set rendering mode to %s (%d)", modeName, mode);
        
        // Reference Android MapRenderer.setRenderingRefreshMode()
        // Forward to the render loop: CONTINUOUS re-arms VSync after every
        // frame and forces a repaint each tick; WHEN_DIRTY sleeps once the map
        // has nothing more to repaint (default mode, saves power).
        // Note: MapObserver::RenderMode (Partial/Full) is a different concept
        // and is intentionally not derived from the refresh mode.
        if (instance->harmonyRenderer) {
            instance->harmonyRenderer->setRenderingRefreshMode(mode);
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
    
    // Get NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "getRenderingRefreshMode: Failed to unwrap instance");
        // Return default value WHEN_DIRTY (1)
        napi_value result;
        napi_create_int32(env, 1, &result);
        return result;
    }
    
    // Check whether destruction is in progress
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
        // Return default value
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
    
    // Get NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setOnFpsChangedListener: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Check whether destruction is in progress
    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "setOnFpsChangedListener: Instance is being destroyed");
        return args.Undefined();
    }
    
    try {
        // Retrieve callback function
        napi_value callback = args.GetValue(0);
        
        // Check for null (remove listener)
        napi_valuetype type;
        napi_typeof(env, callback, &type);
        
        if (type == napi_null || type == napi_undefined) {
            // Remove listener: clear the render-thread use FIRST, then drop the
            // shared reference. The render thread's lambda holds a shared_ptr,
            // so an in-flight invocation keeps the callback alive even if the
            // member is reset concurrently.
            if (instance->harmonyRenderer) {
                instance->harmonyRenderer->setOnFpsChangedCallback(nullptr);
            }
            instance->fpsChangedCallback_.reset();
            Logger::info("NativeMapView", "setOnFpsChangedListener: Listener removed");
        } else if (type == napi_function) {
            // Create ThreadSafeCallback (refer to Android NativeMapView::setOnFpsChangedListener)
            auto callback_ptr = ThreadSafeCallback::Create(env, callback, "OnFpsChanged");
            if (!callback_ptr) {
                Logger::error("NativeMapView", "setOnFpsChangedListener: Failed to create ThreadSafeCallback");
                return args.Undefined();
            }

            instance->fpsChangedCallback_ = std::move(callback_ptr);

            if (instance->harmonyRenderer) {
                // Install callback. Capture the shared_ptr (not a raw pointer)
                // so removal from the JS thread can never free the callback
                // while the render thread is dispatching an fps event.
                auto pinned = instance->fpsChangedCallback_;
                instance->harmonyRenderer->setOnFpsChangedCallback([pinned](double fps) {
                    if (pinned && pinned->IsValid()) {
                        // Use ThreadSafeCallback to safely call back to the ETS layer
                        pinned->Call([fps](napi_env env) -> napi_value {
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

