#pragma once

#include <native_vsync/native_vsync.h>
#include <functional>
#include <atomic>
#include <mutex>

namespace mbgl {

namespace util {
class RunLoop;
}

namespace harmony {

/**
 * HarmonyOS VSync 管理器
 * 
 * 使用 HarmonyOS 原生 VSync API 实现系统级渲染同步，
 * 类似于 Android 的 Choreographer 和 iOS 的 CADisplayLink。
 * 
 * 参考文档：
 * - https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/native-vsync-guidelines
 * - https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-nativevsync
 */
class HarmonyVSyncManager {
public:
    using FrameCallback = std::function<void()>;
    // 归属渲染实例的标识（用于日志）
    void setOwnerInstanceId(uint64_t id) { ownerInstanceId_ = id; }
    
    /**
     * 设置渲染线程的 RunLoop（用于调度回调）
     * 
     * @param runLoop 渲染线程的 RunLoop 指针
     */
    void setRunLoop(util::RunLoop* runLoop);
    
    /**
     * 构造函数
     * 创建 OH_NativeVSync 实例并初始化
     */
    HarmonyVSyncManager();
    
    /**
     * 析构函数
     * 清理 VSync 资源
     */
    ~HarmonyVSyncManager();
    
    /**
     * 请求下一帧回调
     * 
     * 在下一个 VSync 信号到来时执行回调函数。
     * 如果已经有待处理的请求，会被忽略（防抖）。
     * 
     * @param callback 在 VSync 时执行的回调函数
     */
    void requestFrame(FrameCallback callback);
    
    /**
     * 停止 VSync 回调
     */
    void stop();
    
    /**
     * 检查 VSync 是否可用
     */
    bool isAvailable() const { return vsync_ != nullptr; }

private:
    OH_NativeVSync* vsync_ = nullptr;
    util::RunLoop* renderRunLoop_ = nullptr;  // 渲染线程的 RunLoop
    std::atomic<bool> frameRequested_{false};
    FrameCallback pendingCallback_;
    std::mutex callbackMutex_;
    std::atomic<bool> stopped_{false};
    uint64_t ownerInstanceId_{0};
    
    /**
     * VSync 回调函数
     * 
     * 由系统在 VSync 信号到来时调用
     * 
     * @param timestamp VSync 时间戳（纳秒）
     * @param data 用户数据指针（指向 HarmonyVSyncManager 实例）
     */
    static void onVSync(long long timestamp, void* data);
    
    /**
     * 执行待处理的回调
     */
    void executeCallback();
};

} // namespace harmony
} // namespace mbgl

