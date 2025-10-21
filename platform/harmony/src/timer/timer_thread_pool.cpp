#include "timer_thread_pool.hpp"

#include <cassert>

namespace mbgl {
namespace util {

TimerThreadPool::TimerThreadPool(size_t numThreads)
    : stop(false) {
    
    POOL_LOG_INFO("========== TimerThreadPool Constructor START ==========");
    POOL_LOG_INFO("Creating pool with %{public}zu threads", numThreads);
    
    workers.reserve(numThreads);
    
    for (size_t i = 0; i < numThreads; ++i) {
        workers.emplace_back([this, threadId = i] {
            // threadId used in logging (POOL_LOG_* macros)
            (void)threadId;  // Suppress unused warning on non-OHOS platforms
            
            POOL_LOG_DEBUG("Worker thread %{public}zu started", threadId);
            
            while (true) {
                std::function<void()> task;
                
                {
                    std::unique_lock<std::mutex> lock(queueMutex);
                    
                    // 等待任务或停止信号
                    condition.wait(lock, [this] {
                        return stop.load() || !tasks.empty();
                    });
                    
                    // 停止且无任务，退出
                    if (stop.load() && tasks.empty()) {
                        POOL_LOG_DEBUG("Worker thread %{public}zu exiting (stop signal)", threadId);
                        return;
                    }
                    
                    // 取出任务
                    if (!tasks.empty()) {
                        task = std::move(tasks.front());
                        tasks.pop();
                        POOL_LOG_DEBUG("Worker thread %{public}zu: task dequeued, remaining=%{public}zu", 
                                      threadId, tasks.size());
                    }
                }
                
                // 执行任务（锁外）
                if (task) {
                    POOL_LOG_DEBUG("Worker thread %{public}zu: executing task", threadId);
                    try {
                        task();
                        POOL_LOG_DEBUG("Worker thread %{public}zu: task completed", threadId);
                    } catch (const std::exception& e) {
                        POOL_LOG_ERROR("Worker thread %{public}zu: task threw exception: %{public}s", 
                                      threadId, e.what());
                    } catch (...) {
                        POOL_LOG_ERROR("Worker thread %{public}zu: task threw unknown exception", threadId);
                    }
                }
            }
        });
    }
    
    POOL_LOG_INFO("TimerThreadPool created with %{public}zu threads", workers.size());
    POOL_LOG_INFO("========== TimerThreadPool Constructor COMPLETE ==========");
}

TimerThreadPool::~TimerThreadPool() {
    POOL_LOG_INFO("========== TimerThreadPool Destructor START ==========");
    
    // 设置停止标志
    stop.store(true);
    POOL_LOG_DEBUG("Stop flag set");
    
    // 唤醒所有工作线程
    condition.notify_all();
    POOL_LOG_DEBUG("All workers notified");
    
    // 等待所有线程完成
    for (size_t i = 0; i < workers.size(); ++i) {
        if (workers[i].joinable()) {
            POOL_LOG_DEBUG("Joining worker thread %{public}zu", i);
            workers[i].join();
            POOL_LOG_DEBUG("Worker thread %{public}zu joined", i);
        }
    }
    
    // 检查是否有未完成的任务
    if (!tasks.empty()) {
        POOL_LOG_ERROR("Destructor: %{public}zu tasks remain unprocessed", tasks.size());
    }
    
    POOL_LOG_INFO("========== TimerThreadPool Destructor COMPLETE ==========");
}

void TimerThreadPool::submit(std::function<void()>&& task) {
    {
        std::lock_guard<std::mutex> lock(queueMutex);
        
        if (stop.load()) {
            POOL_LOG_ERROR("Cannot submit task: pool is stopped");
            return;
        }
        
        tasks.emplace(std::move(task));
        POOL_LOG_DEBUG("Task submitted, queue size=%{public}zu", tasks.size());
    }
    
    // 唤醒一个工作线程
    condition.notify_one();
}

TimerThreadPool& TimerThreadPool::instance() {
    // 单例，延迟初始化，线程安全（C++11）
    static TimerThreadPool pool(4);  // 4 个工作线程
    return pool;
}

size_t TimerThreadPool::pendingTaskCount() const {
    std::lock_guard<std::mutex> lock(queueMutex);
    return tasks.size();
}

} // namespace util
} // namespace mbgl

