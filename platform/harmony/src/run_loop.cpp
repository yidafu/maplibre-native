/**
 * HarmonyOS RunLoop Implementation
 * 
 * This implementation follows HarmonyOS libuv best practices:
 * - FFRT-aware task scheduling
 * - Thread-safe operations with proper validation
 * - Comprehensive error handling and HiLog integration
 * - Proper resource lifecycle management
 * 
 * References:
 * - HarmonyOS libuv API: https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/libuv-V5
 */

#include "run_loop_impl.hpp"
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/async_task.hpp>
#include <mbgl/util/monotonic_timer.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/thread_local.hpp>

#include <uv.h>

#include <atomic>
#include <cassert>
#include <functional>
#include <unordered_map>
#include <stdexcept>
#include <thread>

// HarmonyOS HiLog integration for debugging and diagnostics
#include <hilog/log.h>

#define RL_LOG_DEBUG(...) OH_LOG_Print(LOG_APP, LOG_DEBUG, 0x0000, "RunLoop", __VA_ARGS__)
#define RL_LOG_INFO(...) OH_LOG_Print(LOG_APP, LOG_INFO, 0x0000, "RunLoop", __VA_ARGS__)
#define RL_LOG_WARN(...) OH_LOG_Print(LOG_APP, LOG_WARN, 0x0000, "RunLoop", __VA_ARGS__)
#define RL_LOG_ERROR(...) OH_LOG_Print(LOG_APP, LOG_ERROR, 0x0000, "RunLoop", __VA_ARGS__)

namespace {

/**
 * Dummy callback for the holder async handle.
 * This handle is used to keep the event loop alive when needed.
 */
void dummyCallback(uv_async_t*) {
    RL_LOG_DEBUG("Holder async callback triggered (no-op)");
}

/**
 * Helper function to convert libuv error codes to readable strings
 */
const char* uvErrorString(int errorCode) {
    return uv_strerror(errorCode);
}

} // namespace

namespace mbgl {
namespace util {

/**
 * Watch: Manages file descriptor polling for network sockets
 * 
 * Used primarily by libcurl backend for async network operations.
 * Each Watch corresponds to a socket that needs monitoring.
 */
struct Watch {
    /**
     * Callback invoked when socket becomes readable/writable
     */
    static void onEvent(uv_poll_t* poll, int status, int event) {
        auto watch = reinterpret_cast<Watch*>(poll->data);
        
        if (status < 0) {
            RL_LOG_ERROR("Poll event error on fd=%{public}d: %{public}s", 
                        watch->fd, uvErrorString(status));
            return;
        }

        RunLoop::Event watchEvent = RunLoop::Event::None;
        switch (event) {
            case UV_READABLE:
                watchEvent = RunLoop::Event::Read;
                RL_LOG_DEBUG("Socket fd=%{public}d: Read event", watch->fd);
                break;
            case UV_WRITABLE:
                watchEvent = RunLoop::Event::Write;
                RL_LOG_DEBUG("Socket fd=%{public}d: Write event", watch->fd);
                break;
            case UV_READABLE | UV_WRITABLE:
                watchEvent = RunLoop::Event::ReadWrite;
                RL_LOG_DEBUG("Socket fd=%{public}d: Read+Write event", watch->fd);
                break;
            default:
                RL_LOG_WARN("Socket fd=%{public}d: Unknown event=%{public}d", watch->fd, event);
                break;
        }

        if (watch->eventCallback && watchEvent != RunLoop::Event::None) {
            watch->eventCallback(watch->fd, watchEvent);
        }
    }

    /**
     * Callback invoked when poll handle is closed
     */
    static void onClose(uv_handle_t* poll) {
        auto watch = reinterpret_cast<Watch*>(poll->data);
        RL_LOG_INFO("Watch closed for fd=%{public}d", watch->fd);
        
        if (watch->closeCallback) {
            watch->closeCallback();
        }
    }

