#include "harmony_renderer_frontend.hpp"
#include "harmony_renderer_backend.hpp"
#include "logger.h"

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
    
    Logger::info("HarmonyRendererFrontend", "========== Constructor END ==========");
}

HarmonyRendererFrontend::~HarmonyRendererFrontend() {
    Logger::info("HarmonyRendererFrontend", "========== Destructor START ==========");
    
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
    Logger::info("HarmonyRendererFrontend", "========== update() CALLED - params=%p ==========", params.get());
    
    if (!params) {
        Logger::warn("HarmonyRendererFrontend", "update() called with null params");
        return;
    }
    
    Logger::info("HarmonyRendererFrontend", "update() - Checking RunLoop...");
    if (!runLoop) {
        Logger::error("HarmonyRendererFrontend", "Cannot update: RunLoop not initialized");
        return;
    }
    
    // CRITICAL DEADLOCK FIX: Check if we're already on the RunLoop thread
    // If yes, execute directly to avoid mutex deadlock in invoke()
    // 
    // Use thread ID comparison instead of RunLoop pointer comparison
    // to avoid potential issues with Scheduler::GetCurrent()
    Logger::info("HarmonyRendererFrontend", "update() - Checking thread ID...");
    auto currentThreadId = std::this_thread::get_id();
    bool onRunLoopThread = (currentThreadId == runLoopThreadId);
    
    Logger::info("HarmonyRendererFrontend", "update() - current thread is %s the RunLoop thread",
                 onRunLoopThread ? "SAME as" : "DIFFERENT from");
    
    // Define the rendering task
    auto renderTask = [this, params]() {
        if (params && renderer && rendererBackend) {
            try {
                Logger::debug("HarmonyRendererFrontend", "Processing update with params on RunLoop thread");
                
                // Activate the OpenGL context before rendering
                // This is CRITICAL - without BackendScope, rendering operations will crash
                auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
                gfx::RendererBackend& backendImpl = harmonyBackend->getImpl();
                gfx::BackendScope backendGuard{backendImpl};
                
                Logger::debug("HarmonyRendererFrontend", "BackendScope activated, rendering frame");
                
                // HarmonyOS渲染时序优化 - 确保在正确的时机进行渲染
                // 添加小延迟以确保EGL上下文完全就绪
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
                
                renderer->render(params);
                Logger::debug("HarmonyRendererFrontend", "Frame rendered successfully");
            } catch (const std::exception& e) {
                Logger::error("HarmonyRendererFrontend", "Render failed: %s", e.what());
            }
        } else {
            Logger::warn("HarmonyRendererFrontend", "Cannot render: params=%s, renderer=%s, backend=%s",
                         params ? "exists" : "null",
                         renderer ? "exists" : "null",
                         rendererBackend ? "exists" : "null");
        }
    };
    
    if (onRunLoopThread) {
        // Already on RunLoop thread - execute directly to avoid deadlock
        Logger::info("HarmonyRendererFrontend", "✅ SAME THREAD - executing directly to avoid deadlock");
        renderTask();
        Logger::info("HarmonyRendererFrontend", "✅ Direct execution completed");
    } else {
        // Different thread - dispatch via invoke()
        Logger::info("HarmonyRendererFrontend", "📤 DIFFERENT THREAD - about to call runLoop->invoke()...");
        runLoop->invoke(std::move(renderTask));
        Logger::info("HarmonyRendererFrontend", "📤 runLoop->invoke() returned - task dispatched");
    }
    Logger::info("HarmonyRendererFrontend", "========== update() END ==========");
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
    needsRender = true;
    Logger::debug("HarmonyRendererFrontend", "requestRender() called");
    
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

