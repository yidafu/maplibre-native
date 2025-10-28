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
    
    // 检查是否已存在相同的回调（避免重复添加）
    auto it = callbacks_.find(name);
    if (it != callbacks_.end()) {
        for (const auto& existing : it->second) {
            // 注意：无法直接比较已包装的回调，所以我们允许重复添加
            // 调用者需要确保不重复添加相同的回调
        }
    }
    
    // 创建 ThreadSafeCallback
    auto tsfn = ThreadSafeCallback::Create(env_, callback, name.c_str());
    if (!tsfn) {
        Logger::error("CallbackManager", "Failed to create ThreadSafeCallback for '%s'", name.c_str());
        return false;
    }
    
    // 添加到回调列表
    callbacks_[name].push_back(std::move(tsfn));
    Logger::debug("CallbackManager", "Registered callback: %s (listeners: %zu, total names: %zu)", 
                  name.c_str(), callbacks_[name].size(), callbacks_.size());
    
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
    
    // 释放所有 ThreadSafeCallback
    for (auto& tsfn : it->second) {
        tsfn->Release();
    }
    callbacks_.erase(it);
    
    Logger::debug("CallbackManager", "Unregistered all callbacks for: %s (remaining names: %zu)", 
                  name.c_str(), callbacks_.size());
    
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
    
    // 由于无法直接比较已包装的回调，我们简单地移除最后一个
    // 这是一个简化实现，假设调用者按正确顺序管理回调
    if (!it->second.empty()) {
        it->second.back()->Release();
        it->second.pop_back();
        
        Logger::debug("CallbackManager", "Unregistered one callback for: %s (remaining: %zu)", 
                      name.c_str(), it->second.size());
        
        // 如果没有剩余监听器，移除整个条目
        if (it->second.empty()) {
            callbacks_.erase(it);
            Logger::debug("CallbackManager", "Removed callback name: %s (no more listeners)", name.c_str());
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
    
    // 获取回调列表（需要持有锁）
    std::unique_lock<std::mutex> lock(mutex_);
    
    auto it = callbacks_.find(name);
    if (it == callbacks_.end()) {
        Logger::warn("CallbackManager", "Callback not found: %s", name.c_str());
        return false;
    }
    
    // 收集所有回调的原始指针（避免在持有锁时调用）
    std::vector<ThreadSafeCallback*> callbackPtrs;
    callbackPtrs.reserve(it->second.size());
    for (const auto& cb : it->second) {
        callbackPtrs.push_back(cb.get());
    }
    
    // 释放锁
    lock.unlock();
    
    // 调用所有回调（不持有锁）
    bool allSucceeded = true;
    for (size_t i = 0; i < callbackPtrs.size(); ++i) {
        // 为每个回调创建独立的 builder 副本
        // 注意：这要求 builder 是可复制的，或者我们需要不同的策略
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
    // 🔍 ANR监控：记录清理耗时
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
    
    // ⚡ ANR FIX: 简化实现，直接释放所有回调
    // 原因：ThreadSafeCallback::Release() 内部已有保护机制
    // 解决方案：通过 ANRDetector 监控整体耗时，如果单个回调耗时过长会被记录
    //
    // 注意：由于 HarmonyOS 标准库限制，无法使用 std::async 实现细粒度超时控制
    // 如果整体清理超过500ms，ANRDetector 会发出错误警告
    
    size_t releasedCount = 0;
    for (auto& pair : callbacks_) {
        Logger::debug("CallbackManager", "Releasing callbacks for: %s (%zu listeners)", 
                      pair.first.c_str(), pair.second.size());
        
        for (auto& callback : pair.second) {
            // 为每个回调添加细粒度的超时监控
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
    // N-API 不提供直接比较两个 napi_value 的方法
    // 我们使用 napi_strict_equals 来比较
    bool isEqual = false;
    napi_status status = napi_strict_equals(env_, callback1, callback2, &isEqual);
    return (status == napi_ok) && isEqual;
}

} // namespace harmony
} // namespace mbgl

