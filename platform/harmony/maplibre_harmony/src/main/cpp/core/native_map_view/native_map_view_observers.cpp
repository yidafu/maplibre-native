#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "bitmap/bitmap_napi.hpp"
#include "rendering/harmony_renderer.hpp"
#include <mbgl/gfx/shader_registry.hpp>
#include <mbgl/style/style.hpp>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

// ✅ 架构修复：线程安全辅助方法实现
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
    
    // ✅ 架构修复：确保回调在渲染线程上执行
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
            }
        });
        return;
    }
    
    // 通知监听器
    if (callbackManager_) {
        bool animated = (mode == MapObserver::CameraChangeMode::Animated);
        callbackManager_->InvokeCallback("onCameraWillChange", [animated](napi_env env) {
            napi_value argv[1];
            napi_get_boolean(env, animated, &argv[0]);
            return argv[0];
        });
    }
}

void NativeMapView::onCameraIsChanging() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // ✅ 架构修复：确保回调在渲染线程上执行
    if (!isOnRenderThread()) {
        runOnRenderThread([this]() {
            if (isDestroying.load(std::memory_order_acquire)) return;
            if (callbackManager_) {
                callbackManager_->InvokeCallbackEmpty("onCameraIsChanging");
            }
        });
        return;
    }
    
    // 通知监听器
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onCameraIsChanging");
    }
}

void NativeMapView::onCameraDidChange(MapObserver::CameraChangeMode mode) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // ✅ 架构修复：确保回调在渲染线程上执行
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
            }
        });
        return;
    }
    
    // 通知监听器
    if (callbackManager_) {
        bool animated = (mode == MapObserver::CameraChangeMode::Animated);
        callbackManager_->InvokeCallback("onCameraDidChange", [animated](napi_env env) {
            napi_value argv[1];
            napi_get_boolean(env, animated, &argv[0]);
            return argv[0];
        });
    }
    
    // MapLibre 内部已经处理渲染时机（通过 triggerRepaint）
    // 不需要在这里额外请求渲染，否则会造成过度渲染
}
void NativeMapView::onWillStartLoadingMap() {
    Logger::info("NativeMapView", "========== onWillStartLoadingMap ==========");
    Logger::info("NativeMapView", "Map loading started");
    Logger::info("NativeMapView", "This is triggered when:");
    Logger::info("NativeMapView", "  - Style URL/JSON is set");
    Logger::info("NativeMapView", "  - Map starts loading resources");
    Logger::info("NativeMapView", "===========================================");
    
    // 通知监听器
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
    
    // 通知监听器
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onDidFinishLoadingMap");
    }
    
    // MapLibre内部已自动处理渲染，不需要额外请求
    // 移除此处的 requestRender() 避免重复渲染
}
void NativeMapView::onDidFailLoadingMap(MapLoadError error, const std::string& errorMsg) {
    Logger::error("NativeMapView", "========== onDidFailLoadingMap ==========");
    
    // 根据错误类型输出不同的信息
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
    
    // 通知监听器
    std::string fullError = std::string(errorType) + ": " + errorMsg;
    if (callbackManager_) {
        callbackManager_->InvokeCallbackWithString("onDidFailLoadingMap", fullError);
    }
    
    // 通知样式加载错误（保留旧的监听器）
    notifyStyleLoadError(fullError);
}
void NativeMapView::onWillStartRenderingFrame() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // 通知监听器
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onWillStartRenderingFrame");
    }
}

void NativeMapView::onDidFinishRenderingFrame(const MapObserver::RenderFrameStatus& status) {
    if (isDestroying.load(std::memory_order_acquire)) {
        return;
    }
    
    // ⚠️ 重要：onDidFinishRenderingFrame 本身就在渲染线程被 Renderer 调用
    // 不应该被分发！分发会导致白屏（渲染无法完成）
    
    // 通知监听器（带渲染统计信息）
    if (callbackManager_) {
        bool fully = (status.mode == MapObserver::RenderMode::Full);
        // 使用 renderingStats 中的实际数据
        // 从 renderingStats 获取实际的编码和渲染时间
        const auto& stats = status.renderingStats;
        // encodingTime 和 renderingTime 已经是秒为单位，转换为毫秒
        double encodingTime = stats.encodingTime * 1000.0;
        double renderingTime = stats.renderingTime * 1000.0;
        
        if (encodingTime > 0.0 || renderingTime > 0.0) {
        }
        
        callbackManager_->InvokeCallback("onDidFinishRenderingFrame", [fully, encodingTime, renderingTime](napi_env env) {
            napi_value argv[3];
            napi_get_boolean(env, fully, &argv[0]);
            napi_create_double(env, encodingTime, &argv[1]);
            napi_create_double(env, renderingTime, &argv[2]);
            return argv[0]; // DataBuilder 需要返回值，这里返回第一个参数
        });
    }
    
    // Network I/O is now handled by the renderer thread's RunLoop
}
void NativeMapView::onWillStartRenderingMap() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    // 通知监听器
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onWillStartRenderingMap");
    }
}

