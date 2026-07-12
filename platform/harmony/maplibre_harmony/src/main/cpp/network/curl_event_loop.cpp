#include "curl_event_loop.hpp"
#include "utils/logger.h"

#include <mbgl/util/logging.hpp>
#include <mbgl/util/string.hpp>

#include <curl/curl.h>
#include <uv.h>

#include <algorithm>
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <thread>
#include <vector>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

CURLEventLoop::CURLEventLoop(Mode mode)
    : loop_(nullptr)
    , thread_(nullptr)
    , running_(false)
    , stopping_(false)
    , activeRequestCount_(0)
    , mode_(mode)
    , multi_(nullptr)
    , timeout_timer_(nullptr)
    , polling_timer_(nullptr)
    , holder_(nullptr)
    , operation_signal_(nullptr) {

    // Create a dedicated libuv event loop
    loop_ = new uv_loop_t;
    if (int err = uv_loop_init(loop_); err != 0) {
        Logger::error("Network", "Failed to initialize libuv loop: %s", uv_strerror(err));
        delete loop_;
        loop_ = nullptr;
        throw std::runtime_error("Failed to initialize libuv loop: " + std::string(uv_strerror(err)));
    }

    // Create a holder async handle to keep the loop alive
    holder_ = new uv_async_t;
    if (int err = uv_async_init(loop_, holder_, [](uv_async_t*) {}); err != 0) {
        Logger::error("Network", "Failed to initialize holder async: %s", uv_strerror(err));
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
        delete holder_;
        holder_ = nullptr;
        throw std::runtime_error("Failed to initialize holder async: " + std::string(uv_strerror(err)));
    }

    // Create the operation signal handle for cross-thread operation dispatch
    operation_signal_ = new uv_async_t;
    if (int err = uv_async_init(loop_, operation_signal_, onOperationSignal); err != 0) {
        Logger::error("Network", "Failed to initialize operation signal: %s", uv_strerror(err));
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), [](uv_handle_t* h) {
            delete reinterpret_cast<uv_async_t*>(h);
        });
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
        delete holder_;
        holder_ = nullptr;
        delete operation_signal_;
        operation_signal_ = nullptr;
        throw std::runtime_error("Failed to initialize operation signal: " + std::string(uv_strerror(err)));
    }
    operation_signal_->data = this;

    // Create the CURL multi handle
    multi_ = curl_multi_init();
    if (!multi_) {
        Logger::error("Network", "Failed to initialize CURL multi handle");
        uv_close(reinterpret_cast<uv_handle_t*>(operation_signal_), nullptr);
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), nullptr);
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
        delete holder_;
        holder_ = nullptr;
        delete operation_signal_;
        operation_signal_ = nullptr;
        throw std::runtime_error("Failed to initialize CURL multi handle");
    }

    // Configure CURL callbacks based on the mode
    if (mode_ == Mode::EventDriven) {
        curl_multi_setopt(multi_, CURLMOPT_SOCKETFUNCTION, handleSocket);
        curl_multi_setopt(multi_, CURLMOPT_SOCKETDATA, this);
        curl_multi_setopt(multi_, CURLMOPT_TIMERFUNCTION, handleTimer);
        curl_multi_setopt(multi_, CURLMOPT_TIMERDATA, this);
    }
}

CURLEventLoop::~CURLEventLoop() {
    // Ensure the event loop has stopped
    if (running_.load()) {
        stop();
    }

    // Clean up the CURL multi handle
    if (multi_) {
        curl_multi_cleanup(multi_);
        multi_ = nullptr;
    }

    // Release the polling timer if present (should already be nullptr after stop)
    if (polling_timer_) {
        delete polling_timer_;
        polling_timer_ = nullptr;
    }

    // Release the holder handle if necessary (should already be nullptr after stop)
    if (holder_) {
        delete holder_;
        holder_ = nullptr;
    }

    // Release the operation signal handle if necessary (should already be nullptr after stop)
    if (operation_signal_) {
        delete operation_signal_;
        operation_signal_ = nullptr;
    }

    // Tear down the libuv event loop
    if (loop_) {
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
    }
}

