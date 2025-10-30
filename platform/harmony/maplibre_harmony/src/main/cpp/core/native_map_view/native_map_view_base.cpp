#include "native_map_view_harmony.hpp"
#include "napi/bindings/marker/marker_napi.hpp"
#include "napi/bindings/style/style_napi.hpp"

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
#include "rendering/harmony_renderer.hpp"
#include "rendering/backends/harmony_renderer_backend.hpp"
#include "rendering/backends/harmony_gl_renderer_backend.hpp"
#include "napi/core/napi_utils.h"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "utils/anr_detector.hpp"
#include "core/thread_safe_callback.hpp"

// 几何类型转换
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "geometry/rect_harmony.hpp"

// 相机类型转换
#include "camera/camera_position_harmony.hpp"

// 样式类型转换
#include "style/transition_options_harmony.hpp"


#include <memory>
#include <native_window/external_window.h>
#include <window_manager/oh_display_manager.h>
#include <string>
#include <thread>
#include <chrono>
#include <vector>
#include <mutex>
#include <set>
#include <filesystem>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using mbgl::harmony::ANRDetector;

namespace mbgl {
namespace harmony {

// ✅ 使用 atomic 计数器准确跟踪活跃实例数
namespace {
    std::atomic<int> g_activeInstanceCount{0};
    std::atomic<int> g_totalInstanceCount{0};  // 总创建数（用于ID）
}

NativeMapView::NativeMapView(napi_env env, napi_value wrapper, const std::string& cachePath) 
    : env_(env), cachePath_(cachePath) {
    // 实例标识（全局计数器，用于多实例调试）
    static std::map<void*, int> globalInstanceIds;
    int instanceId = ++g_totalInstanceCount;
    globalInstanceIds[this] = instanceId;
    
    // ✅ 递增活跃实例计数
    int activeCount = ++g_activeInstanceCount;
    
    // 创建包装器引用
    napi_create_reference(env, wrapper, 1, &wrapper_);
    
    // 初始化成员变量
    mapRenderer = nullptr;
    map = nullptr;
    pixelRatio = 1.0f;
    nativeWindow = nullptr;
    
    // 初始化回调管理器
    callbackManager_ = std::make_unique<mbgl::harmony::CallbackManager>(env);
    Logger::debug("NativeMapView", "[Instance #%d] CallbackManager initialized", instanceId);
    
    Logger::info("NativeMapView", "========== 🗺️ [Instance #%d] NativeMapView constructed (this=%p) ==========", instanceId, this);
    Logger::info("NativeMapView", "[Instance #%d] Cache path: %s", instanceId, cachePath_.c_str());
    Logger::info("NativeMapView", "[Instance #%d] Active instances: %d (Total created: %d)", instanceId, activeCount, instanceId);
    Logger::info("NativeMapView", "[Instance #%d] 多实例支持：每个实例都有独立的 EGL Context 和 Surface", instanceId);
    Logger::info("NativeMapView", "[Instance #%d] 共享资源：所有实例共享进程级别的 EGL Display", instanceId);
}

NativeMapView::~NativeMapView() {
    // 实例标识
    static std::map<void*, int> globalInstanceIds;
    int instanceId = globalInstanceIds[this];
    
    Logger::info("NativeMapView", "========== [Instance #%d] Destructor START (this=%p) ==========", instanceId, this);
    
    // 立即标记对象正在析构，防止回调访问
    isDestroying.store(true, std::memory_order_release);
    Logger::debug("NativeMapView", "[Instance #%d] Marked isDestroying=true", instanceId);
    
    // 确保资源按正确顺序清理
    cleanupAllResources();
    
    Logger::info("NativeMapView", "========== [Instance #%d] Destructor END ==========", instanceId);
}

void NativeMapView::cleanupAllResources() {
    // 同步销毁：阻塞直到渲染线程与资源完全释放
    ANRDetector detector("cleanupAllResources_sync", 100, 2000);

    // 防止重复清理
    if (resourcesCleaned_.exchange(true)) {
        Logger::warn("NativeMapView", "Resources already cleaned (sync), skipping");
        return;
    }

    // 0. 清理回调
    if (callbackManager_) {
        ANRDetector callbackDetector("callbackManager->Clear_sync", 50, 500);
        Logger::debug("NativeMapView", "[sync] Clearing all callbacks...");
        callbackManager_->Clear();
    }

    // 1. 停止渲染并同步退出渲染线程
    if (harmonyRenderer) {
        Logger::info("NativeMapView", "[sync] Stopping HarmonyRenderer and render thread...");
        try {
            harmonyRenderer->cleanup(); // 同步：内部调用 mapRenderThread_->stop() 并 join
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "[sync] Error during HarmonyRenderer cleanup: %s", e.what());
        } catch (...) {
            Logger::error("NativeMapView", "[sync] Unknown error during HarmonyRenderer cleanup");
        }
        harmonyRenderer.reset();
        Logger::info("NativeMapView", "[sync] HarmonyRenderer destroyed");
    }

