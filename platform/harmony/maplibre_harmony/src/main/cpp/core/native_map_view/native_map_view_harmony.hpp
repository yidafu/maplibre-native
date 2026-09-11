#ifndef MAPLIBREHARMONY_NATIVE_MAP_VIEW_HARMONY_HPP
#define MAPLIBREHARMONY_NATIVE_MAP_VIEW_HARMONY_HPP

#include "rendering/backends/harmony_renderer_backend.hpp"
#include "rendering/harmony_renderer.hpp"
#include "core/callback_manager.hpp"
#include "core/gesture/native_gesture_manager.hpp"
#include "core/map_registry.hpp"
#include <mbgl/map/map.hpp>
#include <mbgl/tile/tile_operation.hpp>
#include <mbgl/util/geometry.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/size.hpp>
#include <mbgl/util/constants.hpp>

#include <string>
#include <memory>
#include <future>
#include <chrono>
#include <type_traits>
#include <atomic>
#include <js_native_api.h>
#include <unordered_map>
#include <mutex>
#include <vector>

namespace mbgl {
namespace harmony {

class FileSource;
class MapRenderer;
class RenderingStats;

struct HarmonyViewAnnotation {
    int64_t id = 0;
    mbgl::LatLng anchor;
    mbgl::Size size{0, 0};
    mbgl::ScreenCoordinate offset{0.0, 0.0};
    double anchorHeight = 0;  // Height for anchor positioning (separate from render size)
    double anchorU = 0.5;     // Horizontal anchor (0=left, 0.5=center, 1=right)
    double anchorV = 1.0;     // Vertical anchor (0=top, 0.5=center, 1=bottom)
    bool visible = true;
    bool allowOverlap = false;
    bool draggable = false;
    bool scalesWithViewingDistance = false;
    bool rotatesWithCamera = false;
    double minZoom = 0.0;
    double maxZoom = mbgl::util::DEFAULT_MAX_ZOOM;
};

struct HarmonyViewAnnotationFrame {
    int64_t id = 0;
    mbgl::ScreenCoordinate screen{0.0, 0.0};
    mbgl::Size size{0, 0};
    mbgl::ScreenCoordinate offset{0.0, 0.0};
    double scale = 1.0;
    double rotation = 0.0;
    double opacity = 1.0;
    double pixelRatio = 1.0;
    double positionX = 0.0;  // Final render X in logical pixels (screen.x/pixelRatio - w*anchorU)
    double positionY = 0.0;  // Final render Y in logical pixels (screen.y/pixelRatio - h*anchorV)
    bool visible = true;
    bool draggable = false;
};

class NativeMapView : public MapObserver {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    NativeMapView(napi_env env, napi_value wrapper, const std::string& cachePath);
    virtual ~NativeMapView();
    
    // Resource cleanup helpers
    void cleanupAllResources();
    
    // Asynchronous resource cleanup (mirrors Android/iOS destruction flow)
    // onComplete: callback invoked when cleanup finishes
    void cleanupAllResourcesAsync(std::function<void()> onComplete);
    
    // Explicit resource destruction (invoked from TS layer)
    static napi_value destroy(napi_env env, napi_callback_info info);
    
    // Asynchronous destruction (invoked from TS layer, supports callback)
    static napi_value destroyAsync(napi_env env, napi_callback_info info);

    // Set up native gesture recognizers (replaces ArkTS MapGestureDetector)
    // @param frameNode FrameNode of the XComponent (obtained via UIContext.getFrameNodeById)
    static napi_value setupNativeGestures(napi_env env, napi_callback_info info);

    // Set the native window along with size parameters
    void setNativeWindowWithSize(int64_t surfaceId, int width, int height);

    double getPixelRatioValue() const {
        return static_cast<double>(pixelRatio);
    }

    // mbgl::RendererBackend (mbgl::MapObserver) //
    void onCameraWillChange(MapObserver::CameraChangeMode) override;
    void onCameraIsChanging() override;
    void onCameraDidChange(MapObserver::CameraChangeMode) override;
    void onWillStartLoadingMap() override;
    void onDidFinishLoadingMap() override;
    void onDidFailLoadingMap(MapLoadError, const std::string&) override;
    void onWillStartRenderingFrame() override;
    void onDidFinishRenderingFrame(const MapObserver::RenderFrameStatus&) override;
    void onWillStartRenderingMap() override;
    void onDidFinishRenderingMap(MapObserver::RenderMode) override;
    void onDidBecomeIdle() override;
    void onDidFinishLoadingStyle() override;
    void onSourceChanged(mbgl::style::Source&) override;
    void onStyleImageMissing(const std::string&) override;
    bool onCanRemoveUnusedStyleImage(const std::string&) override;

