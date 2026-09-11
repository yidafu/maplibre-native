#include "harmony_map_render_thread.hpp"
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
    std::unique_ptr<HarmonyRendererBackend> backend,
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

    // Assign the thread ID on the starting thread: the std::thread
    // construction happens-before the thread function, so the new thread (and
    // any JS-thread caller after start() returns) observes it without a race.
    threadId_ = thread_.get_id();

    // Wait for initialization to complete (up to 10 seconds); a failed
    // initialization reports through initFailed_ instead of stalling here.
    auto timeout = std::chrono::seconds(10);
    if (!cv_.wait_for(lock, timeout, [this]() {
            return initialized_.load() || initFailed_.load();
        })) {
        Logger::error("MapRenderThread", "Thread initialization timeout!");
        throw std::runtime_error("MapRenderThread initialization timeout");
    }

    if (!initialized_.load()) {
        Logger::error("MapRenderThread", "Thread initialization failed");
        throw std::runtime_error("MapRenderThread initialization failed");
    }
}

void HarmonyMapRenderThread::threadLoop() {
    // 🎯 Mark the current thread as the render thread (threadId_ was assigned
    // by start() before this function could run)
    started_ = true;

    try {
        // Initialize all components
        if (!initialize()) {
            Logger::error("MapRenderThread", "Initialization failed");
            // Notify that initialization failed so start() can fail fast
            {
                std::lock_guard<std::mutex> lock(mutex_);
                initFailed_ = true;
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
    // CRITICAL: Use Type::New (not Default!) to create a dedicated libuv loop.
    // uv_default_loop() is a process-wide singleton -- if other threads also run
    // uv_run() on it, async signals (e.g. VSync callbacks dispatched via
    // uv_async_send) can be processed on the wrong thread, causing
    // "onVSyncFrame invoked off render thread, redispatching" to loop infinitely.
    runLoop_ = std::make_unique<util::RunLoop>(util::RunLoop::Type::New);
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
    
    // Step 3: create the Renderer (does not require a context yet)
    auto* backend = backend_.get();
    if (!backend) {
        Logger::error("MapRenderThread", "Invalid rendering backend");
        return false;
    }

    gfx::RendererBackend& backendImpl = backend->getImpl();
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
        clientOptions_,
        actionJournalOptions_   // Action journal options
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
    
    // Release backend resources (EGL context/surface or Vulkan device work)
    if (backend_) {
        backend_->cleanupBackend();
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
    // pendingUpdateParams_ is a shared_ptr the render thread reads in
    // update()/onVSyncFrame(); reset it ON the render thread instead of here
    // to keep the access serialized (stop() runs on the JS thread).
    if (runLoop_) {
        runLoop_->invoke([this]() {
            pendingUpdateParams_.reset();
        });
    }
    
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
    
    const bool onRenderThread = isOnThread();

    // ✅ Allow in-flight cleanup work on the render thread even during teardown.
    if (!onRenderThread) {
        if (destroying_.load()) {
            Logger::warn("MapRenderThread", "invoke() ignored: instance is being destroyed");
            return;
        }
        
        if (shouldStop_) {
            Logger::warn("MapRenderThread", "invoke() ignored: thread is stopping");
            return;
        }
    }

    // Check whether we are already on the map/render thread
    if (onRenderThread) {
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
                    gfx::BackendScope scope{backend_->getImpl()};
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
    
    // ⚠️ Critical fix: perform all window-binding operations on the render thread
    // This includes initializing the display/surface (GL) or instance/surface/swapchain (Vulkan)
    invoke([this, window]() {
        nativeWindow_ = window;

        // If backend resources already exist, the backends rebuild them before
        // binding the new window (their setNativeWindow implementations are
        // idempotent for repeated calls)
        // Step 1: initialize the backend surface on the render thread
        Logger::info("MapRenderThread", "Initializing backend surface on render thread...");
        backend_->setNativeWindow(window);
        if (!backend_->hasValidSurface()) {
            Logger::error("MapRenderThread", "Failed to initialize rendering surface; rendering remains paused");
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
            backend_->resizeFramebuffer(lastWidth_, lastHeight_);
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
        // CONTINUOUS mode needs an explicit kick: the pump died while paused
        // because onVSyncFrame() returns early before re-arming VSync.
        if (refreshMode_.load(std::memory_order_relaxed) == 0
            && vsyncManager_ && vsyncManager_->isAvailable()) {
            vsyncManager_->requestFrame([this]() { onVSyncFrame(); });
        }
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

    return backend_->getImpl();
}

std::string HarmonyMapRenderThread::getRendererInfo() {
    if (!backend_) {
        return "uninitialized";
    }
    return backend_->getRendererInfo();
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

        backend_->resizeFramebuffer(width, height);
    });
}

void HarmonyMapRenderThread::setTileCacheEnabled(bool enabled) {
    if (destroying_.load() || shouldStop_) {
        Logger::warn("MapRenderThread", "setTileCacheEnabled() ignored: instance is being destroyed or stopping");
        return;
    }

    invoke([this, enabled]() {
        if (!renderer_) {
            Logger::warn("MapRenderThread", "setTileCacheEnabled() ignored: renderer not initialized");
            return;
        }

        try {
            renderer_->setTileCacheEnabled(enabled);
            Logger::info("MapRenderThread", "Tile cache %s", enabled ? "enabled" : "disabled");
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "setTileCacheEnabled failed: %s", e.what());
        }
    });
}

bool HarmonyMapRenderThread::getTileCacheEnabled() const {
    if (destroying_.load() || shouldStop_) {
        Logger::warn("MapRenderThread", "getTileCacheEnabled() returning false: instance is being destroyed or stopping");
        return false;
    }

    if (isOnThread()) {
        if (!renderer_) {
            Logger::warn("MapRenderThread", "getTileCacheEnabled() on render thread: renderer not initialized");
            return false;
        }
        try {
            return renderer_->getTileCacheEnabled();
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "getTileCacheEnabled failed on render thread: %s", e.what());
            return false;
        }
    }

    auto promise = std::make_shared<std::promise<bool>>();
    auto future = promise->get_future();

    const_cast<HarmonyMapRenderThread*>(this)->invoke([this, promise]() {
        bool enabled = false;
        if (!destroying_.load() && renderer_) {
            try {
                enabled = renderer_->getTileCacheEnabled();
            } catch (const std::exception& e) {
                Logger::error("MapRenderThread", "getTileCacheEnabled failed on dispatched call: %s", e.what());
            }
        } else {
            Logger::warn("MapRenderThread", "getTileCacheEnabled dispatched: renderer unavailable");
        }
        promise->set_value(enabled);
    });

    try {
        return future.get();
    } catch (const std::exception& e) {
        Logger::error("MapRenderThread", "getTileCacheEnabled future failed: %s", e.what());
        return false;
    }
}

std::vector<Feature> HarmonyMapRenderThread::queryRenderedFeatures(
    const ScreenCoordinate& point,
    const RenderedQueryOptions& options) const {
    
    if (destroying_.load() || shouldStop_) {
        Logger::warn("MapRenderThread", "queryRenderedFeatures(point) ignored: render thread is stopping");
        return {};
    }
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "queryRenderedFeatures: Renderer not initialized");
        return {};
    }
    
    if (isOnThread()) {
        return renderer_->queryRenderedFeatures(point, options);
    }

    auto promise = std::make_shared<std::promise<std::vector<Feature>>>();
    auto future = promise->get_future();

    const_cast<HarmonyMapRenderThread*>(this)->invoke([this, promise, point, options]() {
        if (destroying_.load() || shouldStop_ || !renderer_) {
            promise->set_value({});
            return;
        }
        try {
            promise->set_value(renderer_->queryRenderedFeatures(point, options));
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "queryRenderedFeatures(point) failed on render thread: %s", e.what());
            promise->set_value({});
        } catch (...) {
            Logger::error("MapRenderThread", "queryRenderedFeatures(point) failed with unknown exception");
            promise->set_value({});
        }
    });

    if (future.wait_for(std::chrono::seconds(5)) != std::future_status::ready) {
        Logger::error("MapRenderThread", "queryRenderedFeatures(point) timed out waiting for render thread");
        return {};
    }

    return future.get();
}

std::vector<Feature> HarmonyMapRenderThread::queryRenderedFeatures(
    const ScreenBox& box,
    const RenderedQueryOptions& options) const {
    
    if (destroying_.load() || shouldStop_) {
        Logger::warn("MapRenderThread", "queryRenderedFeatures(box) ignored: render thread is stopping");
        return {};
    }
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "queryRenderedFeatures: Renderer not initialized");
        return {};
    }
    
    if (isOnThread()) {
        return renderer_->queryRenderedFeatures(box, options);
    }

    auto promise = std::make_shared<std::promise<std::vector<Feature>>>();
    auto future = promise->get_future();

    const_cast<HarmonyMapRenderThread*>(this)->invoke([this, promise, box, options]() {
        if (destroying_.load() || shouldStop_ || !renderer_) {
            promise->set_value({});
            return;
        }
        try {
            promise->set_value(renderer_->queryRenderedFeatures(box, options));
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "queryRenderedFeatures(box) failed on render thread: %s", e.what());
            promise->set_value({});
        } catch (...) {
            Logger::error("MapRenderThread", "queryRenderedFeatures(box) failed with unknown exception");
            promise->set_value({});
        }
    });

    if (future.wait_for(std::chrono::seconds(5)) != std::future_status::ready) {
        Logger::error("MapRenderThread", "queryRenderedFeatures(box) timed out waiting for render thread");
        return {};
    }

    return future.get();
}

