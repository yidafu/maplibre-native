#pragma once

#include <mln/map/map.hpp>
#include <mln/util/noncopyable.hpp>
#include <mln/actor/scheduler.hpp>
#include <mln/util/identity.hpp>
#include <mln/util/geo.hpp>
#include <mln/util/feature.hpp>
#include <mln/util/geojson.hpp>
#include <mln/renderer/query.hpp>
#include <native_window/external_window.h>
#include <memory>
#include <functional>
#include <mln/util/image.hpp>

namespace mln {
namespace harmony {

// Forward declarations - use the appropriate backend based on build configuration
#if MLN_RENDER_BACKEND_VULKAN
class HarmonyVulkanRendererBackend;
using HarmonyRendererBackendImpl = HarmonyVulkanRendererBackend;
#else
class HarmonyGLRendererBackend;
using HarmonyRendererBackendImpl = HarmonyGLRendererBackend;
#endif

class HarmonyMapRenderThread;
class NativeMapView;  // Forward declaration

class HarmonyRenderer : public mln::util::noncopyable, public mln::Scheduler, public mln::MapObserver {
public:
    HarmonyRenderer();
    ~HarmonyRenderer();
    
    // ✅ Attach NativeMapView (used to forward MapObserver events)
    void setNativeMapView(NativeMapView* nativeMapView) { nativeMapView_ = nativeMapView; }
    
    // ✅ MapObserver methods forwarded to NativeMapView
    void onCameraWillChange(CameraChangeMode mode) override;
    void onCameraIsChanging() override;
    void onCameraDidChange(CameraChangeMode mode) override;
    void onWillStartLoadingMap() override;
    void onDidFinishLoadingMap() override;
    void onDidFailLoadingMap(MapLoadError error, const std::string& message) override;
    void onWillStartRenderingFrame() override;
    void onDidFinishRenderingFrame(const RenderFrameStatus& status) override;
    void onWillStartRenderingMap() override;
    void onDidFinishRenderingMap(RenderMode mode) override;
    void onDidFinishLoadingStyle() override;
    void onSourceChanged(style::Source& source) override;
    void onDidBecomeIdle() override;
    void onStyleImageMissing(const std::string& id) override;
    bool onCanRemoveUnusedStyleImage(const std::string& id) override;
    void onRegisterShaders(gfx::ShaderRegistry& registry) override;
    
    // Shader compilation events
    void onPreCompileShader(shaders::BuiltIn shader, gfx::Backend::Type backend, const std::string& source) override;
    void onPostCompileShader(shaders::BuiltIn shader, gfx::Backend::Type backend, const std::string& source) override;
    void onShaderCompileFailed(shaders::BuiltIn shader, gfx::Backend::Type backend, const std::string& source) override;
    
    // Glyph loading events
    void onGlyphsLoaded(const FontStack& stack, const GlyphRange& range) override;
    void onGlyphsError(const FontStack& stack, const GlyphRange& range, std::exception_ptr error) override;
    void onGlyphsRequested(const FontStack& stack, const GlyphRange& range) override;
    
    // Sprite loading events
    void onSpriteLoaded(const std::optional<style::Sprite>& sprite) override;
    void onSpriteError(const std::optional<style::Sprite>& sprite, std::exception_ptr error) override;
    void onSpriteRequested(const std::optional<style::Sprite>& sprite) override;
    
    // Tile operation events
    void onTileAction(TileOperation operation, const OverscaledTileID& tileID, const std::string& sourceID) override;
    
    // Initialize the renderer
    void initialize(int width, int height, float pixelRatio = 1.0f, const std::string& cachePath = "", 
                   const std::optional<std::string>& localIdeographFontFamily = std::nullopt);
    
    // Set the OHNativeWindow
    void setNativeWindow(OHNativeWindow* window);
    
    // Retrieve the Map reference (external access)
    Map* getMap();
    
    // Resize the renderer
    void resize(int width, int height);
    
    // Request a render
    void requestRender();
    
    // Configure the render mode
    void setRenderingMode(MapObserver::RenderMode mode);
    
    // Limit the render loop frame rate (0 = unlimited, render at display refresh rate)
    void setMaximumFps(int fps);
    