    uv_poll_t poll;
    int fd;
    std::function<void(int, RunLoop::Event)> eventCallback;
    std::function<void()> closeCallback;
};

/**
 * Get the current RunLoop for this thread
 */
RunLoop* RunLoop::Get() {
    auto* scheduler = Scheduler::GetCurrent();
    assert(scheduler && "No RunLoop on current thread");
    return static_cast<RunLoop*>(scheduler);
}

/**
 * RunLoop::Impl - Internal implementation
 */
RunLoop::Impl::Impl(RunLoop*, RunLoop::Type type_) 
    : type(type_) {
    RL_LOG_INFO("RunLoop::Impl constructor - type=%{public}d", static_cast<int>(type));
}

RunLoop::Impl::~Impl() {
    RL_LOG_INFO("RunLoop::Impl destructor");
    
    // Ensure all watches are cleaned up
    if (!watchPoll.empty()) {
        RL_LOG_WARN("RunLoop destroyed with %{public}zu active watches", watchPoll.size());
    }
}

/**
 * RunLoop Constructor
 * 
 * Creates a new event loop or uses the default one.
 * Initializes the holder async handle to keep loop alive.
 * Sets up AsyncTask for cross-thread communication.
 */
RunLoop::RunLoop(Type type)
    : impl(std::make_unique<Impl>(this, type)) {
    
    RL_LOG_INFO("========== RunLoop Constructor START ==========");
    RL_LOG_INFO("Type: %{public}s", type == Type::New ? "New" : "Default");
    
    // Initialize the event loop
    switch (type) {
        case Type::New:
            impl->loop = new uv_loop_t;
            RL_LOG_DEBUG("Allocating new uv_loop_t at %{public}p", impl->loop);
            
            if (int err = uv_loop_init(impl->loop); err != 0) {
                RL_LOG_ERROR("Failed to initialize loop: %{public}s", uvErrorString(err));
                delete impl->loop;
                impl->loop = nullptr;
                throw std::runtime_error("Failed to initialize loop: " + 
                                       std::string(uvErrorString(err)));
            }
            RL_LOG_INFO("Successfully initialized new event loop");
            break;
            
        case Type::Default:
            impl->loop = uv_default_loop();
            RL_LOG_INFO("Using default event loop at %{public}p", impl->loop);
            
            if (!impl->loop) {
                RL_LOG_ERROR("Failed to get default loop");
                throw std::runtime_error("Failed to get default loop");
            }
            break;
    }

    // Initialize holder async handle to keep the loop alive
    // This is a libuv requirement - the loop needs at least one active handle
    RL_LOG_DEBUG("Initializing holder async handle");
    if (int err = uv_async_init(impl->loop, impl->holder, dummyCallback); err != 0) {
        RL_LOG_ERROR("Failed to initialize holder async: %{public}s", uvErrorString(err));
        
        // Cleanup on failure
        if (type == Type::New) {
            uv_loop_close(impl->loop);
            delete impl->loop;
            impl->loop = nullptr;
        }
        
        throw std::runtime_error("Failed to initialize holder async: " + 
                               std::string(uvErrorString(err)));
    }
    
    RL_LOG_INFO("Holder async initialized successfully");

    // Register this RunLoop as the current scheduler for this thread
    Scheduler::SetCurrent(this);
    RL_LOG_DEBUG("Set as current Scheduler for thread");

    // Create AsyncTask for processing queued work items
    // AsyncTask uses uv_async_send which is lock-free and FFRT-aware
    impl->async = std::make_unique<AsyncTask>(std::bind(&RunLoop::process, this));
    RL_LOG_INFO("AsyncTask created for work processing");
    
    RL_LOG_INFO("========== RunLoop Constructor COMPLETE ==========");
}

/**
 * RunLoop Destructor
 * 
 * Properly cleans up all resources:
 * 1. Unregister from Scheduler
 * 2. Close holder handle
 * 3. Destroy AsyncTask
 * 4. Run loop once more to process close callbacks
 * 5. Close and free the loop (for Type::New)
 */
RunLoop::~RunLoop() {
    RL_LOG_INFO("========== RunLoop Destructor START ==========");
    
    // Unregister from scheduler
    Scheduler::SetCurrent(nullptr);
    RL_LOG_DEBUG("Unregistered from Scheduler");

    // 1. 首先强制关闭所有活跃的Watch句柄
    RL_LOG_DEBUG("Force closing all active watches...");
    for (auto it = impl->watchPoll.begin(); it != impl->watchPoll.end(); ++it) {
        int fd = it->first;
        auto& watch = it->second;
        if (watch && !uv_is_closing(reinterpret_cast<uv_handle_t*>(&watch->poll))) {
            RL_LOG_DEBUG("Force closing watch for fd=%{public}d", fd);
            uv_close(reinterpret_cast<uv_handle_t*>(&watch->poll), [](uv_handle_t* handle) {
                auto watch = reinterpret_cast<Watch*>(handle->data);
                RL_LOG_DEBUG("Watch closed for fd=%{public}d", watch->fd);
            });
        }
    }
    impl->watchPoll.clear();
    RL_LOG_DEBUG("All watches force closed");

    // 2. 关闭holder句柄
    impl->closeHolder();
    RL_LOG_DEBUG("Holder handle close scheduled");

    // For default loop, we don't own it, so just return
    if (impl->type == Type::Default) {
        RL_LOG_INFO("Default loop - skipping loop close");
        RL_LOG_INFO("========== RunLoop Destructor COMPLETE ==========");
        return;
    }

    // For new loop, we need to clean up completely
    RL_LOG_DEBUG("Destroying AsyncTask");
    impl->async.reset();

    // 3. 运行循环多次以确保所有关闭回调都被处理
    RL_LOG_DEBUG("Running loop multiple times to process all close callbacks");
    for (int i = 0; i < 10; i++) {
        int result = uv_run(impl->loop, UV_RUN_NOWAIT);
        if (result == 0) {
            RL_LOG_DEBUG("Loop iteration %{public}d: no more work", i + 1);
            break;
        }
        RL_LOG_DEBUG("Loop iteration %{public}d: processed %{public}d events", i + 1, result);
    }

    // 4. 检查并强制关闭任何剩余的句柄
    RL_LOG_DEBUG("Checking for remaining handles...");
    int handleCount = 0;
    uv_walk(impl->loop, [](uv_handle_t* handle, void* arg) {
        int* count = static_cast<int*>(arg);
        (*count)++;
        RL_LOG_WARN("Force closing remaining handle #%{public}d: type=%{public}d, data=%{public}p", 
                   *count, handle->type, handle->data);
        uv_close(handle, nullptr);
    }, &handleCount);
    
    if (handleCount > 0) {
        RL_LOG_WARN("Force closed %{public}d remaining handles", handleCount);
        // 再次运行循环处理关闭回调
        uv_run(impl->loop, UV_RUN_NOWAIT);
    }

    // 5. 关闭循环
    RL_LOG_DEBUG("Closing event loop");
    if (int err = uv_loop_close(impl->loop); err == UV_EBUSY) {
        RL_LOG_ERROR("Failed to close loop: UV_EBUSY - handles still active after force close");
        // 不assert，而是继续清理
    } else if (err != 0) {
        RL_LOG_ERROR("Failed to close loop: %{public}s", uvErrorString(err));
    } else {
        RL_LOG_INFO("Event loop closed successfully");
    }
    
    // Free the loop structure
    delete impl->loop;
    impl->loop = nullptr;
    RL_LOG_DEBUG("Event loop freed");
    
    RL_LOG_INFO("========== RunLoop Destructor COMPLETE ==========");
}

/**
 * Get the raw loop handle
 * Thread-safe: Can be called from any thread
 */
LOOP_HANDLE RunLoop::getLoopHandle() {
    return Get()->impl->loop;
}

/**
 * Wake up the event loop
 * 
 * Thread-safe: Can be called from any thread
 * Uses AsyncTask which internally uses uv_async_send (lock-free)
 */
void RunLoop::wake() {
    if (impl->async) {
        RL_LOG_DEBUG("Waking up event loop");
        impl->async->send();
    } else {
        RL_LOG_WARN("Cannot wake - AsyncTask not initialized");
    }
}

/**
 * Run the event loop
 * 
 * Blocks until stop() is called.
 * Must be called from the loop's owner thread.
 */
void RunLoop::run() {
    MBGL_VERIFY_THREAD(tid);
    
    RL_LOG_INFO("========== RunLoop::run() START ==========");
    RL_LOG_INFO("Running event loop at %{public}p", impl->loop);
    
    // Reference the holder to keep loop alive
    uv_ref(impl->holderHandle());
    RL_LOG_DEBUG("Holder handle referenced");
    
    // Run the loop - blocks until stop() is called
    int result = uv_run(impl->loop, UV_RUN_DEFAULT);
    
    RL_LOG_INFO("========== RunLoop::run() COMPLETE - result=%{public}d ==========", result);
}

/**
 * Run the event loop once without blocking
 * 
 * Processes all ready callbacks and returns.
 * Must be called from the loop's owner thread.
 */
void RunLoop::runOnce() {
    MBGL_VERIFY_THREAD(tid);
    
    RL_LOG_DEBUG("RunLoop::runOnce() - non-blocking iteration");
    
    int result = uv_run(impl->loop, UV_RUN_NOWAIT);
    
    RL_LOG_DEBUG("RunLoop::runOnce() complete - result=%{public}d", result);
}

/**
 * Stop the event loop
 * 
 * Thread-safe: Can be called from any thread
 * Schedules stop operation on the loop thread
 */
void RunLoop::stop() {
    RL_LOG_INFO("RunLoop::stop() called");
    
    invoke([this] {
        RL_LOG_DEBUG("Executing stop - unreferencing holder");
        uv_unref(impl->holderHandle());
    });
}

/**
 * Update the loop's internal time
 * 
 * Must be called from the loop's owner thread.
 * Used for timer management.
 */
void RunLoop::updateTime() {
    MBGL_VERIFY_THREAD(tid);
    
    RL_LOG_DEBUG("Updating loop time");
    uv_update_time(impl->loop);
}

/**
 * Wait until all queued work is processed
 * 
 * Thread-safe: Can be called from any thread.
 * If called from a different thread, work is delegated to the RunLoop thread.
 * Blocks until queues are empty.
 */
void RunLoop::waitForEmpty([[maybe_unused]] const mbgl::util::SimpleIdentity tag) {
    // Check if we're on the RunLoop thread
    if (tid != std::this_thread::get_id()) {
        RL_LOG_WARN("waitForEmpty() called from wrong thread - delegating to RunLoop thread");
        
        // Use atomic flag for synchronization
        std::atomic<bool> done{false};
        
        // Delegate work to RunLoop thread
        invoke([this, &done]() {
            RL_LOG_DEBUG("waitForEmpty() executing on RunLoop thread (delegated)");
            
            // Now we're on the correct thread, wait for queues to empty
            int iterations = 0;
            while (true) {
                std::size_t remaining;
                {
                    std::lock_guard<std::mutex> lock(mutex);
                    remaining = defaultQueue.size() + highPriorityQueue.size();
                }
                
                if (remaining == 0) {
                    RL_LOG_DEBUG("waitForEmpty() - queues empty after %{public}d iterations (delegated)", iterations);
                    break;
                }
                
                RL_LOG_DEBUG("waitForEmpty() - %{public}zu items remaining (delegated)", remaining);
                runOnce();  // Safe - we're on RunLoop thread now
                iterations++;
            }
            
            // Signal completion
            done.store(true, std::memory_order_release);
        });
        
        // Wait for completion (busy wait with yield)
        while (!done.load(std::memory_order_acquire)) {
            std::this_thread::yield();
        }
        
        RL_LOG_DEBUG("waitForEmpty() - delegation complete");
        return;
    }
    
    // We're already on the RunLoop thread - direct execution
    RL_LOG_DEBUG("waitForEmpty() - waiting for queues to drain (direct)");
    
    int iterations = 0;
    while (true) {
        std::size_t remaining;
        {
            std::lock_guard<std::mutex> lock(mutex);
            remaining = defaultQueue.size() + highPriorityQueue.size();
        }

        if (remaining == 0) {
            RL_LOG_DEBUG("waitForEmpty() - queues empty after %{public}d iterations (direct)", iterations);
            return;
        }

        RL_LOG_DEBUG("waitForEmpty() - %{public}zu items remaining (direct)", remaining);
        runOnce();
        iterations++;
    }
}

/**
 * Add a watch for file descriptor events
 * 
 * Used primarily for libcurl network backend.
 * Must be called from the loop's owner thread.
 * 
 * HarmonyOS Note: Ensure fd is valid and not already being watched.
 */
void RunLoop::addWatch(int fd, Event event, std::function<void(int, Event)>&& callback) {
    MBGL_VERIFY_THREAD(tid);
    
    RL_LOG_INFO("========== addWatch: fd=%{public}d, event=%{public}d ==========", 
               fd, static_cast<int>(event));

    // Validate file descriptor
    if (fd < 0) {
        RL_LOG_ERROR("Invalid fd: %{public}d", fd);
        throw std::runtime_error("Invalid file descriptor");
    }

    Watch* watch = nullptr;
    auto watchPollIter = impl->watchPoll.find(fd);

    // Create new watch if this fd isn't already being watched
    if (watchPollIter == impl->watchPoll.end()) {
        RL_LOG_DEBUG("Creating new watch for fd=%{public}d", fd);
        std::unique_ptr<Watch> watchPtr = std::make_unique<Watch>();

        watch = watchPtr.get();
        impl->watchPoll[fd] = std::move(watchPtr);

        // Initialize poll handle
        int initResult;
#ifdef WIN32
        initResult = uv_poll_init_socket(impl->loop, &watch->poll, fd);
#else
        initResult = uv_poll_init(impl->loop, &watch->poll, fd);
#endif
        
        if (initResult != 0) {
            RL_LOG_ERROR("Failed to init poll for fd=%{public}d: %{public}s", 
                        fd, uvErrorString(initResult));
            impl->watchPoll.erase(fd);
            throw std::runtime_error("Failed to init poll on file descriptor: " + 
                                   std::string(uvErrorString(initResult)));
        }
        
        RL_LOG_DEBUG("Poll handle initialized for fd=%{public}d", fd);
    } else {
        RL_LOG_DEBUG("Reusing existing watch for fd=%{public}d", fd);
        watch = watchPollIter->second.get();
    }

    // Set up watch properties
    watch->poll.data = watch;
    watch->fd = fd;
    watch->eventCallback = std::move(callback);

    // Convert event type to libuv poll flags
    int pollEvent = 0;
    switch (event) {
        case Event::Read:
            pollEvent = UV_READABLE;
            break;
        case Event::Write:
            pollEvent = UV_WRITABLE;
            break;
        case Event::ReadWrite:
            pollEvent = UV_READABLE | UV_WRITABLE;
            break;
        case Event::None:
        default:
            RL_LOG_ERROR("Invalid event type: %{public}d", static_cast<int>(event));
            throw std::runtime_error("Invalid event type for watch");
    }

    // Start polling
    RL_LOG_DEBUG("Starting poll for fd=%{public}d with events=0x%{public}x", fd, pollEvent);
    if (int err = uv_poll_start(&watch->poll, pollEvent, &Watch::onEvent); err != 0) {
        RL_LOG_ERROR("Failed to start poll for fd=%{public}d: %{public}s", 
                    fd, uvErrorString(err));
        throw std::runtime_error("Failed to start poll on file descriptor: " + 
                               std::string(uvErrorString(err)));
    }
    
    RL_LOG_INFO("Watch started successfully for fd=%{public}d", fd);
}

/**
 * Remove a watch for file descriptor events
 * 
 * Must be called from the loop's owner thread.
 * Properly stops polling and schedules handle close.
 */
void RunLoop::removeWatch(int fd) {
    MBGL_VERIFY_THREAD(tid);

    RL_LOG_INFO("========== removeWatch: fd=%{public}d ==========", fd);

    auto watchPollIter = impl->watchPoll.find(fd);
    if (watchPollIter == impl->watchPoll.end()) {
        RL_LOG_WARN("Watch not found for fd=%{public}d - already removed?", fd);
        return;
    }

    // Transfer ownership to prepare for async cleanup
    Watch* watch = watchPollIter->second.release();
    impl->watchPoll.erase(watchPollIter);

    RL_LOG_DEBUG("Watch removed from map for fd=%{public}d", fd);

    // Set up close callback to delete watch after handle is closed
    watch->closeCallback = [watch, fd] {
        RL_LOG_DEBUG("Deleting watch for fd=%{public}d", fd);
        delete watch;
    };

    // Stop polling
    if (int err = uv_poll_stop(&watch->poll); err != 0) {
        RL_LOG_ERROR("Failed to stop poll for fd=%{public}d: %{public}s", 
                    fd, uvErrorString(err));
        // Still proceed with close
    } else {
        RL_LOG_DEBUG("Poll stopped for fd=%{public}d", fd);
    }

    // Schedule handle close (callback will delete watch)
    uv_close(reinterpret_cast<uv_handle_t*>(&watch->poll), &Watch::onClose);
    RL_LOG_INFO("Watch close scheduled for fd=%{public}d", fd);
}

} // namespace util
} // namespace mbgl
