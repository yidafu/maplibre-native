#include "url_transform_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "network/url_transform_manager.hpp"
#include "utils/logger.h"
#include <string>
#include <mutex>
#include <condition_variable>
#include <chrono>

using mbgl::harmony::Logger;
using mbgl::harmony::URLTransformManager;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

// Static member initialization
URLTransformNAPI::CallbackContext* URLTransformNAPI::callbackContext_ = nullptr;

// Data structure for invoking the threadsafe function
struct TransformCallData {
    int kind;
    std::string url;
    std::string* result;  // Pointer to the result string
    std::mutex* mutex;    // Mutex used for synchronization
    std::condition_variable* cv;  // Condition variable used for synchronization
    bool* done;           // Completion flag
};

// Threadsafe function callback (runs on the JS thread)
static void CallJS(napi_env env, napi_value js_callback, void* context, void* data) {
    if (env == nullptr || js_callback == nullptr || data == nullptr) {
        return;
    }

    TransformCallData* callData = static_cast<TransformCallData*>(data);

    try {
        // Prepare arguments
        napi_value args[2];
        napi_create_int32(env, callData->kind, &args[0]);
        napi_create_string_utf8(env, callData->url.c_str(), NAPI_AUTO_LENGTH, &args[1]);

        // Invoke the JS callback
        napi_value result_value;
        napi_status status = napi_call_function(env, nullptr, js_callback, 2, args, &result_value);

        if (status == napi_ok) {
            // Retrieve the return value
            size_t result_length;
            napi_get_value_string_utf8(env, result_value, nullptr, 0, &result_length);
            
            if (result_length > 0) {
                std::string result_str(result_length, '\0');
                napi_get_value_string_utf8(env, result_value, &result_str[0], result_length + 1, nullptr);
                *callData->result = result_str;
            } else {
                // Callback returned an empty string or undefined; use the original URL
                *callData->result = callData->url;
            }
        } else {
            Logger::error("URLTransformNAPI", "Failed to call JS callback");
            *callData->result = callData->url;
        }

    } catch (const std::exception& e) {
        Logger::error("URLTransformNAPI", "Exception in CallJS: %s", e.what());
        *callData->result = callData->url;
    } catch (...) {
        Logger::error("URLTransformNAPI", "Unknown exception in CallJS");
        *callData->result = callData->url;
    }

    // Notify the C++ thread that the callback completed
    {
        std::lock_guard<std::mutex> lock(*callData->mutex);
        *callData->done = true;
    }
    callData->cv->notify_one();
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

    // Clean up the previous callback context
    if (callbackContext_ != nullptr) {
        if (callbackContext_->tsfn != nullptr) {
            napi_release_threadsafe_function(callbackContext_->tsfn, napi_tsfn_abort);
        }
        if (callbackContext_->callbackRef != nullptr) {
            napi_delete_reference(callbackContext_->env, callbackContext_->callbackRef);
        }
        delete callbackContext_;
        callbackContext_ = nullptr;
    }

    // Create a new callback context
    callbackContext_ = new CallbackContext();
    callbackContext_->env = env;

    // Create a persistent reference
    napi_create_reference(env, callbackValue, 1, &callbackContext_->callbackRef);

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
        &callbackContext_->tsfn);

    if (status != napi_ok) {
        Logger::error("URLTransformNAPI", "Failed to create threadsafe function");
        delete callbackContext_;
        callbackContext_ = nullptr;
        napi_throw_error(env, nullptr, "Failed to create threadsafe function");
        return nullptr;
    }

    // Install the C++ conversion callback
    URLTransformManager::getInstance().setTransformCallback(
        [](mbgl::Resource::Kind kind, const std::string& url) -> std::string {
            if (callbackContext_ == nullptr || callbackContext_->tsfn == nullptr) {
                return url;
            }

            try {
                // Prepare the call data
                std::string result;
                std::mutex mutex;
                std::condition_variable cv;
                bool done = false;

                TransformCallData callData{
                    static_cast<int>(kind),
                    url,
                    &result,
                    &mutex,
                    &cv,
                    &done
                };

                // Invoke the threadsafe function
                napi_status status = napi_call_threadsafe_function(
                    callbackContext_->tsfn,
                    &callData,
                    napi_tsfn_blocking);

                if (status != napi_ok) {
                    Logger::error("URLTransformNAPI", "Failed to call threadsafe function");
                    return url;
                }

                // Wait for the callback to finish (with timeout protection)
                std::unique_lock<std::mutex> lock(mutex);
                if (!cv.wait_for(lock, std::chrono::seconds(5), [&done] { return done; })) {
                    Logger::error("URLTransformNAPI", "Timeout waiting for JS callback");
                    return url;
                }

                return result;

            } catch (const std::exception& e) {
                Logger::error("URLTransformNAPI", "Exception in transform callback: %s", e.what());
                return url;
            } catch (...) {
                Logger::error("URLTransformNAPI", "Unknown exception in transform callback");
                return url;
            }
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
    if (callbackContext_ != nullptr) {
        if (callbackContext_->tsfn != nullptr) {
            napi_release_threadsafe_function(callbackContext_->tsfn, napi_tsfn_abort);
            callbackContext_->tsfn = nullptr;
        }
        if (callbackContext_->callbackRef != nullptr) {
            napi_delete_reference(callbackContext_->env, callbackContext_->callbackRef);
            callbackContext_->callbackRef = nullptr;
        }
        delete callbackContext_;
        callbackContext_ = nullptr;
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