std::vector<Feature> HarmonyMapRenderThread::querySourceFeatures(
    const std::string& sourceId,
    const SourceQueryOptions& options) const {
    
    if (destroying_.load() || shouldStop_) {
        Logger::warn("MapRenderThread", "querySourceFeatures ignored: render thread is stopping");
        return {};
    }
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "querySourceFeatures: Renderer not initialized");
        return {};
    }
    
    if (isOnThread()) {
        return renderer_->querySourceFeatures(sourceId, options);
    }

    auto promise = std::make_shared<std::promise<std::vector<Feature>>>();
    auto future = promise->get_future();

    const_cast<HarmonyMapRenderThread*>(this)->invoke([this, promise, sourceId, options]() {
        if (destroying_.load() || shouldStop_ || !renderer_) {
            promise->set_value({});
            return;
        }
        try {
            promise->set_value(renderer_->querySourceFeatures(sourceId, options));
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "querySourceFeatures failed on render thread: %s", e.what());
            promise->set_value({});
        } catch (...) {
            Logger::error("MapRenderThread", "querySourceFeatures failed with unknown exception");
            promise->set_value({});
        }
    });

    if (future.wait_for(std::chrono::seconds(5)) != std::future_status::ready) {
        Logger::error("MapRenderThread", "querySourceFeatures timed out waiting for render thread");
        return {};
    }

    return future.get();
}