void NativeMapView::onDidFinishRenderingMap(MapObserver::RenderMode mode) {
    // 立即检查对象是否正在析构
    if (isDestroying.load(std::memory_order_acquire)) {
        return;
    }
    
    try {
        // ⚠️ 重要：onDidFinishRenderingMap 本身就在渲染线程被 Renderer 调用
        // 不应该被分发！分发会导致渲染流程中断
        
        // 通知监听器
        if (callbackManager_) {
            bool fully = (mode == MapObserver::RenderMode::Full);
            callbackManager_->InvokeCallback("onDidFinishRenderingMap", [fully](napi_env env) {
                napi_value argv[1];
                napi_get_boolean(env, fully, &argv[0]);
                return argv[0];
            });
        }
        
        // 渲染已完成，不需要再次请求渲染
        // onCameraDidChange 已经处理了渲染请求
    } catch (...) {
        // 忽略所有异常，避免崩溃
    }
}

void NativeMapView::onDidBecomeIdle() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    // 通知监听器
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onDidBecomeIdle");
    }
}
void NativeMapView::onDidFinishLoadingStyle() {
    // 🔍 日志：最早期的日志，确认回调被调用
    Logger::error("NativeMapView", "🎨🎨🎨 onDidFinishLoadingStyle() ENTRY - START 🎨🎨🎨");
    
    if (isDestroying.load(std::memory_order_acquire)) {
        Logger::warn("NativeMapView", "⚠️ onDidFinishLoadingStyle: Instance is destroying, skipping callback");
        return;
    }
    
    // ✅ 架构修复：确保回调在渲染线程上执行
    if (!isOnRenderThread()) {
        Logger::warn("NativeMapView", "⚠️ onDidFinishLoadingStyle called from wrong thread! Dispatching to render thread.");
        
        // 切换到渲染线程执行
        runOnRenderThread([this]() {
            if (isDestroying.load(std::memory_order_acquire)) return;
            
            Logger::info("NativeMapView", "🎨 onDidFinishLoadingStyle [渲染线程]");
            
            // 通知 Android 风格的监听器
            if (callbackManager_) {
                callbackManager_->InvokeCallbackEmpty("onDidFinishLoadingStyle");
            }
            
            // 通知样式加载完成（旧的监听器）
            notifyStyleLoaded();
        });
        return;
    }
    
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    // 实例标识
    static int instanceCounter = 0;
    static std::map<void*, int> instanceIds;
    if (instanceIds.find(this) == instanceIds.end()) {
        instanceIds[this] = ++instanceCounter;
    }
    int instanceId = instanceIds[this];
    
    Logger::error("NativeMapView", "🎨 [Instance #%d] [%lld ms] onDidFinishLoadingStyle", instanceId, elapsed);
    Logger::error("NativeMapView", "🎨 [Instance #%d] this=%p, map=%p", instanceId, this, map);
    
    // 通知 Android 风格的监听器
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onDidFinishLoadingStyle");
    }
    
    // 通知样式加载完成（旧的监听器）
    Logger::error("NativeMapView", "🎨 [Instance #%d] Calling notifyStyleLoaded()...", instanceId);
    notifyStyleLoaded();
    Logger::error("NativeMapView", "🎨 [Instance #%d] notifyStyleLoaded() completed", instanceId);
    
    if (map) {
        try {
            // 获取样式URL和名称
            std::string styleUrl = invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getStyle().getURL(); }, std::string{});
            std::string styleName = invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getStyle().getName(); }, std::string{});
            
            Logger::info("NativeMapView", "Style loaded successfully:");
            Logger::info("NativeMapView", "  - URL: %s", styleUrl.empty() ? "(inline JSON)" : styleUrl.c_str());
            Logger::info("NativeMapView", "  - Name: %s", styleName.empty() ? "(unnamed)" : styleName.c_str());
            
            // 获取Sources列表
            auto sources = invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getStyle().getSources(); }, std::vector<mbgl::style::Source*>{});
            Logger::info("NativeMapView", "  - Sources count: %zu", sources.size());
            for (const auto* source : sources) {
                if (source) {
                }
            }
            
            // 获取Layers列表
            auto layers = invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getStyle().getLayers(); }, std::vector<mbgl::style::Layer*>{});
            Logger::info("NativeMapView", "  - Layers count: %zu", layers.size());
            for (const auto* layer : layers) {
                if (layer) {
                }
            }
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "Error inspecting loaded style: %s", e.what());
        }
    } else {
        Logger::warn("NativeMapView", "Map object is null");
    }
    
    Logger::info("NativeMapView", "=============================================");
    
    // MapLibre内部已自动处理渲染，不需要额外请求
    // 移除此处的 requestRender() 避免重复渲染
}
void NativeMapView::onSourceChanged(mbgl::style::Source& source) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    // ✅ 架构修复：确保回调在渲染线程上执行
    if (!isOnRenderThread()) {
        Logger::warn("NativeMapView", "⚠️ onSourceChanged called from wrong thread! Dispatching to render thread.");
        
        // 复制 source ID 避免引用失效
        std::string sourceId = source.getID();
        auto sourceType = source.getType();
        
        // 切换到渲染线程执行
        runOnRenderThread([this, sourceId, sourceType]() {
            // 在渲染线程上安全执行
            int count = ++sourceChangedCount;
            auto now = std::chrono::steady_clock::now();
            static auto startTime = now;
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
            
            Logger::info("NativeMapView", "🔄 [%lld ms] onSourceChanged #%d: %s (type=%d) [渲染线程]", 
                         elapsed, count, sourceId.c_str(), static_cast<int>(sourceType));
            
            // 通知监听器
            if (callbackManager_) {
                callbackManager_->InvokeCallbackWithString("onSourceChanged", sourceId);
            }
        });
        return;
    }
    
    // 已经在渲染线程，直接执行
    int count = ++sourceChangedCount;
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    Logger::warn("NativeMapView", "🔄 [%lld ms] onSourceChanged #%d: %s (type=%d)", 
                 elapsed, count, source.getID().c_str(), static_cast<int>(source.getType()));
    
    // 通知监听器
    if (callbackManager_) {
        std::string sourceId = source.getID();
        callbackManager_->InvokeCallbackWithString("onSourceChanged", sourceId);
    }
    
    // MapLibre内部已自动处理渲染，不需要额外请求
    // 移除此处的 requestRender() 避免重复渲染导致无限循环
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
    
    // 通知监听器
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
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getImage: Map not initialized");
        return args.Undefined();
    }
    
    // 获取图像ID
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
    
    // 获取NativeMapView实例和参数
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
        // 参考 Android: 如果启用则设置默认 zoom delta，否则设为 0
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
    
    // 获取NativeMapView实例
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
    
    // 获取NativeMapView实例和参数
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
    
    // 获取NativeMapView实例
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
    // Tile 缓存控制需要渲染器前端支持
    // Tile cache control requires renderer frontend support
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTileCacheEnabled(napi_env env, napi_callback_info info) {
    // Tile 缓存控制需要渲染器前端支持
    // Tile cache control requires renderer frontend support
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::setTileLodMinRadius(napi_env env, napi_callback_info info) {
    // Tile LOD 参数控制已实现
    // Tile LOD parameter control is implemented
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取NativeMapView实例和参数
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
    
    // 获取NativeMapView实例
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
    
    // 获取NativeMapView实例和参数
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
    
    // 获取NativeMapView实例
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
    
    // 获取NativeMapView实例和参数
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
    
    // 获取NativeMapView实例
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
    
    // 获取NativeMapView实例和参数
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
    
    // 获取NativeMapView实例
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
    
    // 请求渲染
    if (instance->harmonyRenderer) {
        instance->harmonyRenderer->requestRender();
    }
    
    return undefined;
}

// 设置NativeWindow的NAPI方法
napi_value NativeMapView::setNativeWindow(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取参数
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
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get this object");
        return undefined;
    }

    int64_t surfaceId = mbgl::harmony::napi::ParseSurfaceId(env, info);
    Logger::info("NativeMapView", "Surface ID: %ld", (long)surfaceId);

    // 获取NativeMapView实例
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
    
    // 保存窗口指针
    nativeMapView->nativeWindow = nativeWindow;
    // pixelRatio will be determined during renderer initialization from device
    Logger::info("NativeMapView", "pixelRatio will be determined from device DPI");
    
    // 初始化渲染器（如果尚未初始化）
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
    // Rendering stats view 未在 Harmony 平台实现
    // Rendering stats view not implemented for Harmony
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::enableRenderingStatsView(napi_env env, napi_callback_info info) {
    // Rendering stats view 未在 Harmony 平台实现
    // Rendering stats view not implemented for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// 设置NativeWindow的NAPI方法（带尺寸参数）
napi_value NativeMapView::setNativeWindowWithSize(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取参数
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
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "Failed to get this object");
        return undefined;
    }

    // 解析参数
    int64_t surfaceId = mbgl::harmony::napi::ParseSurfaceId(env, info);
    int32_t width, height;
    
    if (napi_get_value_int32(env, args[1], &width) != napi_ok ||
        napi_get_value_int32(env, args[2], &height) != napi_ok) {
        Logger::error("NativeMapView", "Failed to parse width/height arguments");
        return undefined;
    }
    
    Logger::info("NativeMapView", "Surface ID: %ld, Width: %d, Height: %d", (long)surfaceId, width, height);

    // 获取NativeMapView实例
    NativeMapView* nativeMapView;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&nativeMapView)) != napi_ok) {
        Logger::error("NativeMapView", "Failed to unwrap NativeMapView");
        return undefined;
    }
    
    // 调用新的方法
    nativeMapView->setNativeWindowWithSize(surfaceId, width, height);
    
    Logger::info("NativeMapView", "========== setNativeWindowWithSize() END - SUCCESS ==========");
    
    return undefined;
}