void CURLEventLoop::start() {
    if (running_.load()) {
        Logger::warn("Network", "Event loop is already running");
        return;
    }

    if (!loop_ || !multi_) {
        Logger::error("Network", "Event loop or multi handle is null");
        throw std::runtime_error("Event loop or multi handle is null");
    }

    running_.store(true);
    stopping_.store(false);

    const char* modeString = (mode_ == Mode::EventDriven) ? "EventDriven" : "SimplePolling";
    Logger::info("Network", "Starting CURLEventLoop (mode=%s)", modeString);

    // Start the polling timer when running in SimplePolling mode
    if (mode_ == Mode::SimplePolling) {
        polling_timer_ = new uv_timer_t;
        polling_timer_->data = this;

        int err = uv_timer_init(loop_, polling_timer_);
        if (err != 0) {
            Logger::error("Network", "Failed to initialize polling timer: %s", uv_strerror(err));
            delete polling_timer_;
            polling_timer_ = nullptr;
            throw std::runtime_error("Failed to initialize polling timer: " + std::string(uv_strerror(err)));
        }

        err = uv_timer_start(polling_timer_, onPolling, 20, 20);
        if (err != 0) {
            Logger::error("Network", "Failed to start polling timer: %s", uv_strerror(err));
            throw std::runtime_error("Failed to start polling timer: " + std::string(uv_strerror(err)));
        }
    }

    // In EventDriven mode, start a low-frequency heartbeat timer as a safety net.
    // If uv_poll_init fails on this platform, socket monitoring is unavailable,
    // and transfers must be driven by periodic polling instead. The heartbeat
    // ensures progress without relying solely on libcurl's adaptive timeout
    // (which can be 30s+ for connection establishment).
    if (mode_ == Mode::EventDriven) {
        polling_timer_ = new uv_timer_t;
        polling_timer_->data = this;

        int err = uv_timer_init(loop_, polling_timer_);
        if (err != 0) {
            Logger::error("Network", "Failed to initialize heartbeat timer: %s", uv_strerror(err));
            delete polling_timer_;
            polling_timer_ = nullptr;
        } else {
            err = uv_timer_start(polling_timer_, onPolling, 100, 100);
            if (err != 0) {
                Logger::error("Network", "Failed to start heartbeat timer: %s", uv_strerror(err));
                uv_close(reinterpret_cast<uv_handle_t*>(polling_timer_), [](uv_handle_t* h) {
                    delete reinterpret_cast<uv_timer_t*>(h);
                });
                polling_timer_ = nullptr;
            } else {
                Logger::debug("Network", "Heartbeat timer started (100ms)");
            }
        }
    }

    // Launch the event loop thread
    thread_ = std::make_unique<std::thread>(&CURLEventLoop::eventLoopThread, this);
}

void CURLEventLoop::stop() {
    if (!running_.load()) {
        return;
    }

    Logger::info("Network", "Stopping CURLEventLoop - begin");
    auto stopStart = std::chrono::steady_clock::now();

    std::mutex watchdogMutex;
    std::condition_variable watchdogCv;
    bool joinCompleted = false;
    bool stopRequested = false;

    std::thread watchdog([&]() {
        std::unique_lock<std::mutex> lk(watchdogMutex);
        using namespace std::chrono_literals;
        const auto warnInterval = 200ms;
        auto lastWarn = std::chrono::steady_clock::now();

        while (!joinCompleted) {
            if (watchdogCv.wait_for(lk, warnInterval, [&]() { return joinCompleted || stopRequested; })) {
                if (joinCompleted) {
                    return;
                }
                if (stopRequested) {
                    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - stopStart);
                    Logger::warn("Network", "Waiting for CURLEventLoop thread join... (%lld ms)",
                                 static_cast<long long>(elapsed.count()));
                    stopRequested = false;
                    lastWarn = std::chrono::steady_clock::now();
                }
            } else {
                auto now = std::chrono::steady_clock::now();
                if (now - lastWarn >= 2s) {
                    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - stopStart);
                    Logger::warn("Network", "Waiting for CURLEventLoop thread join... (%lld ms)",
                                 static_cast<long long>(elapsed.count()));
                    lastWarn = now;
                }
            }
        }
    });

    stopping_.store(true);

    // Wake the CURLEventLoop thread so it can perform shutdown
    if (operation_signal_) {
        uv_async_send(operation_signal_);
    }

    // Wait for the thread to finish
    if (thread_ && thread_->joinable()) {
        Logger::info("Network", "Joining CURLEventLoop thread");
        {
            std::lock_guard<std::mutex> lk(watchdogMutex);
            stopRequested = true;
        }
        watchdogCv.notify_all();
        thread_->join();
    }

    {
        std::lock_guard<std::mutex> lk(watchdogMutex);
        joinCompleted = true;
        stopRequested = false;
    }
    watchdogCv.notify_all();
    if (watchdog.joinable()) {
        watchdog.join();
    }

    auto stopElapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now() - stopStart);
    Logger::info("Network", "Stopping CURLEventLoop - finished in %lld ms",
                 static_cast<long long>(stopElapsed.count()));

    thread_.reset();
    running_.store(false);
}

