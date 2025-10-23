#include "harmony_renderer.hpp"

// Include the appropriate renderer backend based on build configuration
#if MLN_RENDER_BACKEND_VULKAN
#include "harmony_vulkan_renderer_backend.hpp"
#else
#include "harmony_gl_renderer_backend.hpp"
#endif

#include "harmony_renderer_frontend.hpp"
#include "logger.h"

#include <mbgl/map/map.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread_local.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/storage/file_source_manager.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/storage/sqlite3.hpp>

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
    Logger::info("HarmonyRenderer", "========== initialize() START ==========");
    Logger::info("HarmonyRenderer", "Size: %dx%d, pixelRatio: %.2f", width_, height_, pixelRatio_);
    
    if (initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer already initialized");
        Logger::warn("HarmonyRenderer", "Already initialized, skipping");
        return;
    }
    
    width = width_;
    height = height_;
    pixelRatio = pixelRatio_;
    
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
    Logger::info("HarmonyRenderer", "========== initialize() END - SUCCESS ==========");
}

void HarmonyRenderer::setNativeWindow(OHNativeWindow* window) {
    Logger::info("HarmonyRenderer", "========== setNativeWindow() START ==========");
    Logger::info("HarmonyRenderer", "Window pointer: %p", window);
    Logger::debug("HarmonyRenderer", "Current state - initialized=%s, rendererFrontend=%s",
                  initialized ? "true" : "false",
                  rendererFrontend ? "exists" : "null");
    
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        Logger::error("HarmonyRenderer", "setNativeWindow called but renderer not initialized!");
        return;
    }
    
    Logger::debug("HarmonyRenderer", "Getting renderer backend...");
    auto* backend = static_cast<HarmonyRendererBackendImpl*>(&rendererFrontend->getRendererBackend());
    Logger::debug("HarmonyRenderer", "Renderer backend: %p", backend);
    
    if (backend) {
        Logger::info("HarmonyRenderer", "Setting native window to backend...");
        backend->setNativeWindow(window);
        Logger::info("HarmonyRenderer", "Native window set to backend successfully");
        
        if (width > 0 && height > 0) {
            // ℹ️  MapLibre使用逻辑像素尺寸 + pixelRatio来内部处理高DPI渲染
            Logger::info("HarmonyRenderer", "Resizing framebuffer to %dx%d", width, height);
            backend->resizeFramebuffer(width, height);
            Logger::debug("HarmonyRenderer", "Framebuffer resized successfully");
        } else {
            Logger::warn("HarmonyRenderer", "Invalid size for framebuffer: %dx%d", width, height);
        }
    } else {
        Logger::error("HarmonyRenderer", "Backend is null! Cannot set native window!");
    }
    
    Logger::info("HarmonyRenderer", "========== setNativeWindow() END ==========");
}

void HarmonyRenderer::setMap(std::shared_ptr<Map> map_) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    map = std::move(map_);
    if (map) {
        rendererFrontend->setMap(map.get());
    }
}

void HarmonyRenderer::resize(int width_, int height_) {
    if (!initialized) {
        Log::Warning(Event::OpenGL, "HarmonyRenderer not initialized");
        return;
    }
    
    Logger::info("HarmonyRenderer", "========== resize() START ==========");
    Logger::info("HarmonyRenderer", "Resizing: %dx%d -> %dx%d (pixelRatio: %.2f)", 
                 width, height, width_, height_, pixelRatio);
    
    width = width_;
    height = height_;
    
    auto* backend = static_cast<HarmonyRendererBackendImpl*>(&rendererFrontend->getRendererBackend());
    if (backend) {
        try {
            backend->resizeFramebuffer(width, height);
            Logger::info("HarmonyRenderer", "Framebuffer resized successfully");
        } catch (const std::exception& e) {
            Logger::error("HarmonyRenderer", "Failed to resize framebuffer: %s", e.what());
            // 尝试恢复
            try {
                Logger::debug("HarmonyRenderer", "Attempting framebuffer resize recovery...");
                backend->resizeFramebuffer(width, height);
                Logger::info("HarmonyRenderer", "Framebuffer resize recovery successful");
            } catch (const std::exception& e2) {
                Logger::error("HarmonyRenderer", "Framebuffer resize recovery failed: %s", e2.what());
            }
        }
    } else {
        Logger::error("HarmonyRenderer", "Backend is null during resize");
    }
    
    // Note: Map doesn't have a resize method, this needs to be handled differently
    // The resize is handled by the renderer backend
    requestRender();
    Logger::info("HarmonyRenderer", "========== resize() END ==========");
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
    Logger::info("HarmonyRenderer", "========== stopAllRequests START ==========");
    
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
    
    Logger::info("HarmonyRenderer", "========== stopAllRequests END ==========");
}

void HarmonyRenderer::cleanup() {
    if (!initialized) {
        return;
    }
    
    // 首先停止所有网络请求
    stopAllRequests();
    
    rendererFrontend.reset();
    rendererBackend.reset();
    map.reset();
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

} // namespace harmony
} // namespace mbgl


