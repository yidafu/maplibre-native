#include "callback_manager.hpp"
#include "../utils/logger.h"
#include <algorithm>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

CallbackManager::CallbackManager(napi_env env)
    : env_(env), cleared_(false) {
    Logger::debug("CallbackManager", "Created");
}

CallbackManager::~CallbackManager() {
    Clear();
    Logger::debug("CallbackManager", "Destroyed");
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
    
    // 检查是否是有效的函数
    napi_valuetype valueType;
    napi_status status = napi_typeof(env_, callback, &valueType);
    if (status != napi_ok || valueType != napi_function) {
        Logger::error("CallbackManager", "Callback '%s' is not a function", name.c_str());
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 如果已存在同名回调，先注销
    auto it = callbacks_.find(name);
    if (it != callbacks_.end()) {
        Logger::warn("CallbackManager", "Replacing existing callback: %s", name.c_str());
        it->second->Release();
        callbacks_.erase(it);
    }
    
    // 创建 ThreadSafeCallback
    auto tsfn = ThreadSafeCallback::Create(env_, callback, name.c_str());
    if (!tsfn) {
        Logger::error("CallbackManager", "Failed to create ThreadSafeCallback for '%s'", name.c_str());
        return false;
    }
    
    callbacks_[name] = std::move(tsfn);
    Logger::debug("CallbackManager", "Registered callback: %s (total: %zu)", name.c_str(), callbacks_.size());
    
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
    
    // 释放 ThreadSafeCallback
    it->second->Release();
    callbacks_.erase(it);
    
    Logger::debug("CallbackManager", "Unregistered callback: %s (remaining: %zu)", name.c_str(), callbacks_.size());
    
    return true;
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
    
    // 获取回调（需要持有锁）
    std::unique_lock<std::mutex> lock(mutex_);
    
    auto it = callbacks_.find(name);
    if (it == callbacks_.end()) {
        Logger::warn("CallbackManager", "Callback not found: %s", name.c_str());
        return false;
    }
    
    // 获取回调的原始指针（避免在持有锁时调用）
    auto* callback = it->second.get();
    
    // 释放锁
    lock.unlock();
    
    // 调用回调（不持有锁）
    if (!callback->Call(std::move(builder))) {
        Logger::error("CallbackManager", "Failed to invoke callback: %s", name.c_str());
        return false;
    }
    
    return true;
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
    return callbacks_.find(name) != callbacks_.end();
}

size_t CallbackManager::GetCallbackCount() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return callbacks_.size();
}

void CallbackManager::Clear() {
    if (cleared_) {
        return;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    Logger::info("CallbackManager", "Clearing %zu callbacks", callbacks_.size());
    
    // 释放所有回调
    for (auto& pair : callbacks_) {
        Logger::debug("CallbackManager", "Releasing callback: %s", pair.first.c_str());
        pair.second->Release();
    }
    
    callbacks_.clear();
    cleared_ = true;
    
    Logger::info("CallbackManager", "All callbacks cleared");
}

} // namespace harmony
} // namespace mbgl

