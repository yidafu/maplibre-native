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

#include <thread>
#include <chrono>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

HarmonyRenderer::HarmonyRenderer() 
    : uniqueID(util::SimpleIdentity::Empty),
      weakFactory(std::make_shared<mapbox::base::WeakPtrFactory<Scheduler>>(this)) {
}

HarmonyRenderer::~HarmonyRenderer() {
    cleanup();
}

void HarmonyRenderer::initialize(int width_, int height_, float pixelRatio_) {
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
    std::string cachePath = "/data/storage/el2/base/cache";
    mapbox::sqlite::setTempPath(cachePath);
    Logger::debug("HarmonyRenderer", "SQLite temp path set to: %s", cachePath.c_str());
    
    // Initialize FileSourceManager singleton - this registers default file source factories
    // including HTTP network source for downloading styles and tiles
    FileSourceManager::get();
    Logger::info("HarmonyRenderer", "FileSourceManager initialized successfully");
    
    Logger::debug("HarmonyRenderer", "Creating renderer backend...");
    auto backend = std::make_unique<HarmonyRendererBackendImpl>();
    Logger::debug("HarmonyRenderer", "Renderer backend created: %p", backend.get());
    
    Logger::debug("HarmonyRenderer", "Creating HarmonyRendererFrontend...");
    rendererFrontend = std::make_unique<HarmonyRendererFrontend>(std::move(backend), pixelRatio);
    Logger::debug("HarmonyRenderer", "HarmonyRendererFrontend created: %p", rendererFrontend.get());
    
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
        // 🛡️ 首先停止渲染前端，防止新的渲染请求
        if (rendererFrontend) {
            Logger::debug("HarmonyRenderer", "Pausing renderer frontend...");
            rendererFrontend->pause();
        }
        
        // 🛡️ 给网络线程一点时间完成正在进行的操作
        // 这可以避免在清理时访问正在被销毁的对象
        Logger::debug("HarmonyRenderer", "Waiting for async operations to complete...");
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        
        // ⚠️ 注意：不要调用 map->cancelTransitions()
        // 原因：它会触发内部清理，可能访问正在被其他线程销毁的资源
        // Map对象会在自己的析构函数中安全地清理
        Logger::debug("HarmonyRenderer", "Skipping map->cancelTransitions() to avoid race condition");
        
        // 🛡️ FileSourceManager会在自己的析构函数中清理
        // 这里只记录日志，不强制清理
        if (auto fileSourceManager = mbgl::FileSourceManager::get()) {
            Logger::debug("HarmonyRenderer", "FileSourceManager will cleanup in its destructor");
        }
        
        Logger::info("HarmonyRenderer", "All request停止已启动，等待异步操作自然完成");
        
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
    
    Logger::info("HarmonyRenderer", "========== Cleanup START ==========");
    
    // 🛡️ 第零步：立即设置后端的停止标志
    // 这可以防止在析构期间activate()抛出异常
    if (rendererBackend) {
        auto* backend = getRendererBackend();
        if (backend) {
            Logger::debug("HarmonyRenderer", "Setting backend stopped flag...");
            backend->pauseRendering();
        }
    }
    
    // 🛡️ 第一步：停止所有请求（非阻塞）
    stopAllRequests();
    
    // 🛡️ 第二步：清理渲染前端（这会停止渲染线程）
    if (rendererFrontend) {
        Logger::debug("HarmonyRenderer", "Destroying renderer frontend...");
        rendererFrontend.reset();
        Logger::debug("HarmonyRenderer", "✅ Renderer frontend destroyed");
    }
    
    // 🛡️ 第三步：清理渲染后端
    if (rendererBackend) {
        Logger::debug("HarmonyRenderer", "Destroying renderer backend...");
        rendererBackend.reset();
        Logger::debug("HarmonyRenderer", "✅ Renderer backend destroyed");
    }
    
    // 🛡️ 第四步：清除Map引用（不持有所有权，由NativeMapView管理）
    map = nullptr;
    
    // 🛡️ 标记为未初始化
    initialized = false;
    
    Logger::info("HarmonyRenderer", "========== Cleanup END ==========");
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

} // namespace harmony
} // namespace mbgl


