#pragma once

#include <mbgl/map/map.hpp>
#include <mbgl/renderer/renderer.hpp>
#include <mbgl/renderer/renderer_frontend.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/action_journal_options.hpp>
#include <mbgl/map/map_observer.hpp>
#include <mbgl/gfx/backend.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/image.hpp>
#include <mbgl/util/geojson.hpp>

#include "backends/harmony_renderer_backend.hpp"

#include <memory>
#include <thread>
#include <atomic>
#include <functional>
#include <mutex>
#include <condition_variable>

// VSync management
#include "../vsync/harmony_vsync_manager.hpp"

namespace mbgl {
namespace harmony {

/**
 * HarmonyMapRenderThread - unified map and render thread.
 *
 * Architecture:
 * - Map and Renderer live on the same thread.
 * - Thread owns a RunLoop to process asynchronous messages.
 * - EGL context is bound to this thread.
 *
 * Key characteristics:
 * - Eliminates cross-thread concurrency issues.
 * - FileSource callbacks operate normally.
 * - Thread-safe EGL operations.
 *
 * Inspired by the iOS architecture.
 */
class HarmonyMapRenderThread : public RendererFrontend {
public:
    // Unique instance identifier (for logging and isolation)
    static std::atomic<uint64_t> globalInstanceCounter_;
    const uint64_t instanceId_;
    /**
     * Constructor.
     *
     * @param backend Rendering backend (OpenGL ES or Vulkan, chosen at compile time)
     * @param pixelRatio Pixel density ratio
     * @param observer Map observer
     * @param mapOptions Map options (moved in)
     * @param resourceOptions Resource options (moved in)
     * @param clientOptions Client options (moved in)
     * @param localIdeographFontFamily Optional local ideograph font family
     */
    HarmonyMapRenderThread(
        std::unique_ptr<HarmonyRendererBackend> backend,
        float pixelRatio,
        MapObserver& observer,
        MapOptions&& mapOptions,
        ResourceOptions&& resourceOptions,
        ClientOptions&& clientOptions,
        const std::optional<std::string>& localIdeographFontFamily = std::nullopt
    );
    
    /**
     * Destructor - ensures thread-safe cleanup.
     */
    ~HarmonyMapRenderThread() override;

    // Disable copy and move
    HarmonyMapRenderThread(const HarmonyMapRenderThread&) = delete;
    HarmonyMapRenderThread& operator=(const HarmonyMapRenderThread&) = delete;

    // ==================== Thread management ====================
    
    /**
     * Start the combined map/render thread.
     * Blocks until initialization completes.
     */
    void start();
    
    /**
     * Stop the thread and wait for it to exit.
     */
    void stop();
    
    /**
     * Determine whether the current thread is the map/render thread.
     */
    bool isOnThread() const;
    
    /**
     * Retrieve the thread ID.
     */
    std::thread::id getThreadId() const { return threadId_; }

    // ==================== Map access ====================
    
    /**
     * Obtain a reference to the map (thread-safe).
     * Note: Map methods must be invoked via invoke().
     */
    Map& getMap();
    
    /**
     * Execute a task on the map/render thread.
     * If already on the thread, run immediately; otherwise dispatch.
     */
    void invoke(std::function<void()> task);

    // ==================== RendererFrontend interface ====================
    
    /**
     * Map notifies that a render is required.
     * Because we share the thread, invoke the Renderer directly.
     */
    void update(std::shared_ptr<UpdateParameters> params) override;
    
    /**
     * Set the renderer observer.
     */
    void setObserver(RendererObserver& observer) override;
    
    /**
     * Reset the renderer.
     */
    void reset() override;
    
    /**
     * Access the thread pool.
     */
    const TaggedScheduler& getThreadPool() const override;

    // ==================== Rendering control ====================
    
    /**
     * Set the native window (XComponent Surface).
     */
    void setNativeWindow(void* window);
    
    /**
     * Pause rendering.
     */
    void pause();
    
    /**
     * Resume rendering.
     */
    void resume();
    
    /**
     * Retrieve the renderer backend.
     */
    gfx::RendererBackend& getRendererBackend();