FeatureExtensionValue HarmonyMapRenderThread::queryFeatureExtensions(
    const std::string& sourceID,
    const Feature& feature,
    const std::string& extension,
    const std::string& extensionField,
    const std::optional<std::map<std::string, Value>>& args) const {

    if (destroying_.load() || shouldStop_) {
        Logger::warn("MapRenderThread", "queryFeatureExtensions ignored: render thread is stopping");
        return FeatureCollection{};
    }

    if (!renderer_) {
        Logger::error("MapRenderThread", "queryFeatureExtensions: Renderer not initialized");
        return FeatureCollection{};
    }

    if (isOnThread()) {
        return renderer_->queryFeatureExtensions(sourceID, feature, extension, extensionField, args);
    }

    auto promise = std::make_shared<std::promise<FeatureExtensionValue>>();
    auto future = promise->get_future();

    const_cast<HarmonyMapRenderThread*>(this)->invoke(
        [this, promise, sourceID, feature, extension, extensionField, args]() {
            if (destroying_.load() || shouldStop_ || !renderer_) {
                promise->set_value(FeatureCollection{});
                return;
            }
            try {
                promise->set_value(
                    renderer_->queryFeatureExtensions(sourceID, feature, extension, extensionField, args));
            } catch (const std::exception& e) {
                Logger::error("MapRenderThread", "queryFeatureExtensions failed on render thread: %s", e.what());
                promise->set_value(FeatureCollection{});
            } catch (...) {
                Logger::error("MapRenderThread", "queryFeatureExtensions failed with unknown exception");
                promise->set_value(FeatureCollection{});
            }
        });

    if (future.wait_for(std::chrono::seconds(5)) != std::future_status::ready) {
        Logger::error("MapRenderThread", "queryFeatureExtensions timed out waiting for render thread");
        return FeatureCollection{};
    }

    return future.get();
}

