#ifndef MAPLIBREHARMONY_NATIVE_MAP_VIEW_HARMONY_HPP
#define MAPLIBREHARMONY_NATIVE_MAP_VIEW_HARMONY_HPP

#include "harmony_renderer_backend.hpp"
#include <mbgl/map/map.hpp>
#include <mbgl/tile/tile_operation.hpp>
#include <mbgl/util/run_loop.hpp>

#include <string>
#include <memory>
#include <js_native_api.h>

namespace mbgl {
namespace harmony {

class FileSource;
class MapRenderer;
class RenderingStats;
class HarmonyRenderer;

class NativeMapView : public MapObserver {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    NativeMapView(napi_env env, napi_value wrapper);
    virtual ~NativeMapView();
    
    // 资源清理方法
    void cleanupAllResources();
    
    // 设置原生窗口（带尺寸参数）
    void setNativeWindowWithSize(int64_t surfaceId, int width, int height);

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
    static napi_value resetNorth(napi_env env, napi_callback_info info);
    static napi_value setVisibleCoordinateBounds(napi_env env, napi_callback_info info);
    static napi_value getVisibleCoordinateBounds(napi_env env, napi_callback_info info);
    static napi_value scheduleSnapshot(napi_env env, napi_callback_info info);
    static napi_value getCameraPosition(napi_env env, napi_callback_info info);
    static napi_value updateMarker(napi_env env, napi_callback_info info);
    static napi_value addMarkers(napi_env env, napi_callback_info info);
    static napi_value onLowMemory(napi_env env, napi_callback_info info);
    static napi_value setDebug(napi_env env, napi_callback_info info);
    static napi_value getDebug(napi_env env, napi_callback_info info);
    static napi_value getActionJournalLogFiles(napi_env env, napi_callback_info info);
    static napi_value getActionJournalLog(napi_env env, napi_callback_info info);
    static napi_value clearActionJournalLog(napi_env env, napi_callback_info info);
    static napi_value isFullyLoaded(napi_env env, napi_callback_info info);
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
    static napi_value queryPointAnnotations(napi_env env, napi_callback_info info);
    static napi_value queryShapeAnnotations(napi_env env, napi_callback_info info);
    static napi_value queryRenderedFeaturesForPoint(napi_env env, napi_callback_info info);
    static napi_value queryRenderedFeaturesForBox(napi_env env, napi_callback_info info);
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

private:
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    mbgl::Map& getMap();
    
    // 初始化渲染器
    void initializeRenderer();
    
    napi_env env_;
    napi_ref wrapper_;
    
    std::unique_ptr<HarmonyRenderer> harmonyRenderer;
    
    MapRenderer* mapRenderer = nullptr;
    
    std::string styleUrl;
    
    float pixelRatio;
    
    // Minimum texture size according to OpenGL ES 2.0 specification.
    int width = 64;
    int height = 64;
    
    // 窗口指针
    OHNativeWindow* nativeWindow = nullptr;
    
    // 析构标志 - 用于防止析构期间的回调崩溃
    std::atomic<bool> isDestroying{false};
    
    // 调试计数器 - 追踪渲染触发频率
    std::atomic<int> renderRequestCount{0};
    std::atomic<int> sourceChangedCount{0};
    std::atomic<int> cameraChangedCount{0};
    
    // Ensure these are initialised last
    std::unique_ptr<mbgl::Map> map;
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_NATIVE_MAP_VIEW_HARMONY_HPP