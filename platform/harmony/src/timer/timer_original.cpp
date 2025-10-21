#include <mbgl/util/timer.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/run_loop.hpp>

#include <cassert>
#include <chrono>
#include <thread>
#include <atomic>

#ifdef __OHOS__
#include <hilog/log.h>
#define TIMER_LOG(...) OH_LOG_Print(LOG_APP, LOG_DEBUG, 0x0000, "Timer", __VA_ARGS__)
#else
#define TIMER_LOG(...)
#endif

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
        
        // Get the RunLoop from the calling thread (where Timer was created)
        // This ensures callbacks are dispatched to the correct thread
        runLoop = RunLoop::Get();
        
        TIMER_LOG("Timer started: timeout=%lld ms, repeat=%lld ms, runLoop=%p", 
                 std::chrono::duration_cast<std::chrono::milliseconds>(timeout).count(),
                 std::chrono::duration_cast<std::chrono::milliseconds>(repeatInterval).count(),
                 runLoop);

        thread = std::thread([this]() {
            bool hasFired = false;
            while (running) {
                std::this_thread::sleep_for(delay);

                if (running && callback && runLoop) {
                    // CRITICAL FIX: Invoke callback via RunLoop to ensure it runs on the correct thread
                    // This prevents deadlocks from cross-thread Map access
                    // RACE CONDITION FIX: Capture repeat count to decide stop inside lambda
                    TIMER_LOG("Timer fired - dispatching callback to RunLoop thread");
                    TIMER_LOG("RunLoop address: %p, has callback: %d", runLoop, callback != nullptr);
                    
                    auto repeatCount = this->repeat.count();
                    runLoop->invoke([this, repeatCount]() {
                        TIMER_LOG("⭐ INSIDE INVOKE LAMBDA - about to execute timer callback");
                        if (running && callback) {
                            TIMER_LOG("✅ Executing timer callback on RunLoop thread");
                            callback();
                            TIMER_LOG("✅ Timer callback COMPLETED");
                            
                            // Stop timer AFTER callback execution (if non-repeating)
                            if (repeatCount == 0) {
                                TIMER_LOG("Non-repeating timer - stopping after callback");
                                stop();
                            }
                        } else {
                            TIMER_LOG("❌ Timer callback SKIPPED - running=%d, callback=%p", 
                                     running.load(), (void*)&callback);
                        }
                    });
                    TIMER_LOG("runLoop->invoke() returned");
                    
                    hasFired = true;
                }

                // CRITICAL FIX: Don't break for non-repeating timers!
                // Let the lambda execute and call stop(), which sets running=false.
                // Then the while(running) loop will naturally exit on the next iteration.
                // This prevents the race condition where we break before the lambda executes.
                
                if (running && this->repeat.count() > 0) {
                    // For repeating timers, update delay for next iteration
                    delay = this->repeat;
                } else if (hasFired && this->repeat.count() == 0) {
                    // For non-repeating timers that have already fired,
                    // sleep briefly to give lambda time to execute and call stop()
                    delay = std::chrono::milliseconds(10);
                }
            }
            TIMER_LOG("Timer thread exiting");
        });

        thread.detach();
    }

    void stop() {
        running = false;
        // Don't wait for thread to finish since we use detach
    }

private:
    std::atomic<bool> running;
    Duration delay;
    Duration repeat;
    std::function<void()> callback;
    std::thread thread;
    RunLoop* runLoop = nullptr;  // Store the RunLoop pointer
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