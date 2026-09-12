#include "callback_manager.hpp"
#include "../utils/logger.h"
#include "../utils/anr_detector.hpp"
#include <algorithm>
#include <thread>
#include <atomic>
#include <condition_variable>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

CallbackManager::CallbackManager(napi_env env)
    : env_(env), cleared_(false) {
}

CallbackManager::~CallbackManager() {
    Clear();
}

bool CallbackManager::RegisterCallback(const std::string& name, napi_value callback) {
    if (cleared_) {
        Logger::warn("CallbackManager", "Cannot register callback '%s' - already cleared", name.c_str());
        return false;
    }
    
    if (name.empty()) {
        Logger::error("CallbackManager", "Cannot register callback with empty name");
        return false;
    }
    
    // Verify the callback is a valid function
    napi_valuetype valueType;
    napi_status status = napi_typeof(env_, callback, &valueType);
    if (status != napi_ok || valueType != napi_function) {
        Logger::error("CallbackManager", "Callback '%s' is not a function", name.c_str());
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);

    // Check whether the same callback already exists (avoid duplicates)
    auto it = callbacks_.find(name);
    if (it != callbacks_.end()) {
        for (const auto& entry : it->second) {
            if (entry.callbackRef && AreCallbacksEqual(entry.callbackRef, callback)) {
                Logger::warn("CallbackManager", "Duplicate callback registration ignored for: %s", name.c_str());
                return false;
            }
        }
    }

    // Create a persistent reference to the callback for identity comparison
    napi_ref callbackRef = nullptr;
    napi_status refStatus = napi_create_reference(env_, callback, 1, &callbackRef);
    if (refStatus != napi_ok || callbackRef == nullptr) {
        Logger::error("CallbackManager", "Failed to create napi_ref for callback '%s'", name.c_str());
        return false;
    }

    // Create ThreadSafeCallback
    auto tsfn = ThreadSafeCallback::Create(env_, callback, name.c_str());
    if (!tsfn) {
        Logger::error("CallbackManager", "Failed to create ThreadSafeCallback for '%s'", name.c_str());
        napi_delete_reference(env_, callbackRef);
        return false;
    }

    // Add to callback list
    callbacks_[name].push_back({std::move(tsfn), callbackRef});
    return true;
}