    // 2. 清理 Map 引用
    if (map) {
        Logger::debug("NativeMapView", "[sync] Clearing Map reference");
        map = nullptr;
    }

    // 3. 其他原生资源
    mapRenderer = nullptr;
    nativeWindow = nullptr;

    // 4. 释放 NAPI 引用
    if (wrapper_) {
        napi_delete_reference(env_, wrapper_);
        wrapper_ = nullptr;
    }

    // 5. 更新计数
    int remaining = --g_activeInstanceCount;
    Logger::info("NativeMapView", "[sync] Resources cleaned up, remaining active instances: %d", remaining);
}

void NativeMapView::cleanupAllResourcesAsync(std::function<void()> onComplete) {
    // 🔍 ANR监控：记录整个清理过程的耗时
    ANRDetector detector("cleanupAllResourcesAsync", 100, 1000);
    
    // 防止重复清理
    if (resourcesCleaned_.exchange(true)) {
        Logger::warn("NativeMapView", "Resources already cleaned, skipping");
        if (onComplete) onComplete();
        return;
    }
    
    Logger::info("NativeMapView", "========== cleanupAllResourcesAsync START (Android/iOS pattern) ==========");
    
    try {
        // 0. 清理所有回调（带ANR监控）
        if (callbackManager_) {
            ANRDetector callbackDetector("callbackManager->Clear", 50, 500);
            Logger::debug("NativeMapView", "Clearing all callbacks...");
            callbackManager_->Clear();
        }
        
        // 1. ✅ 立即停止渲染（参考 iOS destroyDisplayLink 和 Android MapRenderer.onStop()）
        // 关键修复：在异步等待之前先停止渲染，防止 OpenGL attribute location 断言失败
        if (harmonyRenderer) {
            Logger::debug("NativeMapView", "Immediately pausing renderer to stop rendering loop...");
            harmonyRenderer->pause();
            
            // ✅ 等待正在执行的渲染帧完成（参考 Android GLSurfaceView.onPause()）
            // 原因：pause() 只设置标志，正在执行的渲染可能还在访问资源
            // 解决：等待当前帧完成（通常 1-2帧 = 16-33ms）
            Logger::debug("NativeMapView", "Waiting for current render frame to complete...");
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
            Logger::debug("NativeMapView", "Current render frame should be completed");
        }
        
        // 2. 立即取消所有动画（参考 Android cancelTransitions）——必须在渲染线程执行
        if (harmonyRenderer && map) {
            Logger::debug("NativeMapView", "Cancelling all map transitions on render thread...");
            harmonyRenderer->runOnRenderThread([this]() {
                if (map) {
                    try {
                        map->cancelTransitions();
                    } catch (const std::exception& e) {
                        Logger::warn("NativeMapView", "Error cancelling transitions: %s", e.what());
                    }
                }
            });
        }
        
        // 3. 使用异步方式等待所有后台线程完成（参考 Android/iOS）
        if (harmonyRenderer) {
            Logger::debug("NativeMapView", "Waiting for async operations to complete...");
            
            // 使用异步回调而不是硬编码等待
            harmonyRenderer->stopAllRequestsAsync([this, onComplete = std::move(onComplete)]() {
                // 这个回调会在所有异步操作完成后被调用
                Logger::info("NativeMapView", "Async stop completed, continuing cleanup...");
                
                try {
                    // 4. 清理Map对象（参考 iOS destroyCoreObjects 顺序）
                    if (map) {
                        Logger::debug("NativeMapView", "Destroying Map object...");
                        
                        // Note: In new architecture, Map is owned by HarmonyMapRenderThread
                        // NativeMapView just holds a reference
                        Logger::debug("NativeMapView", "Clearing map reference...");
                        map = nullptr;
                        Logger::debug("NativeMapView", "Map destroyed");
                    }
                    
                    // 5. 清理HarmonyRenderer（参考 iOS destroyCoreObjects）
                    if (harmonyRenderer) {
                        Logger::debug("NativeMapView", "Destroying HarmonyRenderer...");
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
                    
                    // ✅ 递减活跃实例计数
                    int remaining = --g_activeInstanceCount;
                    Logger::info("NativeMapView", "Instance cleaned up, remaining active instances: %d", remaining);
                    Logger::info("NativeMapView", "========== cleanupAllResourcesAsync END ==========");
                    
                    // 8. 调用完成回调
                    if (onComplete) {
                        Logger::debug("NativeMapView", "Invoking cleanup completion callback");
                        onComplete();
                    }
                    
                } catch (const std::exception& e) {
                    Logger::error("NativeMapView", "Error during resource cleanup: %s", e.what());
                    // ✅ 即使出错也要递减计数
                    int remaining = --g_activeInstanceCount;
                    Logger::info("NativeMapView", "Instance cleanup failed but counted, remaining: %d", remaining);
                    if (onComplete) onComplete();
                } catch (...) {
                    Logger::error("NativeMapView", "Unknown error during resource cleanup");
                    // ✅ 即使出错也要递减计数
                    int remaining = --g_activeInstanceCount;
                    Logger::info("NativeMapView", "Instance cleanup failed but counted, remaining: %d", remaining);
                    if (onComplete) onComplete();
                }
            });
            
            return; // 异步执行，立即返回
        }
        
        // 如果没有 harmonyRenderer，直接清理其他资源
        Logger::warn("NativeMapView", "No harmonyRenderer, cleaning up immediately");
        
        mapRenderer = nullptr;
        nativeWindow = nullptr;
        
        if (wrapper_) {
            napi_delete_reference(env_, wrapper_);
            wrapper_ = nullptr;
        }
        
        // ✅ 递减活跃实例计数
        int remaining = --g_activeInstanceCount;
        Logger::info("NativeMapView", "Resources cleaned up (no renderer), remaining instances: %d", remaining);
        if (onComplete) onComplete();
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "Error during resource cleanup: %s", e.what());
        // ✅ 即使出错也要递减计数
        int remaining = --g_activeInstanceCount;
        Logger::info("NativeMapView", "Cleanup error, remaining instances: %d", remaining);
        if (onComplete) onComplete();
    } catch (...) {
        Logger::error("NativeMapView", "Unknown error during resource cleanup");
        // ✅ 即使出错也要递减计数
        int remaining = --g_activeInstanceCount;
        Logger::info("NativeMapView", "Cleanup unknown error, remaining instances: %d", remaining);
        if (onComplete) onComplete();
    }
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
        
        // pixelRatio will be determined from device during renderer initialization
        Logger::info("NativeMapView", "Native window set");
        
        Logger::info("NativeMapView", "Initializing with size %dx%d (logical pixels)", width, height);
        
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
        {"getStyle", nullptr, getStyle, nullptr, nullptr, nullptr, napi_default, nullptr},
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
        {"setNativeWindowWithSize", nullptr, setNativeWindowWithSize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"hardReset", nullptr, hardReset, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"destroy", nullptr, destroy, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"destroyAsync", nullptr, destroyAsync, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // ========== 新增方法：对齐 Android/iOS API ==========
        {"setContentPadding", nullptr, setContentPadding, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getContentPadding", nullptr, getContentPadding, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getPixelRatio", nullptr, getPixelRatio, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getDensityDependantRectangle", nullptr, getDensityDependantRectangle, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 相机监听器方法（旧的）
        {"addOnCameraIdleListener", nullptr, addOnCameraIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraIdleListener", nullptr, removeOnCameraIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveStartedListener", nullptr, addOnCameraMoveStartedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveStartedListener", nullptr, removeOnCameraMoveStartedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveListener", nullptr, addOnCameraMoveListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveListener", nullptr, removeOnCameraMoveListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveCanceledListener", nullptr, addOnCameraMoveCanceledListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveCanceledListener", nullptr, removeOnCameraMoveCanceledListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 样式监听器方法（旧的）
        {"setOnStyleLoadedListener", nullptr, setOnStyleLoadedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setOnStyleLoadErrorListener", nullptr, setOnStyleLoadErrorListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // ========== Android/iOS 风格监听器方法 ==========
        
        // 相机事件监听器
        {"addOnCameraWillChangeListener", nullptr, addOnCameraWillChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraWillChangeListener", nullptr, removeOnCameraWillChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraIsChangingListener", nullptr, addOnCameraIsChangingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraIsChangingListener", nullptr, removeOnCameraIsChangingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraDidChangeListener", nullptr, addOnCameraDidChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraDidChangeListener", nullptr, removeOnCameraDidChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 地图加载事件监听器
        {"addOnWillStartLoadingMapListener", nullptr, addOnWillStartLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnWillStartLoadingMapListener", nullptr, removeOnWillStartLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFinishLoadingMapListener", nullptr, addOnDidFinishLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishLoadingMapListener", nullptr, removeOnDidFinishLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFailLoadingMapListener", nullptr, addOnDidFailLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFailLoadingMapListener", nullptr, removeOnDidFailLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 渲染事件监听器
        {"addOnWillStartRenderingFrameListener", nullptr, addOnWillStartRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnWillStartRenderingFrameListener", nullptr, removeOnWillStartRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFinishRenderingFrameListener", nullptr, addOnDidFinishRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishRenderingFrameListener", nullptr, removeOnDidFinishRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnWillStartRenderingMapListener", nullptr, addOnWillStartRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnWillStartRenderingMapListener", nullptr, removeOnWillStartRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFinishRenderingMapListener", nullptr, addOnDidFinishRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishRenderingMapListener", nullptr, removeOnDidFinishRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 样式事件监听器
        {"addOnDidFinishLoadingStyleListener", nullptr, addOnDidFinishLoadingStyleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishLoadingStyleListener", nullptr, removeOnDidFinishLoadingStyleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnStyleImageMissingListener", nullptr, addOnStyleImageMissingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnStyleImageMissingListener", nullptr, removeOnStyleImageMissingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 其他事件监听器
        {"addOnDidBecomeIdleListener", nullptr, addOnDidBecomeIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidBecomeIdleListener", nullptr, removeOnDidBecomeIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnSourceChangedListener", nullptr, addOnSourceChangedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnSourceChangedListener", nullptr, removeOnSourceChangedListener, nullptr, nullptr, nullptr, napi_default, nullptr}
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
napi_value NativeMapView::hardReset(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== hardReset() START ==========");

    NapiArgs args(env, info);

    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    napi_value thisVar;
    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, &thisVar, nullptr);
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "hardReset: Failed to unwrap instance");
        return args.Undefined();
    }

    // 1) 清理现有渲染器与线程
    if (instance->harmonyRenderer) {
        Logger::info("NativeMapView", "hardReset: Cleaning up current HarmonyRenderer");
        try {
            instance->harmonyRenderer->cleanup();
        } catch (...) {
            Logger::warn("NativeMapView", "hardReset: cleanup threw but continuing");
        }
        instance->harmonyRenderer.reset();
    }
    instance->map = nullptr;
    instance->mapRenderer = nullptr;

    // 2) 清理磁盘缓存
    if (!instance->cachePath_.empty()) {
        std::error_code ec;
        Logger::info("NativeMapView", "hardReset: Purging cache directory: %s", instance->cachePath_.c_str());
        std::filesystem::remove_all(instance->cachePath_, ec);
        if (ec) {
            Logger::warn("NativeMapView", "hardReset: remove_all failed: %s", ec.message().c_str());
        }
        // 重新创建目录，避免后续落盘失败
        std::filesystem::create_directories(instance->cachePath_, ec);
    }

    // 3) 重新创建渲染器并初始化
    Logger::info("NativeMapView", "hardReset: Recreating HarmonyRenderer with size %dx%d", instance->width, instance->height);
    instance->harmonyRenderer = std::make_unique<HarmonyRenderer>();
    instance->harmonyRenderer->initialize(instance->width, instance->height, instance->pixelRatio, instance->cachePath_);

    // 4) 重新设置窗口与尺寸
    if (instance->nativeWindow) {
        Logger::info("NativeMapView", "hardReset: Rebinding native window");
        instance->harmonyRenderer->setNativeWindow(instance->nativeWindow);
        if (instance->width > 0 && instance->height > 0) {
            instance->harmonyRenderer->resize(instance->width, instance->height);
        }
    }

    // 5) 重新获取 Map 引用
    instance->map = instance->harmonyRenderer->getMap();
    if (!instance->map) {
        Logger::warn("NativeMapView", "hardReset: getMap() returned null");
    }

    // 6) 触发首帧
    if (instance->harmonyRenderer) {
        instance->harmonyRenderer->requestRender();
    }

    Logger::info("NativeMapView", "========== hardReset() END ==========");
    return args.Undefined();
}


napi_value NativeMapView::New(napi_env env, napi_callback_info info) {
    napi_status status;
    napi_value thisVar;
    size_t argc = 1;
    napi_value args[1];
    
    // 获取this对象和参数
    status = napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "New: Failed to get callback info");
        return nullptr;
    }
    
    // 解析 cachePath 参数（必需）
    if (argc < 1) {
        Logger::error("NativeMapView", "New: Missing required cachePath parameter");
        napi_throw_error(env, nullptr, "NativeMapView constructor requires cachePath parameter");
        return nullptr;
    }
    
    // 获取字符串长度
    size_t strLen = 0;
    status = napi_get_value_string_utf8(env, args[0], nullptr, 0, &strLen);
    if (status != napi_ok || strLen == 0) {
        Logger::error("NativeMapView", "New: Invalid cachePath parameter");
        napi_throw_error(env, nullptr, "cachePath must be a non-empty string");
        return nullptr;
    }
    
    // 读取字符串内容
    std::string cachePath(strLen, '\0');
    status = napi_get_value_string_utf8(env, args[0], &cachePath[0], strLen + 1, &strLen);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "New: Failed to read cachePath string");
        napi_throw_error(env, nullptr, "Failed to read cachePath parameter");
        return nullptr;
    }
    cachePath.resize(strLen);
    
    Logger::info("NativeMapView", "New: Creating instance with cachePath: %s", cachePath.c_str());
    
    // 创建NativeMapView实例
    NativeMapView* nativeMapView = new NativeMapView(env, thisVar, cachePath);
    
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
        Logger::error("NativeMapView", "New: Failed to wrap instance");
        return nullptr;
    }
    
    return thisVar;
}

// MapObserver 方法实现已全部移至 native_map_view_observers.cpp

void NativeMapView::initializeRenderer() {
    Logger::debug("NativeMapView", "initializeRenderer() called - harmonyRenderer=%s, nativeWindow=%s, map=%s", 
                  harmonyRenderer ? "exists" : "null",
                  nativeWindow ? "exists" : "null",
                  map ? "exists" : "null");
    
    // Set SQLite temp path for database operations (must be done before any database access)
    mapbox::sqlite::setTempPath(cachePath_);
    Logger::info("NativeMapView", "SQLite temp path set to: %s", cachePath_.c_str());
    
    // Pre-fetch device DPI before creating Renderer to ensure all components use correct pixelRatio
    if (pixelRatio <= 1.01f) {  // If still default value
        int32_t densityDPI = 160;
        int32_t ret = OH_NativeDisplayManager_GetDefaultDisplayDensityDpi(&densityDPI);
        if (ret == 0) {
            pixelRatio = static_cast<float>(densityDPI) / 160.0f;
            Logger::info("NativeMapView", "Pre-fetched DPI: %d, pixelRatio: %.2f", 
                        densityDPI, pixelRatio);
        } else {
            pixelRatio = 1.0f;
            Logger::warn("NativeMapView", "Failed to pre-fetch DPI, using 1.0");
        }
    }
    
    // Always create a brand-new HarmonyRenderer to guarantee isolation per NativeMapView instance
    if (harmonyRenderer) {
        Logger::info("NativeMapView", "Disposing existing HarmonyRenderer to avoid reuse...");
        try {
            harmonyRenderer->cleanup();
        } catch (...) {
            // best-effort cleanup
        }
        harmonyRenderer.reset();
        map = nullptr; // drop old Map reference tied to previous renderer/thread
    }
    
    harmonyRenderer = std::make_unique<HarmonyRenderer>();
    harmonyRenderer->initialize(width, height, pixelRatio, cachePath_);
    Logger::info("NativeMapView", "HarmonyRenderer initialized fresh with cachePath: %s", cachePath_.c_str());
    
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
    
    // 3. 获取新的 Map 引用（Map 由新的 HarmonyMapRenderThread 所拥有）
    if (harmonyRenderer) {
        Logger::info("NativeMapView", "Acquiring Map reference from fresh HarmonyRenderer...");
        map = harmonyRenderer->getMap();
        if (!map) {
            Logger::error("NativeMapView", "Cannot get Map - HarmonyRenderer returned null");
            return;
        }
        Logger::info("NativeMapView", "Got Map reference: %p", map);
        return;
    } else {
        Logger::warn("NativeMapView", "Cannot create Map - harmonyRenderer is null");
    }
}

void NativeMapView::ensureResourcesReadyOrRecover(int timeoutMs) {
    Logger::info("NativeMapView", "ensureResourcesReadyOrRecover(timeout=%dms) invoked", timeoutMs);
    if (!harmonyRenderer) {
        Logger::warn("NativeMapView", "ensureResourcesReadyOrRecover: no renderer, initializing fresh");
        initializeRenderer();
        return;
    }
    // 快速检查
//    if (harmonyRenderer->isResourcesReady()) {
//        Logger::debug("NativeMapView", "ensureResourcesReadyOrRecover: resources already ready");
//        return;
//    }
    // 等待就绪
    const auto start = std::chrono::steady_clock::now();
    const auto deadline = start + std::chrono::milliseconds(timeoutMs);
//    while (!harmonyRenderer->isResourcesReady() && std::chrono::steady_clock::now() < deadline) {
//        std::this_thread::sleep_for(std::chrono::milliseconds(20));
//    }
//    if (harmonyRenderer->isResourcesReady()) {
//        Logger::info("NativeMapView", "ensureResourcesReadyOrRecover: resources became ready within timeout");
//        return;
//    }
    // 自愈重建
    Logger::warn("NativeMapView", "ensureResourcesReadyOrRecover: resources NOT ready, attempting self-heal reinitialize");
    try {
        harmonyRenderer->cleanup();
    } catch (...) {
        // best effort
    }
    harmonyRenderer.reset();
    map = nullptr;
    harmonyRenderer = std::make_unique<HarmonyRenderer>();
    harmonyRenderer->initialize(width, height, pixelRatio, cachePath_);
    if (nativeWindow) {
        harmonyRenderer->setNativeWindow(nativeWindow);
        if (width > 0 && height > 0) {
            harmonyRenderer->resize(width, height);
        }
    }
    map = harmonyRenderer->getMap();
}


napi_value NativeMapView::destroy(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== destroy() called from TS layer ==========");
    
    NapiArgs args(env, info);
    
    NativeMapView* nativeMapView = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&nativeMapView));
    
    if (nativeMapView) {
        // 防止重复销毁（使用静态集合跟踪已销毁的实例）
        static std::mutex destroyMutex;
        static std::set<void*> destroyedInstances;
        
        {
            std::lock_guard<std::mutex> lock(destroyMutex);
            if (destroyedInstances.find(nativeMapView) != destroyedInstances.end()) {
                Logger::warn("NativeMapView", "Instance %p already destroyed, skipping", nativeMapView);
                return nullptr;
            }
            destroyedInstances.insert(nativeMapView);
        }
        
        Logger::info("NativeMapView", "Calling cleanupAllResources() for instance %p...", nativeMapView);
        nativeMapView->cleanupAllResources();
        Logger::info("NativeMapView", "✅ Resources cleaned up successfully for instance %p", nativeMapView);
    } else {
        Logger::warn("NativeMapView", "Cannot destroy: native instance is null");
    }
    
    return nullptr;
}

napi_value NativeMapView::destroyAsync(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== destroyAsync() called from TS layer (Android/iOS pattern) ==========");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1); // 需要回调函数参数
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "destroyAsync: Missing callback parameter");
        return args.Undefined();
    }
    
    // 获取回调函数
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) {
        Logger::error("NativeMapView", "destroyAsync: Invalid callback parameter");
        return args.Undefined();
    }
    
    NativeMapView* nativeMapView = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&nativeMapView));
    
    if (nativeMapView) {
        // 防止重复销毁
        static std::mutex destroyMutex;
        static std::set<void*> destroyedInstances;
        
        {
            std::lock_guard<std::mutex> lock(destroyMutex);
            if (destroyedInstances.find(nativeMapView) != destroyedInstances.end()) {
                Logger::warn("NativeMapView", "Instance %p already destroyed, skipping", nativeMapView);
                
                // ✅ 使用 ThreadSafeCallback 确保线程安全
                auto tsfn = ThreadSafeCallback::Create(env, callback, "destroyAsync_skip");
                if (tsfn) {
                    tsfn->CallEmpty();
                }
                
                return args.Undefined();
            }
            destroyedInstances.insert(nativeMapView);
        }
        
        Logger::info("NativeMapView", "Calling cleanupAllResourcesAsync() for instance %p...", nativeMapView);
        
        // ✅ 创建 ThreadSafeCallback（线程安全的跨线程回调）
        auto tsfn = ThreadSafeCallback::Create(env, callback, "destroyAsync_complete");
        if (!tsfn) {
            Logger::error("NativeMapView", "Failed to create ThreadSafeCallback");
            return args.Undefined();
        }
        
        // 调用异步清理，传入回调
        // 使用 shared_ptr 确保回调在异步操作完成前不被释放
        auto sharedTsfn = std::shared_ptr<ThreadSafeCallback>(std::move(tsfn));
        
        nativeMapView->cleanupAllResourcesAsync([sharedTsfn]() {
            Logger::info("NativeMapView", "✅ Async cleanup completed, invoking TS callback via ThreadSafeCallback");
            
            // ✅ ThreadSafeCallback 会自动调度到主线程执行
            // 不需要手动调用 napi_call_function
            if (sharedTsfn && sharedTsfn->IsValid()) {
                sharedTsfn->CallEmpty();
            } else {
                Logger::warn("NativeMapView", "ThreadSafeCallback is invalid or released");
            }
        });
        
        Logger::info("NativeMapView", "Async cleanup initiated");
    } else {
        Logger::warn("NativeMapView", "Cannot destroy: native instance is null");
    }
    
    return args.Undefined();
}

