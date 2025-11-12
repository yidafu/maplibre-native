/**
 * HarmonyOS Timer Implementation - Thread Pool Version
 * 
 * Improvements:
 * - Use a thread pool instead of spawning a dedicated thread per timer.
 * - Reduce the overhead of thread creation and destruction.
 * - Reuse worker threads to lower overall resource usage.
 * 
 * Unchanged behavior:
 * - Preserve thread safety by invoking callbacks via RunLoop::invoke().
 * - Avoid the Harmony main-loop `uv_timer_t` limitations.
 * - Follow the guidance: "start your own thread and run libuv there."
 * 
 * Official documentation:
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/libuv-V5
 */

#include <mbgl/util/timer.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/run_loop.hpp>

#include "timer_thread_pool.hpp"

#include <cassert>
#include <chrono>
#include <thread>
#include <atomic>


namespace mbgl {
namespace util {

class Timer::Impl {
public:
    Impl() : running(false) {}

    ~Impl() {
        stop();
    }

    void start(Duration timeout, Duration repeatInterval, std::function<void()>&& cb) {
        if (running) {
            stop();
        }

        delay = timeout;
        this->repeat = repeatInterval;
        callback = std::move(cb);
        running = true;
        
        // Acquire the RunLoop to ensure callbacks execute on the correct thread.
        runLoop = RunLoop::Get();

        // Submit work to the thread pool instead of creating a dedicated thread.
        TimerThreadPool::instance().submit([this]() {
            bool hasFired = false;
            while (running) {
                std::this_thread::sleep_for(delay);

                if (running && callback && runLoop) {
                    auto repeatCount = this->repeat.count();
                    runLoop->invoke([this, repeatCount]() {
                        if (running && callback) {
                            callback();
                            
                            // Stop non-repeating timers after the callback executes.
                            if (repeatCount == 0) {
                                stop();
                            }
                        }
                    });
                    
                    hasFired = true;
                }

                // Handle repeat versus one-shot timers.
                if (running && this->repeat.count() > 0) {
                    delay = this->repeat;
                } else if (hasFired && this->repeat.count() == 0) {
                    // For one-shot timers, give the lambda time to finish.
                    delay = std::chrono::milliseconds(10);
                }
            }
        });
    }

    void stop() {
        running.exchange(false);
    }

private:
    std::atomic<bool> running;
    Duration delay;
    Duration repeat;
    std::function<void()> callback;
    RunLoop* runLoop = nullptr;
};

Timer::Timer() : impl(std::make_unique<Impl>()) {}

Timer::~Timer() = default;

void Timer::start(Duration timeout, Duration repeat, std::function<void()>&& callback) {
    impl->start(timeout, repeat, std::move(callback));
}

void Timer::stop() {
    impl->stop();
}

} // namespace util
} // namespace mbgl

