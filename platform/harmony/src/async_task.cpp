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

// HarmonyOS HiLog integration for debugging
#include <hilog/log.h>

#define AT_LOG_DEBUG(...) OH_LOG_Print(LOG_APP, LOG_DEBUG, 0x0000, "AsyncTask", __VA_ARGS__)
#define AT_LOG_INFO(...) OH_LOG_Print(LOG_APP, LOG_INFO, 0x0000, "AsyncTask", __VA_ARGS__)
#define AT_LOG_WARN(...) OH_LOG_Print(LOG_APP, LOG_WARN, 0x0000, "AsyncTask", __VA_ARGS__)
#define AT_LOG_ERROR(...) OH_LOG_Print(LOG_APP, LOG_ERROR, 0x0000, "AsyncTask", __VA_ARGS__)

namespace {

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
        
        AT_LOG_INFO("========== AsyncTask::Impl Constructor START ==========");
        
        // Get the RunLoop for the current thread
        runLoop = RunLoop::Get();
        if (!runLoop) {
            AT_LOG_ERROR("No RunLoop on current thread");
            throw std::runtime_error("AsyncTask requires an active RunLoop on the current thread");
        }
        
        AT_LOG_DEBUG("AsyncTask created on RunLoop: %{public}p", runLoop);
        
        // Get the raw loop handle
        auto* loop = static_cast<uv_loop_t*>(runLoop->getLoopHandle());
        if (!loop) {
            AT_LOG_ERROR("Failed to get loop handle from RunLoop");
            throw std::runtime_error("Failed to get loop handle from RunLoop");
        }
        
        AT_LOG_DEBUG("Got loop handle: %{public}p", loop);
        
        // Allocate async handle
        async = new uv_async_t;
        async->data = this;
        
        AT_LOG_DEBUG("Allocated uv_async_t at %{public}p", async);
        
        // Initialize async handle
        // HarmonyOS Note: uv_async_init integrates with FFRT for task scheduling
        if (int err = uv_async_init(loop, async, asyncCallback); err != 0) {
            AT_LOG_ERROR("Failed to initialize uv_async: %{public}s", uvErrorString(err));
            delete async;
            async = nullptr;
            throw std::runtime_error("Failed to initialize async handle: " + 
                                   std::string(uvErrorString(err)));
        }
        
        AT_LOG_INFO("uv_async initialized successfully");
        
        // Unref the handle so it doesn't keep the loop alive
        // The loop is kept alive by the RunLoop's holder handle
        uv_unref(reinterpret_cast<uv_handle_t*>(async));
        AT_LOG_DEBUG("uv_async unreferenced");
        
        AT_LOG_INFO("========== AsyncTask::Impl Constructor COMPLETE ==========");
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
        AT_LOG_INFO("========== AsyncTask::Impl Destructor ==========");
        
        if (async) {
            AT_LOG_DEBUG("Scheduling close for uv_async at %{public}p", async);
            
            // Schedule async handle close
            // The close callback will delete the handle
            uv_close(reinterpret_cast<uv_handle_t*>(async), closeCallback);
            
            // Note: We don't set async = nullptr here because the close
            // callback needs the pointer. The handle is marked as closing.
            AT_LOG_DEBUG("Close scheduled - handle will be deleted in close callback");
        } else {
            AT_LOG_WARN("Destructor called but async handle is null");
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
            AT_LOG_WARN("send() called but async handle is null (already closed?)");
            return;
        }
        
        AT_LOG_DEBUG("AsyncTask::send() - using lock-free uv_async_send");
        
        // uv_async_send is lock-free and thread-safe
        // Multiple calls are automatically coalesced by libuv
        // HarmonyOS: This works correctly with FFRT task scheduling
        if (int err = uv_async_send(async); err != 0) {
            AT_LOG_ERROR("uv_async_send failed: %{public}s", uvErrorString(err));
            throw std::runtime_error("Failed to send async notification: " + 
                                   std::string(uvErrorString(err)));
        }
        
        AT_LOG_DEBUG("uv_async_send succeeded");
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
        
        if (!self) {
            AT_LOG_ERROR("asyncCallback invoked with null data");
            return;
        }
        
        AT_LOG_DEBUG("Executing async task on RunLoop thread");
        
        if (self->task) {
            // Execute the user's callback on the RunLoop thread
            // This is guaranteed to run on the same thread as the event loop
            self->task();
            AT_LOG_DEBUG("Async task executed successfully");
        } else {
            AT_LOG_WARN("Async task callback is null");
        }
    }
    
    /**
     * Static callback invoked when the async handle is closed
     * 
     * This is called on the RunLoop thread after uv_close() is called.
     * Safe to delete the handle here.
     */
    static void closeCallback(uv_handle_t* handle) {
        auto* asyncHandle = reinterpret_cast<uv_async_t*>(handle);
        
        AT_LOG_DEBUG("Close callback for uv_async at %{public}p", asyncHandle);
        
        // Safe to delete now - the handle is fully closed
        delete asyncHandle;
        
        AT_LOG_DEBUG("uv_async deleted");
    }
    
    // The task to execute on the RunLoop thread
    std::function<void()> task;
    
    // The RunLoop this AsyncTask is bound to
    RunLoop* runLoop = nullptr;
    
    // The libuv async handle for cross-thread notifications
    // This is deleted in the close callback, not in the destructor
    uv_async_t* async = nullptr;
};

/**
 * AsyncTask public constructor
 */
AsyncTask::AsyncTask(std::function<void()>&& fn)
    : impl(std::make_unique<Impl>(std::move(fn))) {
    AT_LOG_DEBUG("AsyncTask created at %{public}p", this);
}

/**
 * AsyncTask destructor
 */
AsyncTask::~AsyncTask() {
    AT_LOG_DEBUG("AsyncTask destroyed at %{public}p", this);
}

/**
 * Send notification to execute the task
 * 
 * Thread-safe: Can be called from any thread.
 * The task will be executed on the RunLoop thread.
 */
void AsyncTask::send() {
    if (impl) {
        impl->send();
    } else {
        AT_LOG_ERROR("send() called but impl is null");
    }
}

} // namespace util
} // namespace mbgl
