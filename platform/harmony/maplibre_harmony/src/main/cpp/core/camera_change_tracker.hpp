#pragma once

#include <napi/native_api.h>
#include <vector>
#include <mutex>
#include <memory>
#include <string>

namespace maplibre {
namespace harmony {

/**
 * CameraChangeTracker - 相机变化追踪器
 * 
 * 管理相机事件监听器并分发事件到 ArkTS 层
 * 参考 Android 的 CameraChangeDispatcher 设计
 */
class CameraChangeTracker {
public:
    // 相机移动原因（与 CameraMoveReason.ets 对应）
    enum CameraMoveReason {
        REASON_UNKNOWN = 0,
        REASON_GESTURE = 1,
        REASON_API_ANIMATION = 2,
        REASON_DEVELOPER_ANIMATION = 3,
        REASON_ANIMATION_CANCELLED = 4
    };

    explicit CameraChangeTracker(napi_env env);
    ~CameraChangeTracker();

    // 禁用拷贝
    CameraChangeTracker(const CameraChangeTracker&) = delete;
    CameraChangeTracker& operator=(const CameraChangeTracker&) = delete;

    // 监听器管理
    void addIdleListener(napi_value callback);
    void removeIdleListener(napi_value callback);
    void addMoveStartedListener(napi_value callback);
    void removeMoveStartedListener(napi_value callback);
    void addMoveListener(napi_value callback);
    void removeMoveListener(napi_value callback);
    void addCanceledListener(napi_value callback);
    void removeCanceledListener(napi_value callback);

    // 事件触发
    void notifyCameraMoveStarted(int reason);
    void notifyCameraMove();
    void notifyCameraIdle();
    void notifyCameraMoveCanceled();

    // 清理所有监听器
    void clearAllListeners();

private:
    napi_env env_;
    std::mutex mutex_;

    // 监听器列表（使用 vector 存储 napi_threadsafe_function，实现线程安全）
    std::vector<napi_threadsafe_function> idle_listeners_;
    std::vector<napi_threadsafe_function> move_started_listeners_;
    std::vector<napi_threadsafe_function> move_listeners_;
    std::vector<napi_threadsafe_function> canceled_listeners_;

    // 状态追踪
    bool is_idle_ = true;
    int move_reason_ = REASON_UNKNOWN;

    // 辅助方法
    void addListenerToVector(std::vector<napi_threadsafe_function>& vec, napi_value callback, const char* resource_name);
    void removeListenerFromVector(std::vector<napi_threadsafe_function>& vec, napi_value callback);
    void clearListenerVector(std::vector<napi_threadsafe_function>& vec);
    bool areCallbacksEqual(napi_env env, napi_value callback1, napi_threadsafe_function tsfn);
};

} // namespace harmony
} // namespace maplibre

