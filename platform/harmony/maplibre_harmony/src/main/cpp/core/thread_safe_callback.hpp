#pragma once

#include "napi/native_api.h"
#include <functional>
#include <memory>
#include <string>

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
     * Invoke the callback from any thread.
     *
     * @param builder Data builder executed on the UI thread
     * @return True if dispatch succeeded
     */
    bool Call(DataBuilder builder);
    
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
     * Release resources (may be called explicitly; destructor also releases).
     */
    void Release();
    
    /**
     * Check whether the callback remains valid.
     */
    bool IsValid() const { return tsfn_ != nullptr; }
    
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
        DataBuilder builder;
        
        explicit CallbackData(DataBuilder b) : builder(std::move(b)) {}
    };
    
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
    
    napi_threadsafe_function tsfn_ = nullptr;
    std::string resourceName_;
};

} // namespace harmony
} // namespace mbgl

