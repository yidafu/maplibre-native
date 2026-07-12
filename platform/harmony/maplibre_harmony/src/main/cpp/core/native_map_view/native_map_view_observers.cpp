#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "bitmap/bitmap_napi.hpp"
#include "rendering/harmony_renderer.hpp"
#include <arkui/native_node_napi.h>
#include <mbgl/gfx/shader_registry.hpp>
#include <mbgl/style/style.hpp>
#include <tuple>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

// ✅ Architecture fix: helper methods to ensure thread safety
bool NativeMapView::isOnRenderThread() const {
    if (!harmonyRenderer) {
        return false;
    }
    return harmonyRenderer->isOnRenderThread();
}

void NativeMapView::runOnRenderThread(std::function<void()>&& fn) {
    if (!harmonyRenderer) {
        Logger::error("NativeMapView", "❌ runOnRenderThread: harmonyRenderer is null");
        return;
    }
    harmonyRenderer->runOnRenderThread(std::move(fn));
}

void NativeMapView::onCameraWillChange(MapObserver::CameraChangeMode mode) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // ✅ Architecture fix: ensure callbacks execute on the render thread
    if (!isOnRenderThread()) {
        runOnRenderThread([this, mode]() {
            if (isDestroying.load(std::memory_order_acquire)) return;
            if (callbackManager_) {
                bool animated = (mode == MapObserver::CameraChangeMode::Animated);
                callbackManager_->InvokeCallback("onCameraWillChange", [animated](napi_env env) {
                    napi_value argv[1];
                    napi_get_boolean(env, animated, &argv[0]);
                    return argv[0];
                });
                
                // TODO: Move the Android-style callback mapping to the ETS layer
                // Temporary approach: trigger Android-style callbacks directly in C++
                // Long-term approach: listen to onCameraWillChange in NativeMapView.ets and translate it to onCameraMoveStarted
                // 🔧 Trigger the Android-style onCameraMoveStarted callback
                // reason: 3=DEVELOPER_ANIMATION (animation), 1=GESTURE (gesture)
                int reason = animated ? 3 : 1;
                callbackManager_->InvokeCallback("onCameraMoveStarted", [reason](napi_env env) {
                    napi_value argv[1];
                    napi_create_int32(env, reason, &argv[0]);
                    return argv[0];
                });
            }
        });
        return;
    }
    
    // Notify listeners
    if (callbackManager_) {
        bool animated = (mode == MapObserver::CameraChangeMode::Animated);
        callbackManager_->InvokeCallback("onCameraWillChange", [animated](napi_env env) {
            napi_value argv[1];
            napi_get_boolean(env, animated, &argv[0]);
            return argv[0];
        });
        
        // TODO: Move the Android-style callback mapping to the ETS layer
        // Temporary approach: trigger Android-style callbacks directly in C++
        // Long-term approach: listen to onCameraWillChange in NativeMapView.ets and translate it to onCameraMoveStarted
        // 🔧 Trigger the Android-style onCameraMoveStarted callback
        // reason: 3=DEVELOPER_ANIMATION (animation), 1=GESTURE (gesture)
        int reason = animated ? 3 : 1;
        callbackManager_->InvokeCallback("onCameraMoveStarted", [reason](napi_env env) {
            napi_value argv[1];
            napi_create_int32(env, reason, &argv[0]);
            return argv[0];
        });
    }
}

void NativeMapView::onCameraIsChanging() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // ✅ Architecture fix: ensure callbacks execute on the render thread
    if (!isOnRenderThread()) {
        runOnRenderThread([this]() {
            if (isDestroying.load(std::memory_order_acquire)) return;
            if (callbackManager_) {
                callbackManager_->InvokeCallbackEmpty("onCameraIsChanging");
                
                // TODO: Move the Android-style callback mapping to the ETS layer
                // Temporary approach: trigger Android-style callbacks directly in C++
                // Long-term approach: listen to onCameraIsChanging in NativeMapView.ets and translate it to onCameraMove
                // 🔧 Trigger the Android-style onCameraMove callback
                callbackManager_->InvokeCallbackEmpty("onCameraMove");
            }
        });
        return;
    }
    
    // Notify listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onCameraIsChanging");
        
        // TODO: Move the Android-style callback mapping to the ETS layer
        // Temporary approach: trigger Android-style callbacks directly in C++
        // Long-term approach: listen to onCameraIsChanging in NativeMapView.ets and translate it to onCameraMove
        // 🔧 Trigger the Android-style onCameraMove callback
        callbackManager_->InvokeCallbackEmpty("onCameraMove");
    }
}

void NativeMapView::onCameraDidChange(MapObserver::CameraChangeMode mode) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // ✅ Architecture fix: ensure callbacks execute on the render thread
    if (!isOnRenderThread()) {
        runOnRenderThread([this, mode]() {
            if (isDestroying.load(std::memory_order_acquire)) return;
            if (callbackManager_) {
                bool animated = (mode == MapObserver::CameraChangeMode::Animated);
                callbackManager_->InvokeCallback("onCameraDidChange", [animated](napi_env env) {
                    napi_value argv[1];
                    napi_get_boolean(env, animated, &argv[0]);
                    return argv[0];
                });
                
                // TODO: Move the Android-style callback mapping to the ETS layer
                // Temporary approach: trigger Android-style callbacks directly in C++
                // Long-term approach: listen to onCameraDidChange in NativeMapView.ets and translate it to onCameraIdle
                // 🔧 Trigger the Android-style onCameraIdle callback
                callbackManager_->InvokeCallbackEmpty("onCameraIdle");
            }
        });
        return;
    }
    
    // Notify listeners
    if (callbackManager_) {
        bool animated = (mode == MapObserver::CameraChangeMode::Animated);
        callbackManager_->InvokeCallback("onCameraDidChange", [animated](napi_env env) {
            napi_value argv[1];
            napi_get_boolean(env, animated, &argv[0]);
            return argv[0];
        });
        
        // TODO: Move the Android-style callback mapping to the ETS layer
        // Temporary approach: trigger Android-style callbacks directly in C++
        // Long-term approach: listen to onCameraDidChange in NativeMapView.ets and translate it to onCameraIdle
        // 🔧 Trigger the Android-style onCameraIdle callback
        callbackManager_->InvokeCallbackEmpty("onCameraIdle");
    }
    
    // MapLibre already handles render timing internally (via triggerRepaint)
    // No additional render request is required here; otherwise it leads to over-rendering
}
void NativeMapView::onWillStartLoadingMap() {
    Logger::info("NativeMapView", "========== onWillStartLoadingMap ==========");
    Logger::info("NativeMapView", "Map loading started");
    Logger::info("NativeMapView", "This is triggered when:");
    Logger::info("NativeMapView", "  - Style URL/JSON is set");
    Logger::info("NativeMapView", "  - Map starts loading resources");
    Logger::info("NativeMapView", "===========================================");
    
    // Notify listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onWillStartLoadingMap");
    }
}
void NativeMapView::onDidFinishLoadingMap() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    Logger::warn("NativeMapView", "🗺️ [%lld ms] onDidFinishLoadingMap", elapsed);
    
    // Notify listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onDidFinishLoadingMap");
    }
    
    // MapLibre already handles rendering internally, no additional request is required
    // Remove requestRender() here to avoid redundant rendering
}
void NativeMapView::onDidFailLoadingMap(MapLoadError error, const std::string& errorMsg) {
    Logger::error("NativeMapView", "========== onDidFailLoadingMap ==========");
    
    // Log specific information based on the error type
    const char* errorType = "Unknown";
    const char* suggestion = "";
    
    switch (error) {
        case MapLoadError::StyleParseError:
            errorType = "StyleParseError";
            suggestion = "Check if the style JSON is valid. Validate at: https://maplibre.org/maplibre-style-spec/";
            break;
        case MapLoadError::StyleLoadError:
            errorType = "StyleLoadError";
            suggestion = "Check if the style URL is accessible and the network connection is working";
            break;
        case MapLoadError::NotFoundError:
            errorType = "NotFoundError";
            suggestion = "The style file or resource was not found. Check the URL and file paths";
            break;
        case MapLoadError::UnknownError:
            errorType = "UnknownError";
            suggestion = "An unknown error occurred. Check the error message for details";
            break;
    }
    
    Logger::error("NativeMapView", "Map loading failed!");
    Logger::error("NativeMapView", "  Error Type: %s", errorType);
    Logger::error("NativeMapView", "  Error Message: %s", errorMsg.c_str());
    Logger::info("NativeMapView", "  Suggestion: %s", suggestion);
    Logger::error("NativeMapView", "=========================================");
    
    // Notify listeners
    std::string fullError = std::string(errorType) + ": " + errorMsg;
    if (callbackManager_) {
        callbackManager_->InvokeCallbackWithString("onDidFailLoadingMap", fullError);
    }
    
    // Notify the style load failure (preserve the legacy listener)
    notifyStyleLoadError(fullError);
}
void NativeMapView::onWillStartRenderingFrame() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // Notify listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onWillStartRenderingFrame");
    }
}

