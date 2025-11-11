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

// Include Harmony renderer headers
#include "rendering/harmony_renderer.hpp"
#include "rendering/backends/harmony_renderer_backend.hpp"
#include "rendering/backends/harmony_gl_renderer_backend.hpp"
#include "napi/core/napi_utils.h"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "utils/anr_detector.hpp"
#include "core/thread_safe_callback.hpp"

// Geometry conversion helpers
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "geometry/rect_harmony.hpp"

// Camera type conversion
#include "camera/camera_position_harmony.hpp"

// Style type conversion
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

// ✅ Use atomic counters to accurately track active instances
namespace {
    std::atomic<int> g_activeInstanceCount{0};
    std::atomic<int> g_totalInstanceCount{0};  // Total instances created (used for IDs)
}

NativeMapView::NativeMapView(napi_env env, napi_value wrapper, const std::string& cachePath) 
    : env_(env), cachePath_(cachePath) {
    // Instance identifier (global counter used for multi-instance debugging)
    static std::map<void*, int> globalInstanceIds;
    int instanceId = ++g_totalInstanceCount;
    globalInstanceIds[this] = instanceId;
    
    // ✅ Increment the active instance count
    int activeCount = ++g_activeInstanceCount;
    
    // Create the wrapper reference
    napi_create_reference(env, wrapper, 1, &wrapper_);
    
    // Initialize member fields
    mapRenderer = nullptr;
    map = nullptr;
    pixelRatio = 1.0f;
    nativeWindow = nullptr;
    
    // Initialize the callback manager
    callbackManager_ = std::make_unique<mbgl::harmony::CallbackManager>(env);
}

NativeMapView::~NativeMapView() {
    // Immediately mark destruction to prevent callbacks from touching the object
    isDestroying.store(true, std::memory_order_release);
    
    // Ensure resources are released in order
    cleanupAllResources();
}

void NativeMapView::cleanupAllResources() {
    // Synchronous teardown: block until the render thread and resources are fully released
    ANRDetector detector("cleanupAllResources_sync", 100, 2000);

    // Prevent duplicate cleanup
    if (resourcesCleaned_.exchange(true)) {
        Logger::warn("NativeMapView", "Resources already cleaned (sync), skipping");
        return;
    }

    // 0. Clear callbacks
    if (callbackManager_) {
        ANRDetector callbackDetector("callbackManager->Clear_sync", 50, 500);
        callbackManager_->Clear();
    }

    // 1. Stop rendering and join the render thread synchronously
    if (harmonyRenderer) {
        try {
            harmonyRenderer->cleanup(); // Synchronous: internally calls mapRenderThread_->stop() and join
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "[sync] Error during HarmonyRenderer cleanup: %s", e.what());
        } catch (...) {
            Logger::error("NativeMapView", "[sync] Unknown error during HarmonyRenderer cleanup");
        }
        harmonyRenderer.reset();
    }

    // 2. Clear the Map reference
    if (map) {
        map = nullptr;
    }

    // 3. Other native resources
    mapRenderer = nullptr;
    nativeWindow = nullptr;

    // 4. Release NAPI references
    if (styleRef_) {
        napi_delete_reference(env_, styleRef_);
        styleRef_ = nullptr;
    }
    if (wrapper_) {
        napi_delete_reference(env_, wrapper_);
        wrapper_ = nullptr;
    }

    // 5. Update counters
    --g_activeInstanceCount;
}

