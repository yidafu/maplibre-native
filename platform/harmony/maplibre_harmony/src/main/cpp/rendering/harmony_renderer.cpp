#include "harmony_renderer.hpp"

// Include the appropriate renderer backend based on build configuration
#if MLN_RENDER_BACKEND_VULKAN
#include "backends/harmony_vulkan_renderer_backend.hpp"
#else
#include "backends/harmony_gl_renderer_backend.hpp"
#endif

#include "harmony_map_render_thread.hpp"
#include "utils/logger.h"
#include "core/native_map_view/native_map_view_harmony.hpp"  // ✅ Used to forward MapObserver events
#include "config/maplibre_settings.hpp"  // ✅ Global configuration management

#include <mbgl/map/map.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread_local.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/storage/file_source_manager.hpp>
#include <mbgl/storage/file_source.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/storage/sqlite3.hpp>

#include <sstream>
#include <iomanip>
#include <atomic>
#include <thread>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

namespace {
// Generate a unique instance ID
std::string generateRendererInstanceId() {
    static std::atomic<uint64_t> counter{0};
    auto count = counter.fetch_add(1);
    
    std::ostringstream oss;
    oss << "renderer-" << std::setfill('0') << std::setw(5) << count;
    return oss.str();
}
} // anonymous namespace

HarmonyRenderer::HarmonyRenderer() 
    : instanceId_(generateRendererInstanceId()),
      uniqueID(util::SimpleIdentity::Empty),
      weakFactory(std::make_shared<mapbox::base::WeakPtrFactory<Scheduler>>(this)) {
}

HarmonyRenderer::~HarmonyRenderer() {
    cleanup();
}

void HarmonyRenderer::initialize(int width_, int height_, float pixelRatio_, const std::string& cachePath,
                                 const std::optional<std::string>& localIdeographFontFamily) {
    if (initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer already initialized");
        return;
    }
    
    width = width_;
    height = height_;
    pixelRatio = pixelRatio_;
    
    // Set SQLite temp path for database operations
    if (!cachePath.empty()) {
        mapbox::sqlite::setTempPath(cachePath);
    } else {
        Logger::warn("HarmonyRenderer", "No cache path provided, using default temp directory");
    }
    
    // Initialize FileSourceManager singleton - this registers default file source factories
    // including HTTP network source for downloading styles and tiles
    FileSourceManager::get();
    
    // Create backend
    auto backend = std::make_unique<HarmonyRendererBackendImpl>();
    
    // Create Map options
    MapOptions mapOptions;
    mapOptions.withSize(Size{static_cast<uint32_t>(width_), static_cast<uint32_t>(height_)});
    
    // Create Resource options
    ResourceOptions resourceOptions;
    if (!cachePath.empty()) {
        resourceOptions.withCachePath(cachePath);
    }
    
    // ✅ Apply global configuration (TileServerOptions and API key)
    resourceOptions = MapLibreSettings::getInstance().applyToResourceOptions(std::move(resourceOptions));
    
    // Create Client options
    ClientOptions clientOptions;
    
    // Create Map+Render thread
    mapRenderThread_ = std::make_unique<HarmonyMapRenderThread>(
        std::move(backend),
        pixelRatio,
        *this,  // HarmonyRenderer acts as MapObserver
        std::move(mapOptions),
        std::move(resourceOptions),
        std::move(clientOptions),
        localIdeographFontFamily  // Local glyph font family
    );
    
    // Start the thread
    mapRenderThread_->start();
    
    initialized = true;
    Log::Info(Event::OpenGL, "HarmonyRenderer initialized successfully");
}

void HarmonyRenderer::setNativeWindow(OHNativeWindow* window) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    
    if (mapRenderThread_) {
        mapRenderThread_->setNativeWindow(window);
        
        // ✅ Critical fix: initialize the framebuffer size after setting the native window
        // This ensures the framebuffer size is correct before the first render
        // Because initialize() sets the size while the backend framebuffer has not yet been resized
        if (width > 0 && height > 0) {
            mapRenderThread_->resizeFramebuffer(width, height);
        } else {
            Logger::warn("HarmonyRenderer", "Cannot initialize framebuffer: invalid size %dx%d", width, height);
        }
    }
}

Map* HarmonyRenderer::getMap() {
    if (!mapRenderThread_) {
        return nullptr;
    }
    return &mapRenderThread_->getMap();
}

void HarmonyRenderer::resize(int width_, int height_) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    
    width = width_;
    height = height_;
    
    Logger::info("HarmonyRenderer", "🔍 resize() called: %dx%d", width_, height_);
    
    if (mapRenderThread_) {
        // ✅ Critical fix: update both the backend framebuffer size and the map size
        // Reference Android MapRenderer::onSurfaceChanged()
        // Call resizeFramebuffer first (invoked on the render thread)
        mapRenderThread_->resizeFramebuffer(width_, height_);
        
        // Then update the map size (also executed on the render thread)
        mapRenderThread_->invoke([this, width_, height_]() {
            auto& map = mapRenderThread_->getMap();
            map.setSize(Size{static_cast<uint32_t>(width_), static_cast<uint32_t>(height_)});
        });
    } else {
        Logger::error("HarmonyRenderer", "mapRenderThread_ is null, cannot resize");
    }
    
    requestRender();
}


void HarmonyRenderer::requestRender() {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    
    static int totalCalls = 0;
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - startTime).count();
    
    Logger::warn("HarmonyRenderer", "🎬 [%lld ms] requestRender() #%d", elapsed, ++totalCalls);
    
    // Trigger Map update which will call RendererFrontend::update
    if (mapRenderThread_) {
        mapRenderThread_->invoke([this]() {
            mapRenderThread_->getMap().triggerRepaint();
        });
    }
}

void HarmonyRenderer::setRenderingMode(MapObserver::RenderMode mode) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    // Note: RenderMode handling may need to be implemented if needed
}

void HarmonyRenderer::pause() {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    if (mapRenderThread_) {
        mapRenderThread_->pause();
    }
}

void HarmonyRenderer::resume() {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    if (mapRenderThread_) {
        mapRenderThread_->resume();
    }
}

void HarmonyRenderer::setTileCacheEnabled(bool enabled) {
    if (!mapRenderThread_) {
        Logger::warn("HarmonyRenderer", "[%s] setTileCacheEnabled ignored: mapRenderThread_ not ready", instanceId_.c_str());
        return;
    }
    mapRenderThread_->setTileCacheEnabled(enabled);
}

bool HarmonyRenderer::getTileCacheEnabled() const {
    if (!mapRenderThread_) {
        Logger::warn("HarmonyRenderer", "[%s] getTileCacheEnabled defaulting to false: mapRenderThread_ not ready", instanceId_.c_str());
        return false;
    }
    return mapRenderThread_->getTileCacheEnabled();
}

void HarmonyRenderer::stopAllRequests() {
    
    try {
        Logger::info("HarmonyRenderer", "[%s] Stopping all file source requests...", instanceId_.c_str());
        
        // Get FileSourceManager and pause all file sources
        // This prevents new requests from starting and pauses active ones
        auto* fileSourceManager = mbgl::FileSourceManager::get();
        if (fileSourceManager) {
            // Create empty ResourceOptions to get file sources
            mbgl::ResourceOptions resourceOptions;
            mbgl::ClientOptions clientOptions;
            
            // Pause ResourceLoader (manages all other file sources)
            if (auto resourceLoader = fileSourceManager->getFileSource(
                    mbgl::FileSourceType::ResourceLoader, resourceOptions, clientOptions)) {
                Logger::info("HarmonyRenderer", "[%s] Pausing ResourceLoader...", instanceId_.c_str());
                resourceLoader->pause();
            }
            
            // Also pause Online and Database file sources directly for safety
            if (auto onlineSource = fileSourceManager->getFileSource(
                    mbgl::FileSourceType::Network, resourceOptions, clientOptions)) {
                Logger::info("HarmonyRenderer", "[%s] Pausing Online file source...", instanceId_.c_str());
                onlineSource->pause();
            }
            
            if (auto databaseSource = fileSourceManager->getFileSource(
                    mbgl::FileSourceType::Database, resourceOptions, clientOptions)) {
                Logger::info("HarmonyRenderer", "[%s] Pausing Database file source...", instanceId_.c_str());
                databaseSource->pause();
            }
        }
        
        // Pause rendering to prevent new render requests
        if (mapRenderThread_) {
            Logger::info("HarmonyRenderer", "[%s] Pausing render thread...", instanceId_.c_str());
            mapRenderThread_->pause();
        }
        
        Logger::info("HarmonyRenderer", "[%s] All file source requests stopped successfully", instanceId_.c_str());
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRenderer", "[%s] Error stopping network requests: %s", instanceId_.c_str(), e.what());
    } catch (...) {
        Logger::error("HarmonyRenderer", "[%s] Unknown error stopping network requests", instanceId_.c_str());
    }
    
}

