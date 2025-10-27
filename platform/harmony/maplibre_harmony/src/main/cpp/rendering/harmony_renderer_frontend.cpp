#include "harmony_renderer_frontend.hpp"
#include "backends/harmony_renderer_backend.hpp"
#include "vsync/harmony_vsync_manager.hpp"
#include "utils/logger.h"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gl/renderer_backend.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread_local.hpp>
#include <mbgl/actor/actor_ref.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <thread>
#include <chrono>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

static util::ThreadLocal<HarmonyRendererFrontend> currentRendererFrontend;

// Note: ForwardingRendererObserver was removed to avoid RunLoop dependency
// Observer callbacks are now called directly on the render thread

HarmonyRendererFrontend::HarmonyRendererFrontend(std::unique_ptr<gfx::Backend> backend,
                                                 float pixelRatio_)
    : pixelRatio(pixelRatio_),
      rendererBackend(std::move(backend)) {
    currentRendererFrontend.set(this);
    
    Logger::info("HarmonyRendererFrontend", "========== Constructor START ==========");
    Logger::debug("HarmonyRendererFrontend", "pixelRatio=%.2f, backend=%p", pixelRatio, rendererBackend.get());
    
    try {
        // Create the Renderer using HarmonyRendererBackend::getImpl()
        // Note: Renderer creation must happen BEFORE starting RunLoop thread
        Logger::debug("HarmonyRendererFrontend", "Creating Renderer...");
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        gfx::RendererBackend& glBackend = harmonyBackend->getImpl();
        renderer = std::make_unique<Renderer>(glBackend, pixelRatio);
        Logger::info("HarmonyRendererFrontend", "Renderer created successfully: %p", renderer.get());
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRendererFrontend", "Failed to create Renderer: %s", e.what());
        // Re-throw to prevent using invalid renderer
        throw;
    }
    
    // Create and start RunLoop in background thread
    // IMPORTANT: AsyncTask must be created INSIDE the RunLoop thread!
    Logger::debug("HarmonyRendererFrontend", "Starting RunLoop thread...");
    
    std::promise<void> runLoopReady;
    auto runLoopReadyFuture = runLoopReady.get_future();
    
    runLoopThread = std::thread([this, &runLoopReady]() {
        // Save thread ID for deadlock avoidance in update()
        runLoopThreadId = std::this_thread::get_id();
        
        // Create RunLoop for this thread (will set thread-local automatically)
        runLoop = std::make_unique<util::RunLoop>();
        Logger::info("HarmonyRendererFrontend", "RunLoop thread started, loop=%p, threadId=%p", 
                     runLoop.get(), &runLoopThreadId);
        
        // Signal that RunLoop is ready (before starting the loop)
        runLoopReady.set_value();
        
        // Run the loop - this will process all invoke() calls from update()
        Logger::info("HarmonyRendererFrontend", "Starting RunLoop::run()...");
        runLoop->run();
        
        Logger::info("HarmonyRendererFrontend", "RunLoop thread ended");
    });
    
    // Wait for RunLoop to be fully initialized before returning
    runLoopReadyFuture.wait();
    Logger::debug("HarmonyRendererFrontend", "RunLoop thread ready");
    
    // 🎯 初始化 VSync 管理器（尝试使用系统级 VSync）
    try {
        Logger::info("HarmonyRendererFrontend", "Creating HarmonyVSyncManager...");
        vsyncManager_ = std::make_unique<HarmonyVSyncManager>();
        
        if (vsyncManager_->isAvailable()) {
            useVSync_ = true;
            Logger::info("HarmonyRendererFrontend", "✅ VSync enabled - will use system-level frame synchronization");
        } else {
            Logger::warn("HarmonyRendererFrontend", "⚠️ VSync not available - falling back to manual throttling");
            useVSync_ = false;
            vsyncManager_.reset();
        }
    } catch (const std::exception& e) {
        Logger::error("HarmonyRendererFrontend", "Failed to create VSync manager: %s - falling back to manual throttling", e.what());
        useVSync_ = false;
        vsyncManager_.reset();
    }
    
    Logger::info("HarmonyRendererFrontend", "========== Constructor END ==========");
}

