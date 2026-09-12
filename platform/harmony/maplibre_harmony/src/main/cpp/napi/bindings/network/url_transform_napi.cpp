#include "url_transform_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "network/url_transform_manager.hpp"
#include "utils/logger.h"
#include <string>
#include <memory>
#include <mutex>
#include <condition_variable>
#include <chrono>
#include <thread>

using mbgl::harmony::Logger;
using mbgl::harmony::URLTransformManager;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

// Static member initialization
std::mutex URLTransformNAPI::contextMutex_;
std::shared_ptr<URLTransformNAPI::CallbackContext> URLTransformNAPI::callbackContext_;

// State exchanged between the calling (network/render) thread and the JS thread.
// Heap-allocated and owned by the queued CallJS invocation: if the caller times
// out and abandons the wait, the queued callback still owns the state and frees
// it, so no thread ever dereferences freed memory.
struct TransformCallState {
    int kind = 0;
    std::string url;
    std::string result;
    std::mutex mutex;
    std::condition_variable cv;
    bool done = false;
};

// Invoke the JS transform callback and resolve the result into `out`.
// Must run on the JS thread.
static void InvokeTransformCallback(napi_env env, napi_value js_callback, int kind, const std::string& url, std::string& out) {
    try {
        napi_value args[2];
        napi_create_int32(env, kind, &args[0]);
        napi_create_string_utf8(env, url.c_str(), NAPI_AUTO_LENGTH, &args[1]);

        napi_value result_value = nullptr;
        napi_status status = napi_call_function(env, nullptr, js_callback, 2, args, &result_value);
        if (status != napi_ok || result_value == nullptr) {
            Logger::error("URLTransformNAPI", "Failed to call JS callback");
            out = url;
            return;
        }

        // Measure first; bail out on any failure or non-string return value
        // instead of using an uninitialized length.
        size_t result_length = 0;
        if (napi_get_value_string_utf8(env, result_value, nullptr, 0, &result_length) != napi_ok) {
            out = url;
            return;
        }
        if (result_length == 0) {
            // Callback returned an empty string; use the original URL
            out = url;
            return;
        }
        std::string result_str(result_length, '\0');
        if (napi_get_value_string_utf8(env, result_value, &result_str[0], result_length + 1, nullptr) != napi_ok) {
            out = url;
            return;
        }
        out = std::move(result_str);
    } catch (const std::exception& e) {
        Logger::error("URLTransformNAPI", "Exception in transform callback: %s", e.what());
        out = url;
    } catch (...) {
        Logger::error("URLTransformNAPI", "Unknown exception in transform callback");
        out = url;
    }
}

// Threadsafe function callback (runs on the JS thread)
static void CallJS(napi_env env, napi_value js_callback, void* context, void* data) {
    (void)context;
    if (env == nullptr || js_callback == nullptr || data == nullptr) {
        return;
    }

    // Take ownership: the calling thread may have timed out and abandoned the state.
    std::unique_ptr<TransformCallState> callData(static_cast<TransformCallState*>(data));

    InvokeTransformCallback(env, js_callback, callData->kind, callData->url, callData->result);

    // Notify the C++ thread that the callback completed (no-op if it already timed out)
    {
        std::lock_guard<std::mutex> lock(callData->mutex);
        callData->done = true;
    }
    callData->cv.notify_one();
}