void NativeMapView::cleanupAllResourcesAsync(std::function<void()> onComplete) {
    // 🔍 ANR monitoring: record elapsed time for the full cleanup path
    ANRDetector detector("cleanupAllResourcesAsync", 100, 1000);
    
    // Prevent duplicate cleanup
    if (resourcesCleaned_.exchange(true)) {
        Logger::warn("NativeMapView", "Resources already cleaned, skipping");
        if (onComplete) onComplete();
        return;
    }
    
    try {
        // 0. Clear all callbacks (with ANR monitoring)
        if (callbackManager_) {
            ANRDetector callbackDetector("callbackManager->Clear", 50, 500);
            callbackManager_->Clear();
        }
        
        // 1. ✅ Stop rendering immediately (mirrors iOS destroyDisplayLink and Android MapRenderer.onStop())
        // Critical fix: halt rendering before waiting asynchronously to avoid OpenGL attribute assertions
        if (harmonyRenderer) {
            harmonyRenderer->pause();
            
            // ✅ Wait for the in-flight frame to finish (see Android GLSurfaceView.onPause())
            // Reason: pause() only flips a flag; the active frame may still touch resources
            // Fix: give the current frame time to finish (typically 1-2 frames = 16-33 ms)
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
        }
        
        // 2. Cancel all animations immediately (mirrors Android cancelTransitions) — must run on the render thread
        if (harmonyRenderer && map) {
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
        
        // 3. Wait for background work asynchronously (aligned with Android/iOS)
        if (harmonyRenderer) {
            // Use an asynchronous callback rather than a hard-coded wait
            harmonyRenderer->stopAllRequestsAsync([this, onComplete = std::move(onComplete)]() {
                try {
                    // 4. Clean up Map objects (following the iOS destroyCoreObjects order)
                    if (map) {
                        // Note: In the current architecture, HarmonyMapRenderThread owns Map
                        // NativeMapView simply holds a reference
                        map = nullptr;
                    }
                    
                    // 5. Clean up HarmonyRenderer (mirrors iOS destroyCoreObjects)
                    if (harmonyRenderer) {
                        harmonyRenderer.reset();
                    }
                    
                    // 6. Clean up remaining resources
                    mapRenderer = nullptr;
                    nativeWindow = nullptr;
                    
                    // 7. Release NAPI references
                    if (styleRef_) {
                        napi_delete_reference(env_, styleRef_);
                        styleRef_ = nullptr;
                    }
                    if (wrapper_) {
                        napi_delete_reference(env_, wrapper_);
                        wrapper_ = nullptr;
                    }
                    
                    // ✅ Decrement the active instance count
                    --g_activeInstanceCount;
                    
                    // 8. Invoke the completion callback
                    if (onComplete) {
                        onComplete();
                    }
                    
                } catch (const std::exception& e) {
                    Logger::error("NativeMapView", "Error during resource cleanup: %s", e.what());
                    // ✅ Even on errors, decrement the counter
                    --g_activeInstanceCount;
                    if (onComplete) onComplete();
                } catch (...) {
                    Logger::error("NativeMapView", "Unknown error during resource cleanup");
                    // ✅ Even on errors, decrement the counter
                    --g_activeInstanceCount;
                    if (onComplete) onComplete();
                }
            });
            
            return; // Kick off asynchronously and return immediately
        }
        
        // If harmonyRenderer is missing, clean up the remaining resources immediately
        Logger::warn("NativeMapView", "No harmonyRenderer, cleaning up immediately");
        
        mapRenderer = nullptr;
        nativeWindow = nullptr;

        if (styleRef_) {
            napi_delete_reference(env_, styleRef_);
            styleRef_ = nullptr;
        }
        
        if (wrapper_) {
            napi_delete_reference(env_, wrapper_);
            wrapper_ = nullptr;
        }
        
        // ✅ Decrement the active instance count
        --g_activeInstanceCount;
        if (onComplete) onComplete();
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "Error during resource cleanup: %s", e.what());
        // ✅ Decrement the counter even if an error occurs
        --g_activeInstanceCount;
        if (onComplete) onComplete();
    } catch (...) {
        Logger::error("NativeMapView", "Unknown error during resource cleanup");
        // ✅ Decrement the counter even if an error occurs
        --g_activeInstanceCount;
        if (onComplete) onComplete();
    }
}


void NativeMapView::setNativeWindowWithSize(int64_t surfaceId, int width, int height) {
    // Update stored dimensions
    this->width = width;
    this->height = height;
    
    // Create the native window
    OHNativeWindow *nativeWindow;
    OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &nativeWindow);
    
    if (nativeWindow) {
        this->nativeWindow = nativeWindow;
        
        // Initialize the renderer if it has not been set up yet
        this->initializeRenderer();
    } else {
        Logger::error("NativeMapView", "Failed to create native window from surface ID");
    }
}

void NativeMapView::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<NativeMapView*>(nativeObject);
}


