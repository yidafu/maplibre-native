#include "thread_safe_callback.hpp"
#include "../utils/logger.h"
#include <memory>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

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
        0,  // max_queue_size (0 = unlimited)
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

bool ThreadSafeCallback::Call(DataBuilder builder) {
    if (tsfn_ == nullptr) {
        Logger::warn("ThreadSafeCallback", "Cannot call - already released");
        return false;
    }
    
    if (!builder) {
        Logger::warn("ThreadSafeCallback", "DataBuilder is null");
        return false;
    }
    
    // Create a heap-allocated copy of the data
    auto* data = new CallbackData(std::move(builder));
    
    // Invoke ThreadSafeFunction (non-blocking)
    napi_status status = napi_call_threadsafe_function(
        tsfn_,
        data,
        napi_tsfn_nonblocking
    );
    
    if (status != napi_ok) {
        Logger::error("ThreadSafeCallback", "Failed to call threadsafe function: %d", status);
        delete data;  // Clean up data
        return false;
    }
    
    return true;
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
    
    // Build arguments
    napi_value arg = nullptr;
    if (callbackData->builder) {
        arg = callbackData->builder(env);
    }
    
    // Use undefined if there is no constructor or construction fails
    if (arg == nullptr) {
        napi_get_undefined(env, &arg);
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
                1,  // argc
                &arg,
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

} // namespace harmony
} // namespace mbgl