void HarmonyMapRenderThread::setOnFpsChangedCallback(std::function<void(double)> callback) {
    auto next = callback ? std::make_shared<std::function<void(double)>>(std::move(callback)) : nullptr;
    {
        std::lock_guard<std::mutex> lock(fpsCallbackMutex_);
        fpsCallback_ = std::move(next);
    }
    measureFps_ = (callback != nullptr);
    // lastFrameTime_ is intentionally NOT touched here: it is only accessed on
    // the render thread, which records the start time on the first measured
    // frame after enabling.
    if (measureFps_) {
        Logger::info("MapRenderThread", "FPS measurement enabled");
    } else {
        Logger::info("MapRenderThread", "FPS measurement disabled");
    }
}

void HarmonyMapRenderThread::enableFpsMeasurement(bool enable) {
    measureFps_ = enable;
    if (enable) {
        std::lock_guard<std::mutex> lock(fpsCallbackMutex_);
        if (!fpsCallback_) {
            Logger::warn("MapRenderThread", "FPS measurement enabled but no callback set");
        }
    }
}

void HarmonyMapRenderThread::setMaximumFps(int fps) {
    // 0 (or negative) disables the limit: render at the display refresh rate
    const uint32_t clamped = (fps <= 0) ? 0 : static_cast<uint32_t>(fps);
    maximumFps_.store(clamped, std::memory_order_relaxed);
    if (clamped == 0) {
        Logger::info("MapRenderThread", "Maximum FPS: unlimited");
    } else {
        Logger::info("MapRenderThread", "Maximum FPS: %d", fps);
    }
}

void HarmonyMapRenderThread::setRenderingRefreshMode(int mode) {
    if (mode != 0 && mode != 1) {
        Logger::warn("MapRenderThread", "setRenderingRefreshMode: invalid mode %d", mode);
        return;
    }

    const int previous = refreshMode_.exchange(mode, std::memory_order_relaxed);
    if (previous == mode) {
        return;
    }
    Logger::info("MapRenderThread", "Rendering refresh mode: %s",
                 (mode == 0) ? "CONTINUOUS" : "WHEN_DIRTY");

    if (mode == 0 && !paused_.load()) {
        // Entering CONTINUOUS: the frame pump may be asleep (WHEN_DIRTY stops
        // re-arming VSync once the map is idle), so kick one tick to restart it.
        invoke([this]() {
            if (destroying_.load() || paused_.load()) {
                return;
            }
            if (vsyncManager_ && vsyncManager_->isAvailable()) {
                vsyncManager_->requestFrame([this]() { onVSyncFrame(); });
            }
        });
    }
}

void HarmonyMapRenderThread::requestSnapshot(SnapshotSuccessCallback success, SnapshotErrorCallback error) {
    if (destroying_.load() || shouldStop_) {
        if (error) {
            error("Renderer is shutting down");
        }
        return;
    }
    
    if (!renderer_ || !backend_) {
        if (error) {
            error("Renderer backend not initialized");
        }
        return;
    }
    
    bool accepted = false;
    {
        std::lock_guard<std::mutex> lock(snapshotMutex_);
        if (!snapshotPending_) {
            snapshotSuccessCallback_ = std::move(success);
            snapshotErrorCallback_ = std::move(error);
            snapshotPending_ = true;
            accepted = true;
        }
    }
    
    if (!accepted) {
        if (error) {
            error("Snapshot already in progress");
        }
        return;
    }
    
    invoke([this]() {
        if (destroying_.load() || shouldStop_) {
            return;
        }
        if (map_) {
            map_->triggerRepaint();
        }
    });
}

// ==================== VSync control ====================

