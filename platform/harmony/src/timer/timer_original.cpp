#include <mln/util/timer.hpp>
#include <mln/util/logging.hpp>
#include <mln/util/run_loop.hpp>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <functional>
#include <memory>
#include <mutex>
#include <thread>

namespace mln {
namespace util {

// Timer driven by a joinable worker thread with an interruptible wait.
//
// The previous implementation detached its thread: after the owning map was
// torn down, that thread could wake up and call RunLoop::invoke() through a
// raw RunLoop pointer that was already freed (SIGSEGV in pthread_mutex_lock
// on the OnlineFileSource thread). Two invariants close that hole here:
//
// 1. The worker is never detached. stop() joins it, and ~Impl runs stop(),
//    so the worker cannot outlive the Timer and touch freed members.
// 2. RunLoop callbacks capture a weak lifetime token instead of relying on
//    `this` alone. A queued-but-unexecuted callback becomes a no-op once the
//    Timer is gone; while the Timer is alive it cannot be destroyed
//    concurrently with its own callback, because both destruction and
//    callback execution happen on the Timer's RunLoop thread.
//
// The wait is a condition-variable wait_for, so joining on teardown happens
// immediately instead of after the remaining sleep.

class Timer::Impl {
public:
    ~Impl() {
        stop();
    }

    void start(Duration timeout, Duration repeatInterval, std::function<void()>&& cb) {
        stop();

        {
            std::lock_guard<std::mutex> lock(mutex);
            callback = std::move(cb);
            initialDelay = timeout;
            repeat = repeatInterval;
            running = true;
            generation++;
        }

        worker = std::thread([this]() {
            std::unique_lock<std::mutex> lock(mutex);
            Duration currentDelay = initialDelay;
            while (running) {
                if (cv.wait_for(lock, currentDelay, [this] { return !running.load(); })) {
                    return; // stopped while waiting
                }

                std::function<void()> fired = callback;
                const bool repeating = repeat.count() > 0;
                const uint64_t firedGeneration = generation;
                RunLoop* loop = runLoop;
                std::weak_ptr<void> token = lifetime;
                lock.unlock();

                if (fired && loop) {
                    loop->invoke([this, token, fired = std::move(fired), repeating, firedGeneration]() {
                        // A callback queued before destruction must be a no-op:
                        // the token dies with the Timer, before `this` does.
                        if (token.expired()) {
                            return;
                        }
                        {
                            // Only lock to validate; the callback itself may
                            // call start()/stop() and must not run under the
                            // mutex (same-thread lock → deadlock).
                            std::unique_lock<std::mutex> lock(mutex);
                            if (!running || generation != firedGeneration) {
                                return;
                            }
                        }
                        fired();
                        if (!repeating) {
                            stop();
                        }
                    });
                }

                lock.lock();
                currentDelay = repeating ? repeat : std::chrono::milliseconds(10);
            }
        });
    }

    void stop() {
        {
            std::lock_guard<std::mutex> lock(mutex);
            running = false;
        }
        cv.notify_all();
        // Never join from the worker itself (stop() may run inside a callback
        // dispatched on the RunLoop thread — a different thread).
        if (worker.joinable() && worker.get_id() != std::this_thread::get_id()) {
            worker.join();
        }
    }

private:
    std::mutex mutex;
    std::condition_variable cv;
    std::atomic<bool> running{false};
    std::function<void()> callback;
    Duration initialDelay;
    Duration repeat;
    uint64_t generation = 0;
    RunLoop* runLoop = nullptr;
    std::thread worker;

    // Lives and dies with the Impl; weak copies guard queued callbacks.
    std::shared_ptr<void> lifetime = std::make_shared<char>();
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
} // namespace mln
