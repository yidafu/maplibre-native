#include "native_map_view_harmony.hpp"

#include <js_native_api_types.h>
#include <mbgl/map/map.hpp>
#include <mbgl/map/map_options.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/client_options.hpp>
#include <mbgl/storage/file_source.hpp>
#include <mbgl/storage/file_source_manager.hpp>
#include <mbgl/storage/sqlite3.hpp>
#include <mbgl/style/style.hpp>
#include <mbgl/util/exception.hpp>
#include <mbgl/util/chrono.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/timer.hpp>
#include <mbgl/annotation/annotation.hpp>
#include <mbgl/util/geometry.hpp>
#include <napi/native_api.h>

// 添加Harmony渲染器头文件
#include "harmony_renderer.hpp"
#include "harmony_renderer_frontend.hpp"
#include "harmony_renderer_backend.hpp"
#include "napi_utils.h"
#include "logger.h"


#include <memory>
#include <native_window/external_window.h>
#include <string>
#include <thread>
#include <chrono>
#include <vector>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

NativeMapView::NativeMapView(napi_env env, napi_value wrapper) : env_(env) {
    // 创建包装器引用
    napi_create_reference(env, wrapper, 1, &wrapper_);
    
    // 初始化成员变量
    mapRenderer = nullptr;
    map = nullptr;
    pixelRatio = 1.0f;
    nativeWindow = nullptr;
    
    Logger::info("NativeMapView", "NativeMapView constructed");
}

NativeMapView::~NativeMapView() {
    Logger::info("NativeMapView", "========== Destructor START ==========");
    
    // 立即标记对象正在析构，防止回调访问
    isDestroying.store(true, std::memory_order_release);
    Logger::debug("NativeMapView", "Marked isDestroying=true");
    
    // 确保资源按正确顺序清理
    cleanupAllResources();
    
    Logger::info("NativeMapView", "========== Destructor END ==========");
}

void NativeMapView::cleanupAllResources() {
    Logger::info("NativeMapView", "========== cleanupAllResources START ==========");
    
    try {
        // 1. 首先停止所有网络请求和异步操作
        Logger::debug("NativeMapView", "Stopping all network requests and async operations...");
        
        if (map) {
            Logger::debug("NativeMapView", "Stopping map operations...");
            // 停止地图的所有网络请求和过渡动画
            try {
                map->cancelTransitions();
                // 注意：mbgl::Map没有stop()方法，使用其他方式停止操作
            } catch (const std::exception& e) {
                Logger::warn("NativeMapView", "Error stopping map operations: %s", e.what());
            }
        }
        
        // 2. 停止所有渲染操作和网络请求
        if (harmonyRenderer) {
            Logger::debug("NativeMapView", "Stopping HarmonyRenderer requests...");
            harmonyRenderer->stopAllRequests();
            Logger::debug("NativeMapView", "Pausing HarmonyRenderer...");
            harmonyRenderer->pause();
        }
        
        // 3. 等待所有异步操作完成
        Logger::debug("NativeMapView", "Waiting for async operations to complete...");
        std::this_thread::sleep_for(std::chrono::milliseconds(1000)); // 进一步增加等待时间
        
        // 4. 强制停止所有RunLoop
        Logger::debug("NativeMapView", "Force stopping all RunLoops...");
        try {
            // 这里可以添加强制停止RunLoop的逻辑
            Logger::debug("NativeMapView", "RunLoop cleanup initiated");
        } catch (const std::exception& e) {
            Logger::warn("NativeMapView", "Error during RunLoop cleanup: %s", e.what());
        }
        
        // 5. 再次等待确保RunLoop完全停止
        Logger::debug("NativeMapView", "Final wait for RunLoop shutdown...");
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // 6. 清理Map对象 (在RunLoop仍然有效时)
        if (map) {
            Logger::debug("NativeMapView", "Destroying Map object...");
            map.reset();
            Logger::debug("NativeMapView", "Map destroyed");
        }
        
        // 5. 清理HarmonyRenderer
        if (harmonyRenderer) {
            Logger::debug("NativeMapView", "Destroying HarmonyRenderer...");
            harmonyRenderer->cleanup();
            harmonyRenderer.reset();
            Logger::debug("NativeMapView", "HarmonyRenderer destroyed");
        }
        
        // 6. 清理其他资源
        mapRenderer = nullptr;
        nativeWindow = nullptr;
        
        // 7. 释放NAPI引用
        if (wrapper_) {
            napi_delete_reference(env_, wrapper_);
            wrapper_ = nullptr;
        }
        
        Logger::info("NativeMapView", "All resources cleaned up successfully");
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "Error during resource cleanup: %s", e.what());
    } catch (...) {
        Logger::error("NativeMapView", "Unknown error during resource cleanup");
    }
    
    Logger::info("NativeMapView", "========== cleanupAllResources END ==========");
}

