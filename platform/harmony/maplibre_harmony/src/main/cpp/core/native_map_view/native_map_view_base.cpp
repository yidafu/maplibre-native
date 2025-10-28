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
#include "rendering/harmony_renderer_frontend.hpp"
#include "rendering/backends/harmony_renderer_backend.hpp"
#include "rendering/backends/harmony_gl_renderer_backend.hpp"
#include "napi/core/napi_utils.h"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

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

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

NativeMapView::NativeMapView(napi_env env, napi_value wrapper) : env_(env) {
    // 实例标识（全局计数器，用于多实例调试）
    static int globalInstanceCounter = 0;
    static std::map<void*, int> globalInstanceIds;
    globalInstanceIds[this] = ++globalInstanceCounter;
    int instanceId = globalInstanceIds[this];
    
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
    Logger::info("NativeMapView", "[Instance #%d] Total active instances: %d", instanceId, globalInstanceCounter);
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
    // 防止重复清理
    if (resourcesCleaned_.exchange(true)) {
        Logger::warn("NativeMapView", "Resources already cleaned, skipping");
        return;
    }
    
    Logger::info("NativeMapView", "========== cleanupAllResources START ==========");
    
    try {
        // 0. 清理所有回调
        if (callbackManager_) {
            Logger::debug("NativeMapView", "Clearing all callbacks...");
            callbackManager_->Clear();
        }
        
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
        {"destroy", nullptr, destroy, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 相机监听器方法
        {"addOnCameraIdleListener", nullptr, addOnCameraIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraIdleListener", nullptr, removeOnCameraIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveStartedListener", nullptr, addOnCameraMoveStartedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveStartedListener", nullptr, removeOnCameraMoveStartedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveListener", nullptr, addOnCameraMoveListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveListener", nullptr, removeOnCameraMoveListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveCanceledListener", nullptr, addOnCameraMoveCanceledListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveCanceledListener", nullptr, removeOnCameraMoveCanceledListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // 样式监听器方法
        {"setOnStyleLoadedListener", nullptr, setOnStyleLoadedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setOnStyleLoadErrorListener", nullptr, setOnStyleLoadErrorListener, nullptr, nullptr, nullptr, napi_default, nullptr}
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

// MapObserver 方法实现已全部移至 native_map_view_observers.cpp

void NativeMapView::initializeRenderer() {
    Logger::debug("NativeMapView", "initializeRenderer() called - harmonyRenderer=%s, nativeWindow=%s, map=%s", 
                  harmonyRenderer ? "exists" : "null",
                  nativeWindow ? "exists" : "null",
                  map ? "exists" : "null");
    
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
    
    // Create HarmonyRenderer (if not exists)
    if (!harmonyRenderer) {
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
            Logger::info("NativeMapView", "🔍 [DPI] MapOptions configured:");
            Logger::info("NativeMapView", "  - Size: %dx%d (logical pixels)", width, height);
            Logger::info("NativeMapView", "  - PixelRatio: %.4f", pixelRatio);
            Logger::info("NativeMapView", "  - Expected framebuffer (physical): %dx%d", 
                        static_cast<int>(width * pixelRatio),
                        static_cast<int>(height * pixelRatio));
            
            // Configure ResourceOptions
            // 🔧 关键架构：使用统一的 platformContext，使所有实例共享 FileSource
            // 参考 Android 和 iOS 的实现：
            // - Android: FileSource.getInstance() 单例，所有 MapView 共享
            // - iOS: MLNOfflineStorage.sharedOfflineStorage，所有 MapView 共享
            // 
            // 共享 FileSource 的优势：
            // 1. 第一个实例下载并缓存资源
            // 2. 后续实例直接使用缓存，快速加载
            // 3. 减少内存占用和网络请求
            // 4. FileSourceManager 内部有互斥锁，保证线程安全
            ResourceOptions resourceOptions;
            std::string cachePath = "/data/storage/el2/base/cache";
            
            // 使用统一的标识：进程级别的单例指针
            // 这样所有 Map 实例都会使用相同的 FileSource 实例和缓存
            static void* sharedPlatformContext = reinterpret_cast<void*>(0x1);
            
            resourceOptions.withCachePath(cachePath + "/mbgl_cache.db")
                          .withAssetPath(cachePath)
                          .withPlatformContext(sharedPlatformContext); // 统一的 context，共享 FileSource
            
            Logger::info("NativeMapView", "ResourceOptions configured with SHARED FileSource (Android/iOS pattern)");
            Logger::debug("NativeMapView", "  Cache path: %s/mbgl_cache.db", cachePath.c_str());
            Logger::debug("NativeMapView", "  Shared context: %p (all instances use same FileSource)", sharedPlatformContext);
            
            // Configure ClientOptions
            ClientOptions clientOptions;
            clientOptions.withName("MapLibre Harmony")
                         .withVersion("1.0.0");
            Logger::debug("NativeMapView", "ClientOptions configured");
            
            // Create Map object
            Logger::error("NativeMapView", "🔴🔴🔴 Creating Map object with NativeMapView as Observer 🔴🔴🔴");
            Logger::error("NativeMapView", "  NativeMapView Observer pointer: %p", this);
            
            map = std::make_unique<Map>(
                *rendererFrontend,
                *this,  // NativeMapView 作为 MapObserver
                mapOptions,
                resourceOptions,
                clientOptions
            );
            
            Logger::error("NativeMapView", "✅✅✅ Map object created successfully: %p", map.get());
            Logger::error("NativeMapView", "✅ Observer should be: %p (this NativeMapView instance)", this);
            
            // 🔍 诊断：验证 FileSource 是否共享
            try {
                auto fileSourceManager = FileSourceManager::get();
                auto onlineFileSource = fileSourceManager->getFileSource(
                    FileSourceType::Network,
                    resourceOptions,
                    clientOptions
                );
                auto databaseFileSource = fileSourceManager->getFileSource(
                    FileSourceType::Database,
                    resourceOptions,
                    clientOptions
                );
                
                Logger::info("NativeMapView", "🔍 FileSource Diagnostic Info:");
                Logger::info("NativeMapView", "  ✅ OnlineFileSource: %p (should be SAME for all instances)", onlineFileSource.get());
                Logger::info("NativeMapView", "  ✅ DatabaseFileSource: %p (should be SAME for all instances)", databaseFileSource.get());
                Logger::info("NativeMapView", "  platformContext: %p", sharedPlatformContext);
                
                if (onlineFileSource) {
                    Logger::info("NativeMapView", "  OnlineFileSource is VALID and ready");
                } else {
                    Logger::error("NativeMapView", "  ❌ OnlineFileSource is NULL!");
                }
                
                if (databaseFileSource) {
                    Logger::info("NativeMapView", "  DatabaseFileSource is VALID and ready");
                } else {
                    Logger::error("NativeMapView", "  ❌ DatabaseFileSource is NULL!");
                }
            } catch (const std::exception& e) {
                Logger::error("NativeMapView", "FileSource verification failed: %s", e.what());
            }
            
            // Verify RunLoop exists for network requests
            auto* currentRunLoop = util::RunLoop::Get();
            if (!currentRunLoop) {
                Logger::error("NativeMapView", "RunLoop is NULL - network requests will fail!");
            } else {
                Logger::info("NativeMapView", "RunLoop is available: %p", currentRunLoop);
            }
            
            // Connect Map to RendererFrontend
            auto* frontend = harmonyRenderer->getRendererFrontend();
            if (frontend) {
                frontend->setMap(map.get());
            } else {
                Logger::error("NativeMapView", "Failed to get RendererFrontend");
            }
            
            // Connect Map to HarmonyRenderer (for Transform size updates during resize)
            harmonyRenderer->setMap(map.get());
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "Failed to create Map object: %s", e.what());
        }
    } else if (map) {
        Logger::debug("NativeMapView", "Map already exists, skipping creation");
    } else {
        Logger::warn("NativeMapView", "Cannot create Map - harmonyRenderer is null");
    }
}


napi_value NativeMapView::destroy(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== destroy() called from TS layer ==========");
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    NativeMapView* nativeMapView = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&nativeMapView));
    
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

} // namespace harmony
} // namespace mbgl