// Queue an AddHandle operation and block until the CURLEventLoop thread completes it.
bool CURLEventLoop::addHandle(CURL* handle) {
    if (!handle || !multi_ || !running_.load()) {
        Logger::error("Network", "Invalid parameters or event loop not running");
        return false;
    }

    if (stopping_.load(std::memory_order_acquire)) {
        Logger::error("Network", "Event loop is stopping, cannot add handle");
        return false;
    }

    Logger::debug("Network", "addHandle called on thread %llu (handle=%p)",
                  static_cast<unsigned long long>(std::hash<std::thread::id>{}(std::this_thread::get_id())),
                  static_cast<void*>(handle));

    // Synchronization primitives on the caller's stack
    std::mutex done_mutex;
    std::condition_variable done_cv;
    bool done = false;
    bool success = false;

    // Enqueue the operation
    {
        std::lock_guard<std::mutex> lock(operation_queue_mutex_);
        pending_operations_.push({OperationType::AddHandle, handle, &done_mutex, &done_cv, &done, &success});
    }

    // Wake the CURLEventLoop thread
    uv_async_send(operation_signal_);

    // Block until the operation is processed
    {
        std::unique_lock<std::mutex> lock(done_mutex);
        done_cv.wait(lock, [&done] { return done; });
    }

    return success;
}

// Queue a RemoveHandle operation and block until the CURLEventLoop thread completes it.
bool CURLEventLoop::removeHandle(CURL* handle) {
    if (!handle || !multi_) {
        Logger::error("Network", "Invalid parameters");
        return false;
    }

    Logger::debug("Network", "removeHandle called on thread %llu (handle=%p)",
                  static_cast<unsigned long long>(std::hash<std::thread::id>{}(std::this_thread::get_id())),
                  static_cast<void*>(handle));

    // Synchronization primitives on the caller's stack
    std::mutex done_mutex;
    std::condition_variable done_cv;
    bool done = false;
    bool success = false;

    // Enqueue the operation
    {
        std::lock_guard<std::mutex> lock(operation_queue_mutex_);
        pending_operations_.push({OperationType::RemoveHandle, handle, &done_mutex, &done_cv, &done, &success});
    }

    // Wake the CURLEventLoop thread
    uv_async_send(operation_signal_);

    // Block until the operation is processed
    {
        std::unique_lock<std::mutex> lock(done_mutex);
        done_cv.wait(lock, [&done] { return done; });
    }

    return success;
}

// Queue a RemoveAllHandles operation and block until the CURLEventLoop thread completes it.
void CURLEventLoop::removeAllHandles() {
    Logger::debug("Network", "removeAllHandles: %zu active handles, %zu in-flight requests",
                  active_handles_.size(), activeRequestCount_.load(std::memory_order_acquire));

    // Synchronization primitives on the caller's stack
    std::mutex done_mutex;
    std::condition_variable done_cv;
    bool done = false;
    bool success = false;

    // Enqueue the operation
    {
        std::lock_guard<std::mutex> lock(operation_queue_mutex_);
        pending_operations_.push({OperationType::RemoveAllHandles, nullptr, &done_mutex, &done_cv, &done, &success});
    }

    // Wake the CURLEventLoop thread
    uv_async_send(operation_signal_);

    // Block until the operation is processed
    {
        std::unique_lock<std::mutex> lock(done_mutex);
        done_cv.wait(lock, [&done] { return done; });
    }

    // Wait for in-flight requests to complete (with timeout)
    // These are requests that were already being processed in processCURLMessages
    constexpr size_t kMaxWaitCount = 100;  // 100 * 10ms = 1 second max wait
    size_t waitCount = 0;
    while (activeRequestCount_.load(std::memory_order_acquire) > 0 && waitCount < kMaxWaitCount) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        waitCount++;
    }

    if (activeRequestCount_.load(std::memory_order_acquire) > 0) {
        Logger::warn("Network", "removeAllHandles: %zu requests still in-flight after wait (will be orphaned)",
                     activeRequestCount_.load(std::memory_order_acquire));
    }
}

