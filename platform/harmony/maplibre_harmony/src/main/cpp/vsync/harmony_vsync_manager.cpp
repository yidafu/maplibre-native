#include "harmony_vsync_manager.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

HarmonyVSyncManager::HarmonyVSyncManager() {
    Logger::info("HarmonyVSyncManager", "========== Constructor START ==========");
    
    try {
        // 创建 VSync 实例
        // 参数：name - VSync 实例名称，用于标识
        vsync_ = OH_NativeVSync_Create("MapLibreVSync", 0);
        
        if (!vsync_) {
            Logger::error("HarmonyVSyncManager", "Failed to create OH_NativeVSync instance");
            throw std::runtime_error("Failed to create OH_NativeVSync");
        }
        
        Logger::info("HarmonyVSyncManager", "VSync created successfully: %p", vsync_);
    } catch (const std::exception& e) {
        Logger::error("HarmonyVSyncManager", "Exception during construction: %s", e.what());
        throw;
    }
    
    Logger::info("HarmonyVSyncManager", "========== Constructor END ==========");
}

HarmonyVSyncManager::~HarmonyVSyncManager() {
    Logger::info("HarmonyVSyncManager", "========== Destructor START ==========");
    
    stop();
    
    if (vsync_) {
        Logger::debug("HarmonyVSyncManager", "Destroying VSync instance: %p", vsync_);
        OH_NativeVSync_Destroy(vsync_);
        vsync_ = nullptr;
        Logger::info("HarmonyVSyncManager", "VSync destroyed");
    }
    
    Logger::info("HarmonyVSyncManager", "========== Destructor END ==========");
}

void HarmonyVSyncManager::requestFrame(FrameCallback callback) {
    if (stopped_.load()) {
        Logger::warn("HarmonyVSyncManager", "requestFrame() - VSync已停止，忽略请求");
        return;
    }
    
    if (!vsync_) {
        Logger::error("HarmonyVSyncManager", "requestFrame() - VSync 未初始化");
        return;
    }
    
    // 防抖：如果已经有待处理的帧请求，忽略新请求
    bool expected = false;
    if (!frameRequested_.compare_exchange_strong(expected, true)) {
        Logger::debug("HarmonyVSyncManager", "requestFrame() - 已有待处理的帧请求，跳过（防抖）");
        return;
    }
    
    // 存储回调函数
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = std::move(callback);
    }
    
    // 请求下一帧 VSync 回调
    // 参数：
    // - vsync_: VSync 实例
    // - onVSync: 回调函数
    // - this: 用户数据（传递给回调）
    int ret = OH_NativeVSync_RequestFrame(vsync_, onVSync, this);
    
    if (ret != 0) {
        Logger::error("HarmonyVSyncManager", "OH_NativeVSync_RequestFrame failed: %d", ret);
        frameRequested_ = false;  // 重置标志
        return;
    }
    
    Logger::debug("HarmonyVSyncManager", "✅ VSync frame requested successfully");
}

void HarmonyVSyncManager::stop() {
    Logger::info("HarmonyVSyncManager", "stop() called");
    stopped_.store(true);
    
    // 清空待处理的回调
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = nullptr;
    }
    
    frameRequested_ = false;
}

void HarmonyVSyncManager::onVSync(long long timestamp, void* data) {
    auto* manager = static_cast<HarmonyVSyncManager*>(data);
    
    if (!manager || manager->stopped_.load()) {
        return;
    }
    
    Logger::debug("HarmonyVSyncManager", "⏰ VSync callback fired - timestamp=%lld ns", timestamp);
    
    // 重置帧请求标志
    manager->frameRequested_ = false;
    
    // 执行回调
    manager->executeCallback();
}

void HarmonyVSyncManager::executeCallback() {
    FrameCallback callback;
    
    // 获取并清空回调
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        callback = std::move(pendingCallback_);
        pendingCallback_ = nullptr;
    }
    
    // 执行回调
    if (callback) {
        try {
            Logger::debug("HarmonyVSyncManager", "🎬 Executing VSync callback");
            callback();
            Logger::debug("HarmonyVSyncManager", "✅ VSync callback completed");
        } catch (const std::exception& e) {
            Logger::error("HarmonyVSyncManager", "Exception in VSync callback: %s", e.what());
        }
    } else {
        Logger::warn("HarmonyVSyncManager", "No callback to execute");
    }
}

} // namespace harmony
} // namespace mbgl