    /// Active backend name and GPU description (for diagnostics)
    std::string getRendererInfo();
    
    /**
     * Resize the framebuffer.
     */
    void resizeFramebuffer(int width, int height);

    /**
     * Enable or disable the renderer tile cache.
     */
    void setTileCacheEnabled(bool enabled);

    /**
     * Query the current tile cache state.
     */
    bool getTileCacheEnabled() const;

    /**
     * Set the action journal options.
     */
    void setActionJournalOptions(const util::ActionJournalOptions& opts) { actionJournalOptions_ = opts; }


    // ==================== Query utilities ====================
    
    /**
     * Query rendered features at a point.
     */
    std::vector<Feature> queryRenderedFeatures(const ScreenCoordinate& point,
                                               const RenderedQueryOptions& options = {}) const;
    
    /**
     * Query rendered features within a box.
     */
    std::vector<Feature> queryRenderedFeatures(const ScreenBox& box,
                                               const RenderedQueryOptions& options = {}) const;
    
    /**
     * Query features from a source.
     */
    std::vector<Feature> querySourceFeatures(const std::string& sourceId,
                                            const SourceQueryOptions& options = {}) const;

    /**
     * Query feature extensions (cluster children/leaves/expansion-zoom).
     *
     * Used for GeoJSON cluster queries. Dispatches to the render thread
     * following the same pattern as querySourceFeatures.
     *
     * @param sourceID Source identifier
     * @param feature Feature to query extensions for (with cluster_id property)
     * @param extension Extension identifier (e.g. "supercluster")
     * @param extensionField Extension field (e.g. "children", "leaves", "expansion-zoom")
     * @param args Optional parameters (e.g. limit/offset for "leaves")
     * @return Extension result (Value for expansion-zoom, FeatureCollection for children/leaves)
     */
    FeatureExtensionValue queryFeatureExtensions(
        const std::string& sourceID,
        const Feature& feature,
        const std::string& extension,
        const std::string& extensionField,
        const std::optional<std::map<std::string, Value>>& args = std::nullopt) const;
    
    /**
     * Set the FPS callback (mirrors Android MapRenderer::setOnFpsChangedListener).
     */
    void setOnFpsChangedCallback(std::function<void(double)> callback);

    /**
     * Enable or disable FPS measurement.
     */
    void enableFpsMeasurement(bool enable);

    /**
     * Limit the render loop to at most the given frames per second by skipping
     * VSync ticks that arrive sooner than the frame interval (mirrors Android
     * MapRenderer::setMaximumFps). 0 disables the limit (render at the display
     * refresh rate). Safe to call from any thread.
     */
    void setMaximumFps(int fps);

    /**
     * Current FPS limit; 0 means unlimited.
     */
    int getMaximumFps() const { return static_cast<int>(maximumFps_.load(std::memory_order_relaxed)); }

    /**
     * Control whether the render loop keeps pumping frames when the map is idle.
     * 0 = CONTINUOUS: re-arms VSync after every frame and forces a repaint each
     * tick, matching Android RENDERMODE_CONTINUOUSLY.
     * 1 = WHEN_DIRTY: the loop sleeps once the map has nothing more to repaint;
     * VSync is re-armed by update() when the content changes (saves power).
     * Safe to call from any thread.
     */
    void setRenderingRefreshMode(int mode);

    /**
     * Current refresh mode: 0 = CONTINUOUS, 1 = WHEN_DIRTY.
     */
    int getRenderingRefreshMode() const { return refreshMode_.load(std::memory_order_relaxed); }
    
    using SnapshotSuccessCallback = std::function<void(mbgl::PremultipliedImage&&, float)>;
    using SnapshotErrorCallback = std::function<void(const std::string&)>;
    void requestSnapshot(SnapshotSuccessCallback success, SnapshotErrorCallback error);

private:
    // ==================== Thread functions ====================
    
    /**
     * Main thread loop.
     * 1. Create the RunLoop
     * 2. Initialize EGL
     * 3. Create the Renderer
     * 4. Create the Map
     * 5. Run the RunLoop
     */
    void threadLoop();
    
    /**
     * Initialization sequence (executed on the thread).
     */
    bool initialize();
    