napi_value NativeMapView::Init(napi_env env, napi_value exports) {
    napi_status status;
    napi_value cons;
    
    // Define all instance methods
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
        {"addViewAnnotation", nullptr, addViewAnnotation, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"updateViewAnnotation", nullptr, updateViewAnnotation, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeViewAnnotation", nullptr, removeViewAnnotation, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getViewAnnotationFrames", nullptr, getViewAnnotationFrames, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onLowMemory", nullptr, onLowMemory, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setDebug", nullptr, setDebug, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getDebug", nullptr, getDebug, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setDebugActive", nullptr, setDebugActive, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isDebugActive", nullptr, isDebugActive, nullptr, nullptr, nullptr, napi_default, nullptr},
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
        {"queryRenderedFeaturesForPoint", nullptr, queryRenderedFeaturesForPoint, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"queryRenderedFeaturesForBox", nullptr, queryRenderedFeaturesForBox, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"querySourceFeatures", nullptr, querySourceFeatures, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setMaximumFps", nullptr, setMaximumFps, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setRenderingRefreshMode", nullptr, setRenderingRefreshMode, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getRenderingRefreshMode", nullptr, getRenderingRefreshMode, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setOnFpsChangedListener", nullptr, setOnFpsChangedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
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
        
        // ========== Additional methods aligned with Android/iOS APIs ==========
        {"setContentPadding", nullptr, setContentPadding, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getContentPadding", nullptr, getContentPadding, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getPixelRatio", nullptr, getPixelRatio, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getDensityDependantRectangle", nullptr, getDensityDependantRectangle, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Local font configuration
        {"setLocalIdeographFontFamily", nullptr, setLocalIdeographFontFamily, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLocalIdeographFontFamily", nullptr, getLocalIdeographFontFamily, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Legacy camera listener methods
        {"addOnCameraIdleListener", nullptr, addOnCameraIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraIdleListener", nullptr, removeOnCameraIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveStartedListener", nullptr, addOnCameraMoveStartedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveStartedListener", nullptr, removeOnCameraMoveStartedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveListener", nullptr, addOnCameraMoveListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveListener", nullptr, removeOnCameraMoveListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraMoveCanceledListener", nullptr, addOnCameraMoveCanceledListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraMoveCanceledListener", nullptr, removeOnCameraMoveCanceledListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Map lifecycle listener methods
        {"setOnMapViewCreatedCallback", nullptr, setOnMapViewCreatedCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Legacy style listener methods
        {"setOnStyleLoadedListener", nullptr, setOnStyleLoadedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setOnStyleLoadErrorListener", nullptr, setOnStyleLoadErrorListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // ========== Android/iOS-style listener methods ==========
        
        // Camera event listeners
        {"addOnCameraWillChangeListener", nullptr, addOnCameraWillChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraWillChangeListener", nullptr, removeOnCameraWillChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraIsChangingListener", nullptr, addOnCameraIsChangingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraIsChangingListener", nullptr, removeOnCameraIsChangingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnCameraDidChangeListener", nullptr, addOnCameraDidChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnCameraDidChangeListener", nullptr, removeOnCameraDidChangeListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Map loading event listeners
        {"addOnWillStartLoadingMapListener", nullptr, addOnWillStartLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnWillStartLoadingMapListener", nullptr, removeOnWillStartLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFinishLoadingMapListener", nullptr, addOnDidFinishLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishLoadingMapListener", nullptr, removeOnDidFinishLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFailLoadingMapListener", nullptr, addOnDidFailLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFailLoadingMapListener", nullptr, removeOnDidFailLoadingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Rendering event listeners
        {"addOnWillStartRenderingFrameListener", nullptr, addOnWillStartRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnWillStartRenderingFrameListener", nullptr, removeOnWillStartRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFinishRenderingFrameListener", nullptr, addOnDidFinishRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishRenderingFrameListener", nullptr, removeOnDidFinishRenderingFrameListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnWillStartRenderingMapListener", nullptr, addOnWillStartRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnWillStartRenderingMapListener", nullptr, removeOnWillStartRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnDidFinishRenderingMapListener", nullptr, addOnDidFinishRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishRenderingMapListener", nullptr, removeOnDidFinishRenderingMapListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Style event listeners
        {"addOnDidFinishLoadingStyleListener", nullptr, addOnDidFinishLoadingStyleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidFinishLoadingStyleListener", nullptr, removeOnDidFinishLoadingStyleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnStyleImageMissingListener", nullptr, addOnStyleImageMissingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnStyleImageMissingListener", nullptr, removeOnStyleImageMissingListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Miscellaneous event listeners
        {"addOnDidBecomeIdleListener", nullptr, addOnDidBecomeIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnDidBecomeIdleListener", nullptr, removeOnDidBecomeIdleListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnSourceChangedListener", nullptr, addOnSourceChangedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnSourceChangedListener", nullptr, removeOnSourceChangedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        // Observer event listeners (Shader, Glyph, Sprite, Tile)
        {"addOnPreCompileShaderListener", nullptr, addOnPreCompileShaderListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnPreCompileShaderListener", nullptr, removeOnPreCompileShaderListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnPostCompileShaderListener", nullptr, addOnPostCompileShaderListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnPostCompileShaderListener", nullptr, removeOnPostCompileShaderListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnShaderCompileFailedListener", nullptr, addOnShaderCompileFailedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnShaderCompileFailedListener", nullptr, removeOnShaderCompileFailedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        {"addOnGlyphsLoadedListener", nullptr, addOnGlyphsLoadedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnGlyphsLoadedListener", nullptr, removeOnGlyphsLoadedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnGlyphsErrorListener", nullptr, addOnGlyphsErrorListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnGlyphsErrorListener", nullptr, removeOnGlyphsErrorListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnGlyphsRequestedListener", nullptr, addOnGlyphsRequestedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnGlyphsRequestedListener", nullptr, removeOnGlyphsRequestedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        {"addOnSpriteLoadedListener", nullptr, addOnSpriteLoadedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnSpriteLoadedListener", nullptr, removeOnSpriteLoadedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnSpriteErrorListener", nullptr, addOnSpriteErrorListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnSpriteErrorListener", nullptr, removeOnSpriteErrorListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addOnSpriteRequestedListener", nullptr, addOnSpriteRequestedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnSpriteRequestedListener", nullptr, removeOnSpriteRequestedListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        
        {"addOnTileActionListener", nullptr, addOnTileActionListener, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeOnTileActionListener", nullptr, removeOnTileActionListener, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    // Define the class constructor and supply all property descriptors
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
    
    // Store a reference to the constructor using a static variable
    static napi_ref static_wrapper;
    status = napi_create_reference(env, cons, 1, &static_wrapper);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "Failed to create reference to constructor");
        return nullptr;
    }
    
    // Set up the exports object
    status = napi_set_named_property(env, exports, "NativeMapView", cons);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "Failed to export NativeMapView");
        return nullptr;
    }
    
    return exports;
}
napi_value NativeMapView::hardReset(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    napi_value thisVar;
    size_t argc = 0;
    napi_get_cb_info(env, info, &argc, nullptr, &thisVar, nullptr);
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "hardReset: Failed to unwrap instance");
        return args.Undefined();
    }

    // 1) Clean up the existing renderer and thread
    if (instance->harmonyRenderer) {
        try {
            instance->harmonyRenderer->cleanup();
        } catch (...) {
            Logger::warn("NativeMapView", "hardReset: cleanup threw but continuing");
        }
        instance->harmonyRenderer.reset();
    }
    instance->map = nullptr;
    instance->mapRenderer = nullptr;

    // 2) Clear disk cache
    if (!instance->cachePath_.empty()) {
        std::error_code ec;
        std::filesystem::remove_all(instance->cachePath_, ec);
        if (ec) {
            Logger::warn("NativeMapView", "hardReset: remove_all failed: %s", ec.message().c_str());
        }
        // Recreate the directory to avoid later persistence failures
        std::filesystem::create_directories(instance->cachePath_, ec);
    }

    // 3) Recreate and initialize the renderer
    instance->harmonyRenderer = std::make_unique<HarmonyRenderer>();
    instance->harmonyRenderer->initialize(instance->width, instance->height, instance->pixelRatio, instance->cachePath_,
                                         instance->localIdeographFontFamily_);

    // 4) Reapply window and dimensions
    if (instance->nativeWindow) {
        instance->harmonyRenderer->setNativeWindow(instance->nativeWindow);
        if (instance->width > 0 && instance->height > 0) {
            instance->harmonyRenderer->resize(instance->width, instance->height);
        }
    }

    // 5) Refresh the Map reference
    instance->map = instance->harmonyRenderer->getMap();
    if (!instance->map) {
        Logger::warn("NativeMapView", "hardReset: getMap() returned null");
    }

    // 6) Trigger the first frame
    if (instance->harmonyRenderer) {
        instance->harmonyRenderer->requestRender();
    }

    return args.Undefined();
}


napi_value NativeMapView::New(napi_env env, napi_callback_info info) {
    napi_status status;
    napi_value thisVar;
    size_t argc = 1;
    napi_value args[1];
    
    // Retrieve the this object and arguments
    status = napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "New: Failed to get callback info");
        return nullptr;
    }
    
    // Parse the required cachePath parameter
    if (argc < 1) {
        Logger::error("NativeMapView", "New: Missing required cachePath parameter");
        napi_throw_error(env, nullptr, "NativeMapView constructor requires cachePath parameter");
        return nullptr;
    }
    
    // Get the string length
    size_t strLen = 0;
    status = napi_get_value_string_utf8(env, args[0], nullptr, 0, &strLen);
    if (status != napi_ok || strLen == 0) {
        Logger::error("NativeMapView", "New: Invalid cachePath parameter");
        napi_throw_error(env, nullptr, "cachePath must be a non-empty string");
        return nullptr;
    }
    
    // Read the string contents
    std::string cachePath(strLen, '\0');
    status = napi_get_value_string_utf8(env, args[0], &cachePath[0], strLen + 1, &strLen);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "New: Failed to read cachePath string");
        napi_throw_error(env, nullptr, "Failed to read cachePath parameter");
        return nullptr;
    }
    cachePath.resize(strLen);
    
    // Create the NativeMapView instance
    NativeMapView* nativeMapView = new NativeMapView(env, thisVar, cachePath);
    
    // Attach the NativeMapView instance as external data
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

// MapObserver method implementations are defined in native_map_view_observers.cpp

void NativeMapView::initializeRenderer() {
    // Set SQLite temp path for database operations (must be done before any database access)
    mapbox::sqlite::setTempPath(cachePath_);
    
    // Pre-fetch device DPI before creating Renderer to ensure all components use correct pixelRatio
    if (pixelRatio <= 1.01f) {  // If still default value
        int32_t densityDPI = 160;
        int32_t ret = OH_NativeDisplayManager_GetDefaultDisplayDensityDpi(&densityDPI);
        if (ret == 0) {
            pixelRatio = static_cast<float>(densityDPI) / 160.0f;
            Logger::info("NativeMapView", "🔍 [DPI] Calculated pixelRatio: densityDPI=%d, pixelRatio=%.2f", densityDPI, pixelRatio);
        } else {
            pixelRatio = 1.0f;
            Logger::warn("NativeMapView", "⚠️ [DPI] Failed to get densityDPI, using default pixelRatio=1.0");
        }
    } else {
        Logger::info("NativeMapView", "🔍 [DPI] Using pre-set pixelRatio=%.2f", pixelRatio);
    }
    
    // Always create a brand-new HarmonyRenderer to guarantee isolation per NativeMapView instance
    if (harmonyRenderer) {
        try {
            harmonyRenderer->cleanup();
        } catch (...) {
            // best-effort cleanup
        }
        harmonyRenderer.reset();
        map = nullptr; // drop old Map reference tied to previous renderer/thread
    }
    
    harmonyRenderer = std::make_unique<HarmonyRenderer>();
    
    // ✅ Provide the NativeMapView reference so HarmonyRenderer can forward MapObserver events
    harmonyRenderer->setNativeMapView(this);
    Logger::info("NativeMapView", "NativeMapView registered to HarmonyRenderer for event forwarding");
    
    harmonyRenderer->initialize(width, height, pixelRatio, cachePath_, localIdeographFontFamily_);
    
    // 2. Bind the window if one is available
    if (nativeWindow && harmonyRenderer) {
        harmonyRenderer->setNativeWindow(nativeWindow);
    } else {
        Logger::warn("NativeMapView", "Cannot set native window");
    }
    
    // 3. Obtain the new Map reference (owned by the new HarmonyMapRenderThread)
    if (harmonyRenderer) {
        map = harmonyRenderer->getMap();
        if (!map) {
            Logger::error("NativeMapView", "Cannot get Map - HarmonyRenderer returned null");
            return;
        }
        
        // ✅ New behavior: once the Map is constructed, fire the onMapViewCreated callback
        // At this point the C++ Map exists, allowing ArkTS to create MapLibreMap and register observers
        // Matches Android behavior: trigger before style loading so listeners can be registered
        if (callbackManager_) {
            callbackManager_->InvokeCallbackEmpty("onMapViewCreated");
            Logger::info("NativeMapView", "✅ Triggered onMapViewCreated callback");
        } else {
            Logger::warn("NativeMapView", "⚠️ CallbackManager is null, cannot trigger onMapViewCreated");
        }
    } else {
        Logger::warn("NativeMapView", "Cannot create Map - harmonyRenderer is null");
    }
}

void NativeMapView::ensureResourcesReadyOrRecover(int timeoutMs) {
    if (!harmonyRenderer) {
        Logger::warn("NativeMapView", "ensureResourcesReadyOrRecover: no renderer, initializing fresh");
        initializeRenderer();
        return;
    }
    
    // Wait for readiness
    const auto start = std::chrono::steady_clock::now();
    const auto deadline = start + std::chrono::milliseconds(timeoutMs);
    
    // Self-healing reconstruction
    Logger::warn("NativeMapView", "ensureResourcesReadyOrRecover: resources NOT ready, attempting self-heal reinitialize");
    try {
        harmonyRenderer->cleanup();
    } catch (...) {
        // best effort
    }
    harmonyRenderer.reset();
    map = nullptr;
    harmonyRenderer = std::make_unique<HarmonyRenderer>();
    
    // ✅ Provide the NativeMapView reference
    harmonyRenderer->setNativeMapView(this);
    
    harmonyRenderer->initialize(width, height, pixelRatio, cachePath_, localIdeographFontFamily_);
    if (nativeWindow) {
        harmonyRenderer->setNativeWindow(nativeWindow);
        if (width > 0 && height > 0) {
            harmonyRenderer->resize(width, height);
        }
    }
    map = harmonyRenderer->getMap();
    
    // ✅ After self-healing, also trigger the onMapViewCreated callback
    if (map && callbackManager_) {
        callbackManager_->InvokeCallbackEmpty("onMapViewCreated");
        Logger::info("NativeMapView", "✅ Triggered onMapViewCreated callback (after recovery)");
    }
}

// ========== Local font configuration (Harmony-specific) ==========

/**
 * Configure the local ideograph font family.
 *
 * Harmony implementation details:
 * - Uses the OH_Drawing_TextBlob API for glyph rendering.
 * - Supports automatic fallback (TextBlob feature).
 * - LocalGlyphRasterizer receives the font family, so the renderer must be reinitialized.
 *
 * Reference:
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/textblock-drawing-c
 *
 * @param fontFamily Font family (e.g., "HarmonyOS Sans"); null disables local rendering.
 */
napi_value NativeMapView::setLocalIdeographFontFamily(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "setLocalIdeographFontFamily: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Parse the fontFamily argument (string | null)
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Validate the argument type
    napi_valuetype valueType;
    napi_typeof(env, args.GetValue(0), &valueType);
    
    if (valueType == napi_null || valueType == napi_undefined) {
        // A null value disables local glyph rendering
        instance->localIdeographFontFamily_ = std::nullopt;
        Logger::info("NativeMapView", "setLocalIdeographFontFamily: Local glyph rendering disabled");
    } else if (valueType == napi_string) {
        // Extract the font family name
        std::string fontFamily = args.GetString(0, "fontFamily");
        if (args.HasError()) {
            return args.Undefined();
        }
        
        // Ensure the font family name is not empty
        if (fontFamily.empty()) {
            Logger::info("NativeMapView", "setLocalIdeographFontFamily: Empty font family, treating as disabled");
            instance->localIdeographFontFamily_ = std::nullopt;
        } else {
            instance->localIdeographFontFamily_ = fontFamily;
            Logger::info("NativeMapView", "setLocalIdeographFontFamily: Font family set to '%s' (HarmonyOS TextBlob)", 
                        fontFamily.c_str());
        }
    } else {
        Logger::error("NativeMapView", "setLocalIdeographFontFamily: Invalid parameter type");
        napi_throw_type_error(env, nullptr, "fontFamily must be a string or null");
        return args.Undefined();
    }
    
    // Reinitialize the renderer so the new font configuration takes effect.
    //
    // Rationale:
    // 1. LocalGlyphRasterizer is instantiated when RenderOrchestrator is constructed.
    // 2. The font family is passed into the LocalGlyphRasterizer constructor.
    // 3. LocalGlyphRasterizer renders glyphs via the OH_Drawing_TextBlob API.
    // 4. GlyphManager caches rendered glyphs, so we must rebuild.
    //
    // This mirrors the Android/iOS implementations, which also recreate the renderer.
    try {
        Logger::info("NativeMapView", "setLocalIdeographFontFamily: Reinitializing renderer with new font config...");
        
        // Save the current map state
        std::string currentStyleUrl = instance->styleUrl;
        
        // Reinitialize the renderer, creating a new RenderOrchestrator -> GlyphManager -> LocalGlyphRasterizer
        instance->initializeRenderer();
        
        // Restore the style (glyphs are re-rasterized automatically)
        if (!currentStyleUrl.empty() && instance->map) {
            instance->map->getStyle().loadURL(currentStyleUrl);
            Logger::info("NativeMapView", "setLocalIdeographFontFamily: Style reloaded, glyphs will be re-rasterized");
        }
        
        Logger::info("NativeMapView", "setLocalIdeographFontFamily: Renderer reinitialized successfully");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setLocalIdeographFontFamily: Failed to reinitialize renderer: %s", e.what());
        napi_throw_error(env, nullptr, "Failed to apply font family change");
        return args.Undefined();
    }
    
    return args.Undefined();
}

/**
 * Retrieve the configured local ideograph font family.
 *
 * @returns Font family (e.g., "HarmonyOS Sans"); null means disabled.
 */
napi_value NativeMapView::getLocalIdeographFontFamily(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "getLocalIdeographFontFamily: Failed to unwrap instance");
        return args.Null();
    }
    
    // Return the current font family
    if (instance->localIdeographFontFamily_) {
        napi_value result;
        napi_create_string_utf8(env, instance->localIdeographFontFamily_->c_str(), 
                               NAPI_AUTO_LENGTH, &result);
        return result;
    } else {
        return args.Null();
    }
}

napi_value NativeMapView::destroy(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    NativeMapView* nativeMapView = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&nativeMapView));
    
    if (nativeMapView) {
        // Prevent double destruction (tracked via a static set)
        static std::mutex destroyMutex;
        static std::set<void*> destroyedInstances;
        
        {
            std::lock_guard<std::mutex> lock(destroyMutex);
            if (destroyedInstances.find(nativeMapView) != destroyedInstances.end()) {
                Logger::warn("NativeMapView", "Instance already destroyed, skipping");
                return nullptr;
            }
            destroyedInstances.insert(nativeMapView);
        }
        
        nativeMapView->cleanupAllResources();
    } else {
        Logger::warn("NativeMapView", "Cannot destroy: native instance is null");
    }
    
    return nullptr;
}

napi_value NativeMapView::destroyAsync(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1); // Require a callback argument
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "destroyAsync: Missing callback parameter");
        return args.Undefined();
    }
    
    // Retrieve the callback
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) {
        Logger::error("NativeMapView", "destroyAsync: Invalid callback parameter");
        return args.Undefined();
    }
    
    NativeMapView* nativeMapView = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&nativeMapView));
    
    if (nativeMapView) {
        // Prevent double destruction
        static std::mutex destroyMutex;
        static std::set<void*> destroyedInstances;
        
        {
            std::lock_guard<std::mutex> lock(destroyMutex);
            if (destroyedInstances.find(nativeMapView) != destroyedInstances.end()) {
                Logger::warn("NativeMapView", "Instance already destroyed, skipping");
                
                // ✅ Use ThreadSafeCallback to ensure thread-safety
                auto tsfn = ThreadSafeCallback::Create(env, callback, "destroyAsync_skip");
                if (tsfn) {
                    tsfn->CallEmpty();
                }
                
                return args.Undefined();
            }
            destroyedInstances.insert(nativeMapView);
        }
        
        // ✅ Create a ThreadSafeCallback for cross-thread invocation
        auto tsfn = ThreadSafeCallback::Create(env, callback, "destroyAsync_complete");
        if (!tsfn) {
            Logger::error("NativeMapView", "Failed to create ThreadSafeCallback");
            return args.Undefined();
        }
        
        // Launch asynchronous cleanup with the callback.
        // Use shared_ptr to keep the callback alive until cleanup completes.
        auto sharedTsfn = std::shared_ptr<ThreadSafeCallback>(std::move(tsfn));
        
        nativeMapView->cleanupAllResourcesAsync([sharedTsfn]() {
            // ✅ ThreadSafeCallback dispatches on the main thread automatically
            // No manual napi_call_function invocation is required
            if (sharedTsfn && sharedTsfn->IsValid()) {
                sharedTsfn->CallEmpty();
            } else {
                Logger::warn("NativeMapView", "ThreadSafeCallback is invalid or released");
            }
        });
    } else {
        Logger::warn("NativeMapView", "Cannot destroy: native instance is null");
    }
    
    return args.Undefined();
}