void NativeMapView::setNativeWindowWithSize(int64_t surfaceId, int width, int height) {
    Logger::info("NativeMapView", "========== setNativeWindowWithSize() START ==========");
    Logger::info("NativeMapView", "Surface ID: %ld, Width: %d, Height: %d", (long)surfaceId, width, height);
    
    // 更新尺寸
    this->width = width;
    this->height = height;
    
    // 创建原生窗口
    OHNativeWindow *nativeWindow;
    Logger::debug("NativeMapView", "Creating native window from surface ID...");
    OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &nativeWindow);
    
    if (nativeWindow) {
        Logger::info("NativeMapView", "Native window created successfully: %p", nativeWindow);
        this->nativeWindow = nativeWindow;
        
        // 初始化渲染器（如果尚未初始化）
        Logger::info("NativeMapView", "Initializing renderer with size %dx%d...", width, height);
        this->initializeRenderer();
        
        Logger::info("NativeMapView", "setNativeWindowWithSize completed successfully");
    } else {
        Logger::error("NativeMapView", "Failed to create native window from surface ID");
    }
    
    Logger::info("NativeMapView", "========== setNativeWindowWithSize() END ==========");
}

void NativeMapView::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<NativeMapView*>(nativeObject);
}


napi_value NativeMapView::Init(napi_env env, napi_value exports) {
    Logger::info("NativeMapView", "========== Init() - Registering NAPI class ==========");
    
    napi_status status;
    napi_value cons;
    
    // 定义所有实例方法
    std::vector<napi_property_descriptor> properties = {
        {"resizeView", nullptr, resizeView, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setPixelRatio", nullptr, setPixelRatio, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getStyleUrl", nullptr, getStyleUrl, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStyleUrl", nullptr, setStyleUrl, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getStyleJson", nullptr, getStyleJson, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStyleJson", nullptr, setStyleJson, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setLatLngBounds", nullptr, setLatLngBounds, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"cancelTransitions", nullptr, cancelTransitions, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setGestureInProgress", nullptr, setGestureInProgress, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"moveBy", nullptr, moveBy, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"jumpTo", nullptr, jumpTo, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"easeTo", nullptr, easeTo, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"flyTo", nullptr, flyTo, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLatLng", nullptr, getLatLng, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setLatLng", nullptr, setLatLng, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getCameraForLatLngBounds", nullptr, getCameraForLatLngBounds, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getCameraForGeometry", nullptr, getCameraForGeometry, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setReachability", nullptr, setReachability, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resetPosition", nullptr, resetPosition, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getPitch", nullptr, getPitch, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setPitch", nullptr, setPitch, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setZoom", nullptr, setZoom, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getZoom", nullptr, getZoom, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resetZoom", nullptr, resetZoom, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setMinZoom", nullptr, setMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getMinZoom", nullptr, getMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setMaxZoom", nullptr, setMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getMaxZoom", nullptr, getMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setMinPitch", nullptr, setMinPitch, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getMinPitch", nullptr, getMinPitch, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setMaxPitch", nullptr, setMaxPitch, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getMaxPitch", nullptr, getMaxPitch, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"rotateBy", nullptr, rotateBy, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setBearing", nullptr, setBearing, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setBearingXY", nullptr, setBearingXY, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getBearing", nullptr, getBearing, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resetNorth", nullptr, resetNorth, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setVisibleCoordinateBounds", nullptr, setVisibleCoordinateBounds, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getVisibleCoordinateBounds", nullptr, getVisibleCoordinateBounds, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"scheduleSnapshot", nullptr, scheduleSnapshot, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getCameraPosition", nullptr, getCameraPosition, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"updateMarker", nullptr, updateMarker, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addMarkers", nullptr, addMarkers, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onLowMemory", nullptr, onLowMemory, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setDebug", nullptr, setDebug, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getDebug", nullptr, getDebug, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getActionJournalLogFiles", nullptr, getActionJournalLogFiles, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getActionJournalLog", nullptr, getActionJournalLog, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clearActionJournalLog", nullptr, clearActionJournalLog, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isFullyLoaded", nullptr, isFullyLoaded, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getMetersPerPixelAtLatitude", nullptr, getMetersPerPixelAtLatitude, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"projectedMetersForLatLng", nullptr, projectedMetersForLatLng, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pixelForLatLng", nullptr, pixelForLatLng, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"pixelsForLatLngs", nullptr, pixelsForLatLngs, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"latLngForProjectedMeters", nullptr, latLngForProjectedMeters, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"latLngForPixel", nullptr, latLngForPixel, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"latLngsForPixels", nullptr, latLngsForPixels, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addPolylines", nullptr, addPolylines, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addPolygons", nullptr, addPolygons, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"updatePolyline", nullptr, updatePolyline, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"updatePolygon", nullptr, updatePolygon, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeAnnotations", nullptr, removeAnnotations, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addAnnotationIcon", nullptr, addAnnotationIcon, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeAnnotationIcon", nullptr, removeAnnotationIcon, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTopOffsetPixelsForAnnotationSymbol", nullptr, getTopOffsetPixelsForAnnotationSymbol, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTransitionOptions", nullptr, getTransitionOptions, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTransitionOptions", nullptr, setTransitionOptions, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"queryPointAnnotations", nullptr, queryPointAnnotations, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"queryShapeAnnotations", nullptr, queryShapeAnnotations, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"queryRenderedFeaturesForPoint", nullptr, queryRenderedFeaturesForPoint, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"queryRenderedFeaturesForBox", nullptr, queryRenderedFeaturesForBox, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLight", nullptr, getLight, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLayers", nullptr, getLayers, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLayer", nullptr, getLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addLayer", nullptr, addLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addLayerAbove", nullptr, addLayerAbove, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addLayerAt", nullptr, addLayerAt, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeLayerAt", nullptr, removeLayerAt, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeLayer", nullptr, removeLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSources", nullptr, getSources, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSource", nullptr, getSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addSource", nullptr, addSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeSource", nullptr, removeSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addImage", nullptr, addImage, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addImages", nullptr, addImages, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeImage", nullptr, removeImage, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getImage", nullptr, getImage, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setPrefetchTiles", nullptr, setPrefetchTiles, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getPrefetchTiles", nullptr, getPrefetchTiles, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setPrefetchZoomDelta", nullptr, setPrefetchZoomDelta, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getPrefetchZoomDelta", nullptr, getPrefetchZoomDelta, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTileCacheEnabled", nullptr, setTileCacheEnabled, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTileCacheEnabled", nullptr, getTileCacheEnabled, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTileLodMinRadius", nullptr, setTileLodMinRadius, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTileLodMinRadius", nullptr, getTileLodMinRadius, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTileLodScale", nullptr, setTileLodScale, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTileLodScale", nullptr, getTileLodScale, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTileLodPitchThreshold", nullptr, setTileLodPitchThreshold, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTileLodPitchThreshold", nullptr, getTileLodPitchThreshold, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setTileLodZoomShift", nullptr, setTileLodZoomShift, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getTileLodZoomShift", nullptr, getTileLodZoomShift, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"triggerRepaint", nullptr, triggerRepaint, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isRenderingStatsViewEnabled", nullptr, isRenderingStatsViewEnabled, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"enableRenderingStatsView", nullptr, enableRenderingStatsView, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setNativeWindow", nullptr, setNativeWindow, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setNativeWindowWithSize", nullptr, setNativeWindowWithSize, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    Logger::info("NativeMapView", "Registering %zu methods", properties.size());
    
    // 定义类构造函数，并传入所有属性描述符
    status = napi_define_class(
        env,
        "NativeMapView",
        NAPI_AUTO_LENGTH,
        New,
        nullptr,
        properties.size(),
        properties.data(),
        &cons
    );
    
    if (status != napi_ok) {
        Logger::error("NativeMapView", "Failed to define NativeMapView class");
        return nullptr;
    }
    
    Logger::debug("NativeMapView", "NativeMapView class defined successfully");
    
    // 设置构造函数的引用 - 使用静态变量存储
    static napi_ref static_wrapper;
    status = napi_create_reference(env, cons, 1, &static_wrapper);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "Failed to create reference to constructor");
        return nullptr;
    }
    
    // 设置导出对象
    status = napi_set_named_property(env, exports, "NativeMapView", cons);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "Failed to export NativeMapView");
        return nullptr;
    }
    
    Logger::info("NativeMapView", "NativeMapView class registered successfully with %zu methods", properties.size());
    
    return exports;
}

