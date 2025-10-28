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

#include <atomic>
#include <functional>
#include <memory>
#include <stdexcept>

// Use platform logger
#include "../maplibre_harmony/src/main/cpp/utils/logger.h"

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
     * ⚡ CRITICAL FIX: 避免RunLoop退出死锁
     * 
     * 问题：uv_close()的callback需要RunLoop运行才能触发
     * 如果在RunLoop.stop()后析构AsyncTask，会导致：
     * - 主线程等待RunLoop线程退出
     * - RunLoop线程等待uv_close callback
     * - callback永远不会被调用 → 死锁！
     * 
     * 解决方案：使用 uv_close + 引用计数 + 立即清空data指针
     * - 使用原子标志跟踪清理状态
     * - uv_close标记handle为closing，libuv会在下次迭代清理
     * - 设置data为完成标志，closeCallback可以安全地标记完成
     * - 即使callback没有触发，也不会有内存安全问题
     */
    ~Impl() {
        if (!async) {
            return;
        }
        
        Logger::debug("AsyncTask", "Destructing AsyncTask::Impl, scheduling async handle close");
        
        // 🛡️ 使用原子标志跟踪清理状态
        // closeCallback 会设置这个标志并删除它
        auto* completionFlag = new std::atomic<bool>(false);
        async->data = completionFlag;
        
        // 调用uv_close标记handle为关闭状态
        // libuv会在下次事件循环迭代时清理handle
        // closeCallback 会在 RunLoop 运行时被调用
        uv_close(reinterpret_cast<uv_handle_t*>(async), closeCallback);
        
        // 注意：不要delete async，它会在closeCallback中被删除
        //      如果closeCallback没被调用，会有小的内存泄漏
        //      但这比崩溃或死锁要好得多
        async = nullptr;
        
        Logger::debug("AsyncTask", "AsyncTask::Impl destructor completed, handle scheduled for closing");
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
    
    /**
     * Close callback - invoked by libuv when handle is fully closed
     * 
     * This may be called after the Impl object is destroyed, so we
     * use the completion flag to safely track cleanup state.
     */
    static void closeCallback(uv_handle_t* handle) {
        auto* asyncHandle = reinterpret_cast<uv_async_t*>(handle);
        
        // 如果有完成标志，标记完成并删除
        if (asyncHandle->data) {
            auto* completionFlag = static_cast<std::atomic<bool>*>(asyncHandle->data);
            completionFlag->store(true, std::memory_order_release);
            delete completionFlag;
            asyncHandle->data = nullptr;
            Logger::debug("AsyncTask", "Close callback executed, handle cleanup complete");
        }
        
        // 删除 async handle
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
