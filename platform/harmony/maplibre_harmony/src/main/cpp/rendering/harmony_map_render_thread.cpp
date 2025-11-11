#include "harmony_map_render_thread.hpp"
#include "backends/harmony_gl_renderer_backend.hpp"
#include "backends/egl_display_manager.hpp"
#include "../utils/logger.h"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/thread_pool.hpp>
#include <mbgl/util/logging.hpp>

#include <future>
#include <chrono>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

// Static instance counter initialization
std::atomic<uint64_t> HarmonyMapRenderThread::globalInstanceCounter_{0};

HarmonyMapRenderThread::HarmonyMapRenderThread(
    std::unique_ptr<gfx::Backend> backend,
    float pixelRatio,
    MapObserver& observer,
    MapOptions&& mapOptions,
    ResourceOptions&& resourceOptions,
    ClientOptions&& clientOptions,
    const std::optional<std::string>& localIdeographFontFamily)
    : instanceId_(++globalInstanceCounter_),
      backend_(std::move(backend)),
      pixelRatio_(pixelRatio),
      mapObserver_(&observer),
      mapOptions_(std::move(mapOptions)),
      resourceOptions_(std::move(resourceOptions)),
      clientOptions_(std::move(clientOptions)),
      localIdeographFontFamily_(localIdeographFontFamily) {
}

HarmonyMapRenderThread::~HarmonyMapRenderThread() {
    // Stop the VSync manager
    if (vsyncManager_) {
        vsyncManager_->stop();
    }
    
    // Ensure the thread has stopped
    if (started_) {
        Logger::error("MapRenderThread", 
            "⚠️  IMPROPER SHUTDOWN: Thread still running in destructor!");
        Logger::error("MapRenderThread", 
            "    ALWAYS call stop() explicitly before destroying the instance.");
        stop();
    }
}

void HarmonyMapRenderThread::start() {
    if (started_) {
        Logger::error("MapRenderThread", "start() refused: already started");
        return;
    }
    
    // Use a condition variable to wait for initialization to finish
    std::unique_lock<std::mutex> lock(mutex_);
    
    // Launch the thread
    thread_ = std::thread([this]() {
        threadLoop();
    });
    
    // Wait for initialization to complete (up to 10 seconds)
    auto timeout = std::chrono::seconds(10);
    if (!cv_.wait_for(lock, timeout, [this]() { return initialized_.load(); })) {
        Logger::error("MapRenderThread", "Thread initialization timeout!");
        throw std::runtime_error("MapRenderThread initialization timeout");
    }
}

void HarmonyMapRenderThread::threadLoop() {
    // 🎯 Mark the current thread as the render thread
    threadId_ = std::this_thread::get_id();
    started_ = true;
    
    try {
        // Initialize all components
        if (!initialize()) {
            Logger::error("MapRenderThread", "Initialization failed");
            // Notify that initialization failed
            {
                std::lock_guard<std::mutex> lock(mutex_);
                initialized_ = false;
            }
            cv_.notify_one();
            return;
        }
        
        Logger::warn("MapRenderThread", "⚠️  EGL Context not initialized yet - waiting for setNativeWindow()");
        
        // ✅ Verify the scheduler is set
        auto* scheduler = Scheduler::GetCurrent();
        if (scheduler != runLoop_.get()) {
            Logger::error("MapRenderThread", "❌ SCHEDULER MISMATCH!");
        }
        
        // Notify that initialization is complete (must happen before runLoop_->run()!)
        {
            std::lock_guard<std::mutex> lock(mutex_);
            initialized_ = true;
        }
        cv_.notify_one();
        
        // 🎯 Unified threading model: the RunLoop handles every task
        // - Actor messages (FileSource callbacks, etc.)
        // - VSync callbacks (via renderRunLoop_->invoke())
        // - EGL rendering operations
        runLoop_->run();
        
        // Clean up resources
        cleanup();
        
    } catch (const std::exception& e) {
        Logger::error("MapRenderThread", "Exception in thread loop: %s", e.what());
    }
}