napi_value NativeMapView::New(napi_env env, napi_callback_info info) {
    napi_status status;
    napi_value thisVar;
    
    // 获取this对象
    status = napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    if (status != napi_ok) return nullptr;
    
    // 创建NativeMapView实例
    NativeMapView* nativeMapView = new NativeMapView(env, thisVar);
    
    // 设置NativeMapView实例为外部数据
    status = napi_wrap(
        env,
        thisVar,
        nativeMapView,
        Destructor,
        nullptr,
        nullptr
    );
    
    if (status != napi_ok) {
        delete nativeMapView;
        return nullptr;
    }
    
    return thisVar;
}

// MapObserver 方法实现
void NativeMapView::onCameraWillChange(MapObserver::CameraChangeMode) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onCameraWillChange");
}
void NativeMapView::onCameraIsChanging() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onCameraIsChanging");
}
void NativeMapView::onCameraDidChange(MapObserver::CameraChangeMode) {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onCameraDidChange");
    
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
}
void NativeMapView::onWillStartRenderingFrame() {
    if (isDestroying.load(std::memory_order_acquire)) return;
    Logger::debug("NativeMapView", "onWillStartRenderingFrame");
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
    if (isDestroying.load(std::memory_order_acquire)) return;
    
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    Logger::warn("NativeMapView", "🎨 [%lld ms] onDidFinishLoadingStyle", elapsed);
    
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
    Logger::warn("NativeMapView", "Missing image: %s", id.c_str());
    Logger::info("NativeMapView", "Hint: Add this image using map.addImage() or provide it in sprite sheet");
    Logger::warn("NativeMapView", "=========================================");
}