void NativeMapView::onDidFinishRenderingFrame(const MapObserver::RenderFrameStatus& status) {
    if (isDestroying.load(std::memory_order_acquire)) {
        return;
    }
    
    // ⚠️ Important: onDidFinishRenderingFrame is already invoked by the renderer on the render thread
    // It must not be dispatched again, otherwise the render cannot finish and a blank screen appears
    
    // Notify listeners with render statistics
    if (callbackManager_) {
        bool fully = (status.mode == MapObserver::RenderMode::Full);
        // Use the actual data from renderingStats
        // Retrieve encoding and rendering time from renderingStats
        const auto& stats = status.renderingStats;
        // encodingTime and renderingTime are in seconds; convert them to milliseconds
        double encodingTime = stats.encodingTime * 1000.0;
        double renderingTime = stats.renderingTime * 1000.0;
        
        if (encodingTime > 0.0 || renderingTime > 0.0) {
        }
        
        callbackManager_->InvokeCallback("onDidFinishRenderingFrame", [fully, encodingTime, renderingTime](napi_env env) {
            napi_value argv[3];
            napi_get_boolean(env, fully, &argv[0]);
            napi_create_double(env, encodingTime, &argv[1]);
            napi_create_double(env, renderingTime, &argv[2]);
            return argv[0]; // DataBuilder requires a return value; return the first argument here
        });
    }
    
    // Network I/O is now handled by the renderer thread's RunLoop
}
void NativeMapView::onWillStartRenderingMap() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    // Notify listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onWillStartRenderingMap");
    }
}

void NativeMapView::onDidFinishRenderingMap(MapObserver::RenderMode mode) {
    // Immediately check whether the object is being destroyed
    if (isDestroying.load(std::memory_order_acquire)) {
        return;
    }
    
    try {
        // ⚠️ Important: onDidFinishRenderingMap is already invoked by the renderer on the render thread
        // It must not be dispatched again, or the rendering pipeline will be interrupted
        
        // Notify listeners
        if (callbackManager_) {
            bool fully = (mode == MapObserver::RenderMode::Full);
            callbackManager_->InvokeCallback("onDidFinishRenderingMap", [fully](napi_env env) {
                napi_value argv[1];
                napi_get_boolean(env, fully, &argv[0]);
                return argv[0];
            });
        }
        
        // Rendering is complete; there is no need to request rendering again
        // onCameraDidChange already handled the render request
    } catch (...) {
        // Ignore every exception to avoid crashing
    }
}

void NativeMapView::onDidBecomeIdle() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    // Notify listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onDidBecomeIdle");
    }
}
void NativeMapView::onDidFinishLoadingStyle() {
    if (isDestroying.load(std::memory_order_acquire)) {
        Logger::warn("NativeMapView", "⚠️ onDidFinishLoadingStyle: Instance is destroying, skipping callback");
        return;
    }
    
    // ✅ Architecture fix: ensure callbacks execute on the render thread
    if (!isOnRenderThread()) {
        Logger::warn("NativeMapView", "⚠️ onDidFinishLoadingStyle from non-render thread, dispatching");

        // Switch execution to the render thread
        runOnRenderThread([this]() {
            if (isDestroying.load(std::memory_order_acquire)) return;
            
            // Notify the Android-style listeners
            if (callbackManager_) {
                callbackManager_->InvokeCallbackEmpty("onDidFinishLoadingStyle");
            }
            
            // Notify that style loading completed (legacy listener)
            notifyStyleLoaded();
        });
        return;
    }
    
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    // Instance identifier
    static int instanceCounter = 0;
    static std::map<void*, int> instanceIds;
    if (instanceIds.find(this) == instanceIds.end()) {
        instanceIds[this] = ++instanceCounter;
    }
    int instanceId = instanceIds[this];
    
    Logger::info("NativeMapView", "onDidFinishLoadingStyle (instance=%d, +%lld ms)", instanceId, elapsed);
    
    // Notify the Android-style listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onDidFinishLoadingStyle");
    }
    
    // Notify that style loading completed (legacy listener)
    notifyStyleLoaded();
    
    if (map) {
        try {
            auto info = invokeOnMapThreadSync([&](mbgl::Map* m) {
                return std::tuple<std::string, std::string, size_t, size_t>{
                    m->getStyle().getURL(),
                    m->getStyle().getName(),
                    m->getStyle().getSources().size(),
                    m->getStyle().getLayers().size()};
            }, std::tuple<std::string, std::string, size_t, size_t>{});
            
            const auto& [styleUrl, styleName, sourceCount, layerCount] = info;
            Logger::info("NativeMapView",
                         "Style loaded: url=%s, name=%s, sources=%zu, layers=%zu",
                         styleUrl.empty() ? "(inline JSON)" : styleUrl.c_str(),
                         styleName.empty() ? "(unnamed)" : styleName.c_str(),
                         sourceCount,
                         layerCount);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "Error inspecting loaded style: %s", e.what());
        }
    } else {
        Logger::warn("NativeMapView", "Map object is null");
    }
    
    // MapLibre already handles rendering internally, no additional request is required
    // Remove requestRender() here to avoid redundant rendering
}
void NativeMapView::onSourceChanged(mbgl::style::Source& source) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // ✅ Architecture fix: ensure callbacks execute on the render thread
    if (!isOnRenderThread()) {
        Logger::warn("NativeMapView", "⚠️ onSourceChanged called from wrong thread! Dispatching to render thread.");
        
        // Copy the source ID to avoid dangling references
        std::string sourceId = source.getID();
        auto sourceType = source.getType();
        
        // Switch execution to the render thread
        runOnRenderThread([this, sourceId, sourceType]() {
            // Execute safely on the render thread
            int count = ++sourceChangedCount;
            auto now = std::chrono::steady_clock::now();
            static auto startTime = now;
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
            
            Logger::info("NativeMapView", "🔄 [%lld ms] onSourceChanged #%d: %s (type=%d) [render thread]", 
                         elapsed, count, sourceId.c_str(), static_cast<int>(sourceType));
            
            // Notify listeners
            if (callbackManager_) {
                callbackManager_->InvokeCallbackWithString("onSourceChanged", sourceId);
            }
        });
        return;
    }
    
    // Already on the render thread; execute directly
    int count = ++sourceChangedCount;
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    Logger::warn("NativeMapView", "🔄 [%lld ms] onSourceChanged #%d: %s (type=%d)", 
                 elapsed, count, source.getID().c_str(), static_cast<int>(source.getType()));
    
    // Notify listeners
    if (callbackManager_) {
        std::string sourceId = source.getID();
        callbackManager_->InvokeCallbackWithString("onSourceChanged", sourceId);
    }
    
    // MapLibre already handles rendering internally; no additional request is required
    // Remove requestRender() here to avoid duplicate rendering that leads to an infinite loop
}
void NativeMapView::onStyleImageMissing(const std::string& id) {
    Logger::warn("NativeMapView", "========== onStyleImageMissing ==========");
    Logger::warn("NativeMapView", "[MarkerDebug] Style-Missing: Icon \"%s\" not found in style", id.c_str());
    Logger::warn("NativeMapView", "[MarkerDebug] ⚠️ CRITICAL: This will cause markers with this icon to be INVISIBLE!");
    Logger::info("NativeMapView", "");
    Logger::info("NativeMapView", "[MarkerDebug] Solutions:");
    Logger::info("NativeMapView", "[MarkerDebug]   1. Add custom icon using addAnnotationIcon():");
    Logger::info("NativeMapView", "[MarkerDebug]      mapView.addAnnotationIcon(\"icon-name\", width, height, scale, pixelData)");
    Logger::info("NativeMapView", "[MarkerDebug]   2. Use a style that includes the icon in sprite sheet");
    Logger::info("NativeMapView", "[MarkerDebug]   3. Specify an existing icon name when creating marker");
    Logger::info("NativeMapView", "");
    if (id.empty()) {
        Logger::warn("NativeMapView", "[MarkerDebug] ⚠️ Icon ID is EMPTY - did you forget to set icon when creating Marker?");
        Logger::info("NativeMapView", "[MarkerDebug]    Example: new MarkerOptions().position(latLng).icon(\"my-icon\").getMarker()");
    }
    Logger::warn("NativeMapView", "=========================================");
    
    // Notify listeners
    if (callbackManager_) {
        callbackManager_->InvokeCallbackWithString("onStyleImageMissing", id);
    }
}

