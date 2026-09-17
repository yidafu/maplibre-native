#include "thread_safe_callback.hpp"
#include "../utils/logger.h"
#include <atomic>
#include <memory>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

namespace {
// Bound the per-callback queue so a stalled JS thread cannot accumulate events
// without limit. Overflow drops the newest event (Call) instead of growing memory.
constexpr uint32_t kMaxQueueSize = 256;

// Drop warnings are rate-limited: log the first drop, then one per hundred.
std::atomic<int> g_dropCount{0};

void logDrop(const char* resourceName) {
    int n = ++g_dropCount;
    if (n == 1 || (n % 100) == 0) {
        Logger::warn("ThreadSafeCallback",
                     "Event queue full (%d total drops), dropping callback event for '%s'",
                     n, resourceName);
    }
}
} // namespace

std::unique_ptr<ThreadSafeCallback> ThreadSafeCallback::Create(
    napi_env env,
    napi_value callback,
    const char* resourceName
) {
    if (env == nullptr || callback == nullptr || resourceName == nullptr) {
        Logger::error("ThreadSafeCallback", "Invalid parameters for Create");
        return nullptr;
    }

    // Verify the value is a function
    napi_valuetype valueType;
    napi_status status = napi_typeof(env, callback, &valueType);
    if (status != napi_ok || valueType != napi_function) {
        Logger::error("ThreadSafeCallback", "Callback is not a function");
        return nullptr;
    }

    auto instance = std::unique_ptr<ThreadSafeCallback>(new ThreadSafeCallback());
    if (!instance->Initialize(env, callback, resourceName)) {
        return nullptr;
    }

    return instance;
}

bool ThreadSafeCallback::Initialize(
    napi_env env,
    napi_value callback,
    const char* resourceName
) {
    resourceName_ = resourceName;

    // Create resource name
    napi_value resourceNameValue;
    napi_status status = napi_create_string_utf8(
        env,
        resourceName,
        NAPI_AUTO_LENGTH,
        &resourceNameValue
    );

    if (status != napi_ok) {
        Logger::error("ThreadSafeCallback", "Failed to create resource name: %d", status);
        return false;
    }

    // Create ThreadSafeFunction
    status = napi_create_threadsafe_function(
        env,
        callback,
        nullptr,  // async_resource
        resourceNameValue,
        kMaxQueueSize,  // max_queue_size (bounded)
        1,  // initial_thread_count
        nullptr,  // thread_finalize_data
        Finalize,  // thread_finalize_cb
        this,  // context
        CallJS,  // call_js_cb
        &tsfn_
    );

    if (status != napi_ok) {
        Logger::error("ThreadSafeCallback", "Failed to create threadsafe function: %d", status);
        tsfn_ = nullptr;
        return false;
    }

    return true;
}

ThreadSafeCallback::~ThreadSafeCallback() {
    Release();
}

bool ThreadSafeCallback::DispatchInternal(std::unique_ptr<CallbackData> data, bool blocking) {
    if (!data || (!data->builder && !data->multiBuilder)) {
        Logger::warn("ThreadSafeCallback", "DataBuilder is null");
        return false;
    }

    // Hold the lock across the N-API call so Release() can never free the tsfn
    // between the null check and the dispatch (call-after-finalize is UB).
    // The call itself is non-blocking for the calling thread (or bounded by the
    // queue drain in the blocking variant), so lock hold times are negligible.
    napi_status status;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (tsfn_ == nullptr) {
            Logger::warn("ThreadSafeCallback", "Cannot call - already released");
            return false;
        }

        status = napi_call_threadsafe_function(
            tsfn_,
            data.get(),
            blocking ? napi_tsfn_blocking : napi_tsfn_nonblocking
        );
    }

    if (status != napi_ok) {
        if (status == napi_queue_full) {
            logDrop(resourceName_.c_str());
        } else {
            Logger::warn("ThreadSafeCallback", "Call skipped (status %d) for '%s'",
                         status, resourceName_.c_str());
        }
        // data is a unique_ptr: freed automatically on this failure path.
        return false;
    }

    // Queue succeeded: CallJS (or the tsfn teardown) now owns the data.
    (void)data.release();
    return true;
}

