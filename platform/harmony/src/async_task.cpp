/**
 * HarmonyOS AsyncTask Implementation
 * 
 * Provides thread-safe cross-thread communication using libuv's async handles.
 * This is critical for FFRT integration and avoiding deadlocks.
 * 
 * Key Features:
 * - Lock-free notification via uv_async_send
 * - Automatic call coalescing by libuv
 * - Thread-safe: can be called from any thread
 * - Executes callback on RunLoop thread
 * 
 * HarmonyOS Considerations:
 * - FFRT task scheduling respects uv_async_send priority
 * - Must only be created on a thread with an active RunLoop
 * - Lifetime must not exceed the associated RunLoop
 * 
 * References:
 * - HarmonyOS libuv API: https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/libuv-V5
 */

#include <mbgl/util/async_task.hpp>
#include <mbgl/util/run_loop.hpp>

#include <uv.h>

#include <functional>
#include <memory>
#include <stdexcept>

// Use platform logger
#include "../maplibre_harmony/src/main/cpp/logger.h"

using mbgl::harmony::Logger;

namespace {

const char* uvErrorString(int errorCode) {
    return uv_strerror(errorCode);
}

} // namespace

namespace mbgl {
namespace util {

/**
 * AsyncTask::Impl - Internal implementation
 * 
 * Uses uv_async_t for lock-free cross-thread notifications.
 * The async handle is bound to the RunLoop's event loop.
 */
class AsyncTask::Impl {
public:
    /**
     * Constructor
     * 
     * Creates an async handle on the current RunLoop's event loop.
     * Must be called from a thread with an active RunLoop.
     * 
     * @param task The function to execute on the RunLoop thread
     * @throws std::runtime_error if no RunLoop exists or initialization fails
     */
    explicit Impl(std::function<void()>&& task)
        : task(std::move(task)) {
        
        runLoop = RunLoop::Get();
        if (!runLoop) {
            Logger::error("AsyncTask", "No RunLoop on current thread");
            throw std::runtime_error("AsyncTask requires an active RunLoop on the current thread");
        }
        
        auto* loop = static_cast<uv_loop_t*>(runLoop->getLoopHandle());
        if (!loop) {
            Logger::error("AsyncTask", "Failed to get loop handle from RunLoop");
            throw std::runtime_error("Failed to get loop handle from RunLoop");
        }
        
        async = new uv_async_t;
        async->data = this;
        
        if (int err = uv_async_init(loop, async, asyncCallback); err != 0) {
            Logger::error("AsyncTask", "Failed to initialize uv_async: %s", uvErrorString(err));
            delete async;
            async = nullptr;
            throw std::runtime_error("Failed to initialize async handle: " + std::string(uvErrorString(err)));
        }
        
        uv_unref(reinterpret_cast<uv_handle_t*>(async));
    }

    /**
     * Destructor
     * 
     * Schedules the async handle to be closed.
     * The actual deletion happens in the close callback.
     * 
     * HarmonyOS Note: Close callbacks are processed by the event loop,
     * so the RunLoop must still be alive when this is called.
     */
    ~Impl() {
        if (async) {
            uv_close(reinterpret_cast<uv_handle_t*>(async), closeCallback);
        }
    }

    /**
     * Send notification
     * 
     * Thread-safe: Can be called from any thread.
     * Uses uv_async_send which is lock-free and coalesces multiple calls.
     * 
     * HarmonyOS Note: This integrates with FFRT - the callback will be
     * scheduled on the eventhandler queue with appropriate priority.
     */
    void send() {
        if (!async) {
            return;
        }
        
        if (int err = uv_async_send(async); err != 0) {
            Logger::error("AsyncTask", "uv_async_send failed: %s", uvErrorString(err));
            throw std::runtime_error("Failed to send async notification: " + std::string(uvErrorString(err)));
        }
    }

private:
    /**
     * Static callback invoked by libuv on the RunLoop thread
     * 
     * This is called when the async handle is signaled.
     * Multiple send() calls may result in a single callback invocation (coalescing).
     */
    static void asyncCallback(uv_async_t* handle) {
        auto* self = static_cast<Impl*>(handle->data);
        
        if (self && self->task) {
            self->task();
        }
    }
    
    static void closeCallback(uv_handle_t* handle) {
        auto* asyncHandle = reinterpret_cast<uv_async_t*>(handle);
        delete asyncHandle;
    }
    
    // The task to execute on the RunLoop thread
    std::function<void()> task;
    
    // The RunLoop this AsyncTask is bound to
    RunLoop* runLoop = nullptr;
    
    // The libuv async handle for cross-thread notifications
    // This is deleted in the close callback, not in the destructor
    uv_async_t* async = nullptr;
};

AsyncTask::AsyncTask(std::function<void()>&& fn)
    : impl(std::make_unique<Impl>(std::move(fn))) {
}

AsyncTask::~AsyncTask() {
}

void AsyncTask::send() {
    if (impl) {
        impl->send();
    }
}

} // namespace util
} // namespace mbgl