void HarmonyRenderer::stopAllRequestsAsync(std::function<void()> onComplete) {
    try {
        // 1. Stop all requests immediately (synchronous part)
        stopAllRequests();
        
        // 2. Use an asynchronous task to wait for every thread to finish (align with Android/iOS patterns)
        // Run the wait logic on a dedicated thread to avoid blocking the main thread
        std::thread([this, onComplete = std::move(onComplete), instanceId = instanceId_]() {
            try {
                // Wait for the render thread to complete its current work (prefer condition variables over hard-coded waits)
                // Reference Android MapRenderer::waitForEmpty()
                if (mapRenderThread_) {
                    // Give the render thread time to finish the current frame
                    std::this_thread::sleep_for(std::chrono::milliseconds(50));
                }
                
                // Wait for the RunLoop to finish its pending tasks
                // Reference the iOS RunLoop cleanup pattern
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                
                // Wait for the ResourceLoader thread to stop
                // This is critical to prevent SIGSEGV (see CRASH_FIXES_2025_10_29.md)
                std::this_thread::sleep_for(std::chrono::milliseconds(150));
                
                Logger::info("HarmonyRenderer", "[%s] All async operations completed", instanceId.c_str());
                
                // 3. Invoke the completion callback
                if (onComplete) {
                    onComplete();
                }
                
            } catch (const std::exception& e) {
                Logger::error("HarmonyRenderer", "[%s] Error in async wait: %s", instanceId.c_str(), e.what());
                if (onComplete) {
                    onComplete(); // Call the callback even if an error occurs
                }
            }
        }).detach(); // detach allows the thread to run independently
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRenderer", "[%s] Error in stopAllRequestsAsync: %s", instanceId_.c_str(), e.what());
        // Immediately invoke the callback when an error occurs
        if (onComplete) {
            onComplete();
        }
    }
}

void HarmonyRenderer::cleanup() {
    if (!initialized) {
        return;
    }
    
    Logger::info("HarmonyRenderer", "[%s] Starting cleanup...", instanceId_.c_str());
    
    // Invalidate weak pointers early to prevent accessing this Scheduler after cleanup begins
    if (weakFactory) {
        weakFactory->invalidateWeakPtrs();
    }
    
    // First stop all network requests (pause all file sources)
    stopAllRequests();
    
    // 🔑 Critical: Wait for active network callbacks to complete
    // Network requests in OnlineFileSource thread may still be executing callbacks
    // even after pause() is called. We need to give them time to finish to avoid
    // accessing destroyed mutexes (SIGSEGV in pthread_mutex_lock)
    Logger::info("HarmonyRenderer", "[%s] Waiting for active network callbacks to complete...", instanceId_.c_str());
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // Stop the Map+Render thread
    if (mapRenderThread_) {
        Logger::info("HarmonyRenderer", "[%s] Stopping Map+Render thread...", instanceId_.c_str());
        mapRenderThread_->stop();
        
        // Give render thread time to finish current frame
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        
        mapRenderThread_.reset();
        Logger::info("HarmonyRenderer", "[%s] Map+Render thread stopped", instanceId_.c_str());
    }
    
    initialized = false;
    Logger::info("HarmonyRenderer", "[%s] Cleanup completed successfully", instanceId_.c_str());
}

// ✅ MapObserver implementations - forward to NativeMapView

void HarmonyRenderer::onCameraWillChange(CameraChangeMode mode) {
    if (nativeMapView_) {
        nativeMapView_->onCameraWillChange(mode);
    }
}

void HarmonyRenderer::onCameraIsChanging() {
    if (nativeMapView_) {
        nativeMapView_->onCameraIsChanging();
    }
}

void HarmonyRenderer::onCameraDidChange(CameraChangeMode mode) {
    if (nativeMapView_) {
        nativeMapView_->onCameraDidChange(mode);
    }
}

void HarmonyRenderer::onWillStartLoadingMap() {
    if (nativeMapView_) {
        nativeMapView_->onWillStartLoadingMap();
    }
}

void HarmonyRenderer::onDidFinishLoadingMap() {
    if (nativeMapView_) {
        nativeMapView_->onDidFinishLoadingMap();
    }
}

void HarmonyRenderer::onDidFailLoadingMap(MapLoadError error, const std::string& message) {
    if (nativeMapView_) {
        nativeMapView_->onDidFailLoadingMap(error, message);
    }
}

void HarmonyRenderer::onWillStartRenderingFrame() {
    if (nativeMapView_) {
        nativeMapView_->onWillStartRenderingFrame();
    }
}

