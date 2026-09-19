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

#include "loop_guard.hpp"

#include <uv.h>

#include <atomic>
#include <functional>
#include <memory>
#include <mutex>
#include <stdexcept>

// Use platform logger
#include "../maplibre-harmony/src/main/cpp/utils/logger.h"

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

        // Share the loop-liveness token: once the RunLoop begins final
        // teardown, sends become no-ops and the destructor skips uv_close —
        // neither path can touch a loop that is closing or already freed.
        loopGuard = harmony::acquireLoopGuard(loop);

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
     * Critical Fix: Prevent RunLoop shutdown deadlock
     *
     * Problem: uv_close() callbacks require the RunLoop to continue processing.
     * If AsyncTask is destroyed after RunLoop::stop(), the following deadlock occurs:
     * - The main thread waits for the RunLoop thread to join.
     * - The RunLoop thread waits for the uv_close callback.
     * - The callback never fires because the loop already stopped.
     *
     * Solution: use uv_close + reference counting + immediate data clearing.
     * - Track cleanup state with an atomic flag.
     * - uv_close marks the handle as closing; libuv cleans it during the next iteration.
     * - Replace data with a completion flag so closeCallback can safely finalize cleanup.
     * - Even if the callback never runs, there is no unsafe memory access.
     *
     * Teardown-race fix: send() can be called from a foreign thread (e.g. the
     * CURLEventLoop thread completing a transfer) while this destructor runs on
     * the RunLoop thread. Serializing both under `mutex` with the `closed` flag
     * guarantees a send either fully precedes uv_close (handle still alive) or
     * observes `closed` and never touches the handle again — previously a
     * uv_async_send on a freed handle/freed loop, seen as SIGSEGV in
     * uv__async_io on the RunLoop thread.
     */
    ~Impl() {
        if (!async) {
            return;
        }

        const bool loopAlive = loopGuard && loopGuard->alive.load(std::memory_order_acquire);

        {
            std::lock_guard<std::mutex> lock(mutex);
            closed = true;

            if (!loopAlive) {
                // The loop is gone (or being torn down): running uv_close
                // would touch freed loop internals. Deleting the handle
                // directly would leave a freed node linked in the loop's
                // handle queues if the teardown hasn't reached it yet.
                // Leak the ~80-byte handle instead — the safe choice.
                async = nullptr;
                return;
            }

            // Track cleanup state with an atomic flag.
            // closeCallback sets the flag and deletes it.
            auto* completionFlag = new std::atomic<bool>(false);
            async->data = completionFlag;

            // Call uv_close to mark the handle as closing.
            // libuv cleans it during the next event-loop iteration.
            // closeCallback runs when the RunLoop iterates again.
            uv_close(reinterpret_cast<uv_handle_t*>(async), closeCallback);

            // Do not delete async here: closeCallback owns that responsibility.
            // If closeCallback never runs, we leak a tiny amount of memory,
            // which is preferable to a crash or deadlock.
            async = nullptr;
        }

    }

    /**
     * Send notification
     *
     * Thread-safe: Can be called from any thread, including concurrently with
     * the destructor (see the teardown-race fix note there).
     * Uses uv_async_send which is lock-free and coalesces multiple calls.
     */
    void send() {
        // Serializes against ~Impl(): once `closed` is set under the mutex,
        // the handle is uv_close()d and its memory owned by the close
        // callback — no thread may call uv_async_send on it anymore.
        std::lock_guard<std::mutex> lock(mutex);
        if (closed || !async) {
            return;
        }
        // The loop's liveness token is cleared before uv_loop_close/delete:
        // once false, this loop can no longer accept async notifications.
        if (!loopGuard || !loopGuard->alive.load(std::memory_order_acquire)) {
            return;
        }

        if (int err = uv_async_send(async); err != 0) {
            // Must not throw: send() regularly runs on foreign threads where a
            // thrown error would terminate. The transfer's caller-side
            // callback is dispatched via the RunLoop anyway.
            Logger::error("AsyncTask", "uv_async_send failed: %s", uvErrorString(err));
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
        
        // If a completion flag exists, mark it finished and delete it.
        if (asyncHandle->data) {
            auto* completionFlag = static_cast<std::atomic<bool>*>(asyncHandle->data);
            completionFlag->store(true, std::memory_order_release);
            delete completionFlag;
            asyncHandle->data = nullptr;
        }
        
        // Delete the async handle.
        delete asyncHandle;
    }
    
    // The task to execute on the RunLoop thread
    std::function<void()> task;

    // The RunLoop this AsyncTask is bound to
    RunLoop* runLoop = nullptr;

    // The libuv async handle for cross-thread notifications
    // This is deleted in the close callback, not in the destructor
    uv_async_t* async = nullptr;

    // Serializes send() against the destructor's uv_close: send() runs on
    // foreign threads, the destructor on the RunLoop thread. After `closed`
    // is set (under mutex), send() never touches the handle again.
    std::mutex mutex;
    bool closed = false;

    // Shared liveness token owned by the RunLoop. Cleared before the loop is
    // closed/freed; guards both send() and the destructor against a loop that
    // is already (being) torn down.
    std::shared_ptr<harmony::LoopGuard> loopGuard;
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