void CURLEventLoop::eventLoopThread() {
    const auto threadId = static_cast<unsigned long long>(std::hash<std::thread::id>{}(std::this_thread::get_id()));
    Logger::info("Network", "CURLEventLoop thread start (id=%llu)", threadId);

    // Process any operations that may have been queued between start() and the thread reaching uv_run.
    // The onOperationSignal callback also handles this, but uv_async_send may have fired before
    // uv_run started. Processing here ensures we don't miss early operations.
    onOperationSignal(operation_signal_);

    uv_run(loop_, UV_RUN_DEFAULT);

    Logger::info("Network", "CURLEventLoop thread exit (id=%llu)", threadId);
}

// ============================================================================
// Operation dispatch — runs exclusively on the CURLEventLoop thread
// ============================================================================

void CURLEventLoop::onOperationSignal(uv_async_t* async) {
    auto* eventLoop = static_cast<CURLEventLoop*>(async->data);

    if (!eventLoop) return;

    // If stopping, handle remaining pending operations and perform shutdown
    if (eventLoop->stopping_.load(std::memory_order_acquire)) {
        // Drain and signal any remaining pending operations (mark as failed)
        {
            std::lock_guard<std::mutex> lock(eventLoop->operation_queue_mutex_);
            while (!eventLoop->pending_operations_.empty()) {
                auto& op = eventLoop->pending_operations_.front();
                if (op.success_flag) *op.success_flag = false;
                if (op.done_flag) *op.done_flag = true;
                if (op.done_cv) op.done_cv->notify_one();
                eventLoop->pending_operations_.pop();
            }
        }
        // Perform graceful shutdown — closes all handles so uv_run returns naturally
        eventLoop->performShutdown();
        return;
    }

    // Dequeue all pending operations under lock
    std::queue<PendingOperation> ops;
    {
        std::lock_guard<std::mutex> lock(eventLoop->operation_queue_mutex_);
        std::swap(ops, eventLoop->pending_operations_);
    }

    // Process operations one by one on the CURLEventLoop thread
    while (!ops.empty()) {
        auto& op = ops.front();

        bool op_success = eventLoop->processOperation(op);

        // Signal completion to the waiting caller
        if (op.success_flag) *op.success_flag = op_success;
        if (op.done_flag) *op.done_flag = true;
        if (op.done_cv) op.done_cv->notify_one();

        ops.pop();
    }
}