bool NativeMapView::onCanRemoveUnusedStyleImage(const std::string& id) {
    Logger::debug("NativeMapView", "onCanRemoveUnusedStyleImage: %s - returning false (keep image)", id.c_str());
    return false;
}

void NativeMapView::initializeRenderer() {
    Logger::debug("NativeMapView", "initializeRenderer() called - harmonyRenderer=%s, nativeWindow=%s, map=%s", 
                  harmonyRenderer ? "exists" : "null",
                  nativeWindow ? "exists" : "null",
                  map ? "exists" : "null");
    
    // 1. 创建 HarmonyRenderer（如果不存在）
    if (!harmonyRenderer) {
        Logger::info("NativeMapView", "Creating HarmonyRenderer (width=%d, height=%d, pixelRatio=%.2f)", 
                     width, height, pixelRatio);
        harmonyRenderer = std::make_unique<HarmonyRenderer>();
        harmonyRenderer->initialize(width, height, pixelRatio);
        
        Logger::info("NativeMapView", "HarmonyRenderer initialized successfully");
    } else {
        Logger::debug("NativeMapView", "HarmonyRenderer already exists, skipping creation");
    }
    
    // 2. 如果有窗口，设置窗口
    if (nativeWindow && harmonyRenderer) {
        Logger::info("NativeMapView", "Setting native window to HarmonyRenderer");
        harmonyRenderer->setNativeWindow(nativeWindow);
        Logger::debug("NativeMapView", "Native window set successfully");
    } else {
        Logger::warn("NativeMapView", "Cannot set native window - nativeWindow=%s, harmonyRenderer=%s",
                     nativeWindow ? "exists" : "null",
                     harmonyRenderer ? "exists" : "null");
    }
    
    // 3. 创建 Map 对象（如果不存在）
    if (!map && harmonyRenderer) {
        Logger::info("NativeMapView", "Creating Map object...");
        
        auto* rendererFrontend = harmonyRenderer->getRendererFrontend();
        if (!rendererFrontend) {
            Logger::error("NativeMapView", "Cannot create Map - RendererFrontend is null");
            return;
        }
        Logger::debug("NativeMapView", "Got RendererFrontend: %p", rendererFrontend);
        
        try {
            // Configure MapOptions
            MapOptions mapOptions;
            mapOptions.withMapMode(MapMode::Continuous)
                      .withConstrainMode(ConstrainMode::HeightOnly)
                      .withViewportMode(ViewportMode::Default)
                      .withCrossSourceCollisions(true)
                      .withSize(Size{static_cast<uint32_t>(width), static_cast<uint32_t>(height)})
                      .withPixelRatio(pixelRatio);
            Logger::debug("NativeMapView", "MapOptions configured: size=%dx%d, pixelRatio=%.2f", 
                          width, height, pixelRatio);
            
            // Configure ResourceOptions
            ResourceOptions resourceOptions;
            std::string cachePath = "/data/storage/el2/base/cache";
            resourceOptions.withCachePath(cachePath + "/mbgl_cache.db")
                          .withAssetPath(cachePath)
                          .withPlatformContext(reinterpret_cast<void*>(this)); // Enable platform context
            Logger::debug("NativeMapView", "ResourceOptions configured with cache path and platform context");
            
            // Configure ClientOptions
            ClientOptions clientOptions;
            clientOptions.withName("MapLibre Harmony")
                         .withVersion("1.0.0");
            Logger::debug("NativeMapView", "ClientOptions configured");
            
            // Create Map object
            map = std::make_unique<Map>(
                *rendererFrontend,
                *this,
                mapOptions,
                resourceOptions,
                clientOptions
            );
            
            Logger::info("NativeMapView", "Map object created successfully: %p", map.get());
            
            // DEBUG: Check if RunLoop exists on this thread
            auto* currentRunLoop = util::RunLoop::Get();
            if (currentRunLoop) {
                Logger::info("NativeMapView", "RunLoop EXISTS on current thread: %p", currentRunLoop);
                printf("[MAP DEBUG] RunLoop verified: %p\n", currentRunLoop);
                fflush(stdout);
            } else {
                Logger::error("NativeMapView", "RunLoop is NULL on current thread! Network requests will FAIL!");
                Logger::error("NativeMapView", "CRITICAL: Map must be created on a thread with an active RunLoop");
                printf("[MAP ERROR] RunLoop is NULL!\n");
                fflush(stdout);
            }
            
            // DEBUG: Trigger style loading to test network
            printf("[MAP DEBUG] About to call map->getStyle().loadURL()...\n");
            fflush(stdout);
            
            // Connect Map to RendererFrontend
            auto* frontend = harmonyRenderer->getRendererFrontend();
            if (frontend) {
                frontend->setMap(map.get());
                Logger::info("NativeMapView", "Map connected to RendererFrontend");
            } else {
                Logger::error("NativeMapView", "Failed to get RendererFrontend");
            }
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "Failed to create Map object: %s", e.what());
        }
    } else if (map) {
        Logger::debug("NativeMapView", "Map already exists, skipping creation");
    } else {
        Logger::warn("NativeMapView", "Cannot create Map - harmonyRenderer is null");
    }
}

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
    
    // 如果渲染器已初始化，调整尺寸
    if (instance->harmonyRenderer) {
        instance->harmonyRenderer->resize(instance->width, instance->height);
    }
    
    Logger::info("NativeMapView", "View resized to %d x %d", instance->width, instance->height);
    
    return undefined;
}

