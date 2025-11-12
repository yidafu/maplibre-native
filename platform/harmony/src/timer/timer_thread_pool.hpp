#pragma once

#include <mbgl/util/noncopyable.hpp>

#include <atomic>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <queue>
#include <thread>
#include <vector>


namespace mbgl {
namespace util {

/**
 * TimerThreadPool - Lightweight thread pool dedicated to Timer tasks.
 *
 * Goals:
 * - Reduce the overhead of frequently creating and destroying threads.
 * - Reuse worker threads to execute multiple timer jobs.
 * - Maintain thread safety, allowing submissions from any thread.
 *
 * Usage scenarios:
 * - `Timer::Impl` submits sleep + callback work items.
 * - Multiple `Timer` instances share a fixed set of worker threads.
 *
 * HarmonyOS considerations:
 * - Follow the official guidance: "start your own thread and run libuv on it."
 * - Avoid reliance on the main-thread loop to prevent dual-loop constraints.
 * - Ensure callbacks remain thread-safe via `RunLoop::invoke()`.
 */
class TimerThreadPool : private util::noncopyable {
public:
    /**
     * Constructor.
     *
     * @param numThreads Number of worker threads (default: 4).
     */
    explicit TimerThreadPool(size_t numThreads = 4);
    
    /**
     * Destructor.
     *
     * Wait for all tasks to finish, then shut down the pool.
     */
    ~TimerThreadPool();
    
    /**
     * Submit a task to the pool.
     *
     * @param task The work item to execute.
     *
     * Thread-safe: may be called from any thread.
     */
    void submit(std::function<void()>&& task);
    
    /**
     * Get the global singleton instance.
     *
     * Lazily initialized on the first call.
     */
    static TimerThreadPool& instance();
    
    /**
     * Get the number of pending tasks.
     */
    size_t pendingTaskCount() const;
    
    /**
     * Get the number of worker threads.
     */
    size_t threadCount() const { return workers.size(); }

private:
    // Worker threads.
    std::vector<std::thread> workers;
    
    // Task queue.
    std::queue<std::function<void()>> tasks;
    
    // Synchronization primitives.
    mutable std::mutex queueMutex;
    std::condition_variable condition;
    
    // Shutdown flag.
    std::atomic<bool> stop;
};

} // namespace util
} // namespace mbgl