// Process a single pending operation on the CURLEventLoop thread.
// All curl_multi_* calls happen here — single-threaded access is guaranteed.
bool CURLEventLoop::processOperation(const PendingOperation& op) {
    switch (op.type) {
        case OperationType::AddHandle: {
            if (!multi_ || !op.handle) {
                Logger::error("Network", "processOperation AddHandle: null multi_ or handle");
                return false;
            }

            CURLMcode result = curl_multi_add_handle(multi_, op.handle);
            if (result != CURLM_OK) {
                Logger::error("Network", "Failed to add CURL handle: %s", curl_multi_strerror(result));
                return false;
            }

            // In EventDriven mode, CURL may call handleSocket() within curl_multi_add_handle()
            // to register socket monitoring. Since we're on the CURLEventLoop thread,
            // uv_poll_init/uv_poll_start are called on the correct thread.
            // CURL may also call handleTimer() to set up the timeout.

            // Kick off the handle: tell CURL there's a pending action
            if (mode_ == Mode::EventDriven) {
                int running_handles = 0;
                CURLMcode actionResult = curl_multi_socket_action(multi_, CURL_SOCKET_TIMEOUT, 0, &running_handles);
                if (actionResult != CURLM_OK) {
                    Logger::error("Network", "Failed to kick off CURL handle: %s", curl_multi_strerror(actionResult));
                    // Don't fail — the transfer may still proceed via the timer callback
                }
            }

            // Immediately process any already-completed messages (e.g., cache hits)
            processCURLMessages();
            return true;
        }

        case OperationType::RemoveHandle: {
            if (!multi_ || !op.handle) {
                Logger::error("Network", "processOperation RemoveHandle: null multi_ or handle");
                return false;
            }

            // Close the uv_poll_t handle if present in EventDriven mode
            auto it = active_handles_.find(op.handle);
            if (it != active_handles_.end()) {
                uv_poll_t* poll = it->second;

                // Remove from reverse map first
                handle_by_poll_.erase(poll);

                // Mark as closing to prevent callback execution (defense-in-depth)
                poll->data = reinterpret_cast<void*>(0x1);

                if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
                    uv_poll_stop(poll);
                    uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                        delete reinterpret_cast<uv_poll_t*>(h);
                    });
                }
                active_handles_.erase(it);
            }

            CURLMcode result = curl_multi_remove_handle(multi_, op.handle);
            if (result != CURLM_OK) {
                Logger::warn("Network", "Failed to remove CURL handle: %s (may have been removed already)",
                             curl_multi_strerror(result));
                // Don't fail — the handle may have been removed by removeAllHandles
            }

            return true;
        }

        case OperationType::RemoveAllHandles: {
            Logger::debug("Network", "processOperation RemoveAllHandles: removing %zu active handles",
                          active_handles_.size());

            // CRASH FIX: Collect handles into a separate vector BEFORE calling
            // curl_multi_remove_handle(). Reason: curl_multi_remove_handle() can
            // synchronously invoke handleSocket(CURL_POLL_REMOVE), which erases
            // entries from active_handles_ — invalidating the loop iterator.
            // This caused undefined behavior (skipped handles) and left the CURL
            // multi handle in a corrupted state, leading to SIGSEGV in subsequent
            // curl_multi_socket_action() calls.
            std::vector<CURL*> handlesToRemove;
            handlesToRemove.reserve(active_handles_.size());
            for (const auto& [handle, poll] : active_handles_) {
                handlesToRemove.push_back(handle);
            }

            // Remove all handles from CURL multi (prevents CURLMSG_DONE callbacks).
            // handleSocket(CURL_POLL_REMOVE) will fire for each handle and close
            // the associated uv_poll_t, erasing its entry from active_handles_.
            if (multi_) {
                for (CURL* handle : handlesToRemove) {
                    CURLMcode result = curl_multi_remove_handle(multi_, handle);
                    if (result != CURLM_OK) {
                        Logger::warn("Network", "Failed to remove handle from multi: %s", curl_multi_strerror(result));
                    }
                }
            }

            // Safety net: close any remaining poll handles that weren't cleaned
            // up by handleSocket(CURL_POLL_REMOVE) above.
            for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
                uv_poll_t* poll = it->second;

                // Remove from reverse map
                handle_by_poll_.erase(poll);

                // Mark as closing to prevent any callback execution
                poll->data = reinterpret_cast<void*>(0x1);

                if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
                    uv_poll_stop(poll);
                    uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                        delete reinterpret_cast<uv_poll_t*>(h);
                    });
                }
            }

            active_handles_.clear();
            handle_by_poll_.clear();
            return true;
        }
    }

    return false;
}

// ============================================================================
// Graceful shutdown — runs on the CURLEventLoop thread
// ============================================================================

void CURLEventLoop::performShutdown() {
    Logger::debug("Network", "performShutdown: closing all handles on CURLEventLoop thread");

    // Close all uv handles. After the last handle is closed, uv_run(UV_RUN_DEFAULT)
    // returns naturally. This avoids calling uv_stop() from a different thread.

    // 1. Close polling timer (SimplePolling mode)
    if (polling_timer_) {
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(polling_timer_))) {
            uv_timer_stop(polling_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(polling_timer_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_timer_t*>(h);
            });
        }
        polling_timer_ = nullptr;
    }

    // 2. Close timeout timer (EventDriven mode)
    if (timeout_timer_) {
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(timeout_timer_))) {
            uv_timer_stop(timeout_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(timeout_timer_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_timer_t*>(h);
            });
        }
        timeout_timer_ = nullptr;
    }

    // 3. Close all active poll handles
    for (auto& [handle, poll] : active_handles_) {
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
            uv_poll_stop(poll);
            uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_poll_t*>(h);
            });
        }
    }
    active_handles_.clear();
    handle_by_poll_.clear();

    // 4. Close the holder async handle (this allows uv_run to exit)
    if (holder_) {
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(holder_))) {
            uv_close(reinterpret_cast<uv_handle_t*>(holder_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_async_t*>(h);
            });
        }
        holder_ = nullptr;
    }

    // 5. Close operation_signal_
    // Safe to close from within onOperationSignal's callback — uv_close marks
    // the handle as UV_HANDLE_CLOSING and defers the actual close callback to
    // the next event loop iteration. The restriction is about calling uv_close
    // from within the handle's OWN close callback, not from its regular callback.
    // Without this, uv_run never exits because operation_signal_ keeps the loop alive.
    if (operation_signal_) {
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(operation_signal_))) {
            uv_close(reinterpret_cast<uv_handle_t*>(operation_signal_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_async_t*>(h);
            });
        }
        operation_signal_ = nullptr;
    }

    Logger::debug("Network", "performShutdown: all handles closed, uv_run will return naturally");
}