// ========== Additional methods aligned with Android/iOS APIs ==========

/**
 * Set content padding.
 * Matches Android: setContentPadding(double[] padding)
 */
napi_value NativeMapView::setContentPadding(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    napi_value paddingArray = args.GetArray(0, "padding");
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setContentPadding: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Parse the array [left, top, right, bottom]
    uint32_t length = 0;
    napi_status status = napi_get_array_length(env, paddingArray, &length);
    if (status != napi_ok || length != 4) {
        napi_throw_error(env, nullptr, "Padding array must have exactly 4 elements [left, top, right, bottom]");
        return args.Undefined();
    }
    
    std::array<double, 4> newPadding;
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
        
        newPadding[i] = value;
    }
    
    // Store the new padding values [left, top, right, bottom]
    instance->contentPadding_ = newPadding;
    
    Logger::info("NativeMapView", "setContentPadding: [%.1f, %.1f, %.1f, %.1f]",
                 newPadding[0], newPadding[1], newPadding[2], newPadding[3]);
    
    // Android behavior: padding normally takes effect on the next camera operation.
    // For immediate feedback, trigger a camera update now.
    if (instance->map) {
        // Build EdgeInsets (constructor order: top, left, bottom, right)
        // contentPadding_ storage order: [0]=left, [1]=top, [2]=right, [3]=bottom
        mbgl::EdgeInsets paddingInsets{
            newPadding[1] * instance->pixelRatio, // top = newPadding[1]
            newPadding[0] * instance->pixelRatio, // left = newPadding[0]
            newPadding[3] * instance->pixelRatio, // bottom = newPadding[3]
            newPadding[2] * instance->pixelRatio   // right = newPadding[2]
        };
        
        Logger::info("NativeMapView", "setContentPadding: Logical padding=[%.1f, %.1f, %.1f, %.1f]",
                     newPadding[0], newPadding[1], newPadding[2], newPadding[3]);
        Logger::info("NativeMapView", "setContentPadding: Physical padding (×%.2f): top=%.1f, left=%.1f, bottom=%.1f, right=%.1f",
                     instance->pixelRatio,
                     paddingInsets.top(), paddingInsets.left(),
                     paddingInsets.bottom(), paddingInsets.right());
        
        // Capture the current camera state before applying padding
        auto currentCamera = instance->map->getCameraOptions();
        Logger::info("NativeMapView", "setContentPadding: Current camera - lat=%.6f, lng=%.6f, zoom=%.2f",
                     currentCamera.center ? currentCamera.center->latitude() : 0,
                     currentCamera.center ? currentCamera.center->longitude() : 0,
                     currentCamera.zoom ? *currentCamera.zoom : 0);
        
        // Build new camera options.
        // Key point: keep the camera center (lat/lon) unchanged while applying padding.
        // MapLibre adjusts the view so that the coordinate remains at the logical center.
        CameraOptions newCamera;
        newCamera.center = currentCamera.center;
        newCamera.zoom = currentCamera.zoom;
        newCamera.bearing = currentCamera.bearing;
        newCamera.pitch = currentCamera.pitch;
        newCamera.padding = paddingInsets;
        
        // Apply on the render thread.
        // Use jumpTo for immediate effect (no animation).
        instance->invokeOnMapThread([newCamera](mbgl::Map* m) {
            Logger::info("NativeMapView", "setContentPadding: Executing jumpTo on render thread");
            m->jumpTo(newCamera);
            m->triggerRepaint();
            Logger::info("NativeMapView", "setContentPadding: jumpTo completed, repaint triggered");
        });
        
        Logger::info("NativeMapView", "setContentPadding: Camera update scheduled");
    } else {
        Logger::warn("NativeMapView", "setContentPadding: Map not initialized, padding will be applied on next camera operation");
    }
    
    return args.Undefined();
}