    // N-API methods //
    static napi_value resizeView(napi_env env, napi_callback_info info);
    static napi_value getStyleUrl(napi_env env, napi_callback_info info);
    static napi_value setStyleUrl(napi_env env, napi_callback_info info);
    static napi_value getStyleJson(napi_env env, napi_callback_info info);
    static napi_value setStyleJson(napi_env env, napi_callback_info info);
    static napi_value setLatLngBounds(napi_env env, napi_callback_info info);
    static napi_value cancelTransitions(napi_env env, napi_callback_info info);
    static napi_value setGestureInProgress(napi_env env, napi_callback_info info);
    static napi_value moveBy(napi_env env, napi_callback_info info);
    static napi_value jumpTo(napi_env env, napi_callback_info info);
    static napi_value easeTo(napi_env env, napi_callback_info info);
    static napi_value flyTo(napi_env env, napi_callback_info info);
    static napi_value getLatLng(napi_env env, napi_callback_info info);
    static napi_value setLatLng(napi_env env, napi_callback_info info);
    static napi_value getCameraForLatLngBounds(napi_env env, napi_callback_info info);
    static napi_value getCameraForGeometry(napi_env env, napi_callback_info info);
    static napi_value setReachability(napi_env env, napi_callback_info info);
    static napi_value resetPosition(napi_env env, napi_callback_info info);
    static napi_value getPitch(napi_env env, napi_callback_info info);
    static napi_value setPitch(napi_env env, napi_callback_info info);
    static napi_value setZoom(napi_env env, napi_callback_info info);
    static napi_value getZoom(napi_env env, napi_callback_info info);
    static napi_value resetZoom(napi_env env, napi_callback_info info);
    static napi_value setMinZoom(napi_env env, napi_callback_info info);
    static napi_value getMinZoom(napi_env env, napi_callback_info info);
    static napi_value setMaxZoom(napi_env env, napi_callback_info info);
    static napi_value getMaxZoom(napi_env env, napi_callback_info info);
    static napi_value setMinPitch(napi_env env, napi_callback_info info);
    static napi_value getMinPitch(napi_env env, napi_callback_info info);
    static napi_value setMaxPitch(napi_env env, napi_callback_info info);
    static napi_value getMaxPitch(napi_env env, napi_callback_info info);
    static napi_value rotateBy(napi_env env, napi_callback_info info);
    static napi_value setBearing(napi_env env, napi_callback_info info);
    static napi_value setBearingXY(napi_env env, napi_callback_info info);
    static napi_value getBearing(napi_env env, napi_callback_info info);
    static napi_value getCameraState(napi_env env, napi_callback_info info);
    static napi_value resetNorth(napi_env env, napi_callback_info info);
    static napi_value setVisibleCoordinateBounds(napi_env env, napi_callback_info info);
    static napi_value getVisibleCoordinateBounds(napi_env env, napi_callback_info info);
    static napi_value scheduleSnapshot(napi_env env, napi_callback_info info);
    static napi_value getCameraPosition(napi_env env, napi_callback_info info);
    static napi_value updateMarker(napi_env env, napi_callback_info info);
    static napi_value addMarkers(napi_env env, napi_callback_info info);
    static napi_value addViewAnnotation(napi_env env, napi_callback_info info);
    static napi_value updateViewAnnotation(napi_env env, napi_callback_info info);
    static napi_value removeViewAnnotation(napi_env env, napi_callback_info info);
    static napi_value getViewAnnotationFrames(napi_env env, napi_callback_info info);
    static napi_value setViewAnnotationFramesListener(napi_env env, napi_callback_info info);
    static napi_value onLowMemory(napi_env env, napi_callback_info info);
    
    // Rendering Frame listener with stats
    static napi_value addOnDidFinishRenderingFrameWithStatsListener(napi_env env, napi_callback_info info);
    static napi_value removeOnDidFinishRenderingFrameWithStatsListener(napi_env env, napi_callback_info info);