bool HarmonyMapRenderThread::initialize() {
    // Step 1: create the RunLoop (must happen first)
    runLoop_ = std::make_unique<util::RunLoop>();
    if (!runLoop_) {
        Logger::error("MapRenderThread", "Failed to create RunLoop");
        return false;
    }
    
    // Step 2: create the thread pool
    auto backgroundScheduler = Scheduler::GetBackground();
    if (!backgroundScheduler) {
        Logger::error("MapRenderThread", "Failed to get background scheduler");
        return false;
    }
    threadPool_ = std::make_unique<TaggedScheduler>(
        backgroundScheduler,
        util::SimpleIdentity::Empty
    );
    
    // Step 3: create the Renderer (does not require an EGL context yet)
    auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
    if (!glBackend) {
        Logger::error("MapRenderThread", "Invalid GL backend");
        return false;
    }
    
    gfx::RendererBackend& backendImpl = glBackend->getImpl();
    renderer_ = std::make_unique<Renderer>(backendImpl, pixelRatio_, localIdeographFontFamily_);
    if (!renderer_) {
        Logger::error("MapRenderThread", "Failed to create Renderer");
        return false;
    }
    
    // Step 4: create the Map (it automatically uses the current scheduler)
    map_ = std::make_unique<Map>(
        *this,  // RendererFrontend
        *mapObserver_,
        mapOptions_,
        resourceOptions_,
        clientOptions_
    );
    if (!map_) {
        Logger::error("MapRenderThread", "Failed to create Map");
        return false;
    }
    
    return true;
}

void HarmonyMapRenderThread::cleanup() {
    // ⚠️ Map and Renderer should already be destroyed in stop()
    // This is just a safety check and should not normally execute
    if (map_) {
        Logger::warn("MapRenderThread", "⚠️  Map still exists in cleanup() - destroying now");
        map_.reset();
    }
    
    if (renderer_) {
        Logger::warn("MapRenderThread", "⚠️  Renderer still exists in cleanup() - destroying now");
        renderer_.reset();
    }
    
    // Clean up EGL resources
    if (backend_) {
        auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
        glBackend->cleanupEGL();
        
        // ⚡ Critical fix: manually unregister the instance
        // Reason: gfx::Backend lacks a virtual destructor, so backend_.reset() does not invoke the subclass destructor
        // We must call unregisterInstance() manually to decrement the active-count
        EGLDisplayManager::getInstance().unregisterInstance();
        
        backend_.reset();
    }
    
    // Clean up the thread pool
    if (threadPool_) {
        threadPool_.reset();
    }
    
    // The VSync RunLoop reference was cleared during stop()
    
    // Destroy the RunLoop
    if (runLoop_) {
        runLoop_.reset();
    }
}

void HarmonyMapRenderThread::stop() {
    if (!started_) {
        Logger::warn("MapRenderThread", "Thread not started");
        return;
    }
    
    if (shouldStop_) {
        Logger::warn("MapRenderThread", "Already stopping");
        return;
    }
    
    // ✅ Step 1: mark destruction immediately to block new render requests
    destroying_.store(true);
    
    shouldStop_ = true;
    paused_ = true;

    // ✅ Step 2: stop VSync and clear any pending render state
    if (vsyncManager_) {
        vsyncManager_->stop();
    }
    pendingRender_ = false;
    pendingUpdateParams_.reset();
    
    // ✅ Step 3: clean up Map and Renderer on the render thread
    // Ensure all mailbox messages are processed before destruction
    if (runLoop_ && map_) {
        // ⚠️ Use shared_ptr to avoid promise lifetime issues
        auto cleanupPromise = std::make_shared<std::promise<void>>();
        auto cleanupFuture = cleanupPromise->get_future();
        
        try {
            runLoop_->invoke([this, cleanupPromise]() {
                try {
                    // Destroy the Map (this cancels any pending Actor messages)
                    if (map_) {
                        map_.reset();
                    }
                    
                    // Destroy the Renderer
                    if (renderer_) {
                        renderer_.reset();
                    }
                    
                    cleanupPromise->set_value();
                } catch (const std::exception& e) {
                    Logger::error("MapRenderThread", "Exception in cleanup lambda: %s", e.what());
                    cleanupPromise->set_exception(std::current_exception());
                }
            });
            
            // Wait for cleanup to finish (up to 5 seconds)
            auto status = cleanupFuture.wait_for(std::chrono::seconds(5));
            if (status == std::future_status::timeout) {
                Logger::error("MapRenderThread", "⚠️  Cleanup timeout after 5 seconds!");
                Logger::error("MapRenderThread", "⚠️  Will forcibly continue with RunLoop stop");
                // ⚠️ Continue even after timeout to avoid a permanent stall
            } else {
                try {
                    cleanupFuture.get();  // Check for exceptions
                } catch (const std::exception& e) {
                    Logger::error("MapRenderThread", "Exception during cleanup wait: %s", e.what());
                }
            }
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "Exception during cleanup invoke: %s", e.what());
        }
    }
    
    // ✅ Step 4: stop the RunLoop (this drains all pending messages)
    if (runLoop_) {
        runLoop_->stop();
    }
    
    // ✅ Step 5: wait for the thread to exit
    if (thread_.joinable()) {
        thread_.join();
    }
    
    started_ = false;
    initialized_ = false;
}

