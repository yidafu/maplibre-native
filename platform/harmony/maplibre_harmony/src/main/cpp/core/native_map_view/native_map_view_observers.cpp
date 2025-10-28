#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "rendering/harmony_renderer.hpp"
#include <mbgl/gfx/shader_registry.hpp>
#include <mbgl/style/style.hpp>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

// 用于线程安全传递错误信息的结构体
struct StyleErrorData {
    std::string error;
};

void NativeMapView::onCameraWillChange(MapObserver::CameraChangeMode mode) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onCameraWillChange");
    
    // 通知相机开始移动
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onCameraMoveStarted");
    }
}

void NativeMapView::onCameraIsChanging() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onCameraIsChanging");
    
    // 通知相机移动中（高频事件，考虑节流）
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onCameraMove");
    }
}

void NativeMapView::onCameraDidChange(MapObserver::CameraChangeMode mode) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onCameraDidChange");
    
    // 通知相机移动结束
    if (callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onCameraIdle");
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
}
void NativeMapView::onDidFinishLoadingMap() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    Logger::warn("NativeMapView", "🗺️ [%lld ms] onDidFinishLoadingMap", elapsed);
    
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
    
    // 通知样式加载错误
    std::string fullError = std::string(errorType) + ": " + errorMsg;
    notifyStyleLoadError(fullError);
}
void NativeMapView::onWillStartRenderingFrame() {
    if (isDestroying.load(std::memory_order_acquire)) return;
}
void NativeMapView::onDidFinishRenderingFrame(const MapObserver::RenderFrameStatus& status) {
    if (isDestroying.load(std::memory_order_acquire)) {
        return;
    }
    
    // Network I/O is now handled by the renderer thread's RunLoop
}
void NativeMapView::onWillStartRenderingMap() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onWillStartRenderingMap");
}
void NativeMapView::onDidFinishRenderingMap(MapObserver::RenderMode mode) {
    // 立即检查对象是否正在析构
    if (isDestroying.load(std::memory_order_acquire)) {
        return;
    }
    
    try {
        Logger::debug("NativeMapView", "onDidFinishRenderingMap");
        // 渲染已完成，不需要再次请求渲染
        // onCameraDidChange 已经处理了渲染请求
    } catch (...) {
        // 忽略所有异常，避免崩溃
    }
}
void NativeMapView::onDidBecomeIdle() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onDidBecomeIdle");
}
void NativeMapView::onDidFinishLoadingStyle() {
    // 🔍 日志：最早期的日志，确认回调被调用
    Logger::error("NativeMapView", "🎨🎨🎨 onDidFinishLoadingStyle() ENTRY - START 🎨🎨🎨");
    
    if (isDestroying.load(std::memory_order_acquire)) {
        Logger::warn("NativeMapView", "⚠️ onDidFinishLoadingStyle: Instance is destroying, skipping callback");
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
    Logger::error("NativeMapView", "🎨 [Instance #%d] this=%p, map=%p, callbackManager=%p", 
                  instanceId, this, map, callbackManager_.get());
    
    // 检查样式状态
    if (map) {
        try {
            std::string styleUrl = map->getStyle().getURL();
            Logger::error("NativeMapView", "🎨 [Instance #%d] Style URL: %s", instanceId, styleUrl.c_str());
            
            // 获取 sources 和 layers 数量
            auto sources = map->getStyle().getSources();
            auto layers = map->getStyle().getLayers();
            Logger::error("NativeMapView", "🎨 [Instance #%d] Sources: %zu, Layers: %zu", 
                          instanceId, sources.size(), layers.size());
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "🎨 [Instance #%d] Error getting style info: %s", instanceId, e.what());
        }
    }
    
    // 通知样式加载完成
    Logger::error("NativeMapView", "🎨 [Instance #%d] Calling notifyStyleLoaded()...", instanceId);
    notifyStyleLoaded();
    Logger::error("NativeMapView", "🎨 [Instance #%d] notifyStyleLoaded() completed", instanceId);
    
    if (map) {
        try {
            // 获取样式URL和名称
            std::string styleUrl = map->getStyle().getURL();
            std::string styleName = map->getStyle().getName();
            
            Logger::info("NativeMapView", "Style loaded successfully:");
            Logger::info("NativeMapView", "  - URL: %s", styleUrl.empty() ? "(inline JSON)" : styleUrl.c_str());
            Logger::info("NativeMapView", "  - Name: %s", styleName.empty() ? "(unnamed)" : styleName.c_str());
            
            // 获取Sources列表
            auto sources = map->getStyle().getSources();
            Logger::info("NativeMapView", "  - Sources count: %zu", sources.size());
            for (const auto* source : sources) {
                if (source) {
                    Logger::debug("NativeMapView", "    * Source: %s (type: %d)", 
                                  source->getID().c_str(), static_cast<int>(source->getType()));
                }
            }
            
            // 获取Layers列表
            auto layers = map->getStyle().getLayers();
            Logger::info("NativeMapView", "  - Layers count: %zu", layers.size());
            for (const auto* layer : layers) {
                if (layer) {
                    Logger::debug("NativeMapView", "    * Layer: %s (source: %s)", 
                                  layer->getID().c_str(), layer->getSourceID().c_str());
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
    
    int count = ++sourceChangedCount;
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    Logger::warn("NativeMapView", "🔄 [%lld ms] onSourceChanged #%d: %s (type=%d)", 
                 elapsed, count, source.getID().c_str(), static_cast<int>(source.getType()));
    
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
}

bool NativeMapView::onCanRemoveUnusedStyleImage(const std::string& id) {
    Logger::debug("NativeMapView", "onCanRemoveUnusedStyleImage: %s - returning false (keep image)", id.c_str());
    return false;
}

// Note: initializeRenderer is defined in native_map_view_base.cpp

napi_value NativeMapView::getImage(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getImage() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Bitmap 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:1241-1246
    Logger::warn("NativeMapView", "getImage: Not implemented - requires Bitmap wrapper class");
    
    return undefined;
}

napi_value NativeMapView::setPrefetchTiles(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setPrefetchTiles() called");
    
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
        instance->map->setPrefetchZoomDelta(enable ? mbgl::util::DEFAULT_PREFETCH_ZOOM_DELTA : uint8_t(0));
        Logger::info("NativeMapView", "setPrefetchTiles: Set to %s", enable ? "enabled" : "disabled");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setPrefetchTiles: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getPrefetchTiles(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getPrefetchTiles() called");
    
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
        bool enabled = instance->map->getPrefetchZoomDelta() > 0;
        napi_get_boolean(env, enabled, &result);
        Logger::debug("NativeMapView", "getPrefetchTiles: %s", enabled ? "enabled" : "disabled");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getPrefetchTiles: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setPrefetchZoomDelta(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setPrefetchZoomDelta() called");
    
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
        instance->map->setPrefetchZoomDelta(static_cast<uint8_t>(delta));
        Logger::info("NativeMapView", "setPrefetchZoomDelta: Set to %d", delta);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setPrefetchZoomDelta: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getPrefetchZoomDelta(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getPrefetchZoomDelta() called");
    
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
        int32_t delta = static_cast<int32_t>(instance->map->getPrefetchZoomDelta());
        napi_create_int32(env, delta, &result);
        Logger::debug("NativeMapView", "getPrefetchZoomDelta: %d", delta);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getPrefetchZoomDelta: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileCacheEnabled(napi_env env, napi_callback_info info) {
    // Tile 缓存控制需要渲染器前端支持
    // Tile cache control requires renderer frontend support
    Logger::debug("NativeMapView", "setTileCacheEnabled: Tile cache control requires renderer frontend support");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTileCacheEnabled(napi_env env, napi_callback_info info) {
    // Tile 缓存控制需要渲染器前端支持
    // Tile cache control requires renderer frontend support
    Logger::debug("NativeMapView", "getTileCacheEnabled: Tile cache control requires renderer frontend support");
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::setTileLodMinRadius(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setTileLodMinRadius() called");
    
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
        instance->map->setTileLodMinRadius(radius);
        Logger::info("NativeMapView", "setTileLodMinRadius: Set to %f", radius);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodMinRadius: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodMinRadius(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getTileLodMinRadius() called");
    
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
        double radius = instance->map->getTileLodMinRadius();
        napi_create_double(env, radius, &result);
        Logger::debug("NativeMapView", "getTileLodMinRadius: %f", radius);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileLodMinRadius: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileLodScale(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setTileLodScale() called");
    
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
        instance->map->setTileLodScale(scale);
        Logger::info("NativeMapView", "setTileLodScale: Set to %f", scale);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodScale: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodScale(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getTileLodScale() called");
    
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
        double scale = instance->map->getTileLodScale();
        napi_create_double(env, scale, &result);
        Logger::debug("NativeMapView", "getTileLodScale: %f", scale);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileLodScale: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileLodPitchThreshold(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setTileLodPitchThreshold() called");
    
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
        instance->map->setTileLodPitchThreshold(threshold);
        Logger::info("NativeMapView", "setTileLodPitchThreshold: Set to %f", threshold);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodPitchThreshold: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodPitchThreshold(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getTileLodPitchThreshold() called");
    
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
        double threshold = instance->map->getTileLodPitchThreshold();
        napi_create_double(env, threshold, &result);
        Logger::debug("NativeMapView", "getTileLodPitchThreshold: %f", threshold);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTileLodPitchThreshold: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::setTileLodZoomShift(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setTileLodZoomShift() called");
    
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
        instance->map->setTileLodZoomShift(shift);
        Logger::info("NativeMapView", "setTileLodZoomShift: Set to %f", shift);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTileLodZoomShift: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTileLodZoomShift(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getTileLodZoomShift() called");
    
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
        double shift = instance->map->getTileLodZoomShift();
        napi_create_double(env, shift, &result);
        Logger::debug("NativeMapView", "getTileLodZoomShift: %f", shift);
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
        Logger::debug("NativeMapView", "Render requested");
    }
    
    return undefined;
}

// 设置NativeWindow的NAPI方法
napi_value NativeMapView::setNativeWindow(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== setNativeWindow() START ==========");

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
    
    Logger::debug("NativeMapView", "NativeMapView instance: %p", nativeMapView);
    Logger::debug("NativeMapView", "Current state - harmonyRenderer=%s, map=%s, nativeWindow=%s",
                  nativeMapView->harmonyRenderer ? "exists" : "null",
                  nativeMapView->map ? "exists" : "null",
                  nativeMapView->nativeWindow ? "exists" : "null");

    OHNativeWindow *nativeWindow;
    Logger::debug("NativeMapView", "Creating native window from surface ID...");
    OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &nativeWindow);
    
    if (nativeWindow) {
        Logger::info("NativeMapView", "Native window created successfully: %p", nativeWindow);
    } else {
        Logger::error("NativeMapView", "Failed to create native window from surface ID");
        return undefined;
    }
    
    // 保存窗口指针
    nativeMapView->nativeWindow = nativeWindow;
    Logger::debug("NativeMapView", "Native window saved to NativeMapView");
    
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
    Logger::debug("NativeMapView", "isRenderingStatsViewEnabled: Rendering stats view not implemented for Harmony");
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::enableRenderingStatsView(napi_env env, napi_callback_info info) {
    // Rendering stats view 未在 Harmony 平台实现
    // Rendering stats view not implemented for Harmony
    Logger::debug("NativeMapView", "enableRenderingStatsView: Rendering stats view not implemented for Harmony");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// 设置NativeWindow的NAPI方法（带尺寸参数）
napi_value NativeMapView::setNativeWindowWithSize(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== setNativeWindowWithSize() START ==========");

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
        Logger::debug("NativeMapView", "getMap: returning valid map object");
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

// ========== 相机监听器方法实现（使用 CallbackManager）==========

napi_value NativeMapView::addOnCameraIdleListener(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "addOnCameraIdleListener() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->RegisterCallback("onCameraIdle", args.Get(0));
    }
    
    return args.Undefined();
}

napi_value NativeMapView::removeOnCameraIdleListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->UnregisterCallback("onCameraIdle");
    }
    
    return args.Undefined();
}

napi_value NativeMapView::addOnCameraMoveStartedListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->RegisterCallback("onCameraMoveStarted", args.Get(0));
    }
    
    return args.Undefined();
}

napi_value NativeMapView::removeOnCameraMoveStartedListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->UnregisterCallback("onCameraMoveStarted");
    }
    
    return args.Undefined();
}

napi_value NativeMapView::addOnCameraMoveListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->RegisterCallback("onCameraMove", args.Get(0));
    }
    
    return args.Undefined();
}

napi_value NativeMapView::removeOnCameraMoveListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->UnregisterCallback("onCameraMove");
    }
    
    return args.Undefined();
}

napi_value NativeMapView::addOnCameraMoveCanceledListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->RegisterCallback("onCameraMoveCanceled", args.Get(0));
    }
    
    return args.Undefined();
}

napi_value NativeMapView::removeOnCameraMoveCanceledListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (instance->callbackManager_) {
        instance->callbackManager_->UnregisterCallback("onCameraMoveCanceled");
    }
    
    return args.Undefined();
}

// ========== 样式监听器方法实现（使用 CallbackManager）==========

napi_value NativeMapView::setOnStyleLoadedListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (!instance->callbackManager_) {
        return args.Undefined();
    }
    
    // 检查是否为 null/undefined（移除监听器）
    if (args.IsNullOrUndefined(0)) {
        instance->callbackManager_->UnregisterCallback("onStyleLoaded");
    } else {
        instance->callbackManager_->RegisterCallback("onStyleLoaded", args.Get(0));
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setOnStyleLoadErrorListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        return args.Undefined();
    }
    
    if (!instance->callbackManager_) {
        return args.Undefined();
    }
    
    // 检查是否为 null/undefined（移除监听器）
    if (args.IsNullOrUndefined(0)) {
        instance->callbackManager_->UnregisterCallback("onStyleLoadError");
    } else {
        instance->callbackManager_->RegisterCallback("onStyleLoadError", args.Get(0));
    }
    
    return args.Undefined();
}

void NativeMapView::notifyStyleLoaded() {
    if (isDestroying.load(std::memory_order_acquire)) {
        Logger::warn("NativeMapView", "⚠️ notifyStyleLoaded: Instance is destroying, skipping callback");
        return;
    }
    
    if (!callbackManager_) {
        Logger::warn("NativeMapView", "⚠️ notifyStyleLoaded: CallbackManager is null");
        return;
    }
    
    Logger::info("NativeMapView", "✅ notifyStyleLoaded: Invoking callback via CallbackManager");
    
    // 使用 CallbackManager 调用回调（自动处理线程安全）
    bool success = callbackManager_->InvokeCallbackEmpty("onStyleLoaded");
    
    if (success) {
        Logger::info("NativeMapView", "✅ notifyStyleLoaded: Callback invoked successfully");
    } else {
        Logger::warn("NativeMapView", "⚠️ notifyStyleLoaded: No listener registered or callback failed");
    }
}

void NativeMapView::notifyStyleLoadError(const std::string& error) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    if (!callbackManager_) {
        Logger::warn("NativeMapView", "notifyStyleLoadError: CallbackManager is null");
        return;
    }
    
    Logger::error("NativeMapView", "notifyStyleLoadError: Invoking error callback with: %s", error.c_str());
    
    // 使用 CallbackManager 调用错误回调
    bool success = callbackManager_->InvokeCallbackWithString("onStyleLoadError", error);
    
    if (success) {
        Logger::debug("NativeMapView", "notifyStyleLoadError: Error callback invoked successfully");
    } else {
        Logger::warn("NativeMapView", "notifyStyleLoadError: No error listener registered or callback failed");
    }
}

} // namespace harmony
} // namespace mbgl
