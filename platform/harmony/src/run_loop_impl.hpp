#pragma once

#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/util.hpp>

#include <uv.h>
#include <memory>
#include <functional>
#include <unordered_map>

namespace mbgl {
namespace util {

// Forward declaration
struct Watch;
class AsyncTask;

class RunLoop::Impl {
public:
    Impl(RunLoop*, RunLoop::Type);
    ~Impl();

    void closeHolder() {
        uv_close(holderHandle(), [](uv_handle_t* h) { delete reinterpret_cast<uv_async_t*>(h); });
    }

    uv_handle_t* holderHandle() { return reinterpret_cast<uv_handle_t*>(holder); }

    uv_loop_t* loop = nullptr;
    uv_async_t* holder = new uv_async_t;

    RunLoop::Type type;
    std::unique_ptr<AsyncTask> async;

    std::unordered_map<int, std::unique_ptr<Watch>> watchPoll;
};

} // namespace util
} // namespace mbgl
