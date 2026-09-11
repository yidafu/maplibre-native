#pragma once

#include "thread_safe_callback.hpp"
#include "napi/native_api.h"
#include <atomic>
#include <string>
#include <unordered_map>
#include <memory>
#include <mutex>
#include <functional>

namespace mbgl {
namespace harmony {

/**
 * CallbackManager - centralizes cross-thread JavaScript callbacks.
 *
 * Manages all JavaScript functions that must be invoked on the UI thread from the map runloop thread.
 * Each callback is wrapped by ThreadSafeCallback to guarantee thread safety.
 *
 * Design principles:
 * 1. Centralized management: callbacks registered/invoked through a unified interface
 * 2. Thread-safe: mutex-protected callback storage
 * 3. Lifecycle clarity: explicit registration, deregistration, and cleanup APIs
 * 4. Robust error handling: covers missing callbacks, duplicate registrations, etc.
 *
 * Usage:
 * ```cpp
 * // Create within the NativeMapView constructor
 * callbackManager_ = std::make_unique<CallbackManager>(env);
 * 
 * // Register a callback (UI thread)
 * callbackManager_->RegisterCallback("onMapLoaded", jsCallback);
 * 
 * // Invoke the callback (Map RunLoop thread)
 * callbackManager_->InvokeCallback("onMapLoaded", [](napi_env env) {
 *     napi_value result;
 *     napi_create_string_utf8(env, "Map loaded!", NAPI_AUTO_LENGTH, &result);
 *     return result;
 * });
 * 
 * // Unregister the callback
 * callbackManager_->UnregisterCallback("onMapLoaded");
 * 
 * // Clear all callbacks (during destruction)
 * callbackManager_->Clear();
 * ```
 */
class CallbackManager {
public:
    /**
     * Constructor.
     *
     * @param env N-API environment (UI thread)
     */
    explicit CallbackManager(napi_env env);
    
    ~CallbackManager();
    
    // Disable copy & move
    CallbackManager(const CallbackManager&) = delete;
    CallbackManager& operator=(const CallbackManager&) = delete;
    CallbackManager(CallbackManager&&) = delete;
    CallbackManager& operator=(CallbackManager&&) = delete;
    
    /**
     * Register a callback.
     *
     * @param name Callback name (unique identifier)
     * @param callback JavaScript callback function
     * @return True if registration succeeded
     *
     * Note: multiple listeners per name are supported.
     */
    bool RegisterCallback(const std::string& name, napi_value callback);
    
    /**
     * Unregister all callbacks under a name.
     *
     * @param name Callback name
     * @return True if callbacks were removed
     */
    bool UnregisterCallback(const std::string& name);
    
    /**
     * Unregister a specific callback.
     *
     * @param name Callback name
     * @param callback Callback to remove
     * @return True if the callback was removed
     */
    bool UnregisterCallback(const std::string& name, napi_value callback);
    
    /**
     * Invoke a callback from any thread.
     *
     * @param name Callback name
     * @param builder Data builder executed on the UI thread
     * @return True if dispatch succeeded
     */
    bool InvokeCallback(
        const std::string& name,
        ThreadSafeCallback::DataBuilder builder
    );
    
    /**
     * Convenience: invoke a callback without arguments.
     */
    bool InvokeCallbackEmpty(const std::string& name);
    
    /**
     * Convenience: invoke a callback with a string argument.
     */
    bool InvokeCallbackWithString(const std::string& name, const std::string& value);
    
    /**
     * Convenience: invoke a callback with an object argument.
     */
    bool InvokeCallbackWithObject(
        const std::string& name,
        const std::function<void(napi_env, napi_value)>& buildObject
    );
    
    /**
     * Check whether a callback exists.
     */
    bool HasCallback(const std::string& name) const;
    
    /**
     * Get the total number of registered callbacks across all names.
     */
    size_t GetCallbackCount() const;
    
    /**
     * Get the listener count for a specific name.
     */
    size_t GetCallbackCount(const std::string& name) const;
    
    /**
     * Clear all callbacks.
     *
     * Note: releases all ThreadSafeFunctions; callbacks cannot be invoked afterward.
     */
    void Clear();
    
private:
    napi_env env_;

    /**
     * CallbackEntry - bundles a ThreadSafeCallback with its napi_ref for identity comparison.
     *
     * The napi_ref enables correct per-listener removal in UnregisterCallback(name, callback).
     */
    // Note: napi_delete_reference for callbackRef must be called on the main thread
    // with a valid env. CallbackManager::Clear() handles this explicitly.
    struct CallbackEntry {
        // shared_ptr (not unique_ptr): InvokeCallback() collects entries under
        // the lock and calls them after unlocking — a concurrent
        // Unregister/Clear on the JS thread must not free a callback the
        // render thread is about to invoke.
        std::shared_ptr<ThreadSafeCallback> tsfn;
        napi_ref callbackRef = nullptr;  // persistent reference for identity comparison
    };

    // Thread-safe callback container supporting multiple listeners per event name
    std::unordered_map<std::string, std::vector<CallbackEntry>> callbacks_;

    // Mutex guarding the callback container
    mutable std::mutex mutex_;

    // Indicates whether callbacks have been cleared
    // (atomic: read without the lock on the invoke fast path)
    std::atomic<bool> cleared_{false};

    // Helper: compare a stored napi_ref with a live napi_value callback for equality
    bool AreCallbacksEqual(napi_ref storedRef, napi_value callback) const;
};

} // namespace harmony
} // namespace mbgl