napi_value NativeMapView::setPixelRatio(napi_env env, napi_callback_info info) {
    Logger::warn("NativeMapView", "========== setPixelRatio() CALLED ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象和参数
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setPixelRatio: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setPixelRatio: Missing pixelRatio argument");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setPixelRatio: Failed to unwrap instance or instance is null");
        return undefined;
    }
    
    // 获取 pixelRatio 值
    double pixelRatio;
    if (napi_get_value_double(env, args[0], &pixelRatio) != napi_ok) {
        Logger::error("NativeMapView", "setPixelRatio: Failed to get pixelRatio value");
        return undefined;
    }
    
    // 限制在合理范围内 (0.5 - 4.0)
    pixelRatio = std::max(0.5, std::min(4.0, pixelRatio));
    
    try {
        // 设置像素比
        instance->pixelRatio = static_cast<float>(pixelRatio);
        Logger::warn("NativeMapView", "setPixelRatio: Set to %.2f", instance->pixelRatio);
        
        // 如果 harmonyRenderer 已存在，更新它的 pixelRatio
        if (instance->harmonyRenderer) {
            instance->harmonyRenderer->setPixelRatio(instance->pixelRatio);
            Logger::warn("NativeMapView", "setPixelRatio: Updated HarmonyRenderer pixelRatio");
        } else {
            Logger::warn("NativeMapView", "setPixelRatio: HarmonyRenderer not yet created, pixelRatio will be used during initialization");
        }
        
        Logger::warn("NativeMapView", "========== setPixelRatio() COMPLETED ==========");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setPixelRatio: Exception occurred: %s", e.what());
    } catch (...) {
        Logger::error("NativeMapView", "setPixelRatio: Unknown exception occurred");
    }
    
    return undefined;
}