HarmonyRendererFrontend::~HarmonyRendererFrontend() {
    Logger::info("HarmonyRendererFrontend", "========== Destructor START ==========");
    
    // Stop VSync manager if exists
    if (vsyncManager_) {
        Logger::debug("HarmonyRendererFrontend", "Stopping VSync manager...");
        vsyncManager_->stop();
        vsyncManager_.reset();
        Logger::debug("HarmonyRendererFrontend", "VSync manager stopped and destroyed");
    }
    
    // Stop the RunLoop if it exists
    if (runLoop) {
        Logger::debug("HarmonyRendererFrontend", "Stopping RunLoop...");
        runLoop->stop();
    }
    
    // Wait for RunLoop thread to finish
    if (runLoopThread.joinable()) {
        Logger::debug("HarmonyRendererFrontend", "Waiting for RunLoop thread to join...");
        runLoopThread.join();
        Logger::debug("HarmonyRendererFrontend", "RunLoop thread joined");
    }
    
    currentRendererFrontend.set(nullptr);
    Logger::info("HarmonyRendererFrontend", "========== Destructor END ==========");
}

// Implement pure virtual methods from RendererFrontend
void HarmonyRendererFrontend::reset() {
    Logger::info("HarmonyRendererFrontend", "reset() called");
    if (renderer) {
        // Renderer cleanup is handled by unique_ptr
    }
}

void HarmonyRendererFrontend::setObserver(RendererObserver& observer) {
    Logger::info("HarmonyRendererFrontend", "========== setObserver() START ==========");
    Logger::debug("HarmonyRendererFrontend", "Setting observer for Renderer (direct mode)");
    
    if (renderer) {
        // Directly set observer without ForwardingRendererObserver
        // Events will be called synchronously in render thread
        // This avoids the RunLoop dependency issue
        renderer->setObserver(&observer);
        Logger::info("HarmonyRendererFrontend", "Observer set successfully (direct mode)");
    } else {
        Logger::error("HarmonyRendererFrontend", "Cannot set observer: renderer is null");
    }
    
    Logger::info("HarmonyRendererFrontend", "========== setObserver() END ==========");
}

void HarmonyRendererFrontend::update(std::shared_ptr<UpdateParameters> params) {
    if (!params) {
        return;
    }
    
    // 🚀 请求队列机制：存储最新的参数，然后调度渲染
    {
        std::lock_guard<std::mutex> lock(updateParamsMutex);
        updateParams = std::move(params);
    }
    
    // 增加待处理请求计数
    pendingRequests++;
    
    // 调度渲染（会自动防抖）
    scheduleRender();
}

void HarmonyRendererFrontend::scheduleRender() {
    // 🔧 防抖机制：如果已经有渲染请求在队列中，不重复添加
    // 这类似于 Android 的 requestRender() 行为
    bool expected = false;
    if (!renderRequested.compare_exchange_strong(expected, true)) {
        return;
    }
    
    // 🎯 使用 VSync 同步（优先）
    if (useVSync_ && vsyncManager_) {
        // 使用系统级 VSync 调度
        vsyncManager_->requestFrame([this]() {
            // 重置请求标志，允许下次调度
            renderRequested = false;
            
            // 如果有待处理的请求，执行渲染
            if (pendingRequests > 0) {
                pendingRequests.exchange(0);
                performRender();
            }
        });
    } else {
        // 🔧 降级方案：使用 RunLoop 异步调度（手动节流）
        if (!runLoop) {
            Logger::error("HarmonyRendererFrontend", "Cannot schedule render: RunLoop not initialized");
            renderRequested = false;  // 重置标志
            return;
        }
        
        runLoop->invoke([this]() {
            // 重置请求标志，允许下次调度
            renderRequested = false;
            
            // 如果有待处理的请求，执行渲染
            if (pendingRequests > 0) {
                pendingRequests.exchange(0);
                performRender();
            }
        });
    }
}