    // Debug methods
    static napi_value setDebug(napi_env env, napi_callback_info info);
    static napi_value getDebug(napi_env env, napi_callback_info info);
    static napi_value setDebugActive(napi_env env, napi_callback_info info);
    static napi_value isDebugActive(napi_env env, napi_callback_info info);

    // Renderer diagnostics: active backend name + GPU description
    static napi_value getRendererInfo(napi_env env, napi_callback_info info);
    
    static napi_value getActionJournalLogFiles(napi_env env, napi_callback_info info);
    static napi_value getActionJournalLog(napi_env env, napi_callback_info info);
    static napi_value clearActionJournalLog(napi_env env, napi_callback_info info);
    static napi_value isFullyLoaded(napi_env env, napi_callback_info info);
    static napi_value getStyle(napi_env env, napi_callback_info info);
    static napi_value getMetersPerPixelAtLatitude(napi_env env, napi_callback_info info);
    static napi_value projectedMetersForLatLng(napi_env env, napi_callback_info info);
    static napi_value pixelForLatLng(napi_env env, napi_callback_info info);
    static napi_value pixelsForLatLngs(napi_env env, napi_callback_info info);
    static napi_value latLngForProjectedMeters(napi_env env, napi_callback_info info);
    static napi_value latLngForPixel(napi_env env, napi_callback_info info);
    static napi_value latLngsForPixels(napi_env env, napi_callback_info info);
    static napi_value addPolylines(napi_env env, napi_callback_info info);
    static napi_value addPolygons(napi_env env, napi_callback_info info);
    static napi_value updatePolyline(napi_env env, napi_callback_info info);
    static napi_value updatePolygon(napi_env env, napi_callback_info info);
    static napi_value removeAnnotations(napi_env env, napi_callback_info info);
    static napi_value addAnnotationIcon(napi_env env, napi_callback_info info);
    static napi_value removeAnnotationIcon(napi_env env, napi_callback_info info);
    static napi_value getTopOffsetPixelsForAnnotationSymbol(napi_env env, napi_callback_info info);
    static napi_value getTransitionOptions(napi_env env, napi_callback_info info);
    static napi_value setTransitionOptions(napi_env env, napi_callback_info info);
    static napi_value queryRenderedFeaturesForPoint(napi_env env, napi_callback_info info);
    static napi_value queryRenderedFeaturesForBox(napi_env env, napi_callback_info info);
    static napi_value querySourceFeatures(napi_env env, napi_callback_info info);
    
    // Performance configuration APIs (aligned with Android MapRenderer)
    static napi_value setMaximumFps(napi_env env, napi_callback_info info);
    static napi_value setRenderingRefreshMode(napi_env env, napi_callback_info info);
    static napi_value getRenderingRefreshMode(napi_env env, napi_callback_info info);
    static napi_value setOnFpsChangedListener(napi_env env, napi_callback_info info);
    static napi_value getLight(napi_env env, napi_callback_info info);
    static napi_value getLayers(napi_env env, napi_callback_info info);
    static napi_value getLayer(napi_env env, napi_callback_info info);
    static napi_value addLayer(napi_env env, napi_callback_info info);
    static napi_value addLayerAbove(napi_env env, napi_callback_info info);
    static napi_value addLayerAt(napi_env env, napi_callback_info info);
    static napi_value removeLayerAt(napi_env env, napi_callback_info info);
    static napi_value removeLayer(napi_env env, napi_callback_info info);
    static napi_value getSources(napi_env env, napi_callback_info info);
    static napi_value getSource(napi_env env, napi_callback_info info);
    static napi_value addSource(napi_env env, napi_callback_info info);
    static napi_value removeSource(napi_env env, napi_callback_info info);
    static napi_value addImage(napi_env env, napi_callback_info info);
    static napi_value addImages(napi_env env, napi_callback_info info);
    static napi_value removeImage(napi_env env, napi_callback_info info);
    static napi_value getImage(napi_env env, napi_callback_info info);
    static napi_value setPrefetchTiles(napi_env env, napi_callback_info info);
    static napi_value getPrefetchTiles(napi_env env, napi_callback_info info);
    static napi_value setPrefetchZoomDelta(napi_env env, napi_callback_info info);
    static napi_value getPrefetchZoomDelta(napi_env env, napi_callback_info info);
    static napi_value setTileCacheEnabled(napi_env env, napi_callback_info info);
    static napi_value getTileCacheEnabled(napi_env env, napi_callback_info info);
    static napi_value setTileLodMinRadius(napi_env env, napi_callback_info info);
    static napi_value getTileLodMinRadius(napi_env env, napi_callback_info info);
    static napi_value setTileLodScale(napi_env env, napi_callback_info info);
    static napi_value getTileLodScale(napi_env env, napi_callback_info info);
    static napi_value setTileLodPitchThreshold(napi_env env, napi_callback_info info);
    static napi_value getTileLodPitchThreshold(napi_env env, napi_callback_info info);
    static napi_value setTileLodZoomShift(napi_env env, napi_callback_info info);
    static napi_value getTileLodZoomShift(napi_env env, napi_callback_info info);
    static napi_value triggerRepaint(napi_env env, napi_callback_info info);
    static napi_value isRenderingStatsViewEnabled(napi_env env, napi_callback_info info);
    static napi_value enableRenderingStatsView(napi_env env, napi_callback_info info);
    static napi_value setNativeWindow(napi_env env, napi_callback_info info);
    static napi_value setNativeWindowWithSize(napi_env env, napi_callback_info info);
    static napi_value hardReset(napi_env env, napi_callback_info info);

