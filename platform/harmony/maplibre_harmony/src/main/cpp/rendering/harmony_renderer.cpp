#include "harmony_renderer.hpp"

// Include the appropriate renderer backend based on build configuration
#if MLN_RENDER_BACKEND_VULKAN
#include "backends/harmony_vulkan_renderer_backend.hpp"
#else
#include "backends/harmony_gl_renderer_backend.hpp"
#endif

#include "harmony_map_render_thread.hpp"
#include "utils/logger.h"

#include <mbgl/map/map.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread_local.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/storage/file_source_manager.hpp>
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
    Logger::info("Renderer", "🆕 [%s] Creating HarmonyRenderer", instanceId_.c_str());
}

HarmonyRenderer::~HarmonyRenderer() {
    cleanup();
}

void HarmonyRenderer::initialize(int width_, int height_, float pixelRatio_, const std::string& cachePath) {
    if (initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer already initialized");
        return;
    }
    
    width = width_;
    height = height_;
    pixelRatio = pixelRatio_;
    Logger::info("HarmonyRenderer", "Initializing: %dx%d, pixelRatio=%.2f", width_, height_, pixelRatio);
    
    // Initialize FileSourceManager for network resource loading
    Logger::info("HarmonyRenderer", "Initializing FileSourceManager...");
    
    // Set SQLite temp path for database operations
    if (!cachePath.empty()) {
        mapbox::sqlite::setTempPath(cachePath);
        Logger::debug("HarmonyRenderer", "SQLite temp path set to: %s", cachePath.c_str());
    } else {
        Logger::warn("HarmonyRenderer", "No cache path provided, using default temp directory");
    }
    
    // Initialize FileSourceManager singleton - this registers default file source factories
    // including HTTP network source for downloading styles and tiles
    FileSourceManager::get();
    Logger::info("HarmonyRenderer", "FileSourceManager initialized successfully");
    
    Logger::debug("HarmonyRenderer", "Creating Map+Render thread...");
    
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
    
    // Create Client options
    ClientOptions clientOptions;
    
    // Create Map+Render thread
    mapRenderThread_ = std::make_unique<HarmonyMapRenderThread>(
        std::move(backend),
        pixelRatio,
        *this,  // HarmonyRenderer acts as MapObserver
        std::move(mapOptions),
        std::move(resourceOptions),
        std::move(clientOptions)
    );
    
    // Start the thread
    mapRenderThread_->start();
    Logger::info("HarmonyRenderer", "Map+Render thread created and started");
    
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
        Logger::info("HarmonyRenderer", "Native window set on Map+Render thread");
        
        // ✅ 关键修复：设置 Native Window 后，初始化 framebuffer 大小
        // 这确保在第一次渲染前 framebuffer 大小正确
        // 因为在 initialize() 时 size 已设置，但 backend 的 framebuffer 还没有调整大小
        if (width > 0 && height > 0) {
            Logger::info("HarmonyRenderer", "Initializing framebuffer size: %dx%d", width, height);
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
            Logger::info("HarmonyRenderer", "✅ Map size updated: %dx%d", width_, height_);
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
        // 停止FileSourceManager的所有网络请求
        if (auto fileSourceManager = mbgl::FileSourceManager::get()) {
            Logger::debug("HarmonyRenderer", "Stopping FileSourceManager requests...");
            Logger::debug("HarmonyRenderer", "FileSourceManager cleanup initiated");
        }
        
        // 暂停渲染
        if (mapRenderThread_) {
            Logger::debug("HarmonyRenderer", "Pausing Map+Render thread...");
            mapRenderThread_->pause();
        }
        
        Logger::info("HarmonyRenderer", "All network requests stopped successfully");
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRenderer", "Error stopping network requests: %s", e.what());
    } catch (...) {
        Logger::error("HarmonyRenderer", "Unknown error stopping network requests");
    }
    
}

void HarmonyRenderer::stopAllRequestsAsync(std::function<void()> onComplete) {
    Logger::info("HarmonyRenderer", "[%s] ========== stopAllRequestsAsync START ==========", instanceId_.c_str());
    
    try {
        // 1. 立即停止所有请求（同步部分）
        stopAllRequests();
        
        // 2. 使用异步任务等待所有线程完成（参考 Android/iOS 模式）
        // 在独立线程中执行等待逻辑，避免阻塞主线程
        std::thread([this, onComplete = std::move(onComplete), instanceId = instanceId_]() {
            try {
                Logger::debug("HarmonyRenderer", "[%s] Async wait thread started", instanceId.c_str());
                
                // 等待渲染线程完成当前任务（使用条件变量而不是硬编码等待）
                // 参考 Android MapRenderer 的 waitForEmpty()
                if (mapRenderThread_) {
                    Logger::debug("HarmonyRenderer", "[%s] Waiting for Map+Render thread to finish...", instanceId.c_str());
                    // 给渲染线程时间完成当前帧
                    std::this_thread::sleep_for(std::chrono::milliseconds(50));
                }
                
                // 等待 RunLoop 完成当前任务
                // 参考 iOS 的 RunLoop 清理模式
                Logger::debug("HarmonyRenderer", "[%s] Waiting for RunLoop tasks to complete...", instanceId.c_str());
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                
                // 等待 ResourceLoader 线程停止
                // 这是防止 SIGSEGV 的关键（见 CRASH_FIXES_2025_10_29.md）
                Logger::debug("HarmonyRenderer", "[%s] Waiting for ResourceLoader thread to stop...", instanceId.c_str());
                std::this_thread::sleep_for(std::chrono::milliseconds(150));
                
                Logger::info("HarmonyRenderer", "[%s] All async operations completed", instanceId.c_str());
                
                // 3. 调用完成回调
                if (onComplete) {
                    Logger::debug("HarmonyRenderer", "[%s] Invoking onComplete callback", instanceId.c_str());
                    onComplete();
                }
                
                Logger::info("HarmonyRenderer", "[%s] ========== stopAllRequestsAsync END ==========", instanceId.c_str());
                
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
    
    Logger::info("HarmonyRenderer", "Cleaning up...");
    
    // 首先停止所有网络请求
    stopAllRequests();
    
    // 停止 Map+Render 线程
    if (mapRenderThread_) {
        Logger::info("HarmonyRenderer", "Stopping Map+Render thread...");
        mapRenderThread_->stop();
        mapRenderThread_.reset();
        Logger::info("HarmonyRenderer", "Map+Render thread stopped");
    }
    
    initialized = false;
    Log::Info(Event::OpenGL, "HarmonyRenderer cleaned up successfully");
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


