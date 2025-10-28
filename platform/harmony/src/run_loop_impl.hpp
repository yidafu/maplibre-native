#pragma once

#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/util.hpp>
#include <mbgl/util/chrono.hpp>

#include <memory>
#include <unordered_map>
#include <list>
#include <mutex>

// Forward declare libuv types to avoid including uv.h in header
struct uv_loop_s;
struct uv_async_s;
typedef struct uv_loop_s uv_loop_t;
typedef struct uv_async_s uv_async_t;
typedef struct uv_handle_s uv_handle_t;

namespace mbgl {
namespace util {

// Forward declaration
struct Watch;
class AsyncTask;

class RunLoop::Impl {
public:
    /**
     * Runnable - Abstract interface for scheduled tasks
     * 
     * Similar to Android's RunLoop::Impl::Runnable, this interface
     * allows unified scheduling of AsyncTask and Timer through the
     * same mechanism, ensuring consistent execution order based on
     * due time.
     */
    class Runnable {
    public:
        virtual ~Runnable() = default;

        /**
         * Execute the scheduled task
         */
        virtual void runTask() = 0;

        /**
         * Get the time when this task should be executed
         * 
         * @return TimePoint representing when this task is due
         */
        virtual TimePoint dueTime() const = 0;
    };

    Impl(RunLoop*, RunLoop::Type);
    ~Impl();

    void closeHolder();
    uv_handle_t* holderHandle();

    /**
     * Add a Runnable to the scheduled tasks queue
     * Thread-safe: can be called from any thread
     */
    void addRunnable(Runnable* runnable);

    /**
     * Remove a Runnable from the scheduled tasks queue
     * Thread-safe: can be called from any thread
     */
    void removeRunnable(Runnable* runnable);

    /**
     * Process all Runnables whose due time has passed
     * Should be called from the RunLoop thread
     */
    void processRunnables();

    /**
     * Wake up the event loop
     * Thread-safe: can be called from any thread
     */
    void wake();

    uv_loop_t* loop = nullptr;
    uv_async_t* holder = nullptr;
    uv_async_t* waker = nullptr;  // 用于 wake() 的独立 async handle

    RunLoop::Type type;
    std::unique_ptr<AsyncTask> async;  // 已废弃，保留用于兼容性

    std::unordered_map<int, std::unique_ptr<Watch>> watchPoll;

private:
    // Mutex protecting the runnables list
    std::mutex runnablesMutex;
    
    // List of scheduled Runnables
    std::list<Runnable*> runnables;
};

} // namespace util
} // namespace mbgl