// ============================================================================
// libuv callbacks — all run on the CURLEventLoop thread
// ============================================================================

void CURLEventLoop::onSocketEvent(uv_poll_t* poll, int status, int events) {
    auto* eventLoop = static_cast<CURLEventLoop*>(poll->data);

    // Defense-in-depth: check if handle is marked for closing
    if (eventLoop == reinterpret_cast<CURLEventLoop*>(0x1)) {
        return;  // Handle is being destroyed, exit immediately
    }

    if (status < 0) {
        Logger::error("Network", "Socket event error: %s", uv_strerror(status));
        return;
    }

    if (!eventLoop || eventLoop->stopping_.load()) {
        return;
    }

    // All operations now happen on the CURLEventLoop thread — no lock needed for multi_ access
    if (!eventLoop->multi_) {
        return;
    }

    // CRASH FIX: Verify the poll handle is still tracked in the reverse map.
    // This catches the case where curl_multi_socket_action or handleSocket has
    // already removed this poll from active_handles_ (e.g. when a transfer
    // completes inside curl_multi_socket_action and libcurl calls
    // CURL_POLL_REMOVE synchronously, or when a preceding RemoveHandle
    // operation cleaned it up). Without this check, calling
    // curl_multi_socket_action with a stale socket fd can cause libcurl
    // to dereference a NULL pointer internally (SIGSEGV at offset 0x2c8).
    if (eventLoop->handle_by_poll_.find(poll) == eventLoop->handle_by_poll_.end()) {
        Logger::warn("Network", "onSocketEvent: poll handle %p no longer tracked, skipping stale event",
                     static_cast<void*>(poll));
        return;
    }

    // Obtain the socket file descriptor
    uv_os_fd_t fd = -1;
    if (uv_fileno(reinterpret_cast<uv_handle_t*>(poll), &fd) != 0) {
        Logger::error("Network", "Failed to get socket file descriptor");
        return;
    }

    // Map libuv events to CURL events
    int curl_events = 0;
    if (events & UV_READABLE) {
        curl_events |= CURL_CSELECT_IN;
    }
    if (events & UV_WRITABLE) {
        curl_events |= CURL_CSELECT_OUT;
    }

    // Notify CURL (non-blocking call, on the CURLEventLoop thread)
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(eventLoop->multi_, fd, curl_events, &running_handles);
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_socket_action failed: %s", curl_multi_strerror(result));
        return;
    }

    // Process completed messages
    if (!eventLoop->stopping_.load()) {
        eventLoop->processCURLMessages();
    }
}

void CURLEventLoop::onTimeout(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);

    if (!eventLoop || eventLoop->stopping_.load()) {
        return;
    }

    // All operations on the CURLEventLoop thread — no lock needed
    if (!eventLoop->multi_) {
        return;
    }

    // Notify CURL about a timeout (non-blocking call)
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(eventLoop->multi_, CURL_SOCKET_TIMEOUT, 0, &running_handles);
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_socket_action timeout failed: %s", curl_multi_strerror(result));
        return;
    }

    // Process completed messages
    if (!eventLoop->stopping_.load()) {
        eventLoop->processCURLMessages();
    }
}

// Simple polling callback (SimplePolling mode)
void CURLEventLoop::onPolling(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);

    if (!eventLoop || eventLoop->stopping_.load()) {
        return;
    }

    // All operations on the CURLEventLoop thread — no lock needed
    if (!eventLoop->multi_) {
        return;
    }

    // Execute CURL processing (non-blocking call)
    int running_handles = 0;
    CURLMcode result = curl_multi_perform(eventLoop->multi_, &running_handles);

    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_perform failed: %s", curl_multi_strerror(result));
        return;
    }

    // Process completed messages
    if (!eventLoop->stopping_.load()) {
        eventLoop->processCURLMessages();
    }
}