    // Control the render loop refresh behavior (0 = CONTINUOUS, 1 = WHEN_DIRTY)
    void setRenderingRefreshMode(int refreshMode);
    
    // Pause rendering
    void pause();
    
    // Resume rendering
    void resume();

    // Tile cache control
    void setTileCacheEnabled(bool enabled);
    bool getTileCacheEnabled() const;
    
    // Stop all network requests
    void stopAllRequests();

    // Pause all process-wide file sources (ResourceLoader/Network/Database).
    // Static: safe to call from any thread (touches no renderer state), used
    // by both the synchronous cleanup path and NativeMapView's async destroy
    // worker.
    static void pauseFileSources(const std::string& label);
    
    // Clean up resources
    void cleanup();
    
    // Access the renderer backend
    HarmonyRendererBackendImpl* getRendererBackend() const;

    // Active backend name and GPU description (for diagnostics)
    std::string getRendererInfo() const;
    
    // Query rendered features
    std::vector<Feature> queryRenderedFeatures(const ScreenCoordinate& point,
                                               const RenderedQueryOptions& options = {}) const;
    std::vector<Feature> queryRenderedFeatures(const ScreenBox& box,
                                               const RenderedQueryOptions& options = {}) const;
    
    // Query source features
    std::vector<Feature> querySourceFeatures(const std::string& sourceId,
                                            const SourceQueryOptions& options = {}) const;

    // Feature state management (mirrors Android RendererFrontend feature state API)
    void setFeatureState(const std::string& sourceID,
                         const std::optional<std::string>& sourceLayerID,
                         const std::string& featureID,
                         const FeatureState& state);
    FeatureState getFeatureState(const std::string& sourceID,
                                 const std::optional<std::string>& sourceLayerID,
                                 const std::string& featureID) const;
    void removeFeatureState(const std::string& sourceID,
                            const std::optional<std::string>& sourceLayerID,
                            const std::optional<std::string>& featureID,
                            const std::optional<std::string>& stateKey);

    // Query feature extensions (cluster children/leaves/expansion-zoom)
    FeatureExtensionValue queryFeatureExtensions(
        const std::string& sourceID,
        const Feature& feature,
        const std::string& extension,
        const std::string& extensionField,
        const std::optional<std::map<std::string, Value>>& args = std::nullopt) const;
    
    // FPS measurement (aligned with Android MapRenderer)
    void setOnFpsChangedCallback(std::function<void(double)> callback);
    void enableFpsMeasurement(bool enable);
    
    using SnapshotSuccessCallback = std::function<void(mln::PremultipliedImage&&, float)>;
    using SnapshotErrorCallback = std::function<void(const std::string&)>;
    void requestSnapshot(SnapshotSuccessCallback success, SnapshotErrorCallback error);
    
    // 📝 Instance identifier
    std::string getInstanceId() const { return instanceId_; }
    
    // 🔀 Convenience thread helper (no tag parameter required)
    void runOnRenderThread(std::function<void()>&& fn);
    bool isOnRenderThread() const;

    // Scheduler interface implementation
    void schedule(std::function<void()>&& fn) override;
    void schedule(const util::SimpleIdentity, std::function<void()>&& fn) override;
    mapbox::base::WeakPtr<Scheduler> makeWeakPtr() override;
    void runOnRenderThread(const util::SimpleIdentity tag, std::function<void()>&& fn) override;
    void runRenderJobs(const util::SimpleIdentity tag, bool closeQueue = false) override;
    void waitForEmpty(const util::SimpleIdentity = util::SimpleIdentity::Empty) override;

private:
    std::string instanceId_;  // Unique identifier
    std::unique_ptr<HarmonyMapRenderThread> mapRenderThread_;  // Combined Map + render thread
    int width = 0;
    int height = 0;
    float pixelRatio = 1.0f;
    bool initialized = false;
    
    // Scheduler support
    util::SimpleIdentity uniqueID;
    std::shared_ptr<mapbox::base::WeakPtrFactory<Scheduler>> weakFactory;
    
    // ✅ NativeMapView reference (for forwarding MapObserver events)
    NativeMapView* nativeMapView_ = nullptr;
};

} // namespace harmony
} // namespace mln