void HarmonyRenderer::onDidFinishRenderingFrame(const RenderFrameStatus& status) {
    if (nativeMapView_) {
        nativeMapView_->onDidFinishRenderingFrame(status);
    }
}

void HarmonyRenderer::onWillStartRenderingMap() {
    if (nativeMapView_) {
        nativeMapView_->onWillStartRenderingMap();
    }
}

void HarmonyRenderer::onDidFinishRenderingMap(RenderMode mode) {
    if (nativeMapView_) {
        nativeMapView_->onDidFinishRenderingMap(mode);
    }
}

void HarmonyRenderer::onDidFinishLoadingStyle() {
    Logger::info("HarmonyRenderer", "🎨 onDidFinishLoadingStyle - forwarding to NativeMapView");
    if (nativeMapView_) {
        nativeMapView_->onDidFinishLoadingStyle();
    } else {
        Logger::warn("HarmonyRenderer", "⚠️ onDidFinishLoadingStyle: nativeMapView_ is null");
    }
}

void HarmonyRenderer::onSourceChanged(style::Source& source) {
    if (nativeMapView_) {
        nativeMapView_->onSourceChanged(source);
    }
}

void HarmonyRenderer::onDidBecomeIdle() {
    if (nativeMapView_) {
        nativeMapView_->onDidBecomeIdle();
    }
}

void HarmonyRenderer::onStyleImageMissing(const std::string& id) {
    if (nativeMapView_) {
        nativeMapView_->onStyleImageMissing(id);
    }
}

bool HarmonyRenderer::onCanRemoveUnusedStyleImage(const std::string& id) {
    if (nativeMapView_) {
        return nativeMapView_->onCanRemoveUnusedStyleImage(id);
    }
    return true;
}

void HarmonyRenderer::onRegisterShaders(gfx::ShaderRegistry& registry) {
    if (nativeMapView_) {
        nativeMapView_->onRegisterShaders(registry);
    }
}

// Shader compile events
void HarmonyRenderer::onPreCompileShader(shaders::BuiltIn shader, gfx::Backend::Type backend, const std::string& source) {
    if (nativeMapView_) {
        nativeMapView_->onPreCompileShader(shader, backend, source);
    }
}

void HarmonyRenderer::onPostCompileShader(shaders::BuiltIn shader, gfx::Backend::Type backend, const std::string& source) {
    if (nativeMapView_) {
        nativeMapView_->onPostCompileShader(shader, backend, source);
    }
}

void HarmonyRenderer::onShaderCompileFailed(shaders::BuiltIn shader, gfx::Backend::Type backend, const std::string& source) {
    if (nativeMapView_) {
        nativeMapView_->onShaderCompileFailed(shader, backend, source);
    }
}

// Glyph load events
void HarmonyRenderer::onGlyphsLoaded(const FontStack& stack, const GlyphRange& range) {
    if (nativeMapView_) {
        nativeMapView_->onGlyphsLoaded(stack, range);
    }
}

void HarmonyRenderer::onGlyphsError(const FontStack& stack, const GlyphRange& range, std::exception_ptr error) {
    if (nativeMapView_) {
        nativeMapView_->onGlyphsError(stack, range, error);
    }
}

void HarmonyRenderer::onGlyphsRequested(const FontStack& stack, const GlyphRange& range) {
    if (nativeMapView_) {
        nativeMapView_->onGlyphsRequested(stack, range);
    }
}

// Sprite load events
void HarmonyRenderer::onSpriteLoaded(const std::optional<style::Sprite>& sprite) {
    if (nativeMapView_) {
        nativeMapView_->onSpriteLoaded(sprite);
    }
}

void HarmonyRenderer::onSpriteError(const std::optional<style::Sprite>& sprite, std::exception_ptr error) {
    if (nativeMapView_) {
        nativeMapView_->onSpriteError(sprite, error);
    }
}

void HarmonyRenderer::onSpriteRequested(const std::optional<style::Sprite>& sprite) {
    Logger::info("HarmonyRenderer", "🎨 onSpriteRequested - forwarding to NativeMapView");
    if (nativeMapView_) {
        nativeMapView_->onSpriteRequested(sprite);
    }
}

// Tile operation events
void HarmonyRenderer::onTileAction(TileOperation operation, const OverscaledTileID& tileID, const std::string& sourceID) {
    if (nativeMapView_) {
        nativeMapView_->onTileAction(operation, tileID, sourceID);
    }
}