// 其他方法实现
mbgl::Map& NativeMapView::getMap() {
    // 返回实际的地图对象，如果map为null则抛出异常
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
    Logger::info("NativeMapView", "onPreCompileShader: shader=%d, backend=%d, source_length=%zu", 
                 static_cast<int>(shader), static_cast<int>(backend), source.length());
}

void NativeMapView::onPostCompileShader(mbgl::shaders::BuiltIn shader, mbgl::gfx::Backend::Type backend, const std::string& source) {
    Logger::info("NativeMapView", "onPostCompileShader: shader=%d, backend=%d, source_length=%zu", 
                 static_cast<int>(shader), static_cast<int>(backend), source.length());
    
    // 详细记录shader编译信息
    if (source.find("a_pos") != std::string::npos) {
        Logger::info("NativeMapView", "Shader contains 'a_pos' attribute");
    }
    if (source.find("a_tex") != std::string::npos) {
        Logger::info("NativeMapView", "Shader contains 'a_tex' attribute");
    }
    if (source.find("a_normal") != std::string::npos) {
        Logger::info("NativeMapView", "Shader contains 'a_normal' attribute");
    }
}

void NativeMapView::onShaderCompileFailed(mbgl::shaders::BuiltIn shader, mbgl::gfx::Backend::Type backend, const std::string& source) {
    Logger::error("NativeMapView", "onShaderCompileFailed: shader=%d, backend=%d, source_length=%zu", 
                  static_cast<int>(shader), static_cast<int>(backend), source.length());
}

