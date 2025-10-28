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

// Use platform logger
#include "../maplibre_harmony/src/main/cpp/utils/logger.h"

using mbgl::harmony::Logger;

namespace {

/**
 * Dummy callback for the holder async handle.
 */
void dummyCallback(uv_async_t*) {
    // No-op
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
    static void onEvent(uv_poll_t* poll, int status, int event) {
        auto watch = reinterpret_cast<Watch*>(poll->data);
        
        if (status < 0) {
            Logger::error("RunLoop", "Poll event error on fd=%d: %s", watch->fd, uvErrorString(status));
            return;
        }

        RunLoop::Event watchEvent = RunLoop::Event::None;
        switch (event) {
            case UV_READABLE:
                watchEvent = RunLoop::Event::Read;
                break;
            case UV_WRITABLE:
                watchEvent = RunLoop::Event::Write;
                break;
            case UV_READABLE | UV_WRITABLE:
                watchEvent = RunLoop::Event::ReadWrite;
                break;
            default:
                break;
        }

        if (watch->eventCallback && watchEvent != RunLoop::Event::None) {
            watch->eventCallback(watch->fd, watchEvent);
        }
    }

    static void onClose(uv_handle_t* poll) {
        auto watch = reinterpret_cast<Watch*>(poll->data);
        
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

RunLoop::Impl::Impl(RunLoop*, RunLoop::Type type_) 
    : type(type_) {
    holder = new uv_async_t;
}

uv_handle_t* RunLoop::Impl::holderHandle() {
    return reinterpret_cast<uv_handle_t*>(holder);
}

void RunLoop::Impl::closeHolder() {
    uv_close(holderHandle(), [](uv_handle_t* h) {
        delete reinterpret_cast<uv_async_t*>(h);
    });
}

RunLoop::Impl::~Impl() {
    if (!watchPoll.empty()) {
        Logger::warn("RunLoop", "RunLoop destroyed with %zu active watches", watchPoll.size());
    }
    if (!runnables.empty()) {
        Logger::warn("RunLoop", "RunLoop destroyed with %zu active runnables", runnables.size());
    }
}

/**
 * Add a Runnable to the scheduled tasks queue
 * 
 * Thread-safe: Can be called from any thread.
 * Wakes up the event loop to process the new task.
 */
void RunLoop::Impl::addRunnable(Runnable* runnable) {
    {
        std::lock_guard<std::mutex> lock(runnablesMutex);
        runnables.push_back(runnable);
    }
    
    // Wake up the event loop to process the new runnable
    wake();
}

/**
 * Remove a Runnable from the scheduled tasks queue
 * 
 * Thread-safe: Can be called from any thread.
 */
void RunLoop::Impl::removeRunnable(Runnable* runnable) {
    std::lock_guard<std::mutex> lock(runnablesMutex);
    runnables.remove(runnable);
}

/**
 * Process all Runnables whose due time has passed
 * 
 * This method is called from RunLoop::runOnce() on the RunLoop thread.
 * It collects all ready-to-run tasks, then executes them outside the lock
 * to avoid potential deadlocks.
 * 
 * Based on Android's implementation, we iterate through all runnables
 * and execute those whose dueTime <= now.
 * 
 * Optimization: Tracks next due time and schedules wake() only if needed.
 */
void RunLoop::Impl::processRunnables() {
    auto now = Clock::now();
    std::list<Runnable*> readyToRun;
    TimePoint nextDue = TimePoint::max();
    bool hasRunnables = false;
    
    // Collect all runnables that are due
    {
        std::lock_guard<std::mutex> lock(runnablesMutex);
        
        hasRunnables = !runnables.empty();
        if (hasRunnables) {
            Logger::debug("RunLoop", "processRunnables: checking %zu runnables", runnables.size());
        }
        
        // Similar to Android: O(N) but typically the list is small (1-2 items)
        // We don't remove items - each Runnable manages its own lifecycle
        for (auto* runnable : runnables) {
            auto dueTime = runnable->dueTime();
            
            if (dueTime <= now) {
                readyToRun.push_back(runnable);
            } else {
                // Track the earliest future due time
                nextDue = std::min(nextDue, dueTime);
            }
        }
        
        if (!readyToRun.empty()) {
            Logger::info("RunLoop", "processRunnables: %zu ready to run (out of %zu total)", 
                        readyToRun.size(), runnables.size());
        }
    }
    
    // Execute runnables outside the lock to avoid potential deadlocks
    for (auto* runnable : readyToRun) {
        try {
            runnable->runTask();
        } catch (const std::exception& e) {
            Logger::error("RunLoop", "Runnable threw exception: %s", e.what());
        } catch (...) {
            Logger::error("RunLoop", "Runnable threw unknown exception");
        }
    }
    
    // Optimization: If there are future runnables, log when next one is due
    // The event loop will naturally check again on the next iteration
    if (nextDue != TimePoint::max()) {
        auto waitTime = std::chrono::duration_cast<std::chrono::milliseconds>(nextDue - now);
        Logger::debug("RunLoop", "Next runnable due in %lld ms", waitTime.count());
    }
}

/**
 * Wake up the event loop
 * 
 * Thread-safe: Can be called from any thread.
 * Uses dedicated uv_async (waker) to signal the event loop.
 * 
 * 🔧 关键修复：直接使用 uv_async_send，避免通过 AsyncTask Runnable
 * 这打破了之前的循环依赖问题。
 */
void RunLoop::Impl::wake() {
    // 记录调用线程
    std::ostringstream threadId;
    threadId << std::this_thread::get_id();
    
    Logger::info("RunLoop", "🚨 wake() called from thread=%s, waker=%p", 
        threadId.str().c_str(), waker);
    
    if (waker) {
        if (int err = uv_async_send(waker); err != 0) {
            Logger::error("RunLoop", "uv_async_send failed: %s", uvErrorString(err));
        } else {
            Logger::info("RunLoop", "✅ uv_async_send succeeded");
        }
    } else {
        Logger::error("RunLoop", "❌ wake() called but waker is null!");
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
    
    // Initialize the event loop
    switch (type) {
        case Type::New:
            impl->loop = new uv_loop_t;
            
            if (int err = uv_loop_init(impl->loop); err != 0) {
                Logger::error("RunLoop", "Failed to initialize loop: %s", uvErrorString(err));
                delete impl->loop;
                impl->loop = nullptr;
                throw std::runtime_error("Failed to initialize loop: " + std::string(uvErrorString(err)));
            }
            break;
            
        case Type::Default:
            impl->loop = uv_default_loop();
            
            if (!impl->loop) {
                Logger::error("RunLoop", "Failed to get default loop");
                throw std::runtime_error("Failed to get default loop");
            }
            break;
    }

    // Initialize holder async handle
    if (int err = uv_async_init(impl->loop, impl->holder, dummyCallback); err != 0) {
        Logger::error("RunLoop", "Failed to initialize holder async: %s", uvErrorString(err));
        
        if (type == Type::New) {
            uv_loop_close(impl->loop);
            delete impl->loop;
            impl->loop = nullptr;
        }
        
        throw std::runtime_error("Failed to initialize holder async: " + std::string(uvErrorString(err)));
    }

    Scheduler::SetCurrent(this);
    
    // 🔧 关键修复：创建 uv_async 用于 wake()，而不是 AsyncTask
    // AsyncTask 作为 Runnable 会导致循环依赖：
    //   wake() → async->send() → addRunnable() → wake() → 循环！
    // 解决：使用独立的 uv_async_t 直接唤醒事件循环
    impl->waker = new uv_async_t;
    impl->waker->data = this;
    if (int err = uv_async_init(impl->loop, impl->waker, [](uv_async_t* handle) {
        auto* self = static_cast<RunLoop*>(handle->data);
        
        // 记录回调线程
        std::ostringstream threadId;
        threadId << std::this_thread::get_id();
        
        Logger::info("RunLoop", "🔔 Waker callback triggered in thread=%s, RunLoop=%p", 
            threadId.str().c_str(), self);
        
        // 🔧 关键：必须在这里处理工作队列和 Runnables！
        // uv_async callback 是唯一的执行点，不能依赖 runOnce()
        
        // Process work queue
        std::shared_ptr<WorkTask> task;
        std::unique_lock<std::mutex> lock(self->mutex);
        
        size_t highCount = self->highPriorityQueue.size();
        size_t defaultCount = self->defaultQueue.size();
        
        // 总是记录队列大小（即使为0也记录，这很重要）
        Logger::info("RunLoop", "📊 Work queue: high=%zu, default=%zu", highCount, defaultCount);
        
        int taskCount = 0;
        while (true) {
            if (!self->highPriorityQueue.empty()) {
                task = std::move(self->highPriorityQueue.front());
                self->highPriorityQueue.pop();
                Logger::info("RunLoop", "📤 Dequeued HIGH priority task");
            } else if (!self->defaultQueue.empty()) {
                task = std::move(self->defaultQueue.front());
                self->defaultQueue.pop();
                Logger::info("RunLoop", "📤 Dequeued DEFAULT priority task");
            } else {
                Logger::info("RunLoop", "✅ All work queue tasks processed, count=%d", taskCount);
                break;
            }
            lock.unlock();
            taskCount++;
            Logger::info("RunLoop", "⚙️ Executing WorkTask #%d...", taskCount);
            (*task)();
            Logger::info("RunLoop", "✅ WorkTask #%d completed", taskCount);
            task.reset();
            lock.lock();
        }
        lock.unlock();
        
        // Process scheduled Runnables after work queue
        Logger::info("RunLoop", "📋 Processing Runnables");
        self->impl->processRunnables();
        Logger::info("RunLoop", "🔔 Waker callback completed");
    }); err != 0) {
        Logger::error("RunLoop", "Failed to initialize waker async: %s", uvErrorString(err));
        delete impl->waker;
        impl->waker = nullptr;
        throw std::runtime_error("Failed to initialize waker async");
    }
    
    uv_unref(reinterpret_cast<uv_handle_t*>(impl->waker));
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
    Scheduler::SetCurrent(nullptr);

    // 强制关闭所有活跃的Watch句柄
    for (auto it = impl->watchPoll.begin(); it != impl->watchPoll.end(); ++it) {
        auto& watch = it->second;
        if (watch && !uv_is_closing(reinterpret_cast<uv_handle_t*>(&watch->poll))) {
            uv_close(reinterpret_cast<uv_handle_t*>(&watch->poll), nullptr);
        }
    }
    impl->watchPoll.clear();

    impl->closeHolder();
    
    // 关闭 waker async handle
    if (impl->waker) {
        uv_close(reinterpret_cast<uv_handle_t*>(impl->waker), [](uv_handle_t* h) {
            delete reinterpret_cast<uv_async_t*>(h);
        });
        impl->waker = nullptr;
    }

    if (impl->type == Type::Default) {
        return;
    }

    impl->async.reset();

    // 运行循环以处理关闭回调
    for (int i = 0; i < 10; i++) {
        int result = uv_run(impl->loop, UV_RUN_NOWAIT);
        if (result == 0) {
            break;
        }
    }

    // 检查并强制关闭任何剩余的句柄
    int handleCount = 0;
    uv_walk(impl->loop, [](uv_handle_t* handle, void* arg) {
        int* count = static_cast<int*>(arg);
        (*count)++;
        uv_close(handle, nullptr);
    }, &handleCount);
    
    if (handleCount > 0) {
        uv_run(impl->loop, UV_RUN_NOWAIT);
    }

    // 关闭循环
    if (int err = uv_loop_close(impl->loop); err == UV_EBUSY) {
        Logger::error("RunLoop", "Failed to close loop: UV_EBUSY");
    } else if (err != 0) {
        Logger::error("RunLoop", "Failed to close loop: %s", uvErrorString(err));
    }
    
    delete impl->loop;
    impl->loop = nullptr;
}

/**
 * Schedule overrides with logging
 */
void RunLoop::schedule(std::function<void()>&& fn) {
    std::ostringstream threadId;
    threadId << std::this_thread::get_id();
    Logger::info("RunLoop", "🎯 schedule(fn) called from thread=%s, RunLoop=%p", 
        threadId.str().c_str(), this);
    invoke(std::move(fn));
    Logger::info("RunLoop", "🎯 schedule(fn) - invoke() returned");
}

void RunLoop::schedule(const util::SimpleIdentity tag, std::function<void()>&& fn) {
    (void)tag; // Unused parameter
    Logger::info("RunLoop", "🎯 schedule(tag, fn) called, RunLoop=%p", this);
    schedule(std::move(fn));
}

/**
 * Push implementation with logging
 */
void RunLoop::pushImpl(Priority priority, std::shared_ptr<WorkTask> task) {
    // 记录调用线程
    std::ostringstream threadId;
    threadId << std::this_thread::get_id();
    
    Logger::info("RunLoop", "📥 pushImpl() called from thread=%s, priority=%d, RunLoop=%p", 
        threadId.str().c_str(), static_cast<int>(priority), this);
    
    pushImplInline(priority, std::move(task));
    
    // Log queue sizes after push
    std::lock_guard<std::mutex> lock(mutex);
    Logger::info("RunLoop", "📊 After pushImpl: high=%zu, default=%zu", 
        highPriorityQueue.size(), defaultQueue.size());
}

void RunLoop::push(Priority priority, std::shared_ptr<WorkTask> task) {
    pushImpl(priority, std::move(task));
}

/**
 * Get the RunLoop::Impl pointer
 * Thread-safe: Can be called from any thread
 * 
 * Returns RunLoop::Impl* (not uv_loop_t*) for compatibility with Android platform.
 * This allows AsyncTask and Timer to access addRunnable/removeRunnable methods.
 */
LOOP_HANDLE RunLoop::getLoopHandle() {
    return Get()->impl.get();
}

void RunLoop::wake() {
    // 使用新的 waker 机制（不使用废弃的 async）
    impl->wake();
}

void RunLoop::run() {
    MBGL_VERIFY_THREAD(tid);
    
    std::ostringstream threadId;
    threadId << std::this_thread::get_id();
    Logger::info("RunLoop", "🎬 RunLoop::run() called on thread=%s, RunLoop=%p", threadId.str().c_str(), this);
    
    uv_ref(impl->holderHandle());
    Logger::info("RunLoop", "Starting uv_run(UV_RUN_DEFAULT)...");
    
    int result = uv_run(impl->loop, UV_RUN_DEFAULT);
    
    Logger::info("RunLoop", "⚠️ uv_run() returned! result=%d, thread=%s", result, threadId.str().c_str());
    Logger::info("RunLoop", "This means the event loop has stopped!");
}

void RunLoop::runOnce() {
    MBGL_VERIFY_THREAD(tid);
    
    // First, run the libuv event loop once
    uv_run(impl->loop, UV_RUN_NOWAIT);
    
    // Then process the work queue (high priority first, then default)
    process();
    
    // Finally, process scheduled Runnables (AsyncTask, Timer, etc.)
    impl->processRunnables();
}

void RunLoop::stop() {
    invoke([this] {
        uv_unref(impl->holderHandle());
    });
}

void RunLoop::updateTime() {
    MBGL_VERIFY_THREAD(tid);
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
    if (tid != std::this_thread::get_id()) {
        std::atomic<bool> done{false};
        
        invoke([this, &done]() {
            while (true) {
                std::size_t remaining;
                {
                    std::lock_guard<std::mutex> lock(mutex);
                    remaining = defaultQueue.size() + highPriorityQueue.size();
                }
                
                if (remaining == 0) {
                    break;
                }
                
                runOnce();
            }
            
            done.store(true, std::memory_order_release);
        });
        
        while (!done.load(std::memory_order_acquire)) {
            std::this_thread::yield();
        }
        
        return;
    }
    
    while (true) {
        std::size_t remaining;
        {
            std::lock_guard<std::mutex> lock(mutex);
            remaining = defaultQueue.size() + highPriorityQueue.size();
        }

        if (remaining == 0) {
            return;
        }

        runOnce();
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

    if (fd < 0) {
        Logger::error("RunLoop", "Invalid fd: %d", fd);
        throw std::runtime_error("Invalid file descriptor");
    }

    Watch* watch = nullptr;
    auto watchPollIter = impl->watchPoll.find(fd);

    if (watchPollIter == impl->watchPoll.end()) {
        std::unique_ptr<Watch> watchPtr = std::make_unique<Watch>();

        watch = watchPtr.get();
        impl->watchPoll[fd] = std::move(watchPtr);

        int initResult;
#ifdef WIN32
        initResult = uv_poll_init_socket(impl->loop, &watch->poll, fd);
#else
        initResult = uv_poll_init(impl->loop, &watch->poll, fd);
#endif
        
        if (initResult != 0) {
            Logger::error("RunLoop", "Failed to init poll for fd=%d: %s", fd, uvErrorString(initResult));
            impl->watchPoll.erase(fd);
            throw std::runtime_error("Failed to init poll on file descriptor: " + std::string(uvErrorString(initResult)));
        }
    } else {
        watch = watchPollIter->second.get();
    }

    watch->poll.data = watch;
    watch->fd = fd;
    watch->eventCallback = std::move(callback);

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
            Logger::error("RunLoop", "Invalid event type: %d", static_cast<int>(event));
            throw std::runtime_error("Invalid event type for watch");
    }

    if (int err = uv_poll_start(&watch->poll, pollEvent, &Watch::onEvent); err != 0) {
        Logger::error("RunLoop", "Failed to start poll for fd=%d: %s", fd, uvErrorString(err));
        throw std::runtime_error("Failed to start poll on file descriptor: " + std::string(uvErrorString(err)));
    }
}

/**
 * Remove a watch for file descriptor events
 * 
 * Must be called from the loop's owner thread.
 * Properly stops polling and schedules handle close.
 */
void RunLoop::removeWatch(int fd) {
    MBGL_VERIFY_THREAD(tid);

    auto watchPollIter = impl->watchPoll.find(fd);
    if (watchPollIter == impl->watchPoll.end()) {
        return;
    }

    Watch* watch = watchPollIter->second.release();
    impl->watchPoll.erase(watchPollIter);

    watch->closeCallback = [watch] {
        delete watch;
    };

    if (int err = uv_poll_stop(&watch->poll); err != 0) {
        Logger::warn("RunLoop", "Failed to stop poll for fd=%d: %s", fd, uvErrorString(err));
    }

    uv_close(reinterpret_cast<uv_handle_t*>(&watch->poll), &Watch::onClose);
}

} // namespace util
} // namespace mbgl
