/**
 * HarmonyOS RunLoop Implementation
 * 
 * This implementation follows HarmonyOS libuv best practices:
 * - FFRT-aware task scheduling
 * - Thread-safe operations with proper validation
 * - Comprehensive error handling and HiLog integration
 * - Proper resource lifecycle management
 * 
 * References:
 * - HarmonyOS libuv API: https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/libuv-V5
 */

#include "run_loop_impl.hpp"
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/async_task.hpp>
#include <mbgl/util/monotonic_timer.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/thread_local.hpp>

#include <uv.h>

#include <atomic>
#include <cassert>
#include <functional>
#include <unordered_map>
#include <stdexcept>
#include <thread>

// Use platform logger
#include "../maplibre_harmony/src/main/cpp/utils/logger.h"

using mbgl::harmony::Logger;

namespace {

/**
 * Dummy callback for the holder async handle.
 */
void dummyCallback(uv_async_t*) {
    // No-op
}

/**
 * Helper function to convert libuv error codes to readable strings
 */
const char* uvErrorString(int errorCode) {
    return uv_strerror(errorCode);
}

} // namespace

namespace mbgl {
namespace util {

/**
 * Watch: Manages file descriptor polling for network sockets
 * 
 * Used primarily by libcurl backend for async network operations.
 * Each Watch corresponds to a socket that needs monitoring.
 */
struct Watch {
    static void onEvent(uv_poll_t* poll, int status, int event) {
        auto watch = reinterpret_cast<Watch*>(poll->data);
        
        if (status < 0) {
            Logger::error("RunLoop", "Poll event error on fd=%d: %s", watch->fd, uvErrorString(status));
            return;
        }

        RunLoop::Event watchEvent = RunLoop::Event::None;
        switch (event) {
            case UV_READABLE:
                watchEvent = RunLoop::Event::Read;
                break;
            case UV_WRITABLE:
                watchEvent = RunLoop::Event::Write;
                break;
            case UV_READABLE | UV_WRITABLE:
                watchEvent = RunLoop::Event::ReadWrite;
                break;
            default:
                break;
        }

        if (watch->eventCallback && watchEvent != RunLoop::Event::None) {
            watch->eventCallback(watch->fd, watchEvent);
        }
    }

    static void onClose(uv_handle_t* poll) {
        auto watch = reinterpret_cast<Watch*>(poll->data);
        
        if (watch->closeCallback) {
            watch->closeCallback();
        }
    }