bool NativeMapView::onCanRemoveUnusedStyleImage(const std::string& id) {
    return false;
}

// Note: initializeRenderer is defined in native_map_view_base.cpp

napi_value NativeMapView::getImage(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getImage: Map not initialized");
        return args.Undefined();
    }
    
    // Retrieve the image ID
    std::string imageId = args.GetString(0, "imageId");
    if (args.HasError()) return args.Undefined();
    
    try {
        // Get image from style (returns std::optional<Image>)
        auto optionalImage = instance->map->getStyle().getImage(imageId);
        if (!optionalImage) {
            Logger::warn("NativeMapView", "getImage: Image '%s' not found", imageId.c_str());
            return args.Undefined();
        }
        
        // Copy image data
        auto image = std::make_shared<mbgl::PremultipliedImage>(optionalImage->getImage().clone());
        
        // Create Bitmap NAPI wrapper
        napi_value bitmapObj = BitmapNAPI::CreateFromImage(env, imageId, image);
        
        Logger::info("NativeMapView", "getImage: Returned image '%s' (%ux%u)", 
                    imageId.c_str(), image->size.width, image->size.height);
        return bitmapObj;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getImage: Exception - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::setPrefetchTiles(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
        // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setPrefetchTiles: Missing enable argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setPrefetchTiles: Map not initialized");
        return undefined;
    }
    
    bool enable;
    if (napi_get_value_bool(env, args[0], &enable) != napi_ok) {
        Logger::error("NativeMapView", "setPrefetchTiles: Failed to parse enable argument");
        return undefined;
    }
    
    try {
        // Align with Android: set the default zoom delta when enabled; otherwise set it to 0
        instance->invokeOnMapThread([enable](mbgl::Map* m){ m->setPrefetchZoomDelta(enable ? mbgl::util::DEFAULT_PREFETCH_ZOOM_DELTA : uint8_t(0)); });
        Logger::info("NativeMapView", "setPrefetchTiles: Set to %s", enable ? "enabled" : "disabled");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setPrefetchTiles: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getPrefetchTiles(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getPrefetchTiles: Map not initialized, returning false");
        return result;
    }
    
    try {
        bool enabled = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getPrefetchZoomDelta() > 0; }, false);
        napi_get_boolean(env, enabled, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getPrefetchTiles: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setPrefetchZoomDelta(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setPrefetchZoomDelta: Missing delta argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setPrefetchZoomDelta: Map not initialized");
        return undefined;
    }
    
    int32_t delta;
    if (napi_get_value_int32(env, args[0], &delta) != napi_ok) {
        Logger::error("NativeMapView", "setPrefetchZoomDelta: Failed to parse delta argument");
        return undefined;
    }
    
    try {
        instance->invokeOnMapThread([delta](mbgl::Map* m){ m->setPrefetchZoomDelta(static_cast<uint8_t>(delta)); });
        Logger::info("NativeMapView", "setPrefetchZoomDelta: Set to %d", delta);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setPrefetchZoomDelta: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getPrefetchZoomDelta(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_int32(env, 0, &result);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getPrefetchZoomDelta: Map not initialized, returning 0");
        return result;
    }
    
    try {
        int32_t delta = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return static_cast<int32_t>(m->getPrefetchZoomDelta()); }, 0);
        napi_create_int32(env, delta, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getPrefetchZoomDelta: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileCacheEnabled(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);

    napi_value undefined = args.Undefined();
    if (args.HasError()) {
        Logger::error("NativeMapView", "setTileCacheEnabled: Invalid arguments");
        return undefined;
    }

    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setTileCacheEnabled: Failed to unwrap instance");
        return undefined;
    }

    if (instance->isDestroying.load()) {
        Logger::warn("NativeMapView", "setTileCacheEnabled: Instance is being destroyed");
        return undefined;
    }

    bool enabled = args.GetBool(0, "enabled");
    if (args.HasError()) {
        Logger::error("NativeMapView", "setTileCacheEnabled: Failed to parse enabled flag");
        return undefined;
    }

    if (!instance->harmonyRenderer) {
        Logger::warn("NativeMapView", "setTileCacheEnabled: HarmonyRenderer not initialized");
        return undefined;
    }

    instance->harmonyRenderer->setTileCacheEnabled(enabled);
    return undefined;
}

napi_value NativeMapView::getTileCacheEnabled(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);

    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "getTileCacheEnabled: Failed to unwrap instance");
        return result;
    }

    if (!instance->harmonyRenderer) {
        Logger::warn("NativeMapView", "getTileCacheEnabled: HarmonyRenderer not initialized");
        return result;
    }

    bool enabled = false;
    try {
        enabled = instance->harmonyRenderer->getTileCacheEnabled();
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileCacheEnabled: Exception - %s", e.what());
    }

    napi_get_boolean(env, enabled, &result);
    return result;
}