bool ThreadSafeCallback::Call(DataBuilder builder) {
    return DispatchInternal(std::make_unique<CallbackData>(std::move(builder)), false);
}

bool ThreadSafeCallback::CallBlocking(DataBuilder builder) {
    return DispatchInternal(std::make_unique<CallbackData>(std::move(builder)), true);
}

bool ThreadSafeCallback::CallMulti(MultiArgBuilder builder) {
    return DispatchInternal(std::make_unique<CallbackData>(std::move(builder)), false);
}

bool ThreadSafeCallback::CallWithString(const std::string& value) {
    return Call([value](napi_env env) -> napi_value {
        napi_value result;
        napi_status status = napi_create_string_utf8(
            env,
            value.c_str(),
            value.length(),
            &result
        );

        if (status != napi_ok) {
            Logger::error("ThreadSafeCallback", "Failed to create string value: %d", status);
            napi_get_undefined(env, &result);
        }

        return result;
    });
}

bool ThreadSafeCallback::CallWithObject(const std::function<void(napi_env, napi_value)>& buildObject) {
    return Call([buildObject](napi_env env) -> napi_value {
        napi_value obj;
        napi_status status = napi_create_object(env, &obj);

        if (status != napi_ok) {
            Logger::error("ThreadSafeCallback", "Failed to create object: %d", status);
            napi_get_undefined(env, &obj);
            return obj;
        }

        buildObject(env, obj);
        return obj;
    });
}

bool ThreadSafeCallback::CallEmpty() {
    return Call([](napi_env env) -> napi_value {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    });
}

void ThreadSafeCallback::Release() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (tsfn_ != nullptr) {
        // Release ThreadSafeFunction
        napi_status status = napi_release_threadsafe_function(
            tsfn_,
            napi_tsfn_release
        );

        if (status != napi_ok) {
            Logger::error("ThreadSafeCallback", "Failed to release threadsafe function: %d", status);
        }

        tsfn_ = nullptr;
    }
}

bool ThreadSafeCallback::IsValid() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return tsfn_ != nullptr;
}

void ThreadSafeCallback::CallJS(
    napi_env env,
    napi_value js_callback,
    void* context,
    void* data
) {
    // Retrieve data
    auto* callbackData = static_cast<CallbackData*>(data);

    if (callbackData == nullptr) {
        Logger::error("ThreadSafeCallback", "CallJS: data is null");
        return;
    }

    // Node-API invokes call_js_cb without an ambient handle scope; every
    // napi_value created below would leak without one.
    napi_handle_scope scope = nullptr;
    napi_status scopeStatus = napi_open_handle_scope(env, &scope);
    const bool scopeOpen = (scopeStatus == napi_ok);

    // Build arguments (single-arg and multi-arg builders)
    std::vector<napi_value> args;
    if (callbackData->multiBuilder) {
        args = callbackData->multiBuilder(env);
    } else if (callbackData->builder) {
        args.push_back(callbackData->builder(env));
    }

    // Use undefined for missing builders and failed value construction — a
    // nullptr napi_value must never reach napi_call_function.
    napi_value undefinedValue = nullptr;
    for (auto& arg : args) {
        if (arg == nullptr && napi_get_undefined(env, &undefinedValue) == napi_ok) {
            arg = undefinedValue;
        }
    }
    if (args.empty() && napi_get_undefined(env, &undefinedValue) == napi_ok) {
        args.push_back(undefinedValue);
    }

    // Invoke JavaScript callback
    if (js_callback != nullptr) {
        napi_value global;
        napi_status status = napi_get_global(env, &global);

        if (status == napi_ok) {
            napi_value result;
            status = napi_call_function(
                env,
                global,
                js_callback,
                static_cast<size_t>(args.size()),
                args.data(),
                &result
            );

            if (status != napi_ok) {
                Logger::error("ThreadSafeCallback", "Failed to call JS function: %d", status);

                // Check for exceptions
                bool isPending = false;
                napi_is_exception_pending(env, &isPending);
                if (isPending) {
                    napi_value error;
                    napi_get_and_clear_last_exception(env, &error);

                    // Log exception details
                    napi_value message;
                    if (napi_coerce_to_string(env, error, &message) == napi_ok) {
                        char errorMsg[256];
                        size_t length;
                        if (napi_get_value_string_utf8(env, message, errorMsg, sizeof(errorMsg), &length) == napi_ok) {
                            Logger::error("ThreadSafeCallback", "JS exception: %s", errorMsg);
                        }
                    }
                }
            }
        }
    }

    // Clean up data
    delete callbackData;

    if (scopeOpen) {
        napi_close_handle_scope(env, scope);
    }
}

