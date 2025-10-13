#include <mbgl/util/timer.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/run_loop.hpp>

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

        thread = std::thread([this]() {
            while (running) {
                std::this_thread::sleep_for(delay);

                if (running && callback) {
                    // 在harmony平台上，我们直接执行回调，不经过RunLoop
                    callback();
                }

                if (running && this->repeat.count() == 0) {
                    stop();
                }
            }
        });

        thread.detach();
    }

    void stop() {
        running = false;
        // 不需要等待线程结束，因为我们使用detach
    }

private:
    std::atomic<bool> running;
    Duration delay;
    Duration repeat;
    std::function<void()> callback;
    std::thread thread;
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