    /**
     * Clean up resources (executed on the thread).
     */
    void cleanup();
    
    // ==================== VSync control ====================
    
    /**
     * VSync callback handler (renders when VSync fires).
     */
    void onVSyncFrame();

    /**
     * Frame pacing check for the current tick. Returns true when the tick
     * arrived sooner than the configured frame interval (and should be
     * skipped); otherwise records the frame start time and returns false.
     * Render thread only.
     */
    bool shouldThrottleFrame();

    // ==================== Member variables ====================
    
    // Thread objects
    std::thread thread_;
    std::thread::id threadId_;
    
    // Synchronization primitives
    std::mutex mutex_;
    std::condition_variable cv_;
    std::atomic<bool> started_{false};
    std::atomic<bool> shouldStop_{false};
    std::atomic<bool> initialized_{false};
    std::atomic<bool> initFailed_{false};  // Lets start() fail fast instead of waiting out the timeout
    std::atomic<bool> destroying_{false};  // ✅ Destruction flag to avoid race conditions
    
    // Core objects (created and destroyed on the thread)
    std::unique_ptr<util::RunLoop> runLoop_;
    std::unique_ptr<Map> map_;
    std::unique_ptr<Renderer> renderer_;
    // Race-free cross-thread null-check mirror (P2-2): the render thread
    // publishes/withdraws the raw pointer whenever renderer_ changes; other
    // threads must not read the unique_ptr itself. Ownership stays with
    // renderer_ and is destroyed on the render thread / after join.
    std::atomic<Renderer*> rendererMirror_{nullptr};
    std::unique_ptr<HarmonyRendererBackend> backend_;
    std::unique_ptr<TaggedScheduler> threadPool_;
    
    // Initialization parameters (captured from constructor)
    float pixelRatio_;
    MapObserver* mapObserver_;
    MapOptions mapOptions_;
    ResourceOptions resourceOptions_;
    ClientOptions clientOptions_;
    std::optional<std::string> localIdeographFontFamily_;
    util::ActionJournalOptions actionJournalOptions_{};
    
    // Rendering state
    std::atomic<bool> paused_{true};
    
    // FPS measurement (aligned with Android MapRenderer)
    // Only touched on the render thread; the first frame after enabling just
    // records the start time instead of reporting a bogus interval.
    std::chrono::steady_clock::time_point lastFrameTime_{};
    std::atomic<bool> measureFps_{false};
    // Guarded by fpsCallbackMutex_: written from the JS thread, read per-frame
    // on the render thread. Shared pointer swap lets an in-frame invocation
    // outlive a concurrent setOnFpsChangedCallback(nullptr).
    std::mutex fpsCallbackMutex_;
    std::shared_ptr<std::function<void(double)>> fpsCallback_;
    void* nativeWindow_{nullptr};

    // Frame pacing / render mode (mirrors Android MapRenderer)
    // maximumFps_: 0 disables the limit (render at the display refresh rate)
    // refreshMode_: 0 = CONTINUOUS, 1 = WHEN_DIRTY (default, saves power)
    std::atomic<uint32_t> maximumFps_{0};
    std::atomic<int> refreshMode_{1};
    std::chrono::steady_clock::time_point lastFrameDeadline_;

    // VSync management
    std::unique_ptr<HarmonyVSyncManager> vsyncManager_;
    // Cross-thread mirror of vsyncManager_ (see rendererMirror_ note)
    std::atomic<HarmonyVSyncManager*> vsyncManagerMirror_{nullptr};
    std::shared_ptr<UpdateParameters> pendingUpdateParams_{nullptr};
    std::atomic<bool> pendingRender_{false};
    
    // Snapshot handling
    std::mutex snapshotMutex_;
    SnapshotSuccessCallback snapshotSuccessCallback_;
    SnapshotErrorCallback snapshotErrorCallback_;
    bool snapshotPending_{false};

    // Most recent logical size (used after window recreation). atomic<int>:
    // written from the JS thread (resizeFramebuffer) and read on the render
    // thread (setNativeWindow).
    std::atomic<int> lastWidth_{0};
    std::atomic<int> lastHeight_{0};
};

} // namespace harmony
} // namespace mbgl

