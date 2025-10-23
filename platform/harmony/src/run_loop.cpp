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
#include "../maplibre_harmony/src/main/cpp/logger.h"

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
}

RunLoop::Impl::~Impl() {
    if (!watchPoll.empty()) {
        Logger::warn("RunLoop", "RunLoop destroyed with %zu active watches", watchPoll.size());
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
    impl->async = std::make_unique<AsyncTask>(std::bind(&RunLoop::process, this));
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
 * Get the raw loop handle
 * Thread-safe: Can be called from any thread
 */
LOOP_HANDLE RunLoop::getLoopHandle() {
    return Get()->impl->loop;
}

void RunLoop::wake() {
    if (impl->async) {
        impl->async->send();
    }
}

void RunLoop::run() {
    MBGL_VERIFY_THREAD(tid);
    
    uv_ref(impl->holderHandle());
    uv_run(impl->loop, UV_RUN_DEFAULT);
}

void RunLoop::runOnce() {
    MBGL_VERIFY_THREAD(tid);
    uv_run(impl->loop, UV_RUN_NOWAIT);
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
