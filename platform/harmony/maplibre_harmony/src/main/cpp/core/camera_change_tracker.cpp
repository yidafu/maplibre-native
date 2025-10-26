#include "camera_change_tracker.hpp"
#include "logger.hpp"
#include <algorithm>

namespace maplibre {
namespace harmony {

CameraChangeTracker::CameraChangeTracker(napi_env env) : env_(env) {
    Logger::info("CameraChangeTracker", "Created");
}

CameraChangeTracker::~CameraChangeTracker() {
    Logger::info("CameraChangeTracker", "Destroying");
    clearAllListeners();
}

void CameraChangeTracker::addIdleListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    addListenerToVector(idle_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Added idle listener, total: %zu", idle_listeners_.size());
}

void CameraChangeTracker::removeIdleListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    removeListenerFromVector(idle_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Removed idle listener, remaining: %zu", idle_listeners_.size());
}

void CameraChangeTracker::addMoveStartedListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    addListenerToVector(move_started_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Added move started listener, total: %zu", move_started_listeners_.size());
}

void CameraChangeTracker::removeMoveStartedListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    removeListenerFromVector(move_started_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Removed move started listener, remaining: %zu", move_started_listeners_.size());
}

void CameraChangeTracker::addMoveListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    addListenerToVector(move_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Added move listener, total: %zu", move_listeners_.size());
}

void CameraChangeTracker::removeMoveListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    removeListenerFromVector(move_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Removed move listener, remaining: %zu", move_listeners_.size());
}

void CameraChangeTracker::addCanceledListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    addListenerToVector(canceled_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Added canceled listener, total: %zu", canceled_listeners_.size());
}

void CameraChangeTracker::removeCanceledListener(napi_value callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    removeListenerFromVector(canceled_listeners_, callback);
    Logger::debug("CameraChangeTracker", "Removed canceled listener, remaining: %zu", canceled_listeners_.size());
}

void CameraChangeTracker::notifyCameraMoveStarted(int reason) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 如果已经在移动中，不重复触发
    if (!is_idle_) {
        Logger::debug("CameraChangeTracker", "Camera already moving, skipping moveStarted");
        return;
    }
    
    is_idle_ = false;
    move_reason_ = reason;
    
    Logger::info("CameraChangeTracker", "Camera move started, reason: %d", reason);
    
    // 调用监听器
    napi_value reasonArg;
    napi_create_int32(env_, reason, &reasonArg);
    callListeners(move_started_listeners_, &reasonArg, 1);
}

void CameraChangeTracker::notifyCameraMove() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 只在移动中触发
    if (is_idle_) {
        return;
    }
    
    Logger::debug("CameraChangeTracker", "Camera moving");
    callListeners(move_listeners_);
}

void CameraChangeTracker::notifyCameraIdle() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 如果已经 idle，不重复触发
    if (is_idle_) {
        Logger::debug("CameraChangeTracker", "Camera already idle, skipping");
        return;
    }
    
    is_idle_ = true;
    Logger::info("CameraChangeTracker", "Camera idle");
    
    callListeners(idle_listeners_);
}

void CameraChangeTracker::notifyCameraMoveCanceled() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 只在移动中触发取消事件
    if (is_idle_) {
        return;
    }
    
    Logger::info("CameraChangeTracker", "Camera move canceled");
    callListeners(canceled_listeners_);
}

void CameraChangeTracker::clearAllListeners() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    Logger::info("CameraChangeTracker", "Clearing all listeners");
    
    clearListenerVector(idle_listeners_);
    clearListenerVector(move_started_listeners_);
    clearListenerVector(move_listeners_);
    clearListenerVector(canceled_listeners_);
}

// ========== 私有辅助方法 ==========

void CameraChangeTracker::addListenerToVector(std::vector<napi_ref>& vec, napi_value callback) {
    // 检查是否已存在（避免重复添加）
    for (const auto& ref : vec) {
        napi_value existing;
        napi_get_reference_value(env_, ref, &existing);
        if (areCallbacksEqual(existing, callback)) {
            Logger::debug("CameraChangeTracker", "Listener already exists, skipping");
            return;
        }
    }
    
    // 创建持久引用
    napi_ref ref;
    napi_status status = napi_create_reference(env_, callback, 1, &ref);
    if (status != napi_ok) {
        Logger::error("CameraChangeTracker", "Failed to create reference for callback");
        return;
    }
    
    vec.push_back(ref);
}

void CameraChangeTracker::removeListenerFromVector(std::vector<napi_ref>& vec, napi_value callback) {
    for (auto it = vec.begin(); it != vec.end(); ++it) {
        napi_value existing;
        napi_get_reference_value(env_, *it, &existing);
        
        if (areCallbacksEqual(existing, callback)) {
            napi_delete_reference(env_, *it);
            vec.erase(it);
            return;
        }
    }
    
    Logger::debug("CameraChangeTracker", "Listener not found for removal");
}

void CameraChangeTracker::callListeners(const std::vector<napi_ref>& listeners, napi_value* args, size_t argc) {
    if (listeners.empty()) {
        return;
    }
    
    napi_value global;
    napi_get_global(env_, &global);
    
    for (const auto& ref : listeners) {
        napi_value callback;
        napi_status status = napi_get_reference_value(env_, ref, &callback);
        if (status != napi_ok) {
            Logger::error("CameraChangeTracker", "Failed to get callback from reference");
            continue;
        }
        
        napi_value result;
        status = napi_call_function(env_, global, callback, argc, args, &result);
        if (status != napi_ok) {
            Logger::error("CameraChangeTracker", "Failed to call listener callback");
        }
    }
}

void CameraChangeTracker::clearListenerVector(std::vector<napi_ref>& vec) {
    for (auto& ref : vec) {
        napi_delete_reference(env_, ref);
    }
    vec.clear();
}

bool CameraChangeTracker::areCallbacksEqual(napi_value callback1, napi_value callback2) {
    bool is_equal = false;
    napi_strict_equals(env_, callback1, callback2, &is_equal);
    return is_equal;
}

} // namespace harmony
} // namespace maplibre

