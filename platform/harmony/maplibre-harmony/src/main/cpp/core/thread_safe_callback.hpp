#pragma once

#include "napi/native_api.h"
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace mbgl {
namespace harmony {

/**
 * ThreadSafeCallback - thread-safe cross-thread callback wrapper.
 *
 * Wraps N-API ThreadSafeFunction to allow invoking JavaScript callbacks safely from any thread.
 * Inspired by Android's MapRendererRunnable design but implemented with N-API's ThreadSafeFunction.
 *
 * Usage:
 * ```cpp
 * // Create on the UI thread
 * auto callback = ThreadSafeCallback::Create(env, jsCallback, "onMapLoaded");
 *
 * // Call from the render thread
 * callback->Call([](napi_env env) {
 *     napi_value result;
 *     napi_create_string_utf8(env, "Map loaded", NAPI_AUTO_LENGTH, &result);
 *     return result;
 * });
 *
 * // Destroy (automatically handled in destructor)
 * callback->Release();
 * ```
 *
 * Thread-safety notes:
 * - Call()/Release() may race; the underlying tsfn pointer is guarded by a mutex and the
 *   N-API call happens under that lock, so a call can never land on a released tsfn.
 * - The queue is bounded: when the JS thread stalls, overflow events are dropped instead of
 *   growing without limit. Use CallBlocking() for one-shot completions that must not drop.
 * - CallJS opens a handle scope; without one every napi_create_* handle made in the builder
 *   would accumulate for the lifetime of the engine.
 */
class ThreadSafeCallback {
public:
    /**
     * Data builder invoked on the UI thread to construct callback arguments.
     *
     * @param env N-API environment (UI thread)
     * @return Callback argument (napi_value)
     */
    using DataBuilder = std::function<napi_value(napi_env env)>;

    /**
     * Multi-argument data builder invoked on the UI thread.
     *
     * @param env N-API environment (UI thread)
     * @return Callback arguments, passed to JS in order
     */
    using MultiArgBuilder = std::function<std::vector<napi_value>(napi_env env)>;

    /**
     * Create a thread-safe callback.
     *
     * @param env N-API environment
     * @param callback JavaScript callback function
     * @param resourceName Resource name (for debugging)
     * @return ThreadSafeCallback instance, or nullptr on failure
     */
    static std::unique_ptr<ThreadSafeCallback> Create(
        napi_env env,
        napi_value callback,
        const char* resourceName
    );

    ~ThreadSafeCallback();

    // Disable copying
    ThreadSafeCallback(const ThreadSafeCallback&) = delete;
    ThreadSafeCallback& operator=(const ThreadSafeCallback&) = delete;

    /**
     * Invoke the callback from any thread. Non-blocking: when the bounded queue is
     * full the event is dropped (with a rate-limited warning).
     *
     * @param builder Data builder executed on the UI thread
     * @return True if dispatch succeeded
     */
    bool Call(DataBuilder builder);

    /**
     * Invoke the callback with multiple arguments from any thread.
     * Same queue/drop semantics as Call().
     *
     * @param builder Multi-argument data builder executed on the UI thread
     * @return True if dispatch succeeded
     */
    bool CallMulti(MultiArgBuilder builder);

    /**
     * Invoke the callback from any thread, blocking until the event is queued.
     * Use for one-shot completions (destroy callbacks, etc.) that must not be dropped.
     *
     * Constraint: only for sparsely-used callbacks (a one-shot completion) — if the
     * queue were saturated while the JS thread concurrently blocked in Release(),
     * neither could make progress. Never use on high-frequency callbacks.
     */
    bool CallBlocking(DataBuilder builder);

    /**
     * Convenience call with a single string argument.
     */
    bool CallWithString(const std::string& value);

    /**
     * Convenience call with an object argument.
     */
    bool CallWithObject(const std::function<void(napi_env, napi_value)>& buildObject);

    /**
     * Convenience call with no arguments.
     */
    bool CallEmpty();

    /**
     * Run a task on the JS (env) thread without needing a JavaScript callback up front.
     *
     * Creates an ephemeral threadsafe function around a native stub and dispatches the
     * task through it. The task runs on the JS thread with a valid napi_env — required
     * for any N-API reference work (e.g. napi_delete_reference) triggered from worker
     * threads. The task is always executed or (on shutdown) destroyed; it must not
     * outlive objects it captures.
     *
     * @return True if the task was queued (or, on env/thread errors, false).
     */
    static bool DispatchTask(napi_env env, std::function<void(napi_env)> task);

    /**
     * Release resources (may be called explicitly; destructor also releases).
     */
    void Release();

    /**
     * Check whether the callback remains valid.
     */
    bool IsValid() const;

private:
    ThreadSafeCallback() = default;

    /**
     * Initialize the underlying ThreadSafeFunction.
     */
    bool Initialize(
        napi_env env,
        napi_value callback,
        const char* resourceName
    );

    /**
     * Wrapper for callback data.
     */
    struct CallbackData {
        DataBuilder builder;          // single-argument path (may be empty)
        MultiArgBuilder multiBuilder; // multi-argument path (may be empty)

        explicit CallbackData(DataBuilder b) : builder(std::move(b)) {}
        explicit CallbackData(MultiArgBuilder b) : multiBuilder(std::move(b)) {}
    };

    bool DispatchInternal(std::unique_ptr<CallbackData> data, bool blocking);

    /**
     * N-API callback executed on the UI thread.
     */
    static void CallJS(
        napi_env env,
        napi_value js_callback,
        void* context,
        void* data
    );

    /**
     * ThreadSafeFunction finalizer.
     */
    static void Finalize(
        napi_env env,
        void* finalize_data,
        void* finalize_hint
    );

    mutable std::mutex mutex_;
    napi_threadsafe_function tsfn_ = nullptr;  // guarded by mutex_
    std::string resourceName_;
};

} // namespace harmony
} // namespace mbgl