void CURLEventLoop::onClose(uv_handle_t* handle) {
    Logger::debug("Network", "uv_handle closed: %p", static_cast<void*>(handle));
}

// ============================================================================
// CURL callbacks — invoked from within curl_multi_* calls on the CURLEventLoop thread
// ============================================================================

int CURLEventLoop::handleSocket(CURL* handle, curl_socket_t s, int action, void* userp, void* /*socketp*/) {
    auto* eventLoop = static_cast<CURLEventLoop*>(userp);

    if (!eventLoop || !eventLoop->loop_) {
        Logger::error("Network", "handleSocket: Event loop or loop is null");
        return -1;
    }

    // All operations now happen on the CURLEventLoop thread.
    // uv_poll_init/uv_poll_start are safe to call on this thread.
    // No mutex needed for active_handles_ access.

    switch (action) {
        case CURL_POLL_IN:
        case CURL_POLL_OUT:
        case CURL_POLL_INOUT: {
            // Create or update the poll handle
            uv_poll_t* poll = nullptr;

            auto it = eventLoop->active_handles_.find(handle);
            if (it != eventLoop->active_handles_.end()) {
                poll = it->second;
            } else {
                // Create a new poll handle — safe because we're on the loop's thread
                poll = new uv_poll_t;
                int err = uv_poll_init(eventLoop->loop_, poll, static_cast<int>(s));
                if (err != 0) {
                    Logger::error("Network", "Failed to init poll for fd=%d: %s",
                                 static_cast<int>(s), uv_strerror(err));
                    delete poll;
                    // Don't abort curl_multi_add_handle — returning 0 lets libcurl
                    // drive the transfer via the timer callback (onTimeout) instead
                    // of event-driven socket monitoring. This is a safe degradation.
                    Logger::warn("Network", "Falling back to timer-driven I/O for fd=%d", static_cast<int>(s));
                    return 0;
                }
                eventLoop->handle_by_poll_[poll] = handle;
                poll->data = eventLoop;
                eventLoop->active_handles_[handle] = poll;
            }

            // Configure event monitoring
            int events = 0;
            if (action == CURL_POLL_IN || action == CURL_POLL_INOUT) {
                events |= UV_READABLE;
            }
            if (action == CURL_POLL_OUT || action == CURL_POLL_INOUT) {
                events |= UV_WRITABLE;
            }

            int err = uv_poll_start(poll, events, onSocketEvent);
            if (err != 0) {
                Logger::error("Network", "Failed to start poll for fd=%d: %s",
                             static_cast<int>(s), uv_strerror(err));
                // Clean up the poll handle that was registered above
                eventLoop->handle_by_poll_.erase(poll);
                eventLoop->active_handles_.erase(handle);
                poll->data = reinterpret_cast<void*>(0x1);
                uv_poll_stop(poll);
                uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                    delete reinterpret_cast<uv_poll_t*>(h);
                });
                // Don't abort curl_multi_add_handle — returning 0 lets libcurl
                // drive the transfer via the timer callback (onTimeout) instead
                // of event-driven socket monitoring. This is a safe degradation.
                Logger::warn("Network", "Falling back to timer-driven I/O for fd=%d", static_cast<int>(s));
                return 0;
            }

            break;
        }
        case CURL_POLL_REMOVE: {
            auto it = eventLoop->active_handles_.find(handle);
            if (it != eventLoop->active_handles_.end()) {
                uv_poll_t* poll = it->second;

                // Remove from reverse map first
                eventLoop->handle_by_poll_.erase(poll);

                // Mark handle as closing to prevent callback execution (defense-in-depth)
                poll->data = reinterpret_cast<void*>(0x1);

                uv_poll_stop(poll);
                uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                    delete reinterpret_cast<uv_poll_t*>(h);
                });

                eventLoop->active_handles_.erase(it);
            }
            // If handle not found, it was already removed (e.g. by removeHandle or removeAllHandles).
            // This is safe — just a no-op.
            break;
        }
        default:
            Logger::error("Network", "Unknown CURL socket action: %d", action);
            return -1;
    }

    return 0;
}

int CURLEventLoop::handleTimer(CURLM* /*multi*/, long timeout_ms, void* userp) {
    auto* eventLoop = static_cast<CURLEventLoop*>(userp);

    if (!eventLoop || !eventLoop->loop_) {
        Logger::error("Network", "handleTimer: Event loop or loop is null");
        return -1;
    }

    eventLoop->updateTimeout(timeout_ms);
    return 0;
}