    /**
     * Cancel all pending network requests.
     *
     * This method cancels all ongoing HTTP requests to prevent callbacks from
     * accessing destroyed objects during page transitions. This is critical
     * for preventing SIGSEGV crashes when the map is destroyed.
     */
    static napi_value cancelAllRequests(napi_env env, napi_callback_info info);

    // Shader compilation
    void onRegisterShaders(mbgl::gfx::ShaderRegistry&) override;
    void onPreCompileShader(mbgl::shaders::BuiltIn, mbgl::gfx::Backend::Type, const std::string&) override;
    void onPostCompileShader(mbgl::shaders::BuiltIn, mbgl::gfx::Backend::Type, const std::string&) override;
    void onShaderCompileFailed(mbgl::shaders::BuiltIn, mbgl::gfx::Backend::Type, const std::string&) override;

    // Glyph requests
    void onGlyphsLoaded(const mbgl::FontStack&, const mbgl::GlyphRange&) override;
    void onGlyphsError(const mbgl::FontStack&, const mbgl::GlyphRange&, std::exception_ptr) override;
    void onGlyphsRequested(const mbgl::FontStack&, const mbgl::GlyphRange&) override;

    // Tile requests
    void onTileAction(mbgl::TileOperation, const mbgl::OverscaledTileID&, const std::string&) override;

    // Sprite requests
    void onSpriteLoaded(const std::optional<mbgl::style::Sprite>&) override;
    void onSpriteError(const std::optional<mbgl::style::Sprite>&, std::exception_ptr) override;
    void onSpriteRequested(const std::optional<mbgl::style::Sprite>&) override;
    
    // Gesture listener management (map click / long-click)
    static napi_value addOnMapClickListener(napi_env env, napi_callback_info info);
    static napi_value removeOnMapClickListener(napi_env env, napi_callback_info info);
    static napi_value addOnMapLongClickListener(napi_env env, napi_callback_info info);
    static napi_value removeOnMapLongClickListener(napi_env env, napi_callback_info info);

    // Camera listener management
    static napi_value addOnCameraIdleListener(napi_env env, napi_callback_info info);
    static napi_value removeOnCameraIdleListener(napi_env env, napi_callback_info info);
    static napi_value addOnCameraMoveStartedListener(napi_env env, napi_callback_info info);
    static napi_value removeOnCameraMoveStartedListener(napi_env env, napi_callback_info info);
    static napi_value addOnCameraMoveListener(napi_env env, napi_callback_info info);
    static napi_value removeOnCameraMoveListener(napi_env env, napi_callback_info info);
    static napi_value addOnCameraMoveCanceledListener(napi_env env, napi_callback_info info);
    static napi_value removeOnCameraMoveCanceledListener(napi_env env, napi_callback_info info);
    
    // Map lifecycle listener management
    static napi_value setOnMapViewCreatedCallback(napi_env env, napi_callback_info info);
    
    // Style listener management
    static napi_value setOnStyleLoadedListener(napi_env env, napi_callback_info info);
    static napi_value setOnStyleLoadErrorListener(napi_env env, napi_callback_info info);
    