// ========== 新增方法：对齐 Android/iOS API ==========

/**
 * 设置内容边距
 * 对齐 Android: setContentPadding(double[] padding)
 */
napi_value NativeMapView::setContentPadding(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "setContentPadding() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    napi_value paddingArray = args.GetArray(0, "padding");
    if (args.HasError()) return args.Undefined();
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setContentPadding: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // 解析数组 [top, left, bottom, right]
    uint32_t length = 0;
    napi_status status = napi_get_array_length(env, paddingArray, &length);
    if (status != napi_ok || length != 4) {
        napi_throw_error(env, nullptr, "Padding array must have exactly 4 elements [top, left, bottom, right]");
        return args.Undefined();
    }
    
    for (uint32_t i = 0; i < 4; i++) {
        napi_value element;
        if (napi_get_element(env, paddingArray, i, &element) != napi_ok) {
            napi_throw_error(env, nullptr, "Failed to get padding array element");
            return args.Undefined();
        }
        
        double value;
        if (napi_get_value_double(env, element, &value) != napi_ok) {
            napi_throw_error(env, nullptr, "Padding array elements must be numbers");
            return args.Undefined();
        }
        
        instance->contentPadding_[i] = value;
    }
    
    Logger::info("NativeMapView", "setContentPadding: [top=%.1f, left=%.1f, bottom=%.1f, right=%.1f]",
                 instance->contentPadding_[0], instance->contentPadding_[1],
                 instance->contentPadding_[2], instance->contentPadding_[3]);
    
    return args.Undefined();
}