bool HarmonyMapRenderThread::shouldThrottleFrame() {
    const uint32_t maxFps = maximumFps_.load(std::memory_order_relaxed);
    if (maxFps == 0) {
        return false;
    }

    const auto now = std::chrono::steady_clock::now();
    const auto minInterval = std::chrono::nanoseconds(1000000000LL / static_cast<int64_t>(maxFps));
    if (now - lastFrameDeadline_ < minInterval) {
        return true;
    }
    lastFrameDeadline_ = now;
    return false;
}

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
        // Stray VSync tick with no pending work: ask the Map for a repaint so
        // the pipeline cannot stall (the Map decides whether anything changed).
        // In CONTINUOUS mode this branch is what keeps the frame pump running.
        if (map_) {
            map_->triggerRepaint();
        }
        return;
    }
    
    // FPS limiting (frame pacing): a tick that arrives sooner than the
    // configured frame interval is skipped; the pending render is retried
    // on the next VSync tick (Android paces equivalently via post-render sleep).
    if (shouldThrottleFrame()) {
        if (vsyncManager_ && vsyncManager_->isAvailable()) {
            vsyncManager_->requestFrame([this]() { onVSyncFrame(); });
        }
        return;
    }
    
    pendingRender_ = false;
    auto params = pendingUpdateParams_;
    pendingUpdateParams_.reset();
    
    std::unique_ptr<mbgl::PremultipliedImage> snapshotImage;
    SnapshotSuccessCallback snapshotSuccess;
    SnapshotErrorCallback snapshotError;
    
    // Execute the actual render
    if (params && renderer_ && backend_) {
        try {
            // Begin frame timing
            auto frameStartTime = std::chrono::steady_clock::now();
            
            auto* backend = backend_.get();
            gfx::BackendScope scope{backend->getImpl()};

            // Claim a pending snapshot before rendering so backends that need to
            // queue a readback (Vulkan copies the swapchain image during swap)
            // prepare for this frame; GL reads the surface after present anyway.
            bool shouldCapture = false;
            {
                std::lock_guard<std::mutex> lock(snapshotMutex_);
                if (snapshotPending_) {
                    shouldCapture = true;
                    snapshotPending_ = false;
                    snapshotSuccess = std::move(snapshotSuccessCallback_);
                    snapshotError = std::move(snapshotErrorCallback_);
                    snapshotSuccessCallback_ = nullptr;
                    snapshotErrorCallback_ = nullptr;
                }
            }
            if (shouldCapture) {
                backend->enableFramebufferRead(true);
            }

            renderer_->render(params);

            if (shouldCapture) {
                try {
                    auto image = backend->readFramebuffer();
                    snapshotImage = std::make_unique<mbgl::PremultipliedImage>(std::move(image));
                } catch (const std::exception& e) {
                    if (snapshotError) {
                        snapshotError(std::string("Failed to read framebuffer: ") + e.what());
                    }
                }
            }
            
            // FPS measurement (mirrors Android MapRenderer)
            if (measureFps_.load()) {
                // Copy the shared_ptr under the lock, then invoke the copy: a
                // concurrent setOnFpsChangedCallback may swap the slot but the
                // referenced function object stays alive for this invocation.
                std::shared_ptr<std::function<void(double)>> fpsCb;
                {
                    std::lock_guard<std::mutex> lock(fpsCallbackMutex_);
                    fpsCb = fpsCallback_;
                }
                auto currentTime = std::chrono::steady_clock::now();

                if (lastFrameTime_ == std::chrono::steady_clock::time_point{}) {
                    // First measured frame after enabling: record the start
                    // time only, so we never report a bogus interval.
                    lastFrameTime_ = currentTime;
                } else {
                    auto elapsedNanos = std::chrono::duration_cast<std::chrono::nanoseconds>(
                        currentTime - lastFrameTime_).count();

                    if (fpsCb && elapsedNanos > 0) {
                        // Compute FPS: fps = 1E9 / elapsed_nanoseconds
                        double fps = 1.0e9 / static_cast<double>(elapsedNanos);
                        (*fpsCb)(fps);
                    }

                    lastFrameTime_ = currentTime;
                }
            }
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "Render failed on VSync: %s", e.what());
            if (snapshotError) {
                snapshotError(std::string("Render failed: ") + e.what());
            }
        }
    } else if (map_) {
        // If no parameters are pending, request another repaint (Map decides whether it is necessary)
        
        map_->triggerRepaint();
    }
    
    // Note: if further rendering is needed, Map will call update() again inside onDidFinishRenderingFrame
    // This re-requests VSync and maintains the synchronized render loop
    
    if (snapshotImage && snapshotSuccess) {
        snapshotSuccess(std::move(*snapshotImage), pixelRatio_);
    }
    
    // CONTINUOUS mode: re-arm VSync even when the Map has no further work —
    // the next tick falls into the triggerRepaint branch above, closing the
    // pump loop. WHEN_DIRTY relies on update() to re-arm, so the loop sleeps
    // until the content changes (saves power).
    if (refreshMode_.load(std::memory_order_relaxed) == 0
        && vsyncManager_ && vsyncManager_->isAvailable()) {
        vsyncManager_->requestFrame([this]() { onVSyncFrame(); });
    }
}

} // namespace harmony
} // namespace mbgl