napi_value NativeMapView::setTileLodMinRadius(napi_env env, napi_callback_info info) {
    // Tile LOD parameter control is implemented
    // Tile LOD parameter control is implemented
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setTileLodMinRadius: Missing radius argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setTileLodMinRadius: Map not initialized");
        return undefined;
    }
    
    double radius;
    if (napi_get_value_double(env, args[0], &radius) != napi_ok) {
        Logger::error("NativeMapView", "setTileLodMinRadius: Failed to parse radius argument");
        return undefined;
    }
    
    try {
        instance->invokeOnMapThread([radius](mbgl::Map* m){ m->setTileLodMinRadius(radius); });
        Logger::info("NativeMapView", "setTileLodMinRadius: Set to %f", radius);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodMinRadius: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodMinRadius(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getTileLodMinRadius: Map not initialized, returning 0.0");
        return result;
    }
    
    try {
        double radius = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getTileLodMinRadius(); }, 0.0);
        napi_create_double(env, radius, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileLodMinRadius: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileLodScale(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setTileLodScale: Missing scale argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setTileLodScale: Map not initialized");
        return undefined;
    }
    
    double scale;
    if (napi_get_value_double(env, args[0], &scale) != napi_ok) {
        Logger::error("NativeMapView", "setTileLodScale: Failed to parse scale argument");
        return undefined;
    }
    
    try {
        instance->invokeOnMapThread([scale](mbgl::Map* m){ m->setTileLodScale(scale); });
        Logger::info("NativeMapView", "setTileLodScale: Set to %f", scale);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodScale: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodScale(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getTileLodScale: Map not initialized, returning 0.0");
        return result;
    }
    
    try {
        double scale = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getTileLodScale(); }, 0.0);
        napi_create_double(env, scale, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileLodScale: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileLodPitchThreshold(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setTileLodPitchThreshold: Missing threshold argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setTileLodPitchThreshold: Map not initialized");
        return undefined;
    }
    
    double threshold;
    if (napi_get_value_double(env, args[0], &threshold) != napi_ok) {
        Logger::error("NativeMapView", "setTileLodPitchThreshold: Failed to parse threshold argument");
        return undefined;
    }
    
    try {
        instance->invokeOnMapThread([threshold](mbgl::Map* m){ m->setTileLodPitchThreshold(threshold); });
        Logger::info("NativeMapView", "setTileLodPitchThreshold: Set to %f", threshold);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodPitchThreshold: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodPitchThreshold(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getTileLodPitchThreshold: Map not initialized, returning 0.0");
        return result;
    }
    
    try {
        double threshold = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getTileLodPitchThreshold(); }, 0.0);
        napi_create_double(env, threshold, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileLodPitchThreshold: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileLodZoomShift(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setTileLodZoomShift: Missing shift argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setTileLodZoomShift: Map not initialized");
        return undefined;
    }
    
    double shift;
    if (napi_get_value_double(env, args[0], &shift) != napi_ok) {
        Logger::error("NativeMapView", "setTileLodZoomShift: Failed to parse shift argument");
        return undefined;
    }
    
    try {
        instance->invokeOnMapThread([shift](mbgl::Map* m){ m->setTileLodZoomShift(shift); });
        Logger::info("NativeMapView", "setTileLodZoomShift: Set to %f", shift);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodZoomShift: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodZoomShift(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getTileLodZoomShift: Map not initialized, returning 0.0");
        return result;
    }
    
    try {
        double shift = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getTileLodZoomShift(); }, 0.0);
        napi_create_double(env, shift, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileLodZoomShift: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::triggerRepaint(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get this object");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "Failed to unwrap instance");
        return undefined;
    }
    
    // Request rendering
    if (instance->harmonyRenderer) {
        instance->harmonyRenderer->requestRender();
    }
    
    return undefined;
}

// NAPI method to set the native window
napi_value NativeMapView::setNativeWindow(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve arguments
    size_t argc = 1;
    napi_value args[1];
    
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get setNativeWindow arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setNativeWindow requires 1 argument");
        return undefined;
    }
    
    // Retrieve the this object
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get this object");
        return undefined;
    }

    int64_t surfaceId = mbgl::harmony::napi::ParseSurfaceId(env, info);
    Logger::info("NativeMapView", "Surface ID: %ld", (long)surfaceId);

    // Obtain the NativeMapView instance
    NativeMapView* nativeMapView;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&nativeMapView)) != napi_ok) {
        Logger::error("NativeMapView", "Failed to unwrap NativeMapView");
        return undefined;
    }
    
    OHNativeWindow *nativeWindow;
    OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &nativeWindow);
    
    if (nativeWindow) {
        Logger::info("NativeMapView", "Native window created successfully: %p", nativeWindow);
    } else {
        Logger::error("NativeMapView", "Failed to create native window from surface ID");
        return undefined;
    }
    
    // Store the window pointer
    nativeMapView->nativeWindow = nativeWindow;
    // pixelRatio will be determined during renderer initialization from device
    Logger::info("NativeMapView", "pixelRatio will be determined from device DPI");
    
    // Initialize the renderer if it has not been set up
    try {
        Logger::info("NativeMapView", "Initializing renderer...");
        nativeMapView->initializeRenderer();
        Logger::info("NativeMapView", "Renderer initialized successfully");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "Failed to initialize renderer: %s", e.what());
        return undefined;
    } catch (...) {
        Logger::error("NativeMapView", "Failed to initialize renderer: Unknown exception");
        return undefined;
    }
    
    Logger::info("NativeMapView", "========== setNativeWindow() END - SUCCESS ==========");
    
    return undefined;
}

napi_value NativeMapView::isRenderingStatsViewEnabled(napi_env env, napi_callback_info info) {
    // Rendering stats view is not implemented on the Harmony platform
    // Rendering stats view not implemented for Harmony
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::enableRenderingStatsView(napi_env env, napi_callback_info info) {
    // Rendering stats view is not implemented on the Harmony platform
    // Rendering stats view not implemented for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// NAPI method to set the native window with size
napi_value NativeMapView::setNativeWindowWithSize(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve arguments
    size_t argc = 3;
    napi_value args[3];
    
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get setNativeWindowWithSize arguments");
        return undefined;
    }
    
    if (argc < 3) {
        Logger::error("NativeMapView", "setNativeWindowWithSize requires 3 arguments");
        return undefined;
    }
    
    // Retrieve the this object
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get this object");
        return undefined;
    }

    // Parse arguments
    int64_t surfaceId = mbgl::harmony::napi::ParseSurfaceId(env, info);
    int32_t width, height;
    
    if (napi_get_value_int32(env, args[1], &width) != napi_ok ||
        napi_get_value_int32(env, args[2], &height) != napi_ok) {
        Logger::error("NativeMapView", "Failed to parse width/height arguments");
        return undefined;
    }
    
    Logger::info("NativeMapView", "Surface ID: %ld, Width: %d, Height: %d", (long)surfaceId, width, height);

    // Obtain the NativeMapView instance
    NativeMapView* nativeMapView;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&nativeMapView)) != napi_ok) {
        Logger::error("NativeMapView", "Failed to unwrap NativeMapView");
        return undefined;
    }
    
    // Invoke the new method
    nativeMapView->setNativeWindowWithSize(surfaceId, width, height);
    
    Logger::info("NativeMapView", "========== setNativeWindowWithSize() END - SUCCESS ==========");

    return undefined;
}

