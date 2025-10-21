/**
 * HarmonyOS Timer Implementation - Thread Pool Version
 * 
 * 改进点：
 * - 使用线程池代替每个 Timer 创建独立线程
 * - 减少线程创建/销毁开销
 * - 复用工作线程，降低系统资源占用
 * 
 * 保持不变：
 * - 通过 RunLoop::invoke() 保证回调线程安全
 * - 避免鸿蒙主线程 loop 的 uv_timer_t 限制
 * - 符合官方建议："自己启动线程使用 libuv"
 * 
 * 官方文档参考：
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
        
        // 获取 RunLoop（确保回调在正确线程执行）
        runLoop = RunLoop::Get();
        
        TIMER_LOG("Timer started: timeout=%lld ms, repeat=%lld ms, runLoop=%p", 
                 std::chrono::duration_cast<std::chrono::milliseconds>(timeout).count(),
                 std::chrono::duration_cast<std::chrono::milliseconds>(repeatInterval).count(),
                 runLoop);

        // 提交到线程池（而不是创建独立线程）
        TimerThreadPool::instance().submit([this]() {
            TIMER_LOG("Timer task started in thread pool");
            
            bool hasFired = false;
            while (running) {
                std::this_thread::sleep_for(delay);

                if (running && callback && runLoop) {
                    TIMER_LOG("Timer fired - dispatching callback to RunLoop thread");
                    
                    auto repeatCount = this->repeat.count();
                    runLoop->invoke([this, repeatCount]() {
                        TIMER_LOG("⭐ INSIDE INVOKE LAMBDA - about to execute timer callback");
                        if (running && callback) {
                            TIMER_LOG("✅ Executing timer callback on RunLoop thread");
                            callback();
                            TIMER_LOG("✅ Timer callback COMPLETED");
                            
                            // 非重复 timer 在回调后停止
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

                // 处理重复/非重复逻辑
                if (running && this->repeat.count() > 0) {
                    delay = this->repeat;
                } else if (hasFired && this->repeat.count() == 0) {
                    // 非重复 timer，给 lambda 时间执行
                    delay = std::chrono::milliseconds(10);
                }
            }
            
            TIMER_LOG("Timer task exiting from thread pool");
        });
        
        TIMER_LOG("Timer task submitted to thread pool, pending tasks=%{public}zu", 
                 TimerThreadPool::instance().pendingTaskCount());
    }

    void stop() {
        if (running.exchange(false)) {
            TIMER_LOG("Timer stopped");
        }
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