bool CallbackManager::UnregisterCallback(const std::string& name) {
    if (name.empty()) {
        Logger::error("CallbackManager", "Cannot unregister callback with empty name");
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = callbacks_.find(name);
    if (it == callbacks_.end()) {
        // Silent fast-path: per-frame events (camera moves, render frames) fire
        // whether or not anyone listens — logging here spams the hot path.
        return false;
    }
    
    // Release all ThreadSafeCallbacks and napi_refs
    for (auto& entry : it->second) {
        entry.tsfn->Release();
        if (entry.callbackRef) {
            napi_delete_reference(env_, entry.callbackRef);
        }
    }
    callbacks_.erase(it);
    
    return true;
}

bool CallbackManager::UnregisterCallback(const std::string& name, napi_value callback) {
    if (name.empty()) {
        Logger::error("CallbackManager", "Cannot unregister callback with empty name");
        return false;
    }

    std::lock_guard<std::mutex> lock(mutex_);

    auto it = callbacks_.find(name);
    if (it == callbacks_.end()) {
        Logger::warn("CallbackManager", "Callback '%s' has no registered listeners", name.c_str());
        return false;
    }

    // Find and remove the matching callback using napi_ref identity comparison
    auto& vec = it->second;
    for (auto entryIt = vec.begin(); entryIt != vec.end(); ++entryIt) {
        if (entryIt->callbackRef && AreCallbacksEqual(entryIt->callbackRef, callback)) {
            entryIt->tsfn->Release();
            napi_delete_reference(env_, entryIt->callbackRef);
            vec.erase(entryIt);

            // Remove the name entry if no listeners remain
            if (vec.empty()) {
                callbacks_.erase(it);
            }

            return true;
        }
    }

    Logger::warn("CallbackManager", "Callback not found for removal: %s", name.c_str());
    return false;
}

bool CallbackManager::InvokeCallback(
    const std::string& name,
    ThreadSafeCallback::DataBuilder builder
) {
    if (cleared_) {
        Logger::warn("CallbackManager", "Cannot invoke callback '%s' - already cleared", name.c_str());
        return false;
    }
    
    if (name.empty()) {
        Logger::error("CallbackManager", "Cannot invoke callback with empty name");
        return false;
    }
    
    // Obtain callback list (requires holding the lock)
    std::unique_lock<std::mutex> lock(mutex_);
    
    auto it = callbacks_.find(name);
    if (it == callbacks_.end()) {
        // Silent fast-path: per-frame events (camera moves, render frames) fire
        // whether or not anyone listens — logging here spams the hot path.
        return false;
    }
    
    // Collect shared_ptr copies (requires holding the lock) — a concurrent
    // Unregister/Clear on the JS thread may destroy map entries, so raw
    // pointers would dangle once the lock is released.
    std::vector<std::shared_ptr<ThreadSafeCallback>> callbackPtrs;
    callbackPtrs.reserve(it->second.size());
    for (const auto& entry : it->second) {
        callbackPtrs.push_back(entry.tsfn);
    }
    
    // Release the lock
    lock.unlock();
    
    // Invoke callbacks (lock already released)
    bool allSucceeded = true;
    for (size_t i = 0; i < callbackPtrs.size(); ++i) {
        // Create an independent builder copy for each callback
        // Note: requires the builder to be copyable, otherwise another strategy is needed
        if (!callbackPtrs[i]->Call(builder)) {
            Logger::error("CallbackManager", "Failed to invoke callback #%zu for: %s", i, name.c_str());
            allSucceeded = false;
        }
    }

    return allSucceeded;
}

bool CallbackManager::InvokeCallbackMulti(
    const std::string& name,
    ThreadSafeCallback::MultiArgBuilder builder
) {
    if (cleared_) {
        Logger::warn("CallbackManager", "Cannot invoke callback '%s' - already cleared", name.c_str());
        return false;
    }

    if (name.empty()) {
        Logger::error("CallbackManager", "Cannot invoke callback with empty name");
        return false;
    }

    // Obtain callback list (requires holding the lock)
    std::unique_lock<std::mutex> lock(mutex_);

    auto it = callbacks_.find(name);
    if (it == callbacks_.end()) {
        // Silent fast-path: per-frame events (camera moves, render frames) fire
        // whether or not anyone listens — logging here spams the hot path.
        return false;
    }

    // Collect shared_ptr copies (requires holding the lock) — a concurrent
    // Unregister/Clear on the JS thread may destroy map entries, so raw
    // pointers would dangle once the lock is released.
    std::vector<std::shared_ptr<ThreadSafeCallback>> callbackPtrs;
    callbackPtrs.reserve(it->second.size());
    for (const auto& entry : it->second) {
        callbackPtrs.push_back(entry.tsfn);
    }

    // Release the lock
    lock.unlock();

    // Invoke callbacks (lock already released)
    bool allSucceeded = true;
    for (size_t i = 0; i < callbackPtrs.size(); ++i) {
        // Create an independent builder copy for each callback
        // Note: requires the builder to be copyable, otherwise another strategy is needed
        if (!callbackPtrs[i]->CallMulti(builder)) {
            Logger::error("CallbackManager", "Failed to invoke callback #%zu for: %s", i, name.c_str());
            allSucceeded = false;
        }
    }

    return allSucceeded;
}

bool CallbackManager::InvokeCallbackEmpty(const std::string& name) {
    return InvokeCallback(name, [](napi_env env) -> napi_value {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    });
}

bool CallbackManager::InvokeCallbackWithString(const std::string& name, const std::string& value) {
    return InvokeCallback(name, [value](napi_env env) -> napi_value {
        napi_value result;
        napi_status status = napi_create_string_utf8(
            env,
            value.c_str(),
            value.length(),
            &result
        );
        
        if (status != napi_ok) {
            Logger::error("CallbackManager", "Failed to create string value");
            napi_get_undefined(env, &result);
        }
        
        return result;
    });
}

bool CallbackManager::InvokeCallbackWithObject(
    const std::string& name,
    const std::function<void(napi_env, napi_value)>& buildObject
) {
    return InvokeCallback(name, [buildObject](napi_env env) -> napi_value {
        napi_value obj;
        napi_status status = napi_create_object(env, &obj);
        
        if (status != napi_ok) {
            Logger::error("CallbackManager", "Failed to create object");
            napi_get_undefined(env, &obj);
            return obj;
        }
        
        buildObject(env, obj);
        return obj;
    });
}

bool CallbackManager::HasCallback(const std::string& name) const {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = callbacks_.find(name);
    return it != callbacks_.end() && !it->second.empty();
}

size_t CallbackManager::GetCallbackCount() const {
    std::lock_guard<std::mutex> lock(mutex_);
    size_t total = 0;
    for (const auto& pair : callbacks_) {
        total += pair.second.size();
    }
    return total;
}

size_t CallbackManager::GetCallbackCount(const std::string& name) const {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = callbacks_.find(name);
    if (it == callbacks_.end()) {
        return 0;
    }
    return it->second.size();
}

void CallbackManager::Clear() {
    // ANR monitoring: record cleanup duration
    ANRDetector detector("CallbackManager::Clear", 50, 500);
    
    if (cleared_) {
        return;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    size_t totalCallbacks = 0;
    for (const auto& pair : callbacks_) {
        totalCallbacks += pair.second.size();
    }
    
    Logger::info("CallbackManager", "Clearing %zu callback names with %zu total listeners", 
                 callbacks_.size(), totalCallbacks);
    
    // ANR fix: simplified approach, release all callbacks directly
    // Reason: ThreadSafeCallback::Release() already includes safeguards
    // Solution: monitor total duration with ANRDetector; excessively slow callbacks are logged
    //
    // Note: HarmonyOS standard library limitations prevent fine-grained timeouts via std::async
    // If cleanup exceeds 500 ms, ANRDetector emits an error warning
    
    size_t releasedCount = 0;
    for (auto& pair : callbacks_) {
        for (auto& entry : pair.second) {
            // Add per-callback timeout monitoring
            {
                ANRDetector releaseDetector("callback->Release", 50, 200);
                entry.tsfn->Release();
            }
            // Release the napi_ref used for identity comparison
            if (entry.callbackRef) {
                napi_delete_reference(env_, entry.callbackRef);
                entry.callbackRef = nullptr;
            }
            releasedCount++;
        }
    }
    
    callbacks_.clear();
    cleared_ = true;
    
    Logger::info("CallbackManager", "All %zu callbacks cleared", releasedCount);
}

bool CallbackManager::AreCallbacksEqual(napi_ref storedRef, napi_value callback) const {
    if (storedRef == nullptr || callback == nullptr) {
        return false;
    }

    // Get the napi_value from the stored persistent reference
    napi_value storedValue = nullptr;
    napi_status getStatus = napi_get_reference_value(env_, storedRef, &storedValue);
    if (getStatus != napi_ok || storedValue == nullptr) {
        return false;
    }

    // Compare using strict equality
    bool isEqual = false;
    napi_status status = napi_strict_equals(env_, storedValue, callback, &isEqual);
    return (status == napi_ok) && isEqual;
}

} // namespace harmony
} // namespace mbgl

