#include <mbgl/util/async_task.hpp>
#include <mbgl/util/run_loop.hpp>

#include <functional>
#include <memory>

namespace mbgl {
namespace util {

class AsyncTask::Impl {
public:
    Impl(std::function<void()>&& task) : task(std::move(task)) {
    }

    void send() {
        if (task) {
            task();
        }
    }

private:
    std::function<void()> task;
};

AsyncTask::AsyncTask(std::function<void()>&& task) : impl(std::make_unique<Impl>(std::move(task))) {
}

AsyncTask::~AsyncTask() {
}

void AsyncTask::send() {
    impl->send();
}

} // namespace util
} // namespace mbgl