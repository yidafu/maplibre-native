#include "harmony_renderer.hpp"

// Include the appropriate renderer backend based on build configuration
#if MLN_RENDER_BACKEND_VULKAN
#include "backends/harmony_vulkan_renderer_backend.hpp"
#else
#include "backends/harmony_gl_renderer_backend.hpp"
#endif

#include "harmony_map_render_thread.hpp"
#include "utils/logger.h"
#include "core/native_map_view/native_map_view_harmony.hpp"  // ✅ 用于转发 MapObserver 事件
#include "config/maplibre_settings.hpp"  // ✅ 全局配置管理

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
// 生成唯一实例 ID
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
    
    // ✅ 应用全局配置（TileServerOptions 和 API Key）
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
        
        // ✅ 关键修复：设置 Native Window 后，初始化 framebuffer 大小
        // 这确保在第一次渲染前 framebuffer 大小正确
        // 因为在 initialize() 时 size 已设置，但 backend 的 framebuffer 还没有调整大小
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
        // ✅ 关键修复：同时更新 backend framebuffer size 和 Map size
        // 参考 Android MapRenderer::onSurfaceChanged() 的实现
        // 先调用 resizeFramebuffer（这会通过 invoke 在渲染线程执行）
        mapRenderThread_->resizeFramebuffer(width_, height_);
        
        // 然后更新 Map size（也在渲染线程执行）
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
        // 1. 立即停止所有请求（同步部分）
        stopAllRequests();
        
        // 2. 使用异步任务等待所有线程完成（参考 Android/iOS 模式）
        // 在独立线程中执行等待逻辑，避免阻塞主线程
        std::thread([this, onComplete = std::move(onComplete), instanceId = instanceId_]() {
            try {
                // 等待渲染线程完成当前任务（使用条件变量而不是硬编码等待）
                // 参考 Android MapRenderer 的 waitForEmpty()
                if (mapRenderThread_) {
                    // 给渲染线程时间完成当前帧
                    std::this_thread::sleep_for(std::chrono::milliseconds(50));
                }
                
                // 等待 RunLoop 完成当前任务
                // 参考 iOS 的 RunLoop 清理模式
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                
                // 等待 ResourceLoader 线程停止
                // 这是防止 SIGSEGV 的关键（见 CRASH_FIXES_2025_10_29.md）
                std::this_thread::sleep_for(std::chrono::milliseconds(150));
                
                Logger::info("HarmonyRenderer", "[%s] All async operations completed", instanceId.c_str());
                
                // 3. 调用完成回调
                if (onComplete) {
                    onComplete();
                }
                
            } catch (const std::exception& e) {
                Logger::error("HarmonyRenderer", "[%s] Error in async wait: %s", instanceId.c_str(), e.what());
                if (onComplete) {
                    onComplete(); // 即使出错也要调用回调
                }
            }
        }).detach(); // detach 允许线程独立运行
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRenderer", "[%s] Error in stopAllRequestsAsync: %s", instanceId_.c_str(), e.what());
        // 出错时立即调用回调
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
    
    // 首先停止所有网络请求（pause all file sources）
    stopAllRequests();
    
    // 🔑 Critical: Wait for active network callbacks to complete
    // Network requests in OnlineFileSource thread may still be executing callbacks
    // even after pause() is called. We need to give them time to finish to avoid
    // accessing destroyed mutexes (SIGSEGV in pthread_mutex_lock)
    Logger::info("HarmonyRenderer", "[%s] Waiting for active network callbacks to complete...", instanceId_.c_str());
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // 停止 Map+Render 线程
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

// ✅ MapObserver 方法实现 - 转发给 NativeMapView

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

// Shader 编译事件
void HarmonyRenderer::onPreCompileShader(shaders::BuiltIn shader, gfx::Backend::Type backend, const std::string& source) {
    Logger::info("HarmonyRenderer", "🔧 onPreCompileShader - forwarding to NativeMapView");
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

// Glyph 加载事件
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
    Logger::info("HarmonyRenderer", "📝 onGlyphsRequested - forwarding to NativeMapView");
    if (nativeMapView_) {
        nativeMapView_->onGlyphsRequested(stack, range);
    }
}

// Sprite 加载事件
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

// Tile 操作事件
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
    
    // 参考 Android MapRenderer::setOnFpsChangedListener
    mapRenderThread_->setOnFpsChangedCallback(std::move(callback));
}

void HarmonyRenderer::enableFpsMeasurement(bool enable) {
    if (!mapRenderThread_) {
        Logger::error("HarmonyRenderer", "enableFpsMeasurement: MapRenderThread not initialized");
        return;
    }
    
    mapRenderThread_->enableFpsMeasurement(enable);
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

// 🔀 便利的线程切换方法（不需要 tag 参数）
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