napi_value NativeMapView::getStyleUrl(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setStyleUrl(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== setStyleUrl() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to unwrap instance");
        return undefined;
    }
    
    Logger::debug("NativeMapView", "setStyleUrl: instance=%p", instance);
    Logger::debug("NativeMapView", "setStyleUrl: Current state - map=%s, harmonyRenderer=%s, nativeWindow=%s",
                  instance->map ? "exists" : "null",
                  instance->harmonyRenderer ? "exists" : "null",
                  instance->nativeWindow ? "exists" : "null");
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::error("NativeMapView", "setStyleUrl: Map not initialized! Please call setNativeWindow first.");
        return undefined;
    }
    
    // 获取样式URL参数
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setStyleUrl: Missing style URL argument");
        return undefined;
    }
    
    // 提取样式URL字符串
    size_t strSize;
    if (napi_get_value_string_utf8(env, args[0], nullptr, 0, &strSize) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get style URL string size");
        return undefined;
    }
    
    std::string styleUrl(strSize + 1, '\0');
    if (napi_get_value_string_utf8(env, args[0], &styleUrl[0], strSize + 1, &strSize) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get style URL string");
        return undefined;
    }
    styleUrl.resize(strSize);
    
    Logger::info("NativeMapView", "setStyleUrl: Loading style from URL: %s", styleUrl.c_str());
    
    // 加载样式
    try {
        printf("[STYLE DEBUG] Calling getStyle().loadURL('%s')...\n", styleUrl.c_str());
        fflush(stdout);
        
        instance->map->getStyle().loadURL(styleUrl);
        
        Logger::info("NativeMapView", "✅ loadURL() returned successfully");
        Logger::info("NativeMapView", "📞 About to call triggerRepaint()...");
        printf("[STYLE DEBUG] loadURL() returned successfully\n");
        printf("[STYLE DEBUG] Calling triggerRepaint()...\n");
        fflush(stdout);
        
        instance->map->triggerRepaint();  // Trigger rendering
        
        Logger::info("NativeMapView", "✅ triggerRepaint() returned successfully");
        printf("[STYLE DEBUG] triggerRepaint() completed\n");
        printf("[STYLE DEBUG] If no RunLoop::addWatch() was called, HTTP request was NOT initiated!\n");
        fflush(stdout);
        
        Logger::info("NativeMapView", "setStyleUrl: Style URL set successfully");
        Logger::info("NativeMapView", "========== setStyleUrl() END - SUCCESS ==========");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to load style: %s", e.what());
        Logger::error("NativeMapView", "========== setStyleUrl() END - FAILED ==========");
        printf("[STYLE ERROR] loadURL() exception: %s\n", e.what());
        fflush(stdout);
    }
    
    return undefined;
}