// NAPI method to initialize native gesture recognizers (replaces ArkTS MapGestureDetector)
// Accepts a FrameNode napi_value and extracts ArkUI_NodeHandle via OH_ArkUI_GetNodeHandleFromNapiValue.
napi_value NativeMapView::setupNativeGestures(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);

    // Get the 'this' object and arguments
    size_t argc = 1;
    napi_value args[1];
    napi_value thisObj;
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setupNativeGestures: failed to get arguments");
        return undefined;
    }

    if (argc < 1) {
        Logger::warn("NativeMapView", "setupNativeGestures: no FrameNode provided, skipping gesture init");
        return undefined;
    }

    // Extract ArkUI_NodeHandle from the FrameNode napi_value
    ArkUI_NodeHandle nodeHandle = nullptr;
    int32_t result = OH_ArkUI_GetNodeHandleFromNapiValue(env, args[0], &nodeHandle);
    if (result != 0 || !nodeHandle) {
        Logger::error("NativeMapView", "setupNativeGestures: failed to get node handle from FrameNode, error=%d", result);
        return undefined;
    }

    // Get NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setupNativeGestures: failed to unwrap instance");
        return undefined;
    }

    if (!instance->map) {
        Logger::warn("NativeMapView", "setupNativeGestures: map not ready yet, deferring gesture init");
        return undefined;
    }

    // Initialize gesture manager with a render-thread dispatcher
    // Gesture callbacks arrive on the UI thread, but mbgl::Map operations
    // must run on the render thread to avoid data races and bad_function_call.
    auto renderThreadDispatcher = [instance](std::function<void()> task) {
        if (instance->harmonyRenderer) {
            instance->harmonyRenderer->runOnRenderThread(std::move(task));
        }
    };
    instance->gestureManager_ = std::make_unique<gesture::NativeGestureManager>();
    if (!instance->gestureManager_->initialize(nodeHandle, instance->map, instance->getPixelRatioValue(), std::move(renderThreadDispatcher))) {
        Logger::error("NativeMapView", "setupNativeGestures: failed to initialize gesture manager");
        instance->gestureManager_.reset();
        return undefined;
    }

    // Wire tap gesture → JS callback via CallbackManager
    if (instance->callbackManager_) {
        instance->gestureManager_->setOnMapClickListener(
            [instance](double x, double y) {
                instance->callbackManager_->InvokeCallback(
                    "onMapClick",
                    [x, y](napi_env env) -> napi_value {
                        // Pass both coordinates as a single object {x, y}
                        // because ThreadSafeCallback only supports 1 argument
                        napi_value obj;
                        napi_create_object(env, &obj);
                        napi_value xVal, yVal;
                        napi_create_double(env, x, &xVal);
                        napi_create_double(env, y, &yVal);
                        napi_set_named_property(env, obj, "x", xVal);
                        napi_set_named_property(env, obj, "y", yVal);
                        return obj;
                    });
            });

        instance->gestureManager_->setOnMapLongClickListener(
            [instance](double x, double y) {
                instance->callbackManager_->InvokeCallback(
                    "onMapLongClick",
                    [x, y](napi_env env) -> napi_value {
                        napi_value obj;
                        napi_create_object(env, &obj);
                        napi_value xVal, yVal;
                        napi_create_double(env, x, &xVal);
                        napi_create_double(env, y, &yVal);
                        napi_set_named_property(env, obj, "x", xVal);
                        napi_set_named_property(env, obj, "y", yVal);
                        return obj;
                    });
            });
    } else {
        Logger::warn("NativeMapView", "setupNativeGestures: callbackManager_ not available, tap/long-click disabled");
    }

    Logger::info("NativeMapView", "setupNativeGestures: native gesture recognizers initialized successfully");
    return undefined;
}

// ========== Map click listener management ==========

napi_value NativeMapView::addOnMapClickListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);

    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "addOnMapClickListener: Failed to get callback argument");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addOnMapClickListener: Failed to unwrap instance");
        return undefined;
    }

    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "addOnMapClickListener: CallbackManager not initialized");
        return undefined;
    }

    // Register the callback under the "onMapClick" name
    if (instance->callbackManager_->RegisterCallback("onMapClick", args[0])) {
        Logger::info("NativeMapView", "addOnMapClickListener: registered");
    } else {
        Logger::error("NativeMapView", "addOnMapClickListener: Failed to register callback");
    }

    return undefined;
}

napi_value NativeMapView::removeOnMapClickListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);

    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "removeOnMapClickListener: Failed to get callback argument");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeOnMapClickListener: Failed to unwrap instance");
        return undefined;
    }

    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "removeOnMapClickListener: CallbackManager not initialized");
        return undefined;
    }

    instance->callbackManager_->UnregisterCallback("onMapClick", args[0]);
    return undefined;
}

napi_value NativeMapView::addOnMapLongClickListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);

    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "addOnMapLongClickListener: Failed to get callback argument");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addOnMapLongClickListener: Failed to unwrap instance");
        return undefined;
    }

    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "addOnMapLongClickListener: CallbackManager not initialized");
        return undefined;
    }

    if (instance->callbackManager_->RegisterCallback("onMapLongClick", args[0])) {
        Logger::info("NativeMapView", "addOnMapLongClickListener: registered");
    } else {
        Logger::error("NativeMapView", "addOnMapLongClickListener: Failed to register callback");
    }

    return undefined;
}

napi_value NativeMapView::removeOnMapLongClickListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);

    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "removeOnMapLongClickListener: Failed to get callback argument");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeOnMapLongClickListener: Failed to unwrap instance");
        return undefined;
    }

    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "removeOnMapLongClickListener: CallbackManager not initialized");
        return undefined;
    }

    instance->callbackManager_->UnregisterCallback("onMapLongClick", args[0]);
    return undefined;
}

// Other method implementations
mbgl::Map& NativeMapView::getMap() {
    // Return the actual map object; throw if map is null
    if (map) {
        return *map;
    } else {
        Logger::error("NativeMapView", "getMap: map object is null");
        throw std::runtime_error("Map object is null");
    }
}

// Shader compilation
void NativeMapView::onRegisterShaders(mbgl::gfx::ShaderRegistry&) {
    Logger::info("NativeMapView", "onRegisterShaders called");
}

void NativeMapView::onPreCompileShader(mbgl::shaders::BuiltIn shader, mbgl::gfx::Backend::Type backend, const std::string& source) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_) {
        int shaderId = static_cast<int>(shader);
        int backendType = static_cast<int>(backend);
        std::string defines = source; // Copy to avoid dangling references
        
        callbackManager_->InvokeCallback("onPreCompileShader", [shaderId, backendType, defines](napi_env env) {
            napi_value argv[3];
            napi_create_int32(env, shaderId, &argv[0]);
            napi_create_int32(env, backendType, &argv[1]);
            napi_create_string_utf8(env, defines.c_str(), defines.length(), &argv[2]);
            return argv[0];
        });
    }
}

void NativeMapView::onPostCompileShader(mbgl::shaders::BuiltIn shader, mbgl::gfx::Backend::Type backend, const std::string& source) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_) {
        int shaderId = static_cast<int>(shader);
        int backendType = static_cast<int>(backend);
        std::string defines = source; // Copy to avoid dangling references
        
        callbackManager_->InvokeCallback("onPostCompileShader", [shaderId, backendType, defines](napi_env env) {
            napi_value argv[3];
            napi_create_int32(env, shaderId, &argv[0]);
            napi_create_int32(env, backendType, &argv[1]);
            napi_create_string_utf8(env, defines.c_str(), defines.length(), &argv[2]);
            return argv[0];
        });
    }
}

void NativeMapView::onShaderCompileFailed(mbgl::shaders::BuiltIn shader, mbgl::gfx::Backend::Type backend, const std::string& source) {
    Logger::error("NativeMapView", "onShaderCompileFailed: shader=%d, backend=%d, source_length=%zu", 
                  static_cast<int>(shader), static_cast<int>(backend), source.length());
    
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_) {
        int shaderId = static_cast<int>(shader);
        int backendType = static_cast<int>(backend);
        std::string defines = source; // Copy to avoid dangling references
        
        callbackManager_->InvokeCallback("onShaderCompileFailed", [shaderId, backendType, defines](napi_env env) {
            napi_value argv[3];
            napi_create_int32(env, shaderId, &argv[0]);
            napi_create_int32(env, backendType, &argv[1]);
            napi_create_string_utf8(env, defines.c_str(), defines.length(), &argv[2]);
            return argv[0];
        });
    }
}