    // ========== Additional Android/iOS-style listeners ==========
    
    // Camera event listeners (Android-style)
    static napi_value addOnCameraWillChangeListener(napi_env env, napi_callback_info info);
    static napi_value removeOnCameraWillChangeListener(napi_env env, napi_callback_info info);
    static napi_value addOnCameraIsChangingListener(napi_env env, napi_callback_info info);
    static napi_value removeOnCameraIsChangingListener(napi_env env, napi_callback_info info);
    static napi_value addOnCameraDidChangeListener(napi_env env, napi_callback_info info);
    static napi_value removeOnCameraDidChangeListener(napi_env env, napi_callback_info info);
    
    // Map loading event listeners
    static napi_value addOnWillStartLoadingMapListener(napi_env env, napi_callback_info info);
    static napi_value removeOnWillStartLoadingMapListener(napi_env env, napi_callback_info info);
    static napi_value addOnDidFinishLoadingMapListener(napi_env env, napi_callback_info info);
    static napi_value removeOnDidFinishLoadingMapListener(napi_env env, napi_callback_info info);
    static napi_value addOnDidFailLoadingMapListener(napi_env env, napi_callback_info info);
    static napi_value removeOnDidFailLoadingMapListener(napi_env env, napi_callback_info info);
    
    // Rendering event listeners
    static napi_value addOnWillStartRenderingFrameListener(napi_env env, napi_callback_info info);
    static napi_value removeOnWillStartRenderingFrameListener(napi_env env, napi_callback_info info);
    static napi_value addOnDidFinishRenderingFrameListener(napi_env env, napi_callback_info info);
    static napi_value removeOnDidFinishRenderingFrameListener(napi_env env, napi_callback_info info);
    static napi_value addOnWillStartRenderingMapListener(napi_env env, napi_callback_info info);
    static napi_value removeOnWillStartRenderingMapListener(napi_env env, napi_callback_info info);
    static napi_value addOnDidFinishRenderingMapListener(napi_env env, napi_callback_info info);
    static napi_value removeOnDidFinishRenderingMapListener(napi_env env, napi_callback_info info);
    static napi_value addOnSnapshotReadyListener(napi_env env, napi_callback_info info);
    static napi_value removeOnSnapshotReadyListener(napi_env env, napi_callback_info info);
    static napi_value addOnSnapshotErrorListener(napi_env env, napi_callback_info info);
    static napi_value removeOnSnapshotErrorListener(napi_env env, napi_callback_info info);
    
    // Style event listeners (Android-style)
    static napi_value addOnDidFinishLoadingStyleListener(napi_env env, napi_callback_info info);
    static napi_value removeOnDidFinishLoadingStyleListener(napi_env env, napi_callback_info info);
    static napi_value addOnStyleImageMissingListener(napi_env env, napi_callback_info info);
    static napi_value removeOnStyleImageMissingListener(napi_env env, napi_callback_info info);
    
    // Other event listeners
    static napi_value addOnDidBecomeIdleListener(napi_env env, napi_callback_info info);
    static napi_value removeOnDidBecomeIdleListener(napi_env env, napi_callback_info info);
    static napi_value addOnSourceChangedListener(napi_env env, napi_callback_info info);
    static napi_value removeOnSourceChangedListener(napi_env env, napi_callback_info info);
    
    // Observer event listeners (Shader, Glyph, Sprite, Tile)
    static napi_value addOnPreCompileShaderListener(napi_env env, napi_callback_info info);
    static napi_value removeOnPreCompileShaderListener(napi_env env, napi_callback_info info);
    static napi_value addOnPostCompileShaderListener(napi_env env, napi_callback_info info);
    static napi_value removeOnPostCompileShaderListener(napi_env env, napi_callback_info info);
    static napi_value addOnShaderCompileFailedListener(napi_env env, napi_callback_info info);
    static napi_value removeOnShaderCompileFailedListener(napi_env env, napi_callback_info info);
    
    static napi_value addOnGlyphsLoadedListener(napi_env env, napi_callback_info info);
    static napi_value removeOnGlyphsLoadedListener(napi_env env, napi_callback_info info);
    static napi_value addOnGlyphsErrorListener(napi_env env, napi_callback_info info);
    static napi_value removeOnGlyphsErrorListener(napi_env env, napi_callback_info info);
    static napi_value addOnGlyphsRequestedListener(napi_env env, napi_callback_info info);
    static napi_value removeOnGlyphsRequestedListener(napi_env env, napi_callback_info info);
    
