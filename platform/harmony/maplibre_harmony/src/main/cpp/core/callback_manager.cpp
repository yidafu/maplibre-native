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
        for (const auto& existing : it->second) {
            // Note: wrapped callbacks cannot be compared directly, so we allow duplicates
            // Callers must ensure they do not register the same callback repeatedly
        }
    }
    
    // Create ThreadSafeCallback
    auto tsfn = ThreadSafeCallback::Create(env_, callback, name.c_str());
    if (!tsfn) {
        Logger::error("CallbackManager", "Failed to create ThreadSafeCallback for '%s'", name.c_str());
        return false;
    }
    
    // Add to callback list
    callbacks_[name].push_back(std::move(tsfn));
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
        Logger::warn("CallbackManager", "Callback not found: %s", name.c_str());
        return false;
    }
    
    // Release all ThreadSafeCallbacks
    for (auto& tsfn : it->second) {
        tsfn->Release();
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
        Logger::warn("CallbackManager", "Callback not found: %s", name.c_str());
        return false;
    }
    
    // Because wrapped callbacks cannot be directly compared, simply remove the last one
    // Simplified logic assumes the caller manages callbacks in the correct order
    if (!it->second.empty()) {
        it->second.back()->Release();
        it->second.pop_back();
        
        // Remove the entry if no listeners remain
        if (it->second.empty()) {
            callbacks_.erase(it);
        }
        
        return true;
    }
    
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
        Logger::warn("CallbackManager", "Callback not found: %s", name.c_str());
        return false;
    }
    
    // Collect raw pointers to callbacks (avoid invoking while holding the lock)
    std::vector<ThreadSafeCallback*> callbackPtrs;
    callbackPtrs.reserve(it->second.size());
    for (const auto& cb : it->second) {
        callbackPtrs.push_back(cb.get());
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
        for (auto& callback : pair.second) {
            // Add per-callback timeout monitoring
            {
                ANRDetector releaseDetector("callback->Release", 50, 200);
                callback->Release();
            }
            releasedCount++;
        }
    }
    
    callbacks_.clear();
    cleared_ = true;
    
    Logger::info("CallbackManager", "All %zu callbacks cleared", releasedCount);
}

bool CallbackManager::AreCallbacksEqual(napi_value callback1, napi_value callback2) const {
    // N-API does not provide direct comparison for two napi_value handles
    // Use napi_strict_equals for comparison
    bool isEqual = false;
    napi_status status = napi_strict_equals(env_, callback1, callback2, &isEqual);
    return (status == napi_ok) && isEqual;
}

} // namespace harmony
} // namespace mbgl

