#include "run_loop_impl.hpp"
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread.hpp>
#include <mbgl/util/work_task.hpp>

#include <condition_variable>
#include <thread>
#include <memory>

namespace mbgl {
namespace util {

RunLoop::Impl::Impl(RunLoop*) {
}

RunLoop::Impl::~Impl() {
}

void RunLoop::Impl::wake() {
    // harmony平台上的简化实现
}

void RunLoop::Impl::stop() {
    running = false;
    wake();
}

void RunLoop::Impl::push(std::function<void()> fn) {
    {   
        std::lock_guard<std::mutex> lock(mutex);
        queue.push(std::move(fn));
    }
    wake();
}

void RunLoop::Impl::bind(RunLoop*) {
    // harmony平台上的简化实现
}

RunLoop::RunLoop(Type) : impl(std::make_unique<Impl>(this)) {
}

RunLoop::~RunLoop() {
}

RunLoop* RunLoop::Get() {
    return nullptr;
}

void RunLoop::run() {
    // harmony平台上的简化实现
    // 实际运行时可能需要根据harmony平台的事件循环机制调整
    
    while (impl->running) {
        std::function<void()> fn;
        {
            std::lock_guard<std::mutex> lock(impl->mutex);
            if (!impl->queue.empty()) {
                fn = std::move(impl->queue.front());
                impl->queue.pop();
            }
        }
        
        if (fn) {
            fn();
        } else {
            // 让出CPU时间片
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }
}

void RunLoop::stop() {
    impl->stop();
}

void RunLoop::wake() {
    impl->wake();
}

void RunLoop::waitForEmpty([[maybe_unused]] const SimpleIdentity tag) {
    while (true) {
        std::size_t remaining;
        {
            std::lock_guard<std::mutex> lock(impl->mutex);
            remaining = impl->queue.size();
        }

        if (remaining == 0) {
            return;
        }

        runOnce();
    }
}

void RunLoop::runOnce() {
    std::function<void()> fn;
    {
        std::lock_guard<std::mutex> lock(impl->mutex);
        if (!impl->queue.empty()) {
            fn = std::move(impl->queue.front());
            impl->queue.pop();
        }
    }
    
    if (fn) {
        fn();
    }
}

} // namespace util
} // namespace mbgl