// Glyph requests
void NativeMapView::onGlyphsLoaded(const mbgl::FontStack& stack, const mbgl::GlyphRange& range) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_) {
        // Copy the data to avoid dangling references
        std::vector<std::string> fontStack(stack.begin(), stack.end());
        int rangeStart = range.first;
        int rangeEnd = range.second;
        
        callbackManager_->InvokeCallback("onGlyphsLoaded", [fontStack, rangeStart, rangeEnd](napi_env env) {
            napi_value argv[3];
            
            // Create the font array
            napi_create_array(env, &argv[0]);
            for (size_t i = 0; i < fontStack.size(); i++) {
                napi_value fontName;
                napi_create_string_utf8(env, fontStack[i].c_str(), NAPI_AUTO_LENGTH, &fontName);
                napi_set_element(env, argv[0], i, fontName);
            }
            
            napi_create_int32(env, rangeStart, &argv[1]);
            napi_create_int32(env, rangeEnd, &argv[2]);
            return argv[0];
        });
    }
}

void NativeMapView::onGlyphsError(const mbgl::FontStack& stack, const mbgl::GlyphRange& range, std::exception_ptr) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_) {
        // Copy the data to avoid dangling references
        std::vector<std::string> fontStack(stack.begin(), stack.end());
        int rangeStart = range.first;
        int rangeEnd = range.second;
        
        callbackManager_->InvokeCallback("onGlyphsError", [fontStack, rangeStart, rangeEnd](napi_env env) {
            napi_value argv[3];
            
            // Create the font array
            napi_create_array(env, &argv[0]);
            for (size_t i = 0; i < fontStack.size(); i++) {
                napi_value fontName;
                napi_create_string_utf8(env, fontStack[i].c_str(), NAPI_AUTO_LENGTH, &fontName);
                napi_set_element(env, argv[0], i, fontName);
            }
            
            napi_create_int32(env, rangeStart, &argv[1]);
            napi_create_int32(env, rangeEnd, &argv[2]);
            return argv[0];
        });
    }
}

void NativeMapView::onGlyphsRequested(const mbgl::FontStack& stack, const mbgl::GlyphRange& range) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_) {
        // Copy the data to avoid dangling references
        std::vector<std::string> fontStack(stack.begin(), stack.end());
        int rangeStart = range.first;
        int rangeEnd = range.second;
        
        callbackManager_->InvokeCallback("onGlyphsRequested", [fontStack, rangeStart, rangeEnd](napi_env env) {
            napi_value argv[3];
            
            // Create the font array
            napi_create_array(env, &argv[0]);
            for (size_t i = 0; i < fontStack.size(); i++) {
                napi_value fontName;
                napi_create_string_utf8(env, fontStack[i].c_str(), NAPI_AUTO_LENGTH, &fontName);
                napi_set_element(env, argv[0], i, fontName);
            }
            
            napi_create_int32(env, rangeStart, &argv[1]);
            napi_create_int32(env, rangeEnd, &argv[2]);
            return argv[0];
        });
    }
}

// Tile requests
void NativeMapView::onTileAction(mbgl::TileOperation op, const mbgl::OverscaledTileID& tileID, const std::string& sourceID) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_) {
        int operation = static_cast<int>(op);
        int x = tileID.canonical.x;
        int y = tileID.canonical.y;
        int z = tileID.canonical.z;
        int wrap = tileID.wrap;
        int overscaledZ = tileID.overscaledZ;
        std::string source = sourceID; // Copy to avoid dangling references
        
        callbackManager_->InvokeCallback("onTileAction", [operation, x, y, z, wrap, overscaledZ, source](napi_env env) {
            napi_value argv[7];
            napi_create_int32(env, operation, &argv[0]);
            napi_create_int32(env, x, &argv[1]);
            napi_create_int32(env, y, &argv[2]);
            napi_create_int32(env, z, &argv[3]);
            napi_create_int32(env, wrap, &argv[4]);
            napi_create_int32(env, overscaledZ, &argv[5]);
            napi_create_string_utf8(env, source.c_str(), NAPI_AUTO_LENGTH, &argv[6]);
            return argv[0];
        });
    }
}

// Sprite requests
void NativeMapView::onSpriteLoaded(const std::optional<mbgl::style::Sprite>& sprite) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_ && sprite) {
        std::string spriteId = sprite->id;
        std::string url = sprite->spriteURL;
        
        callbackManager_->InvokeCallback("onSpriteLoaded", [spriteId, url](napi_env env) {
            napi_value argv[2];
            napi_create_string_utf8(env, spriteId.c_str(), NAPI_AUTO_LENGTH, &argv[0]);
            napi_create_string_utf8(env, url.c_str(), NAPI_AUTO_LENGTH, &argv[1]);
            return argv[0];
        });
    }
}

void NativeMapView::onSpriteError(const std::optional<mbgl::style::Sprite>& sprite, std::exception_ptr) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_ && sprite) {
        std::string spriteId = sprite->id;
        std::string url = sprite->spriteURL;
        
        callbackManager_->InvokeCallback("onSpriteError", [spriteId, url](napi_env env) {
            napi_value argv[2];
            napi_create_string_utf8(env, spriteId.c_str(), NAPI_AUTO_LENGTH, &argv[0]);
            napi_create_string_utf8(env, url.c_str(), NAPI_AUTO_LENGTH, &argv[1]);
            return argv[0];
        });
    }
}

void NativeMapView::onSpriteRequested(const std::optional<mbgl::style::Sprite>& sprite) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (callbackManager_ && sprite) {
        std::string spriteId = sprite->id;
        std::string url = sprite->spriteURL;
        
        callbackManager_->InvokeCallback("onSpriteRequested", [spriteId, url](napi_env env) {
            napi_value argv[2];
            napi_create_string_utf8(env, spriteId.c_str(), NAPI_AUTO_LENGTH, &argv[0]);
            napi_create_string_utf8(env, url.c_str(), NAPI_AUTO_LENGTH, &argv[1]);
            return argv[0];
        });
    }
}

// ========== Camera listener implementations ==========

napi_value NativeMapView::addOnCameraIdleListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "addOnCameraIdleListener: Failed to get callback argument");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addOnCameraIdleListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "addOnCameraIdleListener: CallbackManager not initialized");
        return undefined;
    }
    
    // Add the listener
    if (instance->callbackManager_->RegisterCallback("onCameraIdle", args[0])) {
    } else {
        Logger::error("NativeMapView", "addOnCameraIdleListener: Failed to register callback");
    }
    
    return undefined;
}

napi_value NativeMapView::removeOnCameraIdleListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "removeOnCameraIdleListener: Failed to get callback argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeOnCameraIdleListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "removeOnCameraIdleListener: CallbackManager not initialized");
        return undefined;
    }
    
    if (instance->callbackManager_->UnregisterCallback("onCameraIdle", args[0])) {
    } else {
        Logger::warn("NativeMapView", "removeOnCameraIdleListener: Listener not found");
    }
    
    return undefined;
}

napi_value NativeMapView::addOnCameraMoveStartedListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "addOnCameraMoveStartedListener: Failed to get callback argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addOnCameraMoveStartedListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "addOnCameraMoveStartedListener: CallbackManager not initialized");
        return undefined;
    }
    
    if (instance->callbackManager_->RegisterCallback("onCameraMoveStarted", args[0])) {
    } else {
        Logger::error("NativeMapView", "addOnCameraMoveStartedListener: Failed to register callback");
    }
    
    return undefined;
}

napi_value NativeMapView::removeOnCameraMoveStartedListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "removeOnCameraMoveStartedListener: Failed to get callback argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeOnCameraMoveStartedListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "removeOnCameraMoveStartedListener: CallbackManager not initialized");
        return undefined;
    }
    
    if (instance->callbackManager_->UnregisterCallback("onCameraMoveStarted", args[0])) {
    } else {
        Logger::warn("NativeMapView", "removeOnCameraMoveStartedListener: Listener not found");
    }
    
    return undefined;
}

