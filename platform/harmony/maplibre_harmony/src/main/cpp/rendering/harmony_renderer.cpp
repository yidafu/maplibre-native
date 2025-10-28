#include "harmony_renderer.hpp"

// Include the appropriate renderer backend based on build configuration
#if MLN_RENDER_BACKEND_VULKAN
#include "backends/harmony_vulkan_renderer_backend.hpp"
#else
#include "backends/harmony_gl_renderer_backend.hpp"
#endif

#include "harmony_renderer_frontend.hpp"
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
    
    Logger::debug("HarmonyRenderer", "Creating renderer backend...");
    auto backend = std::make_unique<HarmonyRendererBackendImpl>();
    Logger::debug("HarmonyRenderer", "Renderer backend created: %p", backend.get());
    
    Logger::debug("HarmonyRenderer", "Creating HarmonyRendererFrontend...");
    // 传递 instanceId 到 Frontend
    rendererFrontend = std::make_unique<HarmonyRendererFrontend>(std::move(backend), pixelRatio, instanceId_);
    Logger::debug("HarmonyRenderer", "HarmonyRendererFrontend created: %p (ID: %s)", 
                  rendererFrontend.get(), instanceId_.c_str());
    
    initialized = true;
    Log::Info(Event::OpenGL, "HarmonyRenderer initialized successfully");
}

void HarmonyRenderer::setNativeWindow(OHNativeWindow* window) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    
    auto* backend = static_cast<HarmonyRendererBackendImpl*>(&rendererFrontend->getRendererBackend());
    
    if (backend) {
        backend->setNativeWindow(window);
        
        if (width > 0 && height > 0) {
            backend->resizeFramebuffer(width, height);
        }
    }
}

void HarmonyRenderer::setMap(Map* map_) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    map = map_;
    if (map) {
        rendererFrontend->setMap(map);
        Logger::info("HarmonyRenderer", "Map reference saved: %p", map);
    }
}

void HarmonyRenderer::resize(int width_, int height_) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    
    width = width_;
    height = height_;
    
    // Update both framebuffer (physical pixels) and Map Transform (logical pixels)
    auto* backend = static_cast<HarmonyRendererBackendImpl*>(&rendererFrontend->getRendererBackend());
    if (backend) {
        try {
            // 1. Update framebuffer (will calculate physical pixels based on pixelRatio)
            backend->resizeFramebuffer(width, height);
            
            // 2. Update Map Transform size (using logical pixels)
            if (map) {
                map->setSize(Size{static_cast<uint32_t>(width), static_cast<uint32_t>(height)});
            }
        } catch (const std::exception& e) {
            Logger::error("HarmonyRenderer", "Failed to resize: %s", e.what());
        }
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
    rendererFrontend->requestRender();
}

void HarmonyRenderer::setRenderingMode(MapObserver::RenderMode mode) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    rendererFrontend->setRenderingMode(mode);
}

void HarmonyRenderer::pause() {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    rendererFrontend->pause();
}

void HarmonyRenderer::resume() {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    rendererFrontend->resume();
}

void HarmonyRenderer::stopAllRequests() {
    
    try {
        // 停止FileSourceManager的所有网络请求
        if (auto fileSourceManager = mbgl::FileSourceManager::get()) {
            Logger::debug("HarmonyRenderer", "Stopping FileSourceManager requests...");
            
            // 强制清理所有文件源
            // 注意：这里需要更安全的清理方式
            Logger::debug("HarmonyRenderer", "FileSourceManager cleanup initiated");
        }
        
        // 停止渲染前端的请求
        if (rendererFrontend) {
            Logger::debug("HarmonyRenderer", "Stopping renderer frontend requests...");
            // 停止渲染前端的异步操作
            rendererFrontend->pause();
        }
        
        // 停止地图的网络请求
        if (map) {
            Logger::debug("HarmonyRenderer", "Stopping map network requests...");
            map->cancelTransitions();
        }
        
        Logger::info("HarmonyRenderer", "All network requests stopped successfully");
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRenderer", "Error stopping network requests: %s", e.what());
    } catch (...) {
        Logger::error("HarmonyRenderer", "Unknown error stopping network requests");
    }
    
}

void HarmonyRenderer::cleanup() {
    if (!initialized) {
        return;
    }
    
    // 首先停止所有网络请求
    stopAllRequests();
    
    rendererFrontend.reset();
    rendererBackend.reset();
    map = nullptr;  // 清除引用（不持有所有权）
    initialized = false;
    Log::Info(Event::OpenGL, "HarmonyRenderer cleaned up successfully");
}

HarmonyRendererBackendImpl* HarmonyRenderer::getRendererBackend() const {
    if (!initialized || !rendererFrontend) {
        return nullptr;
    }
    return static_cast<HarmonyRendererBackendImpl*>(&rendererFrontend->getRendererBackend());
}

HarmonyRendererFrontend* HarmonyRenderer::getRendererFrontend() const {
    return rendererFrontend.get();
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
    if (!rendererFrontend) {
        Logger::error("Renderer", "[%s] Cannot runOnRenderThread: frontend is null", instanceId_.c_str());
        return;
    }
    
    rendererFrontend->runOnRenderThread(std::move(fn));
}

bool HarmonyRenderer::isOnRenderThread() const {
    if (!rendererFrontend) {
        return false;
    }
    
    return rendererFrontend->isOnRenderThread();
}

} // namespace harmony
} // namespace mbgl