/**
 * 获取内容边距
 * 对齐 Android: getContentPadding()
 */
napi_value NativeMapView::getContentPadding(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getContentPadding() called");
    
    NapiArgs args(env, info);
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getContentPadding: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // 创建返回数组 [top, left, bottom, right]
    napi_value result;
    napi_create_array_with_length(env, 4, &result);
    
    for (uint32_t i = 0; i < 4; i++) {
        napi_value element;
        napi_create_double(env, instance->contentPadding_[i], &element);
        napi_set_element(env, result, i, element);
    }
    
    Logger::debug("NativeMapView", "getContentPadding: [%.1f, %.1f, %.1f, %.1f]",
                  instance->contentPadding_[0], instance->contentPadding_[1],
                  instance->contentPadding_[2], instance->contentPadding_[3]);
    
    return result;
}

/**
 * 获取设备像素比
 * 对齐 Android: getPixelRatio()
 * 对齐 iOS: contentScaleFactor
 */
napi_value NativeMapView::getPixelRatio(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getPixelRatio() called");
    
    NapiArgs args(env, info);
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getPixelRatio: Failed to unwrap instance");
        return args.Undefined();
    }
    
    napi_value result;
    napi_create_double(env, instance->pixelRatio, &result);
    
    Logger::debug("NativeMapView", "getPixelRatio: %.2f", instance->pixelRatio);
    
    return result;
}

