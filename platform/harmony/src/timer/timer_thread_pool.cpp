#include "timer_thread_pool.hpp"

#include <cassert>

#ifdef __OHOS__
using mbgl::harmony::Logger;
#endif

namespace mbgl {
namespace util {

TimerThreadPool::TimerThreadPool(size_t numThreads)
    : stop(false) {
    
    workers.reserve(numThreads);
    
    for (size_t i = 0; i < numThreads; ++i) {
        workers.emplace_back([this] {
            while (true) {
                std::function<void()> task;
                
                {
                    std::unique_lock<std::mutex> lock(queueMutex);
                    
                    condition.wait(lock, [this] {
                        return stop.load() || !tasks.empty();
                    });
                    
                    if (stop.load() && tasks.empty()) {
                        return;
                    }
                    
                    if (!tasks.empty()) {
                        task = std::move(tasks.front());
                        tasks.pop();
                    }
                }
                
                if (task) {
                    try {
                        task();
                    } catch (const std::exception& e) {
#ifdef __OHOS__
                        Logger::error("Timer", "Task threw exception: %s", e.what());
#endif
                    } catch (...) {
#ifdef __OHOS__
                        Logger::error("Timer", "Task threw unknown exception");
#endif
                    }
                }
            }
        });
    }
}

TimerThreadPool::~TimerThreadPool() {
    stop.store(true);
    condition.notify_all();
    
    for (auto& worker : workers) {
        if (worker.joinable()) {
            worker.join();
        }
    }
    
    if (!tasks.empty()) {
#ifdef __OHOS__
        Logger::warn("Timer", "%zu tasks remain unprocessed", tasks.size());
#endif
    }
}

void TimerThreadPool::submit(std::function<void()>&& task) {
    {
        std::lock_guard<std::mutex> lock(queueMutex);
        
        if (stop.load()) {
            return;
        }
        
        tasks.emplace(std::move(task));
    }
    
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