/**
 * Retrieve the current content padding.
 * Aligns with Android: getContentPadding()
 */
napi_value NativeMapView::getContentPadding(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getContentPadding: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Build the return array [left, top, right, bottom]
    napi_value result;
    napi_create_array_with_length(env, 4, &result);
    
    for (uint32_t i = 0; i < 4; i++) {
        napi_value element;
        napi_create_double(env, instance->contentPadding_[i], &element);
        napi_set_element(env, result, i, element);
    }
    
    return result;
}

/**
 * Retrieve the device pixel ratio.
 * Aligns with Android: getPixelRatio()
 * Aligns with iOS: contentScaleFactor
 */
napi_value NativeMapView::getPixelRatio(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getPixelRatio: Failed to unwrap instance");
        return args.Undefined();
    }
    
    napi_value result;
    napi_create_double(env, instance->pixelRatio, &result);
    
    return result;
}

/**
 * Adjust a rectangle according to the device pixel ratio.
 * Aligns with Android: getDensityDependantRectangle(RectF rectangle)
 */
napi_value NativeMapView::getDensityDependantRectangle(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    napi_value rectObj = args.GetObject(0, "rectangle");
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getDensityDependantRectangle: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Read rectangle properties
    double left = args.GetDoubleProperty(rectObj, "left", 0.0);
    double top = args.GetDoubleProperty(rectObj, "top", 0.0);
    double right = args.GetDoubleProperty(rectObj, "right", 0.0);
    double bottom = args.GetDoubleProperty(rectObj, "bottom", 0.0);
    
    // Apply the pixel ratio adjustment
    double pixelRatio = instance->pixelRatio;
    
    // Create the return object
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
    
    return result;
}

} // namespace harmony
} // namespace mbgl
