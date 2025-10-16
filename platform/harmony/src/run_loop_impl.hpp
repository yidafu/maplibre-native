#pragma once

#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/util.hpp>

#include <memory>
#include <functional>
#include <mutex>
#include <queue>

namespace mbgl {
namespace util {

class RunLoop::Impl {
public:
    Impl(RunLoop*);
    ~Impl();

    void wake();
    void stop();
    void push(std::function<void()>);
    void bind(RunLoop*);
    
    void addWatch(int fd, RunLoop::Event, std::function<void(int, RunLoop::Event)>&& callback);
    void removeWatch(int fd);

    enum class Type : uint8_t {
        Default,
        EventLoop,
        NewThread
    };

    bool running = true;
    std::mutex mutex;
    std::queue<std::function<void()>> queue;
};

} // namespace util
} // namespace mbgl