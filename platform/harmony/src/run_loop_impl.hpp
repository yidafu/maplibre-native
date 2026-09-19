#pragma once

#include <mln/util/run_loop.hpp>
#include <mln/util/util.hpp>

#include <uv.h>
#include <memory>
#include <functional>
#include <mutex>
#include <unordered_map>
#include <thread>

namespace mln {
namespace util {

// Forward declaration
struct Watch;
class AsyncTask;

class RunLoop::Impl {
public:
    Impl(RunLoop*, RunLoop::Type);
    ~Impl();

    void closeHolder();  // Implemented in run_loop.cpp.

    uv_handle_t* holderHandle() {
        // If it is already closed, return nullptr to avoid dangling pointers.
        return holderClosed ? nullptr : reinterpret_cast<uv_handle_t*>(holder);
    }

    bool isHolderClosed() const { return holderClosed; }

    uv_loop_t* loop = nullptr;
    uv_async_t* holder = new uv_async_t;

    RunLoop::Type type;

    // `async` is destroyed on the RunLoop thread (stop()/destructor) but read
    // by wake() from foreign threads. All accesses go through asyncMutex so a
    // racing wake() can never touch a half-destroyed unique_ptr; the AsyncTask
    // itself additionally serializes sends against its own handle teardown.
    std::mutex asyncMutex;
    std::unique_ptr<AsyncTask> async;

    std::unordered_map<int, std::unique_ptr<Watch>> watchPoll;

    // Store thread ID for thread safety checks (available in both debug and release)
    std::thread::id tid;

private:
    bool holderClosed = false;  // Prevent double-deleting the holder during shutdown.
};

} // namespace util
} // namespace mln