    uv_poll_t poll;
    int fd;
    std::function<void(int, RunLoop::Event)> eventCallback;
    std::function<void()> closeCallback;
};

/**
 * Get the current RunLoop for this thread
 */
RunLoop* RunLoop::Get() {
    auto* scheduler = Scheduler::GetCurrent();
    assert(scheduler && "No RunLoop on current thread");
    return static_cast<RunLoop*>(scheduler);
}

RunLoop::Impl::Impl(RunLoop*, RunLoop::Type type_) 
    : type(type_) {
}

// ✅ 修复退出崩溃：closeHolder() 实现
void RunLoop::Impl::closeHolder() {
    if (!holderClosed) {
        Logger::debug("RunLoop", "closeHolder() called, marking as closed");
        // 先保存 holder 指针，因为设置 holderClosed 后 holderHandle() 会返回 nullptr
        auto* holderPtr = reinterpret_cast<uv_handle_t*>(holder);
        holderClosed = true;  // ✅ 标记为已关闭，防止重复删除
        uv_close(holderPtr, [](uv_handle_t* h) { 
            Logger::debug("RunLoop", "Holder close callback, deleting holder");
            delete reinterpret_cast<uv_async_t*>(h); 
        });
    } else {
        Logger::warn("RunLoop", "closeHolder() called but already closed");
    }
}

RunLoop::Impl::~Impl() {
    if (!watchPoll.empty()) {
        Logger::warn("RunLoop", "RunLoop destroyed with %zu active watches", watchPoll.size());
    }
    
    // ✅ 修复退出崩溃：安全清理 holder（如果还未删除）
    // 注意：正常情况下 holder 应该在 stop() 或析构函数中已经通过 uv_close 删除
    // 这里只是防御性编程，处理异常情况
    if (holder && !holderClosed) {
        Logger::warn("RunLoop", "Holder not properly closed before Impl destruction");
        // 注意：这里不能调用 uv_close，因为 loop 可能已经不可用
        // 直接删除可能会造成小的内存泄漏（uv handle 未正确关闭），但比崩溃好
        delete holder;
        holder = nullptr;
    }
}

/**
 * RunLoop Constructor
 * 
 * Creates a new event loop or uses the default one.
 * Initializes the holder async handle to keep loop alive.
 * Sets up AsyncTask for cross-thread communication.
 */
RunLoop::RunLoop(Type type)
    : impl(std::make_unique<Impl>(this, type)) {
    
    // Initialize the event loop
    switch (type) {
        case Type::New:
            impl->loop = new uv_loop_t;
            
            if (int err = uv_loop_init(impl->loop); err != 0) {
                Logger::error("RunLoop", "Failed to initialize loop: %s", uvErrorString(err));
                delete impl->loop;
                impl->loop = nullptr;
                throw std::runtime_error("Failed to initialize loop: " + std::string(uvErrorString(err)));
            }
            break;
            
        case Type::Default:
            impl->loop = uv_default_loop();
            
            if (!impl->loop) {
                Logger::error("RunLoop", "Failed to get default loop");
                throw std::runtime_error("Failed to get default loop");
            }
            break;
    }

    // Initialize holder async handle
    if (int err = uv_async_init(impl->loop, impl->holder, dummyCallback); err != 0) {
        Logger::error("RunLoop", "Failed to initialize holder async: %s", uvErrorString(err));
        
        if (type == Type::New) {
            uv_loop_close(impl->loop);
            delete impl->loop;
            impl->loop = nullptr;
        }
        
        throw std::runtime_error("Failed to initialize holder async: " + std::string(uvErrorString(err)));
    }

    Scheduler::SetCurrent(this);
    impl->async = std::make_unique<AsyncTask>(std::bind(&RunLoop::process, this));
}

/**
 * RunLoop Destructor
 * 
 * Properly cleans up all resources:
 * 1. Unregister from Scheduler
 * 2. Close holder handle
 * 3. Destroy AsyncTask
 * 4. Run loop multiple times to process close callbacks
 * 5. Close and free the loop (for Type::New)
 * 
 * ⚡ ENHANCED FIX: 确保所有 AsyncTask close callbacks 被处理
 * - 增加循环迭代次数，从 10 次提高到 50 次
 * - 添加详细日志记录清理状态
 * - 使用 uv_walk 检查未关闭的句柄
 */
RunLoop::~RunLoop() {
    Logger::debug("RunLoop", "RunLoop destructor started");
    
    Scheduler::SetCurrent(nullptr);

    // 强制关闭所有活跃的Watch句柄
    if (!impl->watchPoll.empty()) {
        Logger::debug("RunLoop", "Closing %zu active watch handles", impl->watchPoll.size());
        for (auto it = impl->watchPoll.begin(); it != impl->watchPoll.end(); ++it) {
            auto& watch = it->second;
            if (watch && !uv_is_closing(reinterpret_cast<uv_handle_t*>(&watch->poll))) {
                uv_close(reinterpret_cast<uv_handle_t*>(&watch->poll), nullptr);
            }
        }
        impl->watchPoll.clear();
    }

    // ✅ 修复退出崩溃：检查 holder 是否已经被关闭
    // 如果在 stop() 中已经关闭，holderHandle() 会返回 nullptr，避免访问悬空指针
    if (!impl->isHolderClosed() && impl->holderHandle()) {
        Logger::debug("RunLoop", "Closing holder handle in destructor");
        impl->closeHolder();
    } else {
        Logger::debug("RunLoop", "Holder handle already closed (in stop())");
    }

    if (impl->type == Type::Default) {
        Logger::debug("RunLoop", "Default loop - skipping cleanup");
        return;
    }

    // 销毁 AsyncTask - 这会调用 uv_close
    // 注意：stop() 可能已经销毁了 impl->async
    if (impl->async) {
        Logger::debug("RunLoop", "Destroying AsyncTask");
        impl->async.reset();
    } else {
        Logger::debug("RunLoop", "AsyncTask already destroyed (in stop())");
    }

    // ⚡ 关键修复：增加循环迭代次数，确保 AsyncTask close callbacks 被处理
    // 从 10 次提高到 50 次，给足够时间处理所有 pending close callbacks
    const int MAX_CLEANUP_ITERATIONS = 50;
    Logger::debug("RunLoop", "Running loop to process close callbacks (max %d iterations)", MAX_CLEANUP_ITERATIONS);
    
    int lastResult = 0;
    for (int i = 0; i < MAX_CLEANUP_ITERATIONS; i++) {
        int result = uv_run(impl->loop, UV_RUN_NOWAIT);
        lastResult = result;
        if (result == 0) {
            Logger::debug("RunLoop", "All pending handles processed after %d iterations", i + 1);
            break;
        }
        
        // 每10次迭代记录一次状态
        if ((i + 1) % 10 == 0) {
            Logger::debug("RunLoop", "Still processing handles after %d iterations (active: %d)", i + 1, result);
        }
    }
    
    if (lastResult > 0) {
        Logger::warn("RunLoop", "Loop still has %d active handles after %d iterations", lastResult, MAX_CLEANUP_ITERATIONS);
    }

    // 检查并强制关闭任何剩余的句柄
    int handleCount = 0;
    uv_walk(impl->loop, [](uv_handle_t* handle, void* arg) {
        int* count = static_cast<int*>(arg);
        (*count)++;
        
        if (!uv_is_closing(handle)) {
            const char* typeName = uv_handle_type_name(uv_handle_get_type(handle));
            Logger::warn("RunLoop", "Force closing handle type: %s", typeName);
            uv_close(handle, nullptr);
        }
    }, &handleCount);
    
    if (handleCount > 0) {
        Logger::debug("RunLoop", "Found %d handles, running loop once more", handleCount);
        uv_run(impl->loop, UV_RUN_NOWAIT);
    }

    // 关闭循环
    if (int err = uv_loop_close(impl->loop); err == UV_EBUSY) {
        Logger::error("RunLoop", "Failed to close loop: UV_EBUSY - loop still has active handles");
    } else if (err != 0) {
        Logger::error("RunLoop", "Failed to close loop: %s", uvErrorString(err));
    } else {
        Logger::debug("RunLoop", "Loop closed successfully");
    }
    
    delete impl->loop;
    impl->loop = nullptr;
    
    Logger::debug("RunLoop", "RunLoop destructor completed");
}

/**
 * Get the raw loop handle
 * Thread-safe: Can be called from any thread
 */
LOOP_HANDLE RunLoop::getLoopHandle() {
    return Get()->impl->loop;
}

void RunLoop::wake() {
    if (impl->async) {
        impl->async->send();
    }
}

void RunLoop::run() {
    MBGL_VERIFY_THREAD(tid);
    
    uv_ref(impl->holderHandle());
    uv_run(impl->loop, UV_RUN_DEFAULT);
}

void RunLoop::runOnce() {
    MBGL_VERIFY_THREAD(tid);
    uv_run(impl->loop, UV_RUN_NOWAIT);
}

void RunLoop::stop() {
    invoke([this] {
        // ⚡ ANR FIX: 关闭所有 active handles，让 RunLoop 能够立即退出
        // 
        // 根本问题：
        // - uv_run(UV_RUN_NOWAIT) 只要有 active handle 就返回非零值
        // - 即使关闭了 holder，impl->async 仍然 active
        // - 导致 RunLoop 线程无法退出 → 主线程 join() 阻塞 → ANR
        //
        // 解决方案：
        // 1. 销毁 impl->async（这会调用 uv_close）
        // 2. 关闭 holder handle
        // 3. 运行循环处理所有 close callbacks
        // 4. uv_run() 会在所有 handles 关闭后返回 0
        // 5. RunLoop 线程正常退出，无需 detach
        
        Logger::debug("RunLoop", "stop() called - shutting down all handles");
        
        // ⚡ 关键修复 1：先销毁 AsyncTask（这会触发 uv_close）
        if (impl->async) {
            Logger::debug("RunLoop", "Destroying AsyncTask to close its async handle");
            impl->async.reset();
            
            // 立即运行一次循环，让 uv_close 生效（从 pending 变为 closing）
            Logger::debug("RunLoop", "Running loop once to process AsyncTask close");
            uv_run(impl->loop, UV_RUN_NOWAIT);
        }
        
        // ✅ 修复退出崩溃：使用 closeHolder() 方法，它会设置 holderClosed 标志
        if (!impl->isHolderClosed()) {
            Logger::debug("RunLoop", "Closing holder handle");
            impl->closeHolder();  // 这会设置 holderClosed = true，防止析构函数重复删除
            
            // 立即运行一次循环，让 uv_close 生效
            Logger::debug("RunLoop", "Running loop once to process holder close");
            uv_run(impl->loop, UV_RUN_NOWAIT);
        }
        
        // 运行循环以处理所有 close callbacks
        // 现在需要处理：holder + AsyncTask 的 async handle
        const int MAX_ITERATIONS = 30;  // 增加迭代次数给更多时间
        int lastResult = 0;
        
        for (int i = 0; i < MAX_ITERATIONS; i++) {
            int result = uv_run(impl->loop, UV_RUN_NOWAIT);
            lastResult = result;
            
            if (result == 0) {
                // 没有更多 active handles - 完美！
                Logger::info("RunLoop", "✅ All handles closed after %d iterations - RunLoop will exit cleanly", i + 1);
                break;
            }
            
            // 每5次迭代记录一次状态 + 诊断信息
            if ((i + 1) % 5 == 0) {
                Logger::debug("RunLoop", "Still processing in stop() after %d iterations (active: %d)", i + 1, result);
                
                // 🔍 在迭代过程中也列出 handles 帮助诊断
                if ((i + 1) == 10 || (i + 1) == 20) {
                    int handleCount = 0;
                    uv_walk(impl->loop, [](uv_handle_t* handle, void* arg) {
                        int* count = static_cast<int*>(arg);
                        const char* typeName = uv_handle_type_name(uv_handle_get_type(handle));
                        bool isClosing = uv_is_closing(handle);
                        Logger::debug("RunLoop", "     Active handle: type=%s, closing=%d", typeName, isClosing);
                        (*count)++;
                    }, &handleCount);
                }
            }
        }
        
        if (lastResult > 0) {
            Logger::warn("RunLoop", "⚠️ stop() completed with %d active handles remaining", lastResult);
            
            // 🔍 诊断：列出所有未关闭的 handles
            int handleCount = 0;
            uv_walk(impl->loop, [](uv_handle_t* handle, void* arg) {
                int* count = static_cast<int*>(arg);
                (*count)++;
                
                const char* typeName = uv_handle_type_name(uv_handle_get_type(handle));
                bool isClosing = uv_is_closing(handle);
                bool hasRef = uv_has_ref(handle);
                
                Logger::warn("RunLoop", "   Handle #%d: type=%s, closing=%d, hasRef=%d, handle=%p", 
                             *count, typeName, isClosing, hasRef, handle);
            }, &handleCount);
            
            Logger::warn("RunLoop", "   Total handles found: %d", handleCount);
            Logger::warn("RunLoop", "   These will be force-closed in destructor");
        } else {
            Logger::info("RunLoop", "✅ stop() completed successfully - no active handles remaining");
        }
    });
}

void RunLoop::updateTime() {
    MBGL_VERIFY_THREAD(tid);
    uv_update_time(impl->loop);
}

/**
 * Wait until all queued work is processed
 * 
 * Thread-safe: Can be called from any thread.
 * If called from a different thread, work is delegated to the RunLoop thread.
 * Blocks until queues are empty.
 */
void RunLoop::waitForEmpty([[maybe_unused]] const mbgl::util::SimpleIdentity tag) {
    if (tid != std::this_thread::get_id()) {
        std::atomic<bool> done{false};
        
        invoke([this, &done]() {
            while (true) {
                std::size_t remaining;
                {
                    std::lock_guard<std::mutex> lock(mutex);
                    remaining = defaultQueue.size() + highPriorityQueue.size();
                }
                
                if (remaining == 0) {
                    break;
                }
                
                runOnce();
            }
            
            done.store(true, std::memory_order_release);
        });
        
        while (!done.load(std::memory_order_acquire)) {
            std::this_thread::yield();
        }
        
        return;
    }
    
    while (true) {
        std::size_t remaining;
        {
            std::lock_guard<std::mutex> lock(mutex);
            remaining = defaultQueue.size() + highPriorityQueue.size();
        }

        if (remaining == 0) {
            return;
        }

        runOnce();
    }
}

/**
 * Add a watch for file descriptor events
 * 
 * Used primarily for libcurl network backend.
 * Must be called from the loop's owner thread.
 * 
 * HarmonyOS Note: Ensure fd is valid and not already being watched.
 */
void RunLoop::addWatch(int fd, Event event, std::function<void(int, Event)>&& callback) {
    MBGL_VERIFY_THREAD(tid);

    if (fd < 0) {
        Logger::error("RunLoop", "Invalid fd: %d", fd);
        throw std::runtime_error("Invalid file descriptor");
    }

    Watch* watch = nullptr;
    auto watchPollIter = impl->watchPoll.find(fd);

    if (watchPollIter == impl->watchPoll.end()) {
        std::unique_ptr<Watch> watchPtr = std::make_unique<Watch>();

        watch = watchPtr.get();
        impl->watchPoll[fd] = std::move(watchPtr);

        int initResult;
#ifdef WIN32
        initResult = uv_poll_init_socket(impl->loop, &watch->poll, fd);
#else
        initResult = uv_poll_init(impl->loop, &watch->poll, fd);
#endif
        
        if (initResult != 0) {
            Logger::error("RunLoop", "Failed to init poll for fd=%d: %s", fd, uvErrorString(initResult));
            impl->watchPoll.erase(fd);
            throw std::runtime_error("Failed to init poll on file descriptor: " + std::string(uvErrorString(initResult)));
        }
    } else {
        watch = watchPollIter->second.get();
    }

    watch->poll.data = watch;
    watch->fd = fd;
    watch->eventCallback = std::move(callback);

    int pollEvent = 0;
    switch (event) {
        case Event::Read:
            pollEvent = UV_READABLE;
            break;
        case Event::Write:
            pollEvent = UV_WRITABLE;
            break;
        case Event::ReadWrite:
            pollEvent = UV_READABLE | UV_WRITABLE;
            break;
        case Event::None:
        default:
            Logger::error("RunLoop", "Invalid event type: %d", static_cast<int>(event));
            throw std::runtime_error("Invalid event type for watch");
    }

    if (int err = uv_poll_start(&watch->poll, pollEvent, &Watch::onEvent); err != 0) {
        Logger::error("RunLoop", "Failed to start poll for fd=%d: %s", fd, uvErrorString(err));
        throw std::runtime_error("Failed to start poll on file descriptor: " + std::string(uvErrorString(err)));
    }
}

/**
 * Remove a watch for file descriptor events
 * 
 * Must be called from the loop's owner thread.
 * Properly stops polling and schedules handle close.
 */
void RunLoop::removeWatch(int fd) {
    MBGL_VERIFY_THREAD(tid);

    auto watchPollIter = impl->watchPoll.find(fd);
    if (watchPollIter == impl->watchPoll.end()) {
        return;
    }

    Watch* watch = watchPollIter->second.release();
    impl->watchPoll.erase(watchPollIter);

    watch->closeCallback = [watch] {
        delete watch;
    };

    if (int err = uv_poll_stop(&watch->poll); err != 0) {
        Logger::warn("RunLoop", "Failed to stop poll for fd=%d: %s", fd, uvErrorString(err));
    }

    uv_close(reinterpret_cast<uv_handle_t*>(&watch->poll), &Watch::onClose);
}

} // namespace util
} // namespace mbgl