void ThreadSafeCallback::Finalize(
    napi_env env,
    void* finalize_data,
    void* finalize_hint
) {
    // SIGSEGV fix: do not access instance members here
    // Reason: Finalize may run after the object is destroyed; touching members would crash
    // Solution: only log that Finalize was invoked, avoid accessing object state
}

bool ThreadSafeCallback::DispatchTask(napi_env env, std::function<void(napi_env)> task) {
    if (env == nullptr || !task) {
        return false;
    }

    struct TaskContext {
        std::function<void(napi_env)> task;
        explicit TaskContext(std::function<void(napi_env)> t) : task(std::move(t)) {}
    };

    auto* context = new TaskContext(std::move(task));

    // Native stub: never actually invoked through napi_call_function — the
    // threadsafe function dispatches to CallTask below instead. It only serves
    // as the referenced JS value the tsfn lifecycle requires.
    napi_value stub = nullptr;
    napi_status status = napi_create_function(
        env, "mbgl_dispatch_task", NAPI_AUTO_LENGTH,
        [](napi_env env, napi_callback_info) -> napi_value {
            napi_value undefined;
            napi_get_undefined(env, &undefined);
            return undefined;
        }, nullptr, &stub);

    napi_value name = nullptr;
    if (status == napi_ok) {
        status = napi_create_string_utf8(env, "mbgl_dispatch_task", NAPI_AUTO_LENGTH, &name);
    }

    napi_threadsafe_function tsfn = nullptr;
    if (status == napi_ok) {
        status = napi_create_threadsafe_function(
            env,
            stub,
            nullptr,
            name,
            4,  // small bound: task dispatches are one-shot
            1,
            context,          // finalize_data: owns the context lifetime
            [](napi_env env, void* data, void*) {
                // Runs on the JS thread after the queue drains; the task either
                // already ran (queued item) or is dropped with the queue.
                delete static_cast<TaskContext*>(data);
            },
            context,          // context: passed through to the call_js_cb
            [](napi_env env, napi_value, void* ctx, void*) {
                auto* tc = static_cast<TaskContext*>(ctx);
                napi_handle_scope scope = nullptr;
                const bool open = (napi_open_handle_scope(env, &scope) == napi_ok);
                if (tc && tc->task) {
                    tc->task(env);
                }
                if (open) {
                    napi_close_handle_scope(env, scope);
                }
            },
            &tsfn);
    }

    if (status != napi_ok || tsfn == nullptr) {
        Logger::error("ThreadSafeCallback", "DispatchTask: failed to create threadsafe function: %d", status);
        delete context;
        return false;
    }

    // Queue the task, then drop our thread-count reference. The queued item
    // still executes; finalize (above) deletes the context once drained.
    status = napi_call_threadsafe_function(tsfn, nullptr, napi_tsfn_nonblocking);
    napi_release_threadsafe_function(tsfn, napi_tsfn_release);

    if (status != napi_ok) {
        Logger::warn("ThreadSafeCallback", "DispatchTask: task not queued (status %d)", status);
        // The finalize callback deletes the context either way.
        return false;
    }

    return true;
}

} // namespace harmony
} // namespace mbgl
