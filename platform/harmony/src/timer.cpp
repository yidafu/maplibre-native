/**
 * HarmonyOS Timer Implementation - Runnable-based
 * 
 * Refactored to use the unified Runnable interface for consistent scheduling
 * with AsyncTask. This follows the Android platform pattern.
 * 
 * Key Changes:
 * - Timer::Impl now inherits RunLoop::Impl::Runnable
 * - Uses addRunnable/removeRunnable for registration
 * - No separate thread needed - uses RunLoop's event loop
 * - Executed via processRunnables() based on dueTime
 * 
 * Benefits:
 * - Unified scheduling mechanism with AsyncTask
 * - Time-based priority ordering
 * - Reduced thread overhead (no thread per timer)
 * - Thread-safe task management
 * 
 * References:
 * - Android platform: platform/android/src/timer.cpp
 */

#include <mbgl/util/timer.hpp>
#include <mbgl/util/run_loop.hpp>

#include "../maplibre_harmony/src/main/cpp/utils/logger.h"
#include "run_loop_impl.hpp"

#include <cassert>

using mbgl::harmony::Logger;

namespace mbgl {
namespace util {

/**
 * Timer::Impl - Runnable-based implementation
 * 
 * Similar to Android's implementation, this class:
 * 1. Inherits RunLoop::Impl::Runnable for unified scheduling
 * 2. Maintains due time for proper ordering
 * 3. Supports both one-shot and repeating timers
 * 4. Registers/unregisters with RunLoop's runnable queue
 */
class Timer::Impl : public RunLoop::Impl::Runnable {
public:
    Impl()
        : active(false) {}

    ~Impl() override {
        stop();
    }

    /**
     * Start the timer
     * 
     * @param timeout Initial delay before first execution
     * @param repeat Interval for repeating execution (zero for one-shot)
     * @param task_ The callback to execute
     */
    void start(Duration timeout, Duration repeat_, std::function<void()>&& task_) {
        // Stop any existing timer
        stop();

        repeat = repeat_;
        task = std::move(task_);
        
        // Calculate due time
        // Prevent overflows when timeout is Duration::max()
        due = (timeout == Duration::max()) ? 
              TimePoint::max() : 
              Clock::now() + timeout;

        // Get the RunLoop::Impl to access addRunnable
        loopImpl = reinterpret_cast<RunLoop::Impl*>(RunLoop::getLoopHandle());
        if (!loopImpl) {
            Logger::error("Timer", "Failed to get RunLoop::Impl");
            return;
        }

        // Register with the runnable queue
        loopImpl->addRunnable(this);
        active = true;
    }

    /**
     * Stop the timer
     * 
     * Removes from the runnable queue and cancels execution.
     */
    void stop() {
        if (!active) {
            return;
        }

        active = false;
        
        if (loopImpl) {
            loopImpl->removeRunnable(this);
        }
    }

    /**
     * Get the due time for this timer (Runnable interface)
     * 
     * @return TimePoint when this timer should fire
     */
    TimePoint dueTime() const override {
        return due;
    }

    /**
     * Execute the timer callback (Runnable interface)
     * 
     * This is called by processRunnables() on the RunLoop thread
     * when the due time has passed.
     */
    void runTask() override {
        if (!active) {
            Logger::debug("Timer", "runTask called but timer is not active, skipping");
            return;
        }

        Logger::debug("Timer", "Timer firing, repeat=%lld ms", 
                     std::chrono::duration_cast<std::chrono::milliseconds>(repeat).count());

        // Execute the callback
        if (task) {
            try {
                task();
            } catch (const std::exception& e) {
                Logger::error("Timer", "Timer callback threw exception: %s", e.what());
            } catch (...) {
                Logger::error("Timer", "Timer callback threw unknown exception");
            }
        }

        // Handle repeating vs one-shot timer
        if (repeat != Duration::zero()) {
            // Repeating timer: update due time for next interval
            // No need to call wake() - processRunnables will check next due time
            due = Clock::now() + repeat;
            Logger::debug("Timer", "Timer rescheduled, next due in %lld ms",
                         std::chrono::duration_cast<std::chrono::milliseconds>(repeat).count());
        } else {
            // One-shot timer: stop after execution
            Logger::debug("Timer", "One-shot timer completed, stopping");
            stop();
        }
    }

private:
    // Whether the timer is active
    bool active;
    
    // Time when the timer should fire
    TimePoint due;
    
    // Repeat interval (zero for one-shot timers)
    Duration repeat;
    
    // The callback to execute
    std::function<void()> task;
    
    // Pointer to RunLoop::Impl for accessing runnable queue
    RunLoop::Impl* loopImpl = nullptr;
};

Timer::Timer()
    : impl(std::make_unique<Impl>()) {}

Timer::~Timer() = default;

void Timer::start(Duration timeout, Duration repeat, std::function<void()>&& callback) {
    impl->start(timeout, repeat, std::move(callback));
}

void Timer::stop() {
    impl->stop();
}

} // namespace util
} // namespace mbgl