napi_value URLTransformNAPI::Init(napi_env env, napi_value exports) {
    napi_property_descriptor descriptors[] = {
        {"setResourceTransformCallback", nullptr, SetResourceTransformCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clearResourceTransformCallback", nullptr, ClearResourceTransformCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"hasResourceTransformCallback", nullptr, HasResourceTransformCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_status status = napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    if (status != napi_ok) {
        Logger::error("URLTransformNAPI", "Failed to define properties");
    }

    return exports;
}

napi_value URLTransformNAPI::SetResourceTransformCallback(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value callbackValue = args.GetFunction(0, "callback");
    if (args.HasError()) {
        return nullptr;
    }

    // Clean up the previous callback context. The mutex keeps this racing-free
    // against transform callbacks resolving the context on network threads.
    {
        std::lock_guard<std::mutex> lock(contextMutex_);
        if (callbackContext_ != nullptr) {
            if (callbackContext_->tsfn != nullptr) {
                napi_release_threadsafe_function(callbackContext_->tsfn, napi_tsfn_release);
                callbackContext_->tsfn = nullptr;
            }
            if (callbackContext_->callbackRef != nullptr) {
                napi_delete_reference(callbackContext_->env, callbackContext_->callbackRef);
                callbackContext_->callbackRef = nullptr;
            }
        }
        callbackContext_.reset();
    }

    // Create a new callback context
    auto ctx = std::make_shared<CallbackContext>();
    ctx->env = env;
    ctx->jsThreadId = std::this_thread::get_id();

    napi_status refStatus = napi_create_reference(env, callbackValue, 1, &ctx->callbackRef);
    if (refStatus != napi_ok) {
        Logger::error("URLTransformNAPI", "Failed to create callback reference");
        napi_throw_error(env, nullptr, "Failed to create callback reference");
        return nullptr;
    }

    // Create the threadsafe function
    napi_value async_resource_name;
    napi_create_string_utf8(env, "URLTransformCallback", NAPI_AUTO_LENGTH, &async_resource_name);

    napi_status status = napi_create_threadsafe_function(
        env,
        callbackValue,
        nullptr,
        async_resource_name,
        0,  // Unlimited queue size
        1,  // Initial thread count
        nullptr,
        nullptr,
        nullptr,
        CallJS,
        &ctx->tsfn);

    if (status != napi_ok) {
        Logger::error("URLTransformNAPI", "Failed to create threadsafe function");
        napi_delete_reference(env, ctx->callbackRef);
        napi_throw_error(env, nullptr, "Failed to create threadsafe function");
        return nullptr;
    }

    {
        std::lock_guard<std::mutex> lock(contextMutex_);
        callbackContext_ = std::move(ctx);
    }

    // Install the C++ conversion callback
    URLTransformManager::getInstance().setTransformCallback(
        [](mbgl::Resource::Kind kind, const std::string& url) -> std::string {
            std::shared_ptr<CallbackContext> ctx;
            {
                std::lock_guard<std::mutex> lock(contextMutex_);
                ctx = callbackContext_;
            }
            if (ctx == nullptr) {
                return url;
            }

            // Same-thread fast path: if the request originates on the JS thread,
            // queuing the callback and blocking on the wait would deadlock until
            // the timeout elapses — invoke the JS callback directly instead.
            if (std::this_thread::get_id() == ctx->jsThreadId && ctx->env != nullptr) {
                napi_value jsCallback = nullptr;
                if (ctx->callbackRef == nullptr ||
                    napi_get_reference_value(ctx->env, ctx->callbackRef, &jsCallback) != napi_ok ||
                    jsCallback == nullptr) {
                    return url;
                }
                std::string result;
                InvokeTransformCallback(ctx->env, jsCallback, static_cast<int>(kind), url, result);
                return result;
            }

            // Keep the threadsafe function alive for the duration of the call.
            // Acquire fails with napi_closing if the callback was cleared concurrently.
            napi_threadsafe_function tsfn = nullptr;
            {
                std::lock_guard<std::mutex> lock(contextMutex_);
                if (callbackContext_ != ctx || ctx->tsfn == nullptr) {
                    return url;
                }
                if (napi_acquire_threadsafe_function(ctx->tsfn) != napi_ok) {
                    return url;
                }
                tsfn = ctx->tsfn;
            }

            auto* state = new TransformCallState();
            state->kind = static_cast<int>(kind);
            state->url = url;

            napi_status status = napi_call_threadsafe_function(tsfn, state, napi_tsfn_blocking);
            if (status != napi_ok) {
                delete state;
                napi_release_threadsafe_function(tsfn, napi_tsfn_release);
                return url;
            }

            std::string result = url;
            {
                std::unique_lock<std::mutex> lock(state->mutex);
                if (state->cv.wait_for(lock, std::chrono::seconds(5), [&state] { return state->done; })) {
                    result = std::move(state->result);
                } else {
                    // Timed out: ownership of `state` has moved to the queued CallJS
                    // invocation — do not touch it any further.
                    Logger::error("URLTransformNAPI", "Timeout waiting for JS callback");
                }
            }
            napi_release_threadsafe_function(tsfn, napi_tsfn_release);
            return result;
        });

    Logger::info("URLTransformNAPI", "Resource transform callback set");

    return args.Undefined();
}

napi_value URLTransformNAPI::ClearResourceTransformCallback(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    // Clean up the callback context
    {
        std::lock_guard<std::mutex> lock(contextMutex_);
        if (callbackContext_ != nullptr) {
            if (callbackContext_->tsfn != nullptr) {
                napi_release_threadsafe_function(callbackContext_->tsfn, napi_tsfn_release);
                callbackContext_->tsfn = nullptr;
            }
            if (callbackContext_->callbackRef != nullptr) {
                napi_delete_reference(callbackContext_->env, callbackContext_->callbackRef);
                callbackContext_->callbackRef = nullptr;
            }
        }
        callbackContext_.reset();
    }

    // Clear the C++ callback
    URLTransformManager::getInstance().clearTransformCallback();

    Logger::info("URLTransformNAPI", "Resource transform callback cleared");

    return args.Undefined();
}

napi_value URLTransformNAPI::HasResourceTransformCallback(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    bool hasCallback = URLTransformManager::getInstance().hasCallback();

    napi_value result;
    napi_get_boolean(env, hasCallback, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl
