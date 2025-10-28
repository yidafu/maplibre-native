#pragma once

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <mutex>
#include <atomic>

namespace mbgl {
namespace harmony {

/**
 * @brief 全局 EGL Display 管理器（单例模式）
 * 
 * 职责：
 * - 管理共享的 EGL Display（所有地图实例共用一个 Display）
 * - 线程安全的初始化和清理
 * - 引用计数管理（最后一个实例销毁时才清理 Display）
 * - 资源限制（防止创建过多实例导致系统资源耗尽）
 * 
 * 设计原理：
 * - EGL Display 代表与显示系统的连接，可以在多个 Context 之间共享
 * - 每个地图实例拥有独立的 EGLContext 和 EGLSurface，但共享同一个 EGLDisplay
 * - 这样既保证了实例独立性，又避免了多次初始化 Display 导致的冲突
 */
class EGLDisplayManager {
public:
    /**
     * @brief 获取单例实例
     */
    static EGLDisplayManager& getInstance();

    /**
     * @brief 获取共享的 EGL Display（如果未初始化则自动创建）
     * 增加引用计数，每个实例只应调用一次（在初始化时）
     * @return EGLDisplay 共享的 Display，失败返回 EGL_NO_DISPLAY
     */
    EGLDisplay acquireDisplay();

    /**
     * @brief 获取共享的 EGL Display（不增加引用计数）
     * 仅用于已经 acquire 过的实例内部使用
     * @return EGLDisplay 共享的 Display，如果未初始化返回 EGL_NO_DISPLAY
     */
    EGLDisplay getDisplay() const;

    /**
     * @brief 选择 EGL 配置
     * @param attribs 配置属性数组
     * @param config 输出的配置
     * @return true 成功，false 失败
     */
    bool chooseConfig(const EGLint* attribs, EGLConfig& config);

    /**
     * @brief 释放 Display 引用（减少引用计数）
     * 当引用计数降为 0 时，自动清理 EGL Display
     */
    void releaseDisplay();

    /**
     * @brief 获取当前活跃的实例数量
     */
    int getActiveInstanceCount() const { return activeInstanceCount_.load(); }

    /**
     * @brief 注册新实例（增加活跃计数）
     * @return true 成功，false 超过最大实例限制
     */
    bool registerInstance();

    /**
     * @brief 注销实例（减少活跃计数）
     */
    void unregisterInstance();

    /**
     * @brief 获取最大支持的并发实例数
     */
    static constexpr int getMaxConcurrentInstances() { return MAX_CONCURRENT_INSTANCES; }

    // 删除拷贝构造和赋值操作（单例模式）
    EGLDisplayManager(const EGLDisplayManager&) = delete;
    EGLDisplayManager& operator=(const EGLDisplayManager&) = delete;

private:
    EGLDisplayManager() = default;
    ~EGLDisplayManager();

    /**
     * @brief 初始化 EGL Display（内部使用，需持有锁）
     * @return true 成功，false 失败
     */
    bool initializeDisplay();

    /**
     * @brief 清理 EGL Display（内部使用，需持有锁）
     */
    void cleanupDisplay();

    // 最大并发地图实例数（根据 HarmonyOS 系统限制设置）
    static constexpr int MAX_CONCURRENT_INSTANCES = 4;

    // 线程安全保护
    std::mutex mutex_;

    // 共享的 EGL Display
    EGLDisplay sharedDisplay_ = EGL_NO_DISPLAY;

    // Display 初始化状态
    bool displayInitialized_ = false;

    // Display 引用计数（有多少个 Backend 实例在使用）
    int displayRefCount_ = 0;

    // 活跃的实例数量（用于资源限制）
    std::atomic<int> activeInstanceCount_{0};

    // EGL 版本信息
    EGLint majorVersion_ = 0;
    EGLint minorVersion_ = 0;
};

} // namespace harmony
} // namespace mbgl