napi_value NativeMapView::addOnCameraMoveListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "addOnCameraMoveListener: Failed to get callback argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addOnCameraMoveListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "addOnCameraMoveListener: CallbackManager not initialized");
        return undefined;
    }
    
    if (instance->callbackManager_->RegisterCallback("onCameraMove", args[0])) {
    } else {
        Logger::error("NativeMapView", "addOnCameraMoveListener: Failed to register callback");
    }
    
    return undefined;
}

napi_value NativeMapView::removeOnCameraMoveListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "removeOnCameraMoveListener: Failed to get callback argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeOnCameraMoveListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "removeOnCameraMoveListener: CallbackManager not initialized");
        return undefined;
    }
    
    if (instance->callbackManager_->UnregisterCallback("onCameraMove", args[0])) {
    } else {
        Logger::warn("NativeMapView", "removeOnCameraMoveListener: Listener not found");
    }
    
    return undefined;
}

napi_value NativeMapView::addOnCameraMoveCanceledListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "addOnCameraMoveCanceledListener: Failed to get callback argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addOnCameraMoveCanceledListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "addOnCameraMoveCanceledListener: CallbackManager not initialized");
        return undefined;
    }
    
    if (instance->callbackManager_->RegisterCallback("onCameraMoveCanceled", args[0])) {
    } else {
        Logger::error("NativeMapView", "addOnCameraMoveCanceledListener: Failed to register callback");
    }
    
    return undefined;
}

napi_value NativeMapView::removeOnCameraMoveCanceledListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "removeOnCameraMoveCanceledListener: Failed to get callback argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeOnCameraMoveCanceledListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "removeOnCameraMoveCanceledListener: CallbackManager not initialized");
        return undefined;
    }
    
    if (instance->callbackManager_->UnregisterCallback("onCameraMoveCanceled", args[0])) {
    } else {
        Logger::warn("NativeMapView", "removeOnCameraMoveCanceledListener: Listener not found");
    }
    
    return undefined;
}

// ========== Map lifecycle listener implementations ==========

/**
 * setOnMapViewCreatedCallback - Register the callback invoked when the map is created
 *
 * Purpose: notify the ArkTS layer right after the C++ map object finishes initialization
 * Timing: before the style loads so observers can be attached in advance
 * Alignment: mirrors the Android onMapViewReady callback
 *
 * @param env N-API environment
 * @param info Callback info; argument must be a JavaScript function
 * @return undefined
 */
napi_value NativeMapView::setOnMapViewCreatedCallback(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setOnMapViewCreatedCallback: Failed to get callback argument");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setOnMapViewCreatedCallback: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "setOnMapViewCreatedCallback: CallbackManager not initialized");
        return undefined;
    }
    
    // Check for null to remove the listener
    napi_valuetype valueType;
    napi_typeof(env, args[0], &valueType);
    
    if (valueType == napi_null || valueType == napi_undefined) {
        instance->callbackManager_->UnregisterCallback("onMapViewCreated");
        Logger::info("NativeMapView", "setOnMapViewCreatedCallback: Unregistered callback");
        return undefined;
    }
    
    if (valueType != napi_function) {
        Logger::error("NativeMapView", "setOnMapViewCreatedCallback: Argument is not a function");
        return undefined;
    }
    
    // Remove the previous listener before registering a new one (singleton pattern)
    instance->callbackManager_->UnregisterCallback("onMapViewCreated");
    
    // Register the callback
    if (instance->callbackManager_->RegisterCallback("onMapViewCreated", args[0])) {
        Logger::info("NativeMapView", "✅ Registered onMapViewCreated callback");
    } else {
        Logger::error("NativeMapView", "setOnMapViewCreatedCallback: Failed to register callback");
    }
    
    return undefined;
}

// ========== Style listener implementations ==========

napi_value NativeMapView::setOnStyleLoadedListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: Failed to get callback argument");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: CallbackManager not initialized");
        return undefined;
    }
    
    // Check for null to remove the listener
    napi_valuetype valueType;
    napi_typeof(env, args[0], &valueType);
    
    if (valueType == napi_null || valueType == napi_undefined) {
        instance->callbackManager_->UnregisterCallback("onStyleLoaded");
        return undefined;
    }
    
    if (valueType != napi_function) {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: Argument is not a function");
        return undefined;
    }
    
    // Remove the previous listener before registering a new one (style listener is singleton)
    instance->callbackManager_->UnregisterCallback("onStyleLoaded");
    
    // Register the callback
    if (instance->callbackManager_->RegisterCallback("onStyleLoaded", args[0])) {
        // 如果样式已经加载完成，则立即通知监听器，保持与 Android API 一致的行为
        if (instance->styleLoadedOnce.load(std::memory_order_acquire)) {
            if (!instance->callbackManager_->InvokeCallbackEmpty("onStyleLoaded")) {
                Logger::warn("NativeMapView", "setOnStyleLoadedListener: Immediate invoke failed");
            }
        }
    } else {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: Failed to register callback");
    }
    
    return undefined;
}

napi_value NativeMapView::setOnStyleLoadErrorListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: Failed to get callback argument");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: CallbackManager not initialized");
        return undefined;
    }
    
    // Check for null to remove the listener
    napi_valuetype valueType;
    napi_typeof(env, args[0], &valueType);
    
    if (valueType == napi_null || valueType == napi_undefined) {
        instance->callbackManager_->UnregisterCallback("onStyleLoadError");
        return undefined;
    }
    
    if (valueType != napi_function) {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: Argument is not a function");
        return undefined;
    }
    
    // Remove the previous listener before registering a new one (style listener is singleton)
    instance->callbackManager_->UnregisterCallback("onStyleLoadError");
    
    // Register the callback
    if (instance->callbackManager_->RegisterCallback("onStyleLoadError", args[0])) {
    } else {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: Failed to register callback");
    }
    
    return undefined;
}

void NativeMapView::notifyStyleLoaded() {
    if (isDestroying.load(std::memory_order_acquire)) {
        Logger::warn("NativeMapView", "⚠️ notifyStyleLoaded: Instance is destroying, skipping callback");
        return;
    }
    
    // 标记当前样式已加载完成，供后续注册的监听器立即回放
    styleLoadedOnce.store(true, std::memory_order_release);
    
    if (!callbackManager_) {
        Logger::warn("NativeMapView", "⚠️ notifyStyleLoaded: CallbackManager not initialized");
        return;
    }
    
    if (!callbackManager_->HasCallback("onStyleLoaded")) {
        Logger::warn("NativeMapView", "⚠️ notifyStyleLoaded: No listener registered");
        return;
    }
    
    if (callbackManager_->InvokeCallbackEmpty("onStyleLoaded")) {
    } else {
        Logger::error("NativeMapView", "❌ notifyStyleLoaded: Failed to invoke callback");
    }
}

void NativeMapView::notifyStyleLoadError(const std::string& error) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (!callbackManager_) {
        Logger::warn("NativeMapView", "notifyStyleLoadError: CallbackManager not initialized");
        return;
    }
    
    if (!callbackManager_->HasCallback("onStyleLoadError")) {
        return;
    }
    
    if (callbackManager_->InvokeCallbackWithString("onStyleLoadError", error)) {
    } else {
        Logger::error("NativeMapView", "notifyStyleLoadError: Failed to invoke callback");
    }
}

// ========== Android/iOS style listener NAPI implementations ==========