void HarmonyMapRenderThread::invoke(std::function<void()> task) {
    if (!task) {
        Logger::warn("MapRenderThread", "invoke() called with null task");
        return;
    }
    
    // ✅ Check the destruction flag
    if (destroying_.load()) {
        Logger::warn("MapRenderThread", "invoke() ignored: instance is being destroyed");
        return;
    }
    
    if (shouldStop_) {
        Logger::warn("MapRenderThread", "invoke() ignored: thread is stopping");
        return;
    }

    // Check whether we are already on the map/render thread
    if (isOnThread()) {
        // ✅ Ensure the scheduler is set correctly
        Scheduler::SetCurrent(runLoop_.get());
        task();
    } else {
        if (!runLoop_) {
            Logger::error("MapRenderThread", "RunLoop not initialized");
            return;
        }
        
        // ✅ Dispatch to the RunLoop so execution happens on the correct thread
        runLoop_->invoke([this, task = std::move(task)]() {
            // Ensure the scheduler is set before executing the task
            Scheduler::SetCurrent(runLoop_.get());
            task();
        });
    }
}

bool HarmonyMapRenderThread::isOnThread() const {
    return std::this_thread::get_id() == threadId_;
}

void HarmonyMapRenderThread::update(std::shared_ptr<UpdateParameters> params) {
    // ✅ Check the destruction flag (highest priority)
    if (destroying_.load()) {
        Logger::warn("MapRenderThread", "update() ignored: instance is being destroyed");
        return;
    }
    
    if (shouldStop_) {
        Logger::warn("MapRenderThread", "update() ignored: thread is stopping");
        return;
    }

    if (!renderer_ || !backend_) {
        Logger::error("MapRenderThread", "Renderer or backend not initialized");
        return;
    }
    
    if (paused_) {
        return;
    }
    
    // ✅ VSync-synchronized rendering: store the parameters and request VSync instead of rendering immediately
    invoke([this, params]() {
        // If a VSync manager is available, use VSync for synchronized rendering
        if (vsyncManager_ && vsyncManager_->isAvailable()) {
            // Save the pending render parameters
            pendingUpdateParams_ = params;
            pendingRender_ = true;
            
            // Request a VSync frame; the actual render runs inside the VSync callback
            vsyncManager_->requestFrame([this]() {
                onVSyncFrame();
            });
        } else {
            // If VSync is unavailable, render immediately as a fallback
            // Execute here instead of calling onVSyncFrame() to avoid thread scheduling issues
            if (params && renderer_ && backend_) {
                try {
                    auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
                    gfx::BackendScope scope{glBackend->getImpl()};
                    renderer_->render(params);
                } catch (const std::exception& e) {
                    Logger::error("MapRenderThread", "Immediate render failed: %s", e.what());
                }
            }
        }
    });
}

void HarmonyMapRenderThread::setObserver(RendererObserver& observer) {
    Logger::info("MapRenderThread", "setObserver() called");
    
    invoke([this, &observer]() {
        if (renderer_) {
            renderer_->setObserver(&observer);
        }
    });
}

void HarmonyMapRenderThread::reset() {
    Logger::info("MapRenderThread", "reset() called");
    // Note: Renderer doesn't have a reset() method in the current API
    // This method is part of RendererFrontend interface but may not be needed
}