    static napi_value addOnSpriteLoadedListener(napi_env env, napi_callback_info info);
    static napi_value removeOnSpriteLoadedListener(napi_env env, napi_callback_info info);
    static napi_value addOnSpriteErrorListener(napi_env env, napi_callback_info info);
    static napi_value removeOnSpriteErrorListener(napi_env env, napi_callback_info info);
    static napi_value addOnSpriteRequestedListener(napi_env env, napi_callback_info info);
    static napi_value removeOnSpriteRequestedListener(napi_env env, napi_callback_info info);
    
    static napi_value addOnTileActionListener(napi_env env, napi_callback_info info);
    static napi_value removeOnTileActionListener(napi_env env, napi_callback_info info);
    
    // ========== Additional methods to align with Android/iOS APIs ==========
    
    // Content padding
    static napi_value setContentPadding(napi_env env, napi_callback_info info);
    static napi_value getContentPadding(napi_env env, napi_callback_info info);
    
    // Pixel ratio
    static napi_value getPixelRatio(napi_env env, napi_callback_info info);
    static napi_value getDensityDependantRectangle(napi_env env, napi_callback_info info);
    
    // Local glyph configuration
    static napi_value setLocalIdeographFontFamily(napi_env env, napi_callback_info info);
    static napi_value getLocalIdeographFontFamily(napi_env env, napi_callback_info info);
    
    // Helper methods for notifying style listeners
    void notifyStyleLoaded();
    void notifyStyleLoadError(const std::string& error);
    
    // ✅ Thread-safety helpers
    bool isOnRenderThread() const;
    void runOnRenderThread(std::function<void()>&& fn);

private:
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    static napi_value ensureStyleWrapper(napi_env env, NativeMapView* instance);
    friend bool CallStyleMethod(napi_env env,
                                NativeMapView* instance,
                                const char* methodName,
                                size_t argc,
                                napi_value* argv);

    mbgl::Map& getMap();

    // Publish (or re-publish) the current Map in the MapRegistry so style
    // wrappers (StyleNAPI etc.) can resolve a liveness token and a
    // render-thread dispatcher for the raw map pointer they were given.
    void attachMapRegistry();
    // Invalidate the registry entry for the current map before dropping it.
    // Call before every harmonyRenderer.reset() / map = nullptr.
    void detachMapRegistry();

    // Initialize the renderer
    void initializeRenderer();
    // Ensure resource subsystems are ready; attempt self-recovery if not
    void ensureResourcesReadyOrRecover(int timeoutMs = 500);
    
    napi_env env_;
    napi_ref wrapper_;
    napi_ref styleRef_ = nullptr;
    
    std::unique_ptr<HarmonyRenderer> harmonyRenderer;
    
    MapRenderer* mapRenderer = nullptr;
    
    std::string styleUrl;
    
    float pixelRatio;
    
    // Minimum texture size according to OpenGL ES 2.0 specification.
    int width = 64;
    int height = 64;
    
    // Native window pointer
    OHNativeWindow* nativeWindow = nullptr;
    
    // Destruction flag used to prevent callbacks during teardown from crashing
    std::atomic<bool> isDestroying{false};
    
    // Indicates whether the current style has completed loading at least once
    std::atomic<bool> styleLoadedOnce{false};
    
    // Resource cleanup flag to prevent repeated cleanup
    std::atomic<bool> resourcesCleaned_{false};
    
    // Debug counters tracking render trigger frequency
    std::atomic<int> renderRequestCount{0};
    std::atomic<int> sourceChangedCount{0};
    std::atomic<int> cameraChangedCount{0};
    
    // Performance configuration (aligned with Android MapRenderer)
    int maximumFps_ = 0;  // 0 = unlimited (render at display refresh rate); setMaximumFps() applies it to the render loop
    int renderingRefreshMode_ = 1;  // Default WHEN_DIRTY mode (0=CONTINUOUS, 1=WHEN_DIRTY)
    // shared_ptr (not unique_ptr): the render thread's fps lambda captures the
    // same instance, so a listener swap/removal must not free it mid-call.
    std::shared_ptr<ThreadSafeCallback> fpsChangedCallback_;  // Callback invoked when FPS changes
    