// Helper macro: simplify listener registration code
#define IMPLEMENT_ADD_LISTENER(MethodName, CallbackName) \
napi_value NativeMapView::MethodName(napi_env env, napi_callback_info info) { \
    napi_value undefined; \
    napi_get_undefined(env, &undefined); \
    napi_value thisObj; \
    size_t argc = 1; \
    napi_value args[1]; \
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) { \
        Logger::error("NativeMapView", #MethodName ": Failed to get callback argument"); \
        return undefined; \
    } \
    NativeMapView* instance = nullptr; \
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) { \
        Logger::error("NativeMapView", #MethodName ": Failed to unwrap instance"); \
        return undefined; \
    } \
    if (!instance->callbackManager_) { \
        Logger::error("NativeMapView", #MethodName ": CallbackManager not initialized"); \
        return undefined; \
    } \
    if (instance->callbackManager_->RegisterCallback(CallbackName, args[0])) { \
    } else { \
        Logger::error("NativeMapView", #MethodName ": Failed to register callback"); \
    } \
    return undefined; \
}

#define IMPLEMENT_REMOVE_LISTENER(MethodName, CallbackName) \
napi_value NativeMapView::MethodName(napi_env env, napi_callback_info info) { \
    napi_value undefined; \
    napi_get_undefined(env, &undefined); \
    napi_value thisObj; \
    size_t argc = 1; \
    napi_value args[1]; \
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) { \
        Logger::error("NativeMapView", #MethodName ": Failed to get callback argument"); \
        return undefined; \
    } \
    NativeMapView* instance = nullptr; \
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) { \
        Logger::error("NativeMapView", #MethodName ": Failed to unwrap instance"); \
        return undefined; \
    } \
    if (!instance->callbackManager_) { \
        Logger::error("NativeMapView", #MethodName ": CallbackManager not initialized"); \
        return undefined; \
    } \
    if (instance->callbackManager_->UnregisterCallback(CallbackName, args[0])) { \
    } else { \
        Logger::warn("NativeMapView", #MethodName ": Listener not found"); \
    } \
    return undefined; \
}

// ===== Camera event listeners =====
IMPLEMENT_ADD_LISTENER(addOnCameraWillChangeListener, "onCameraWillChange")
IMPLEMENT_REMOVE_LISTENER(removeOnCameraWillChangeListener, "onCameraWillChange")
IMPLEMENT_ADD_LISTENER(addOnCameraIsChangingListener, "onCameraIsChanging")
IMPLEMENT_REMOVE_LISTENER(removeOnCameraIsChangingListener, "onCameraIsChanging")
IMPLEMENT_ADD_LISTENER(addOnCameraDidChangeListener, "onCameraDidChange")
IMPLEMENT_REMOVE_LISTENER(removeOnCameraDidChangeListener, "onCameraDidChange")

// ===== Map load event listeners =====
IMPLEMENT_ADD_LISTENER(addOnWillStartLoadingMapListener, "onWillStartLoadingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnWillStartLoadingMapListener, "onWillStartLoadingMap")
IMPLEMENT_ADD_LISTENER(addOnDidFinishLoadingMapListener, "onDidFinishLoadingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishLoadingMapListener, "onDidFinishLoadingMap")
IMPLEMENT_ADD_LISTENER(addOnDidFailLoadingMapListener, "onDidFailLoadingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFailLoadingMapListener, "onDidFailLoadingMap")

// ===== Render event listeners =====
IMPLEMENT_ADD_LISTENER(addOnWillStartRenderingFrameListener, "onWillStartRenderingFrame")
IMPLEMENT_REMOVE_LISTENER(removeOnWillStartRenderingFrameListener, "onWillStartRenderingFrame")
IMPLEMENT_ADD_LISTENER(addOnDidFinishRenderingFrameListener, "onDidFinishRenderingFrame")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishRenderingFrameListener, "onDidFinishRenderingFrame")
IMPLEMENT_ADD_LISTENER(addOnWillStartRenderingMapListener, "onWillStartRenderingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnWillStartRenderingMapListener, "onWillStartRenderingMap")
IMPLEMENT_ADD_LISTENER(addOnDidFinishRenderingMapListener, "onDidFinishRenderingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishRenderingMapListener, "onDidFinishRenderingMap")

// ===== Style event listeners =====
IMPLEMENT_ADD_LISTENER(addOnDidFinishLoadingStyleListener, "onDidFinishLoadingStyle")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishLoadingStyleListener, "onDidFinishLoadingStyle")
IMPLEMENT_ADD_LISTENER(addOnStyleImageMissingListener, "onStyleImageMissing")
IMPLEMENT_REMOVE_LISTENER(removeOnStyleImageMissingListener, "onStyleImageMissing")

// ===== Other event listeners =====
IMPLEMENT_ADD_LISTENER(addOnDidBecomeIdleListener, "onDidBecomeIdle")
IMPLEMENT_REMOVE_LISTENER(removeOnDidBecomeIdleListener, "onDidBecomeIdle")
IMPLEMENT_ADD_LISTENER(addOnSourceChangedListener, "onSourceChanged")
IMPLEMENT_REMOVE_LISTENER(removeOnSourceChangedListener, "onSourceChanged")
IMPLEMENT_ADD_LISTENER(addOnSnapshotReadyListener, "onSnapshotReady")
IMPLEMENT_REMOVE_LISTENER(removeOnSnapshotReadyListener, "onSnapshotReady")
IMPLEMENT_ADD_LISTENER(addOnSnapshotErrorListener, "onSnapshotError")
IMPLEMENT_REMOVE_LISTENER(removeOnSnapshotErrorListener, "onSnapshotError")

// ===== Observer event listeners (Shader, Glyph, Sprite, Tile) =====
IMPLEMENT_ADD_LISTENER(addOnPreCompileShaderListener, "onPreCompileShader")
IMPLEMENT_REMOVE_LISTENER(removeOnPreCompileShaderListener, "onPreCompileShader")
IMPLEMENT_ADD_LISTENER(addOnPostCompileShaderListener, "onPostCompileShader")
IMPLEMENT_REMOVE_LISTENER(removeOnPostCompileShaderListener, "onPostCompileShader")
IMPLEMENT_ADD_LISTENER(addOnShaderCompileFailedListener, "onShaderCompileFailed")
IMPLEMENT_REMOVE_LISTENER(removeOnShaderCompileFailedListener, "onShaderCompileFailed")

IMPLEMENT_ADD_LISTENER(addOnGlyphsLoadedListener, "onGlyphsLoaded")
IMPLEMENT_REMOVE_LISTENER(removeOnGlyphsLoadedListener, "onGlyphsLoaded")
IMPLEMENT_ADD_LISTENER(addOnGlyphsErrorListener, "onGlyphsError")
IMPLEMENT_REMOVE_LISTENER(removeOnGlyphsErrorListener, "onGlyphsError")
IMPLEMENT_ADD_LISTENER(addOnGlyphsRequestedListener, "onGlyphsRequested")
IMPLEMENT_REMOVE_LISTENER(removeOnGlyphsRequestedListener, "onGlyphsRequested")

IMPLEMENT_ADD_LISTENER(addOnSpriteLoadedListener, "onSpriteLoaded")
IMPLEMENT_REMOVE_LISTENER(removeOnSpriteLoadedListener, "onSpriteLoaded")
IMPLEMENT_ADD_LISTENER(addOnSpriteErrorListener, "onSpriteError")
IMPLEMENT_REMOVE_LISTENER(removeOnSpriteErrorListener, "onSpriteError")
IMPLEMENT_ADD_LISTENER(addOnSpriteRequestedListener, "onSpriteRequested")
IMPLEMENT_REMOVE_LISTENER(removeOnSpriteRequestedListener, "onSpriteRequested")

IMPLEMENT_ADD_LISTENER(addOnTileActionListener, "onTileAction")
IMPLEMENT_REMOVE_LISTENER(removeOnTileActionListener, "onTileAction")

#undef IMPLEMENT_ADD_LISTENER
#undef IMPLEMENT_REMOVE_LISTENER

} // namespace harmony
} // namespace mbgl