/**
 * 根据设备像素比调整矩形尺寸
 * 对齐 Android: getDensityDependantRectangle(RectF rectangle)
 */
napi_value NativeMapView::getDensityDependantRectangle(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getDensityDependantRectangle() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    napi_value rectObj = args.GetObject(0, "rectangle");
    if (args.HasError()) return args.Undefined();
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getDensityDependantRectangle: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // 读取矩形的属性
    double left = args.GetDoubleProperty(rectObj, "left", 0.0);
    double top = args.GetDoubleProperty(rectObj, "top", 0.0);
    double right = args.GetDoubleProperty(rectObj, "right", 0.0);
    double bottom = args.GetDoubleProperty(rectObj, "bottom", 0.0);
    
    // 根据像素比调整
    double pixelRatio = instance->pixelRatio;
    
    // 创建返回对象
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value leftValue, topValue, rightValue, bottomValue;
    napi_create_double(env, left / pixelRatio, &leftValue);
    napi_create_double(env, top / pixelRatio, &topValue);
    napi_create_double(env, right / pixelRatio, &rightValue);
    napi_create_double(env, bottom / pixelRatio, &bottomValue);
    
    napi_set_named_property(env, result, "left", leftValue);
    napi_set_named_property(env, result, "top", topValue);
    napi_set_named_property(env, result, "right", rightValue);
    napi_set_named_property(env, result, "bottom", bottomValue);
    
    Logger::debug("NativeMapView", "getDensityDependantRectangle: Input=[%.1f,%.1f,%.1f,%.1f], Output=[%.1f,%.1f,%.1f,%.1f] (pixelRatio=%.2f)",
                  left, top, right, bottom,
                  left/pixelRatio, top/pixelRatio, right/pixelRatio, bottom/pixelRatio,
                  pixelRatio);
    
    return result;
}

} // namespace harmony
} // namespace mbgl