// Glyph requests
void NativeMapView::onGlyphsLoaded(const mbgl::FontStack&, const mbgl::GlyphRange&) {}
void NativeMapView::onGlyphsError(const mbgl::FontStack&, const mbgl::GlyphRange&, std::exception_ptr) {}
void NativeMapView::onGlyphsRequested(const mbgl::FontStack&, const mbgl::GlyphRange&) {}

// Tile requests
void NativeMapView::onTileAction(mbgl::TileOperation, const mbgl::OverscaledTileID&, const std::string&) {}

// Sprite requests
void NativeMapView::onSpriteLoaded(const std::optional<mbgl::style::Sprite>&) {}
void NativeMapView::onSpriteError(const std::optional<mbgl::style::Sprite>&, std::exception_ptr) {}
void NativeMapView::onSpriteRequested(const std::optional<mbgl::style::Sprite>&) {}

// ========== 相机监听器方法实现 ==========

napi_value NativeMapView::addOnCameraIdleListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象和参数
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "addOnCameraIdleListener: Failed to get callback argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addOnCameraIdleListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "addOnCameraIdleListener: CallbackManager not initialized");
        return undefined;
    }
    
    // 添加监听器
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

// ========== 样式监听器方法实现 ==========

napi_value NativeMapView::setOnStyleLoadedListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象和参数
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: Failed to get callback argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: CallbackManager not initialized");
        return undefined;
    }
    
    // 检查是否为null（移除监听器）
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
    
    // 先移除旧的监听器，再注册新的（Style 监听器是单例模式）
    instance->callbackManager_->UnregisterCallback("onStyleLoaded");
    
    // 注册回调
    if (instance->callbackManager_->RegisterCallback("onStyleLoaded", args[0])) {
    } else {
        Logger::error("NativeMapView", "setOnStyleLoadedListener: Failed to register callback");
    }
    
    return undefined;
}