    // Unified callback manager
    std::shared_ptr<mbgl::harmony::CallbackManager> callbackManager_;

    // Native gesture manager (replaces ArkTS MapGestureDetector)
    std::unique_ptr<mbgl::harmony::gesture::NativeGestureManager> gestureManager_;
    
    // Application cache directory path
    std::string cachePath_;
    
    // Local glyph font family configuration
    std::optional<std::string> localIdeographFontFamily_ = std::string("HarmonyOS_Sans");

    // Content padding [top, left, bottom, right]
    std::array<double, 4> contentPadding_ = {0.0, 0.0, 0.0, 0.0};

    std::unordered_map<int64_t, HarmonyViewAnnotation> viewAnnotations_;
    int64_t nextViewAnnotationId_ = 1;
    mutable std::mutex viewAnnotationMutex_;

    // Push-model view annotation positioning: the render thread computes frames
    // (buildFrame) after each camera update, dedupes them against the last
    // pushed snapshot, and dispatches the full frame list to ArkTS through the
    // thread-safe callback. viewAnnotationFramesCallback_/lastPushed... are
    // touched from both the JS thread (listener registration) and the render
    // thread (push), hence the dedicated mutex below.
    std::shared_ptr<ThreadSafeCallback> viewAnnotationFramesCallback_;
    std::vector<HarmonyViewAnnotationFrame> lastPushedViewAnnotationFrames_;
    mutable std::mutex viewAnnotationFrameMutex_;

    // Compute view annotation frames and push them to ArkTS when they changed
    // beyond the epsilon threshold. Must be called on the map/render thread;
    // no-ops when no listener is registered or when nothing was ever pushed
    // and no annotations exist.
    void pushViewAnnotationFrames();
    
    // Snapshot state
    std::mutex snapshotMutex_;
    bool snapshotInProgress_ = false;
    void resetSnapshotState();
    
    // ==================== Map thread helper methods ====================
    
    /**
     * Execute a map operation on the Map+Render thread asynchronously.
     * Thread scheduling and error handling are managed automatically.
     *
     * @param func Operation to perform; receives a Map* argument.
     */
    template<typename Func>
    void invokeOnMapThread(Func&& func) {
        if (!harmonyRenderer) {
            return;
        }
        
        harmonyRenderer->runOnRenderThread([this, func = std::forward<Func>(func)]() {
            if (map) {
                try {
                    func(map);
                } catch (...) {
                    // Error handled internally
                }
            }
        });
    }
    
    /**
     * Execute a map operation on the Map+Render thread synchronously, waiting for the result.
     *
     * @param func Operation to perform; receives a Map* argument and returns a result.
     * @return The result of the operation, or the default value if it fails.
     */
    template<typename Func, typename Result = std::invoke_result_t<Func, mbgl::Map*>>
    Result invokeOnMapThreadSync(Func&& func, Result defaultValue = Result{}) {
        if (!harmonyRenderer || !map) {
            return defaultValue;
        }

        // Heap-allocate the promise: if the render thread stalls past the wait
        // timeout below, this frame returns while the queued lambda stays alive
        // holding the promise. A stack promise captured by reference here would
        // be written after its frame is gone (same pattern as
        // HarmonyMapRenderThread::queryRenderedFeatures).
        auto promise = std::make_shared<std::promise<Result>>();
        auto future = promise->get_future();

        harmonyRenderer->runOnRenderThread([this, func = std::forward<Func>(func), promise]() mutable {
            try {
                if (map) {
                    Result result = func(map);
                    promise->set_value(std::move(result));
                } else {
                    promise->set_value(Result{});
                }
            } catch (...) {
                try {
                    promise->set_exception(std::current_exception());
                } catch (...) {
                    // Promise may already be set
                }
            }
        });

        // Wait for the result (up to 5 seconds)
        auto status = future.wait_for(std::chrono::seconds(5));
        if (status == std::future_status::timeout) {
            return defaultValue;
        }
        
        try {
            return future.get();
        } catch (...) {
            return defaultValue;
        }
    }
    
    // Ensure these are initialised last
    mbgl::Map* map = nullptr;  // Reference to Map owned by HarmonyMapRenderThread

    // Liveness token for the current map, published in the MapRegistry
    std::shared_ptr<MapToken> mapToken_;
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_NATIVE_MAP_VIEW_HARMONY_HPP