// ============================================================================
// Message processing — runs exclusively on the CURLEventLoop thread
// ============================================================================

// External function declaration (implemented in http_file_source_harmony.cpp)
extern "C" void handleHTTPRequestResult(void* request, CURLcode code);

void CURLEventLoop::processCURLMessages() {
    // Fast fail if stopping
    if (stopping_.load(std::memory_order_acquire)) {
        return;
    }

    CURLMsg* msg;
    int msgs_left;

    // All curl_multi_* operations are now on the CURLEventLoop thread — no lock needed
    while ((msg = curl_multi_info_read(multi_, &msgs_left))) {
        if (msg->msg == CURLMSG_DONE) {
            CURL* handle = msg->easy_handle;
            CURLcode result = msg->data.result;

            // Verify handle is still valid (may have been removed during shutdown)
            if (active_handles_.find(handle) == active_handles_.end()) {
                // Handle has been removed, skip processing
                Logger::debug("Network", "Skipping CURLMSG_DONE for removed handle");
                continue;
            }

            // Increment request count to track in-flight requests
            incrementRequestCount();

            // Diagnostics: fetch the request URL
            char* url = nullptr;
            curl_easy_getinfo(handle, CURLINFO_EFFECTIVE_URL, &url);

            // Diagnostics: gather response info
            long response_code = 0;
            curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &response_code);

            double total_time = 0;
            curl_easy_getinfo(handle, CURLINFO_TOTAL_TIME, &total_time);

            if (result != CURLE_OK) {
                Logger::warn("Network", "Request FAILED:");
                Logger::warn("Network", "  URL: %s", url ? url : "unknown");
                Logger::warn("Network", "  Error: %s", curl_easy_strerror(result));
                Logger::warn("Network", "  Time: %.2f seconds", total_time);
            }

            // Retrieve the HTTPRequest and propagate the result
            void* privateData = nullptr;
            curl_easy_getinfo(handle, CURLINFO_PRIVATE, &privateData);

            // Validate privateData before invoking the callback
            if (privateData) {
                // Double-check the pointer validity
                void* verify = nullptr;
                CURLcode info_result = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &verify);

                if (info_result == CURLE_OK && verify == privateData) {
                    // Process result directly on this (CURLEventLoop) thread.
                    // handleHTTPRequestResult uses AsyncTask to dispatch the callback
                    // to the correct RunLoop thread safely.
                    handleHTTPRequestResult(privateData, result);
                } else {
                    Logger::error("Network", "privateData validity check failed (URL: %s, expected=%p, actual=%p)",
                                 url ? url : "unknown", privateData, verify);
                }
            } else {
                Logger::error("Network", "No private data found for completed handle (URL: %s)",
                             url ? url : "unknown");
            }

            // Decrement request count
            decrementRequestCount();
        }
    }
}

// ============================================================================
// Timeout management — runs on the CURLEventLoop thread
// ============================================================================

void CURLEventLoop::updateTimeout(long timeout_ms) {
    if (!loop_ || stopping_.load()) {
        return;
    }

    // All callers are on the CURLEventLoop thread — no lock needed

    if (timeout_ms < 0) {
        // Stop the timer
        if (timeout_timer_) {
            int err = uv_timer_stop(timeout_timer_);
            if (err != 0) {
                Logger::warn("Network", "Failed to stop timer: %s", uv_strerror(err));
            }
        }
    } else {
        // Configure the timer
        if (!timeout_timer_) {
            timeout_timer_ = new uv_timer_t;
            timeout_timer_->data = this;

            int err = uv_timer_init(loop_, timeout_timer_);
            if (err != 0) {
                Logger::error("Network", "Failed to initialize timer: %s", uv_strerror(err));
                delete timeout_timer_;
                timeout_timer_ = nullptr;
                return;
            }
        }

        int err = uv_timer_start(timeout_timer_, onTimeout, timeout_ms, 0);
        if (err != 0) {
            Logger::error("Network", "Failed to start timer: %s", uv_strerror(err));
        }
    }
}

void CURLEventLoop::logError(const char* function, const char* error) {
    Logger::error("Network", "Error in %s: %s", function, error);
}

} // namespace harmony
} // namespace mbgl
