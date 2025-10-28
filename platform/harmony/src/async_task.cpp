/**
 * HarmonyOS AsyncTask Implementation - Runnable-based
 * 
 * Refactored to use the unified Runnable interface for consistent scheduling
 * with Timer and other async tasks. This follows the Android platform pattern.
 * 
 * Key Changes:
 * - AsyncTask::Impl now inherits RunLoop::Impl::Runnable
 * - Uses addRunnable/removeRunnable for registration
 * - Executed via processRunnables() in the main event loop
 * 
 * Benefits:
 * - Unified scheduling mechanism with Timer
 * - Predictable execution order based on dueTime
 * - Thread-safe task management
 * 
 * References:
 * - Android platform: platform/android/src/async_task.cpp
 * - HarmonyOS libuv API: https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/libuv-V5
 */

#include <mbgl/util/async_task.hpp>
#include <mbgl/util/run_loop.hpp>

#include "../maplibre_harmony/src/main/cpp/utils/logger.h"
#include "run_loop_impl.hpp"

#include <atomic>
#include <functional>
#include <memory>
#include <stdexcept>

using mbgl::harmony::Logger;

namespace mbgl {
namespace util {

/**
 * AsyncTask::Impl - Runnable-based implementation
 * 
 * Similar to Android's implementation, this class:
 * 1. Inherits RunLoop::Impl::Runnable for unified scheduling
 * 2. Uses atomic flag for coalescing (prevent duplicate scheduling)
 * 3. Registers/unregisters with RunLoop's runnable queue
 */
class AsyncTask::Impl : public RunLoop::Impl::Runnable {
public:
    /**
     * Constructor
     * 
     * @param fn The function to execute on the RunLoop thread
     * @throws std::runtime_error if no RunLoop exists
     */
    explicit Impl(std::function<void()>&& fn)
        : task(std::move(fn)),
          queued(true) {
        
        // Get the current RunLoop implementation
        auto* runLoop = RunLoop::Get();
        if (!runLoop) {
            Logger::error("AsyncTask", "No RunLoop on current thread");
            throw std::runtime_error("AsyncTask requires an active RunLoop on the current thread");
        }
        
        // Get the RunLoop::Impl to access addRunnable/removeRunnable
        loopImpl = reinterpret_cast<RunLoop::Impl*>(RunLoop::getLoopHandle());
        if (!loopImpl) {
            Logger::error("AsyncTask", "Failed to get RunLoop::Impl");
            throw std::runtime_error("Failed to get RunLoop::Impl");
        }
    }

    /**
     * Destructor
     * 
     * Ensures the task is removed from the runnable queue.
     */
    ~Impl() override {
        // Mark as queued to prevent re-adding
        queued = true;
        
        // Remove from the runnable queue
        if (loopImpl) {
            loopImpl->removeRunnable(this);
        }
    }

    /**
     * Send notification to schedule this task
     * 
     * Thread-safe: Can be called from any thread.
     * Uses atomic flag to prevent duplicate scheduling (coalescing).
     */
    void send() {
        // Only add to queue if not already queued
        // This provides the same coalescing behavior as uv_async_send
        bool wasQueued = queued.exchange(false);
        
        Logger::debug("AsyncTask", "send() called, wasQueued=%d", wasQueued);
        
        if (wasQueued && loopImpl) {
            loopImpl->addRunnable(this);
        }
    }

    /**
     * Get the due time for this task (Runnable interface)
     * 
     * AsyncTask should run immediately, so we return a time in the past.
     * This ensures it's always ready when checked.
     */
    TimePoint dueTime() const override {
        return due;
    }

    /**
     * Execute the task (Runnable interface)
     * 
     * This is called by processRunnables() on the RunLoop thread.
     * We reset the queued flag to allow future send() calls to re-add this task.
     * The task is NOT removed from the runnable queue here - it's managed by
     * the destructor to avoid concurrent modification issues.
     */
    void runTask() override {
        Logger::debug("AsyncTask", "runTask called, queued=%d", queued.load());
        
        // Reset the queued flag to allow re-queueing
        // Only execute if we were actually queued (not already reset)
        bool wasQueued = !queued.exchange(true);
        
        if (wasQueued && task) {
            Logger::info("AsyncTask", "Executing AsyncTask");
            
            try {
                task();
            } catch (const std::exception& e) {
                Logger::error("AsyncTask", "Task threw exception: %s", e.what());
            } catch (...) {
                Logger::error("AsyncTask", "Task threw unknown exception");
            }
        } else {
            Logger::debug("AsyncTask", "Task already executed or queued=%d, skipping", queued.load());
        }
    }

private:
    // Always expired (in the past), so this task runs immediately when checked
    const TimePoint due = Clock::now();
    
    // The task to execute on the RunLoop thread
    std::function<void()> task;
    
    // Atomic flag for coalescing: true = ready to be added, false = already in queue
    // This mimics the behavior of uv_async_send coalescing
    std::atomic<bool> queued;
    
    // Pointer to RunLoop::Impl for accessing runnable queue
    RunLoop::Impl* loopImpl = nullptr;
};

AsyncTask::AsyncTask(std::function<void()>&& fn)
    : impl(std::make_unique<Impl>(std::move(fn))) {
}

AsyncTask::~AsyncTask() = default;

void AsyncTask::send() {
    if (impl) {
        impl->send();
    }
}

} // namespace util
} // namespace mbgl