const TaggedScheduler& HarmonyMapRenderThread::getThreadPool() const {
    if (!threadPool_) {
        throw std::runtime_error("ThreadPool not initialized");
    }
    return *threadPool_;
}

void HarmonyMapRenderThread::setNativeWindow(void* window) {
    if (!backend_) {
        Logger::error("MapRenderThread", "Backend not initialized");
        return;
    }
    
    // ⚠️ Critical fix: perform all EGL operations on the render thread
    // This includes initializing the display, surface, and context
    invoke([this, window]() {
        nativeWindow_ = window;
        
        auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
        
        // If EGL resources already exist, clean them up before rebuilding to avoid reusing state across sessions
        // This relies on the backend's setNativeWindow implementation being idempotent
        // Step 1: initialize the display and surface on the render thread
        Logger::info("MapRenderThread", "Initializing EGL Display and Surface on render thread...");
        glBackend->setNativeWindow(window);
        if (!glBackend->hasValidSurface()) {
            Logger::error("MapRenderThread", "Failed to initialize EGL surface; rendering remains paused");
            paused_ = true;
            return;
        }
        // Step 2: do not create the context here!
        // 🎯 Key point: invoke() callbacks run on a thread-pool worker, not on the render thread
        // The context must be created on the real render thread (renderLoopThread)
        // It will be created lazily on the first activate()
        Logger::info("MapRenderThread", "⏳ EGL Context will be created lazily on first activate() in render thread");
        Logger::info("MapRenderThread", "   Current thread: %lu (this is NOT the render thread)",
                     std::hash<std::thread::id>{}(std::this_thread::get_id()));

        // Mark the renderer context as lost so resources will be rebuilt in the new context
        if (renderer_) {
            Logger::info("MapRenderThread", "Marking context lost and reducing memory");
            renderer_->markContextLost();
            renderer_->reduceMemoryUse();
        }

        // Ensure rendering can resume
        paused_ = false;
        
        // Initialize the VSync manager
        try {
            vsyncManager_ = std::make_unique<HarmonyVSyncManager>();
            vsyncManager_->setOwnerInstanceId(instanceId_);
            
            // 🎯 Provide the RunLoop so VSync callbacks are scheduled through it
            vsyncManager_->setRunLoop(runLoop_.get());
            
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "Failed to initialize VSync Manager: %s", e.what());
            Logger::warn("MapRenderThread", "Continuing without VSync (will use immediate render)");
        }
        
        // ✅ Critical fix: reset VSync-related state
        // Make sure pendingRender_ is cleared during reinitialization
        pendingRender_ = false;
        pendingUpdateParams_.reset();
        
        // ✅ If we have a remembered size, apply it immediately and trigger an initial render
        if (lastWidth_ > 0 && lastHeight_ > 0) {
            auto* glBackend2 = static_cast<HarmonyGLRendererBackend*>(backend_.get());
            if (glBackend2) {
                glBackend2->resizeFramebuffer(lastWidth_, lastHeight_);
            }
            if (map_) {
                map_->setSize(Size{static_cast<uint32_t>(lastWidth_), static_cast<uint32_t>(lastHeight_)});
            }
        }

        // Trigger the first render
        if (map_) {
            map_->triggerRepaint();
        }
    });
}

void HarmonyMapRenderThread::pause() {
    Logger::info("MapRenderThread", "pause() called");
    paused_ = true;
}

void HarmonyMapRenderThread::resume() {
    Logger::info("MapRenderThread", "resume() called");
    paused_ = false;
    
    // ✅ Critical fix: reset VSync state when resuming to avoid stale flags
    invoke([this]() {
        pendingRender_ = false;
        pendingUpdateParams_.reset();
    });
}

Map& HarmonyMapRenderThread::getMap() {
    if (!map_) {
        throw std::runtime_error("Map not initialized");
    }
    return *map_;
}

gfx::RendererBackend& HarmonyMapRenderThread::getRendererBackend() {
    if (!backend_) {
        throw std::runtime_error("Backend not initialized");
    }
    
    auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
    return glBackend->getImpl();
}

void HarmonyMapRenderThread::resizeFramebuffer(int width, int height) {
    // Record the most recent logical size (used when rebuilding the window)
    lastWidth_ = width;
    lastHeight_ = height;

    invoke([this, width, height]() {
        if (!backend_) {
            Logger::error("MapRenderThread", "Backend not initialized, cannot resize");
            return;
        }
        
        auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
        if (glBackend) {
            glBackend->resizeFramebuffer(width, height);
        } else {
            Logger::error("MapRenderThread", "Invalid backend type");
        }
    });
}