void HarmonyRendererFrontend::performRender() {
    // 检查是否暂停
    if (renderingPaused) {
        Logger::warn("HarmonyRendererFrontend", "performRender() - rendering paused, skipping");
        return;
    }
    
    // 🎯 VSync 模式：不需要手动节流（系统级同步）
    // 🔧 降级模式：使用手动帧率限制
    if (!useVSync_) {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - lastFrameTime);
        
        if (elapsed < minFrameInterval) {
            return;  // 跳过此帧
        }
        
        lastFrameTime = now;
    }
    
    // 🔧 重要：重置 needsRender 标志
    if (needsRender) {
        needsRender = false;
    }
    
    // 获取最新的更新参数
    std::shared_ptr<UpdateParameters> params;
    {
        std::lock_guard<std::mutex> lock(updateParamsMutex);
        params = updateParams;
    }
    
    if (!params || !renderer || !rendererBackend) {
        Logger::warn("HarmonyRendererFrontend", "performRender() - missing params/renderer/backend");
        return;
    }
    
    // CRITICAL DEADLOCK FIX: Check if we're already on the RunLoop thread
    auto currentThreadId = std::this_thread::get_id();
    bool onRunLoopThread = (currentThreadId == runLoopThreadId);
    
    // 执行渲染
    try {
        // Activate the OpenGL context before rendering
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        gfx::RendererBackend& backendImpl = harmonyBackend->getImpl();
        gfx::BackendScope backendGuard{backendImpl};
        
        // HarmonyOS渲染时序优化 - 小延迟确保EGL上下文就绪
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        
        renderer->render(params);
        
        // 🔧 渲染成功，重置错误计数
        consecutiveErrors = 0;
        
    } catch (const std::runtime_error& e) {
        // 🔧 改进的错误处理：不要立即永久停止
        consecutiveErrors++;
        Logger::error("HarmonyRendererFrontend", "Render failed (%d/%d): %s", 
                      consecutiveErrors.load(), 10, e.what());
        
        // 只有连续错误超过阈值才停止渲染
        if (consecutiveErrors >= 10) {
            Logger::error("HarmonyRendererFrontend", "Too many consecutive errors, pausing rendering");
            renderingPaused = true;
        }
    } catch (const std::exception& e) {
        consecutiveErrors++;
        Logger::error("HarmonyRendererFrontend", "Render failed (%d/%d): %s", 
                      consecutiveErrors.load(), 10, e.what());
        
        if (consecutiveErrors >= 10) {
            Logger::error("HarmonyRendererFrontend", "Too many consecutive errors, pausing rendering");
            renderingPaused = true;
        }
    }
}

const TaggedScheduler& HarmonyRendererFrontend::getThreadPool() const {
    // Create a TaggedScheduler using the background scheduler
    static std::unique_ptr<TaggedScheduler> scheduler;
    if (!scheduler) {
        auto backgroundScheduler = Scheduler::GetBackground();
        scheduler = std::make_unique<TaggedScheduler>(backgroundScheduler, util::SimpleIdentity::Empty);
    }
    return *scheduler;
}

void HarmonyRendererFrontend::setMap(Map* map_) {
    Logger::debug("HarmonyRendererFrontend", "setMap() called: %p", map_);
    map = map_;
}

void HarmonyRendererFrontend::render(Map& /* map */) {
    if (renderingPaused) {
        return;
    }
    try {
        // Rendering is handled through the update() mechanism
        Logger::debug("HarmonyRendererFrontend", "render() called");
    } catch (const std::exception& ex) {
        Log::Error(Event::OpenGL, "Error during rendering: " + std::string(ex.what()));
    }
}

void HarmonyRendererFrontend::setRenderingMode(MapObserver::RenderMode mode) {
    Logger::debug("HarmonyRendererFrontend", "setRenderingMode: %d", static_cast<int>(mode));
    renderingMode = mode;
}

void HarmonyRendererFrontend::requestRender() {
    if (renderingPaused) {
        return;
    }
    
    // 防抖：如果已经有待处理的渲染请求，忽略新请求
    // 这可以防止过度的渲染请求堆积
    if (needsRender) {
        return;
    }
    
    needsRender = true;
    
    // Note: Rendering is triggered through the update() mechanism
    // No need to explicitly trigger rendering here
    if (!map) {
        Logger::warn("HarmonyRendererFrontend", "Cannot trigger render: map is null");
    }
}

void HarmonyRendererFrontend::processRenderRequest() {
    if (!needsRender || renderingPaused || !map) {
        return;
    }
    needsRender = false;
    Logger::debug("HarmonyRendererFrontend", "processRenderRequest()");
}

void HarmonyRendererFrontend::pause() {
    Logger::info("HarmonyRendererFrontend", "pause() called");
    renderingPaused = true;
}

void HarmonyRendererFrontend::resume() {
    Logger::info("HarmonyRendererFrontend", "resume() called");
    if (renderingPaused) {
        renderingPaused = false;
        consecutiveErrors = 0;  // 重置错误计数
        Logger::info("HarmonyRendererFrontend", "Rendering resumed, error count reset");
        if (map) {
            requestRender();
        }
    }
}

gfx::Backend& HarmonyRendererFrontend::getRendererBackend() {
    return *rendererBackend;
}

} // namespace harmony
} // namespace mbgl