napi_value NativeMapView::setOnStyleLoadErrorListener(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象和参数
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: Failed to get callback argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "setOnStyleLoadErrorListener: CallbackManager not initialized");
        return undefined;
    }
    
    // 检查是否为null（移除监听器）
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
    
    // 先移除旧的监听器，再注册新的（Style 监听器是单例模式）
    instance->callbackManager_->UnregisterCallback("onStyleLoadError");
    
    // 注册回调
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

// ========== Android/iOS 风格监听器的 NAPI 方法实现 ==========

// 辅助宏：简化监听器注册代码
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

// ===== 相机事件监听器 =====
IMPLEMENT_ADD_LISTENER(addOnCameraWillChangeListener, "onCameraWillChange")
IMPLEMENT_REMOVE_LISTENER(removeOnCameraWillChangeListener, "onCameraWillChange")
IMPLEMENT_ADD_LISTENER(addOnCameraIsChangingListener, "onCameraIsChanging")
IMPLEMENT_REMOVE_LISTENER(removeOnCameraIsChangingListener, "onCameraIsChanging")
IMPLEMENT_ADD_LISTENER(addOnCameraDidChangeListener, "onCameraDidChange")
IMPLEMENT_REMOVE_LISTENER(removeOnCameraDidChangeListener, "onCameraDidChange")

// ===== 地图加载事件监听器 =====
IMPLEMENT_ADD_LISTENER(addOnWillStartLoadingMapListener, "onWillStartLoadingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnWillStartLoadingMapListener, "onWillStartLoadingMap")
IMPLEMENT_ADD_LISTENER(addOnDidFinishLoadingMapListener, "onDidFinishLoadingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishLoadingMapListener, "onDidFinishLoadingMap")
IMPLEMENT_ADD_LISTENER(addOnDidFailLoadingMapListener, "onDidFailLoadingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFailLoadingMapListener, "onDidFailLoadingMap")

// ===== 渲染事件监听器 =====
IMPLEMENT_ADD_LISTENER(addOnWillStartRenderingFrameListener, "onWillStartRenderingFrame")
IMPLEMENT_REMOVE_LISTENER(removeOnWillStartRenderingFrameListener, "onWillStartRenderingFrame")
IMPLEMENT_ADD_LISTENER(addOnDidFinishRenderingFrameListener, "onDidFinishRenderingFrame")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishRenderingFrameListener, "onDidFinishRenderingFrame")
IMPLEMENT_ADD_LISTENER(addOnWillStartRenderingMapListener, "onWillStartRenderingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnWillStartRenderingMapListener, "onWillStartRenderingMap")
IMPLEMENT_ADD_LISTENER(addOnDidFinishRenderingMapListener, "onDidFinishRenderingMap")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishRenderingMapListener, "onDidFinishRenderingMap")

// ===== 样式事件监听器 =====
IMPLEMENT_ADD_LISTENER(addOnDidFinishLoadingStyleListener, "onDidFinishLoadingStyle")
IMPLEMENT_REMOVE_LISTENER(removeOnDidFinishLoadingStyleListener, "onDidFinishLoadingStyle")
IMPLEMENT_ADD_LISTENER(addOnStyleImageMissingListener, "onStyleImageMissing")
IMPLEMENT_REMOVE_LISTENER(removeOnStyleImageMissingListener, "onStyleImageMissing")

// ===== 其他事件监听器 =====
IMPLEMENT_ADD_LISTENER(addOnDidBecomeIdleListener, "onDidBecomeIdle")
IMPLEMENT_REMOVE_LISTENER(removeOnDidBecomeIdleListener, "onDidBecomeIdle")
IMPLEMENT_ADD_LISTENER(addOnSourceChangedListener, "onSourceChanged")
IMPLEMENT_REMOVE_LISTENER(removeOnSourceChangedListener, "onSourceChanged")

#undef IMPLEMENT_ADD_LISTENER
#undef IMPLEMENT_REMOVE_LISTENER

} // namespace harmony
} // namespace mbgl
