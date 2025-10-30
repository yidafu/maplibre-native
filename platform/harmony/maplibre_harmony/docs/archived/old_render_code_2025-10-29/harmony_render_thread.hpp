#pragma once

#include <atomic>
#include <condition_variable>
#include <deque>
#include <functional>
#include <mutex>
#include <thread>

namespace mbgl {
namespace harmony {

/**
 * HarmonyRenderThread - 简单的渲染线程实现
 * 
 * 参考 Android TextureViewRenderThread 架构：
 * - 纯 C++ 线程 + 条件变量（无 libuv RunLoop）
 * - 简单的任务队列用于跨线程通信
 * - 明确的渲染线程所有权
 * 
 * 关键特性：
 * - queueEvent(): 调度任务到渲染线程
 * - requestRender(): 请求执行渲染（通过回调）
 * - 线程安全的启动和停止
 */
class HarmonyRenderThread {
public:
    HarmonyRenderThread();
    ~HarmonyRenderThread();

    // 禁止拷贝和移动
    HarmonyRenderThread(const HarmonyRenderThread&) = delete;
    HarmonyRenderThread& operator=(const HarmonyRenderThread&) = delete;

    /**
     * 启动渲染线程
     * 必须在使用前调用
     */
    void start();

    /**
     * 停止渲染线程
     * 会等待所有待处理任务完成
     */
    void stop();

    /**
     * 调度任务到渲染线程执行
     * 类似 Android GLSurfaceView.queueEvent()
     * 
     * @param task 要执行的任务
     */
    void queueEvent(std::function<void()> task);

    /**
     * 设置渲染回调
     * 当 requestRender() 被调用时执行
     * 
     * @param callback 渲染回调函数
     */
    void setRenderCallback(std::function<void()> callback);

    /**
     * 请求执行渲染
     * 会调用 setRenderCallback 设置的回调
     * 可以从任何线程调用
     */
    void requestRender();

    /**
     * 等待任务队列为空
     * 用于同步销毁
     */
    void waitForEmpty();

    /**
     * 暂停渲染
     */
    void pause();

    /**
     * 恢复渲染
     */
    void resume();

    /**
     * 检查当前线程是否为渲染线程
     */
    bool isOnRenderThread() const;

    /**
     * 获取渲染线程 ID
     */
    std::thread::id getRenderThreadId() const;

private:
    /**
     * 渲染线程主循环
     */
    void renderLoop();

    /**
     * 处理任务队列中的事件
     * 在渲染线程执行
     */
    void processEvents();

    /**
     * 执行渲染（如果有请求）
     * 在渲染线程执行
     */
    void performRenderIfRequested();

    // 线程对象
    std::thread renderThread_;
    std::thread::id renderThreadId_;

    // 任务队列（替代 RunLoop）
    std::mutex queueMutex_;
    std::condition_variable queueCondition_;
    std::deque<std::function<void()>> eventQueue_;

    // 渲染回调
    std::mutex renderCallbackMutex_;
    std::function<void()> renderCallback_;

    // 控制标志
    std::atomic<bool> renderRequested_{false};
    std::atomic<bool> shouldExit_{false};
    std::atomic<bool> paused_{false};
    std::atomic<bool> started_{false};
};

} // namespace harmony
} // namespace mbgl