HarmonyRendererBackendImpl* HarmonyRenderer::getRendererBackend() const {
    if (!initialized || !mapRenderThread_) {
        return nullptr;
    }
    // Note: Getting backend requires thread synchronization
    // For now, return nullptr as backend is managed by MapRenderThread
    Logger::warn("HarmonyRenderer", "getRendererBackend() called - backend is managed by MapRenderThread");
    return nullptr;
}

std::vector<Feature> HarmonyRenderer::queryRenderedFeatures(
    const ScreenCoordinate& point,
    const RenderedQueryOptions& options) const {
    
    if (!mapRenderThread_) {
        Logger::error("HarmonyRenderer", "queryRenderedFeatures: MapRenderThread not initialized");
        return {};
    }
    
    return mapRenderThread_->queryRenderedFeatures(point, options);
}

std::vector<Feature> HarmonyRenderer::queryRenderedFeatures(
    const ScreenBox& box,
    const RenderedQueryOptions& options) const {
    
    if (!mapRenderThread_) {
        Logger::error("HarmonyRenderer", "queryRenderedFeatures: MapRenderThread not initialized");
        return {};
    }
    
    return mapRenderThread_->queryRenderedFeatures(box, options);
}

std::vector<Feature> HarmonyRenderer::querySourceFeatures(
    const std::string& sourceId,
    const SourceQueryOptions& options) const {
    
    if (!mapRenderThread_) {
        Logger::error("HarmonyRenderer", "querySourceFeatures: MapRenderThread not initialized");
        return {};
    }
    
    return mapRenderThread_->querySourceFeatures(sourceId, options);
}

void HarmonyRenderer::setOnFpsChangedCallback(std::function<void(double)> callback) {
    if (!mapRenderThread_) {
        Logger::error("HarmonyRenderer", "setOnFpsChangedCallback: MapRenderThread not initialized");
        return;
    }
    
    // Reference Android MapRenderer::setOnFpsChangedListener
    mapRenderThread_->setOnFpsChangedCallback(std::move(callback));
}

void HarmonyRenderer::enableFpsMeasurement(bool enable) {
    if (!mapRenderThread_) {
        Logger::error("HarmonyRenderer", "enableFpsMeasurement: MapRenderThread not initialized");
        return;
    }
    
    mapRenderThread_->enableFpsMeasurement(enable);
}

void HarmonyRenderer::requestSnapshot(SnapshotSuccessCallback success, SnapshotErrorCallback error) {
    if (!mapRenderThread_) {
        if (error) {
            error("Render thread not initialized");
        }
        return;
    }
    
    mapRenderThread_->requestSnapshot(
        [success = std::move(success)](mbgl::PremultipliedImage&& image, float pixelRatio) mutable {
            if (success) {
                success(std::move(image), pixelRatio);
            }
        },
        std::move(error));
}

// Scheduler interface implementation
void HarmonyRenderer::schedule(std::function<void()>&& fn) {
    // For now, execute immediately on the current thread
    // In a real implementation, this would queue the function for execution
    if (fn) {
        fn();
    }
}

void HarmonyRenderer::schedule(const util::SimpleIdentity tag, std::function<void()>&& fn) {
    // For now, execute immediately on the current thread
    // In a real implementation, this would queue the function for execution with the given tag
    if (fn) {
        fn();
    }
}

mapbox::base::WeakPtr<Scheduler> HarmonyRenderer::makeWeakPtr() {
    return weakFactory->makeWeakPtr();
}

void HarmonyRenderer::runOnRenderThread(const util::SimpleIdentity tag, std::function<void()>&& fn) {
    // For now, execute immediately on the current thread
    // In a real implementation, this would queue the function for execution on the render thread
    if (fn) {
        fn();
    }
}

void HarmonyRenderer::runRenderJobs(const util::SimpleIdentity tag, bool closeQueue) {
    // For now, this is a no-op
    // In a real implementation, this would process queued render jobs
}

void HarmonyRenderer::waitForEmpty(const util::SimpleIdentity tag) {
    // For now, this is a no-op since we execute functions immediately
    // In a real implementation, this would wait for all queued tasks to complete
}

// 🔀 Convenience thread-switch helper (no tag parameter required)
void HarmonyRenderer::runOnRenderThread(std::function<void()>&& fn) {
    if (!mapRenderThread_) {
        Logger::error("Renderer", "[%s] Cannot runOnRenderThread: thread is null", instanceId_.c_str());
        return;
    }
    
    mapRenderThread_->invoke(std::move(fn));
}

bool HarmonyRenderer::isOnRenderThread() const {
    if (!mapRenderThread_) {
        return false;
    }
    
    return mapRenderThread_->isOnThread();
}

} // namespace harmony
} // namespace mbgl


