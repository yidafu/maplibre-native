#include "harmony_vsync_manager.hpp"
#include "utils/logger.h"
#include <mbgl/util/run_loop.hpp>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

HarmonyVSyncManager::HarmonyVSyncManager() {
    Logger::info("HarmonyVSyncManager", "========== Constructor START (ownerInstanceId=%llu) ==========",
                 static_cast<unsigned long long>(ownerInstanceId_));
    
    try {
        // 创建 VSync 实例
        // 参数：name - VSync 实例名称，用于标识
        vsync_ = OH_NativeVSync_Create("MapLibreVSync", 0);
        
        if (!vsync_) {
            Logger::error("HarmonyVSyncManager", "Failed to create OH_NativeVSync instance");
            throw std::runtime_error("Failed to create OH_NativeVSync");
        }
        
        Logger::info("HarmonyVSyncManager", "VSync created successfully: %p (ownerInstanceId=%llu)",
                     vsync_, static_cast<unsigned long long>(ownerInstanceId_));
    } catch (const std::exception& e) {
        Logger::error("HarmonyVSyncManager", "Exception during construction: %s", e.what());
        throw;
    }
    
    Logger::info("HarmonyVSyncManager", "========== Constructor END ==========");
}

HarmonyVSyncManager::~HarmonyVSyncManager() {
    Logger::info("HarmonyVSyncManager", "========== Destructor START (ownerInstanceId=%llu) ==========",
                 static_cast<unsigned long long>(ownerInstanceId_));
    
    stop();
    
    if (vsync_) {
        Logger::debug("HarmonyVSyncManager", "Destroying VSync instance: %p", vsync_);
        OH_NativeVSync_Destroy(vsync_);
        vsync_ = nullptr;
        Logger::info("HarmonyVSyncManager", "VSync destroyed");
    }
    
    Logger::info("HarmonyVSyncManager", "========== Destructor END ==========");
}

void HarmonyVSyncManager::setRunLoop(util::RunLoop* runLoop) {
    std::lock_guard<std::mutex> lock(callbackMutex_);
    renderRunLoop_ = runLoop;
    Logger::info("HarmonyVSyncManager", "✅ RunLoop set: %p - VSync will invoke callbacks on RunLoop", runLoop);
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
    
    // ✅ 检查 RunLoop 是否已设置（防止在初始化完成前请求帧）
    // 注意：快速检查，无需锁（在存储回调时会再次检查）
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        if (!renderRunLoop_) {
            Logger::warn("HarmonyVSyncManager", 
                "⚠️  requestFrame() - RunLoop 未设置，忽略请求（防止线程安全问题）");
            return;
        }
        
        // 防抖：如果已经有待处理的回调，忽略新请求
        if (pendingCallback_) {
            Logger::debug("HarmonyVSyncManager", "requestFrame() - 已有待处理的回调，忽略新请求");
            return;
        }
        
        // 存储回调函数
        pendingCallback_ = std::move(callback);
    }
    
    // 防抖：如果已经有待处理的帧请求，忽略新请求
    bool expected = false;
    if (!frameRequested_.compare_exchange_strong(expected, true)) {
        // 已有帧请求，清空刚存储的回调
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = nullptr;
        return;
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
        
        // 清空回调
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = nullptr;
        return;
    }
}

void HarmonyVSyncManager::stop() {
    Logger::info("HarmonyVSyncManager", "stop() called");
    
    // ✅ 先设置停止标志，阻止新的请求
    stopped_.store(true);
    
    // ✅ 清空待处理的回调和 RunLoop 引用（线程安全）
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = nullptr;
        renderRunLoop_ = nullptr;  // 清空 RunLoop 引用，防止悬空指针
    }
    
    frameRequested_ = false;
    
    Logger::info("HarmonyVSyncManager", "✅ VSync stopped and RunLoop reference cleared");
}

void HarmonyVSyncManager::onVSync(long long timestamp, void* data) {
    auto* manager = static_cast<HarmonyVSyncManager*>(data);
    
    if (!manager || manager->stopped_.load()) {
        return;
    }
    
    // 重置帧请求标志
    manager->frameRequested_ = false;
    
    // 执行回调
    manager->executeCallback();
}

void HarmonyVSyncManager::executeCallback() {
    // 🎯 通过 RunLoop 调度回调到渲染线程
    // 确保回调在正确的渲染线程执行，与其他 Actor 消息统一调度
    
    // ✅ 双重检查：stopped 和 RunLoop 有效性
    if (stopped_.load()) {
        Logger::debug("HarmonyVSyncManager", "VSync stopped, skipping callback");
        return;
    }
    
    FrameCallback callback;
    util::RunLoop* runLoop = nullptr;
    
    // ✅ 在互斥锁保护下获取回调和 RunLoop 引用
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        callback = std::move(pendingCallback_);
        pendingCallback_ = nullptr;
        runLoop = renderRunLoop_;  // 获取 RunLoop 的副本（指针）
    }
    
    if (!callback) {
        Logger::warn("HarmonyVSyncManager", "No callback to execute");
        return;
    }
    
    // ✅ 检查 RunLoop 有效性（防止访问已销毁的 RunLoop）
    if (!runLoop) {
        Logger::warn("HarmonyVSyncManager", 
            "⚠️  RunLoop not set, skipping VSync callback (would cause thread safety violation)");
        return;
    }
    
    if (stopped_.load()) {
        Logger::debug("HarmonyVSyncManager", "VSync stopped during callback, skipping");
        return;
    }
    
    // 🎯 通过 RunLoop 调度到渲染线程（确保线程安全）
    // 注意：这里使用局部变量 runLoop，避免在 lambda 中访问成员变量
    runLoop->invoke([callback]() {
        try {
            callback();
        } catch (const std::exception& e) {
            Logger::error("HarmonyVSyncManager", "Exception in VSync callback: %s", e.what());
        }
    });
}

} // namespace harmony
} // namespace mbgl