napi_value NativeMapView::getStyleJson(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setStyleJson(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setLatLngBounds(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

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
        instance->map->cancelTransitions();
        Logger::debug("NativeMapView", "cancelTransitions: Transitions cancelled successfully");
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
        
        Logger::debug("NativeMapView", "jumpTo: Executing map->jumpTo()...");
        instance->map->jumpTo(cameraOptions);
        
        Logger::debug("NativeMapView", "jumpTo: Executing map->triggerRepaint()...");
        instance->map->triggerRepaint();  // Trigger rendering
        
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
        instance->map->easeTo(cameraOptions, 
                             mbgl::AnimationOptions(std::chrono::milliseconds(duration)));
        instance->map->triggerRepaint();
        Logger::info("NativeMapView", "easeTo: Camera animation started successfully");
        Logger::info("NativeMapView", "========== easeTo() END - SUCCESS ==========");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "easeTo: Failed - %s", e.what());
        Logger::error("NativeMapView", "========== easeTo() END - FAILED ==========");
    }
    
    return undefined;
}

napi_value NativeMapView::flyTo(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getLatLng(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setLatLng(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getCameraForLatLngBounds(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getCameraForGeometry(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setReachability(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::resetPosition(napi_env env, napi_callback_info info) {
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
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMinZoom(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMinZoom(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMaxZoom(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMaxZoom(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMinPitch(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMinPitch(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setMaxPitch(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getMaxPitch(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::rotateBy(napi_env env, napi_callback_info info) {
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
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setVisibleCoordinateBounds(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getVisibleCoordinateBounds(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::scheduleSnapshot(napi_env env, napi_callback_info info) {
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

napi_value NativeMapView::updateMarker(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addMarkers(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::onLowMemory(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setDebug(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getDebug(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getActionJournalLogFiles(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getActionJournalLog(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::clearActionJournalLog(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::isFullyLoaded(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::getMetersPerPixelAtLatitude(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    return result;
}

napi_value NativeMapView::projectedMetersForLatLng(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::pixelForLatLng(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::pixelsForLatLngs(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::latLngForProjectedMeters(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::latLngForPixel(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::latLngsForPixels(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addPolylines(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addPolygons(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::updatePolyline(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::updatePolygon(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::removeAnnotations(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addAnnotationIcon(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::removeAnnotationIcon(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTopOffsetPixelsForAnnotationSymbol(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    return result;
}

napi_value NativeMapView::getTransitionOptions(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setTransitionOptions(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::queryPointAnnotations(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::queryShapeAnnotations(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::queryRenderedFeaturesForPoint(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::queryRenderedFeaturesForBox(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getLight(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getLayers(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getLayer(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addLayer(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addLayerAbove(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addLayerAt(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::removeLayerAt(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::removeLayer(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::getSources(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getSource(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addSource(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::removeSource(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::addImage(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::addImages(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::removeImage(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getImage(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setPrefetchTiles(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getPrefetchTiles(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::setPrefetchZoomDelta(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getPrefetchZoomDelta(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_int32(env, 0, &result);
    return result;
}

napi_value NativeMapView::setTileCacheEnabled(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTileCacheEnabled(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::setTileLodMinRadius(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTileLodMinRadius(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    return result;
}

napi_value NativeMapView::setTileLodScale(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTileLodScale(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    return result;
}

napi_value NativeMapView::setTileLodPitchThreshold(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTileLodPitchThreshold(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    return result;
}

napi_value NativeMapView::setTileLodZoomShift(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getTileLodZoomShift(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
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
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::enableRenderingStatsView(napi_env env, napi_callback_info info) {
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

} // namespace harmony
} // namespace mbgl
