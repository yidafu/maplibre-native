#pragma once

#include <mbgl/util/noncopyable.hpp>

#include <atomic>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <queue>
#include <thread>
#include <vector>

#ifdef __OHOS__
#include <hilog/log.h>
#define POOL_LOG_DEBUG(...) OH_LOG_Print(LOG_APP, LOG_DEBUG, 0x0000, "TimerPool", __VA_ARGS__)
#define POOL_LOG_INFO(...) OH_LOG_Print(LOG_APP, LOG_INFO, 0x0000, "TimerPool", __VA_ARGS__)
#define POOL_LOG_ERROR(...) OH_LOG_Print(LOG_APP, LOG_ERROR, 0x0000, "TimerPool", __VA_ARGS__)
#else
#define POOL_LOG_DEBUG(...)
#define POOL_LOG_INFO(...)
#define POOL_LOG_ERROR(...)
#endif

namespace mbgl {
namespace util {

/**
 * TimerThreadPool - 专门用于 Timer 的轻量级线程池
 * 
 * 设计目标：
 * - 减少频繁创建/销毁线程的开销
 * - 复用工作线程执行多个 timer 任务
 * - 线程安全，支持从任意线程提交任务
 * 
 * 使用场景：
 * - Timer::Impl 提交睡眠+回调任务
 * - 多个 Timer 共享固定数量的工作线程
 * 
 * HarmonyOS 考虑：
 * - 符合官方建议："自己启动线程，并在上面使用 libuv 完成自己的业务"
 * - 不依赖主线程 loop，避免双 loop 限制
 * - 通过 RunLoop::invoke() 确保回调线程安全
 */
class TimerThreadPool : private util::noncopyable {
public:
    /**
     * 构造函数
     * 
     * @param numThreads 工作线程数量（默认 4）
     */
    explicit TimerThreadPool(size_t numThreads = 4);
    
    /**
     * 析构函数
     * 
     * 等待所有任务完成，然后关闭线程池
     */
    ~TimerThreadPool();
    
    /**
     * 提交任务到线程池
     * 
     * @param task 要执行的任务
     * 
     * 线程安全：可以从任意线程调用
     */
    void submit(std::function<void()>&& task);
    
    /**
     * 获取全局单例
     * 
     * 延迟初始化，第一次调用时创建
     */
    static TimerThreadPool& instance();
    
    /**
     * 获取当前待处理任务数量
     */
    size_t pendingTaskCount() const;
    
    /**
     * 获取工作线程数量
     */
    size_t threadCount() const { return workers.size(); }

private:
    // 工作线程
    std::vector<std::thread> workers;
    
    // 任务队列
    std::queue<std::function<void()>> tasks;
    
    // 同步原语
    mutable std::mutex queueMutex;
    std::condition_variable condition;
    
    // 停止标志
    std::atomic<bool> stop;
};

} // namespace util
} // namespace mbgl