std::vector<Feature> HarmonyMapRenderThread::queryRenderedFeatures(
    const ScreenCoordinate& point,
    const RenderedQueryOptions& options) const {
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "queryRenderedFeatures: Renderer not initialized");
        return {};
    }
    
    return renderer_->queryRenderedFeatures(point, options);
}

std::vector<Feature> HarmonyMapRenderThread::queryRenderedFeatures(
    const ScreenBox& box,
    const RenderedQueryOptions& options) const {
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "queryRenderedFeatures: Renderer not initialized");
        return {};
    }
    
    return renderer_->queryRenderedFeatures(box, options);
}

std::vector<Feature> HarmonyMapRenderThread::querySourceFeatures(
    const std::string& sourceId,
    const SourceQueryOptions& options) const {
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "querySourceFeatures: Renderer not initialized");
        return {};
    }
    
    return renderer_->querySourceFeatures(sourceId, options);
}

void HarmonyMapRenderThread::setOnFpsChangedCallback(std::function<void(double)> callback) {
    fpsCallback_ = std::move(callback);
    measureFps_ = (fpsCallback_ != nullptr);
    if (measureFps_) {
        lastFrameTime_ = std::chrono::steady_clock::now();
        Logger::info("MapRenderThread", "FPS measurement enabled");
    } else {
        Logger::info("MapRenderThread", "FPS measurement disabled");
    }
}

void HarmonyMapRenderThread::enableFpsMeasurement(bool enable) {
    measureFps_ = enable;
    if (enable && !fpsCallback_) {
        Logger::warn("MapRenderThread", "FPS measurement enabled but no callback set");
    }
}

// ==================== VSync control ====================

void HarmonyMapRenderThread::onVSyncFrame() {
    // ✅ Check the destruction flag (must happen before assertions!)
    if (destroying_.load()) {
        return;
    }
    
    if (paused_) {
        return;
    }
    
    // 🎯 Two-thread model: VSync now wakes the render thread via a condition variable
    // Assert to guarantee we are always on the render thread
    // ⚠️ Perform this assertion after the destroying_ check because callbacks may arrive late during teardown
    if (!isOnThread()) {
        Logger::warn("MapRenderThread", "onVSyncFrame invoked off render thread, redispatching");
        if (runLoop_) {
            runLoop_->invoke([self = this]() {
                if (self->destroying_.load()) {
                    return;
                }
                self->onVSyncFrame();
            });
        }
        return;
    }
    
    // Fetch the pending render parameters
    if (!pendingRender_.load()) {
        return;
    }
    
    pendingRender_ = false;
    auto params = pendingUpdateParams_;
    pendingUpdateParams_.reset();
    
    // Execute the actual render
    if (params && renderer_ && backend_) {
        try {
            // Begin frame timing
            auto frameStartTime = std::chrono::steady_clock::now();
            
            auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
            gfx::BackendScope scope{glBackend->getImpl()};
            
            renderer_->render(params);
            
            // FPS measurement (mirrors Android MapRenderer::updateFps)
            if (measureFps_.load() && fpsCallback_) {
                auto currentTime = std::chrono::steady_clock::now();
                auto elapsedNanos = std::chrono::duration_cast<std::chrono::nanoseconds>(
                    currentTime - lastFrameTime_).count();
                
                if (elapsedNanos > 0) {
                    // Compute FPS: fps = 1E9 / elapsed_nanoseconds
                    double fps = 1.0e9 / static_cast<double>(elapsedNanos);
                    fpsCallback_(fps);
                }
                
                lastFrameTime_ = currentTime;
            }
            
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "Render failed on VSync: %s", e.what());
        }
    } else if (map_) {
        // If no parameters are pending, request another repaint (Map decides whether it is necessary)
        
        map_->triggerRepaint();
    }
    
    // Note: if further rendering is needed, Map will call update() again inside onDidFinishRenderingFrame
    // This re-requests VSync and maintains the synchronized render loop
}

} // namespace harmony
} // namespace mbgl
