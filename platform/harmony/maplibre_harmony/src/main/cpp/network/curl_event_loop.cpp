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
    , holder_(nullptr) {
    
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
    
    // Create the CURL multi handle
    multi_ = curl_multi_init();
    if (!multi_) {
        Logger::error("Network", "Failed to initialize CURL multi handle");
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), nullptr);
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
        delete holder_;
        holder_ = nullptr;
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
    
    // Release the polling timer if present
    if (polling_timer_) {
        delete polling_timer_;
        polling_timer_ = nullptr;
    }
    
    // Release the holder handle if necessary
    if (holder_) {
        delete holder_;
        holder_ = nullptr;
    }
    
    // Tear down the libuv event loop
    if (loop_) {
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
    }
}

void CURLEventLoop::start() {
    std::lock_guard<std::mutex> lock(mutex_);
    
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
    
    if (loop_) {
        Logger::debug("Network", "Issuing uv_stop on loop %p", static_cast<void*>(loop_));
        uv_stop(loop_);
        if (holder_) {
            Logger::debug("Network", "Waking loop via uv_async_send before shutdown");
            uv_async_send(holder_);
        }
    } else {
        Logger::warn("Network", "Loop pointer is null during stop");
    }
    
    {
        std::lock_guard<std::mutex> lock(mutex_);
        
        Logger::debug("Network", "Closing timers (polling_timer_=%p, timeout_timer_=%p)",
                      static_cast<void*>(polling_timer_), static_cast<void*>(timeout_timer_));
        
        // Stop and clean up the polling timer
        if (polling_timer_) {
            uv_timer_stop(polling_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(polling_timer_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_timer_t*>(h);
            });
            polling_timer_ = nullptr;
        }
        
        // Stop and clean up the timeout timer
        if (timeout_timer_) {
            uv_timer_stop(timeout_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(timeout_timer_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_timer_t*>(h);
            });
            timeout_timer_ = nullptr;
        }
        
        // Close all active handles
        Logger::debug("Network", "Closing %zu active poll handles", active_handles_.size());
        for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
            uv_poll_t* poll = it->second;
            if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
                Logger::debug("Network", "Closing active poll handle");
                uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
            }
        }
        active_handles_.clear();
    }
    
    // Close the holder handle to stop the loop
    if (holder_) {
        Logger::debug("Network", "Closing holder async handle");
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), [](uv_handle_t* h) {
            delete reinterpret_cast<uv_async_t*>(h);
        });
        holder_ = nullptr;
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

bool CURLEventLoop::addHandle(CURL* handle) {
    if (!handle || !multi_ || !running_.load()) {
        Logger::error("Network", "Invalid parameters or event loop not running");
        return false;
    }

    Logger::debug("Network", "addHandle called on thread %llu (handle=%p)",
                  static_cast<unsigned long long>(std::hash<std::thread::id>{}(std::this_thread::get_id())),
                  static_cast<void*>(handle));

    // 🔒 THREAD SAFETY: Copy multi handle to minimize lock time
    CURLM* multiCopy = nullptr;
    {
        std::lock_guard<std::mutex> lock(mutex_);

        if (!multi_) {
            Logger::error("Network", "Multi handle is null");
            return false;
        }

        CURLMcode result = curl_multi_add_handle(multi_, handle);
        if (result != CURLM_OK) {
            Logger::error("Network", "Failed to add CURL handle: %s", curl_multi_strerror(result));
            return false;
        }
        multiCopy = multi_;
    }

    // 🔒 NON-BLOCKING: Process outside lock to prevent deadlock
    if (mode_ == Mode::EventDriven) {
        int running_handles = 0;
        CURLMcode result = curl_multi_socket_action(multiCopy, CURL_SOCKET_TIMEOUT, 0, &running_handles);
        if (result != CURLM_OK) {
            Logger::error("Network", "Failed to kick off CURL handle: %s", curl_multi_strerror(result));
        }

        // 🔒 CRASH FIX: Process messages directly instead of creating detached threads
        // Issue: Creating detached threads with raw pointers caused use-after-free crashes
        // Solution: Process messages directly on this thread. This is safe because:
        // 1. HTTPRequest objects are alive during processCURLMessages execution
        // 2. handleResult uses AsyncTask for thread-safe callback dispatch
        // 3. Eliminates race conditions from detached thread lifetime issues
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (multi_ && !stopping_.load()) {
                processCURLMessages();
            }
        }
    }

    return true;
}

bool CURLEventLoop::removeHandle(CURL* handle) {
    if (!handle || !multi_) {
        Logger::error("Network", "Invalid parameters");
        return false;
    }
    
    Logger::debug("Network", "removeHandle called on thread %llu (handle=%p)",
                  static_cast<unsigned long long>(std::hash<std::thread::id>{}(std::this_thread::get_id())),
                  static_cast<void*>(handle));

    std::lock_guard<std::mutex> lock(mutex_);
    
    // 🔒 ENHANCED FIX: Safer poll handle removal with lifecycle protection
    auto it = active_handles_.find(handle);
    if (it != active_handles_.end()) {
        uv_poll_t* poll = it->second;

        // Mark as closing to prevent callback execution
        poll->data = reinterpret_cast<void*>(0x1);

        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
            uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                // Safe cleanup after close completes
                delete reinterpret_cast<uv_poll_t*>(h);
            });
        }
        active_handles_.erase(it);
    }
    
    // Remove the CURL handle
    CURLMcode result = curl_multi_remove_handle(multi_, handle);
    if (result != CURLM_OK) {
        Logger::error("Network", "Failed to remove CURL handle: %s", curl_multi_strerror(result));
        return false;
    }

    return true;
}

void CURLEventLoop::removeAllHandles() {
    // 🔒 CRASH FIX: Remove all handles before shutdown to prevent callbacks on destroyed objects
    //
    // Issue: When HTTPFileSource::Impl destructor runs while network requests are still pending,
    // the curlEventLoop->stop() call doesn't immediately prevent CURL from completing requests.
    // This leads to use-after-free when processCURLMessages tries to access destroyed HTTPRequest objects.
    //
    // Solution: Remove all handles from the CURL multi handle before stopping the event loop.
    // This prevents CURL from invoking any completion callbacks during shutdown.
    // Additionally, wait for in-flight requests to complete.

    std::lock_guard<std::mutex> lock(mutex_);

    Logger::debug("Network", "removeAllHandles: removing %zu active handles, %zu in-flight requests",
                  active_handles_.size(), activeRequestCount_.load(std::memory_order_acquire));

    // First, remove all handles from CURL multi (this prevents CURLMSG_DONE callbacks)
    if (multi_) {
        for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
            CURL* handle = it->first;
            CURLMcode result = curl_multi_remove_handle(multi_, handle);
            if (result != CURLM_OK) {
                Logger::warn("Network", "Failed to remove handle from multi: %s", curl_multi_strerror(result));
            }
        }
    }

    // Then close all poll handles (safely, without triggering callbacks)
    for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
        uv_poll_t* poll = it->second;

        // Mark as closing to prevent any callback execution
        poll->data = reinterpret_cast<void*>(0x1);

        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
            uv_poll_stop(poll);
            uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_poll_t*>(h);
            });
        }
    }

    // Clear the map
    active_handles_.clear();

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

// getActiveHandleCount removed; no longer required

void CURLEventLoop::eventLoopThread() {
    const auto threadId = static_cast<unsigned long long>(std::hash<std::thread::id>{}(std::this_thread::get_id()));
    Logger::info("Network", "CURLEventLoop thread start (id=%llu)", threadId);
    uv_run(loop_, UV_RUN_DEFAULT);
    Logger::info("Network", "CURLEventLoop thread exit (id=%llu)", threadId);
}

// libuv callback function
void CURLEventLoop::onSocketEvent(uv_poll_t* poll, int status, int events) {
    auto* eventLoop = static_cast<CURLEventLoop*>(poll->data);

    // 🔒 CRITICAL FIX: Check if handle is marked for closing (thread safety)
    if (eventLoop == reinterpret_cast<CURLEventLoop*>(0x1)) {
        return;  // Handle is being destroyed, exit immediately
    }

    if (status < 0) {
        Logger::error("Network", "Socket event error: %s", uv_strerror(status));
        return;
    }

    // 🔒 ENHANCED THREAD SAFETY: Early validation and non-blocking processing
    if (!eventLoop || eventLoop->stopping_.load()) {
        return;
    }

    // Copy necessary data to avoid holding lock during network operations
    CURLM* multiCopy = nullptr;
    uv_os_fd_t fd = -1;

    {
        std::lock_guard<std::mutex> lock(eventLoop->mutex_);

        if (!eventLoop->multi_) {
            return;
        }

        multiCopy = eventLoop->multi_;

        // Obtain the socket file descriptor safely
        if (uv_fileno(reinterpret_cast<uv_handle_t*>(poll), &fd) != 0) {
            Logger::error("Network", "Failed to get socket file descriptor");
            return;
        }
    }

    // Map libuv events to CURL events
    int curl_events = 0;
    if (events & UV_READABLE) {
        curl_events |= CURL_CSELECT_IN;
    }
    if (events & UV_WRITABLE) {
        curl_events |= CURL_CSELECT_OUT;
    }

    // Notify CURL (non-blocking call)
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(multiCopy, fd, curl_events, &running_handles);
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_socket_action failed: %s", curl_multi_strerror(result));
        return;
    }

    // 🔒 CRASH FIX: Process messages directly on this thread instead of detached thread
    // Issue: Detached threads with raw pointers caused use-after-free crashes
    // Solution: Process messages directly. Safe because:
    // 1. HTTPRequest objects are alive during this function execution
    // 2. handleResult uses AsyncTask for proper thread dispatch
    {
        std::lock_guard<std::mutex> lock(eventLoop->mutex_);
        if (eventLoop->multi_ && !eventLoop->stopping_.load()) {
            eventLoop->processCURLMessages();
        }
    }
}

void CURLEventLoop::onTimeout(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);

    // 🔒 ENHANCED THREAD SAFETY: Early validation
    if (!eventLoop || eventLoop->stopping_.load()) {
        return;
    }

    // Copy multi handle to avoid holding lock during network operation
    CURLM* multiCopy = nullptr;
    {
        std::lock_guard<std::mutex> lock(eventLoop->mutex_);

        if (!eventLoop->multi_) {
            return;
        }
        multiCopy = eventLoop->multi_;
    }

    // Notify CURL about a timeout (non-blocking call)
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(multiCopy, CURL_SOCKET_TIMEOUT, 0, &running_handles);
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_socket_action timeout failed: %s", curl_multi_strerror(result));
        return;
    }

    // 🔒 CRASH FIX: Process messages directly on this thread instead of detached thread
    {
        std::lock_guard<std::mutex> lock(eventLoop->mutex_);
        if (eventLoop->multi_ && !eventLoop->stopping_.load()) {
            eventLoop->processCURLMessages();
        }
    }
}

// Simple polling callback (SimplePolling mode)
void CURLEventLoop::onPolling(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);

    if (!eventLoop || eventLoop->stopping_.load()) {
        return;
    }

    // Copy multi handle to minimize lock contention
    CURLM* multiCopy = nullptr;
    {
        std::lock_guard<std::mutex> lock(eventLoop->mutex_);

        if (!eventLoop->multi_) {
            return;
        }
        multiCopy = eventLoop->multi_;
    }

    // Execute CURL processing (non-blocking call)
    int running_handles = 0;
    CURLMcode result = curl_multi_perform(multiCopy, &running_handles);

    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_perform failed: %s", curl_multi_strerror(result));
        return;
    }

    // 🔒 CRASH FIX: Process messages directly on this thread instead of detached thread
    {
        std::lock_guard<std::mutex> lock(eventLoop->mutex_);
        if (eventLoop->multi_ && !eventLoop->stopping_.load()) {
            eventLoop->processCURLMessages();
        }
    }
}

void CURLEventLoop::onClose(uv_handle_t* handle) {
    Logger::debug("Network", "uv_handle closed: %p", static_cast<void*>(handle));
}

// CURL callback helpers
int CURLEventLoop::handleSocket(CURL* handle, curl_socket_t s, int action, void* userp, void* /*socketp*/) {
    auto* eventLoop = static_cast<CURLEventLoop*>(userp);
    
    if (!eventLoop || !eventLoop->loop_) {
        Logger::error("Network", "Event loop or loop is null");
        return -1;
    }
    
    switch (action) {
        case CURL_POLL_IN:
        case CURL_POLL_OUT:
        case CURL_POLL_INOUT: {
            // 🔒 CRITICAL FIX: Add thread synchronization for active_handles_ access
            std::lock_guard<std::mutex> lock(eventLoop->mutex_);

            // Create or update the poll handle
            uv_poll_t* poll = nullptr;

            // Check whether it already exists (now thread-safe)
            auto it = eventLoop->active_handles_.find(handle);
            if (it != eventLoop->active_handles_.end()) {
                poll = it->second;
            } else {
                // Create a new poll handle
                poll = new uv_poll_t;
                int err = uv_poll_init(eventLoop->loop_, poll, static_cast<int>(s));
                if (err != 0) {
                    Logger::error("Network", "Failed to init poll handle: %s", uv_strerror(err));
                    delete poll;
                    return -1;
                }
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
                Logger::error("Network", "Failed to start poll: %s", uv_strerror(err));
                return -1;
            }
            
            break;
        }
        case CURL_POLL_REMOVE: {
            // 🔒 CRITICAL FIX: Thread-safe poll handle removal with lifecycle protection
            std::lock_guard<std::mutex> lock(eventLoop->mutex_);

            auto it = eventLoop->active_handles_.find(handle);
            if (it != eventLoop->active_handles_.end()) {
                uv_poll_t* poll = it->second;

                // Mark handle as closing to prevent callback execution
                poll->data = reinterpret_cast<void*>(0x1);

                uv_poll_stop(poll);
                uv_close(reinterpret_cast<uv_handle_t*>(poll), [](uv_handle_t* h) {
                    // Only delete after close completes
                    delete reinterpret_cast<uv_poll_t*>(h);
                });

                eventLoop->active_handles_.erase(it);
            }
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
        Logger::error("Network", "Event loop or loop is null");
        return -1;
    }
    
    eventLoop->updateTimeout(timeout_ms);
    return 0;
}

// External function declaration (implemented in http_file_source_harmony.cpp)
extern "C" void handleHTTPRequestResult(void* request, CURLcode code);

void CURLEventLoop::processCURLMessages() {
    // 🔒 Fast fail if stopping
    if (stopping_.load(std::memory_order_acquire)) {
        return;
    }

    CURLMsg* msg;
    int msgs_left;

    while ((msg = curl_multi_info_read(multi_, &msgs_left))) {
        if (msg->msg == CURLMSG_DONE) {
            CURL* handle = msg->easy_handle;
            CURLcode result = msg->data.result;

            // 🔒 Enhanced check: verify handle is still valid
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (active_handles_.find(handle) == active_handles_.end()) {
                    // Handle has been removed, skip processing
                    Logger::debug("Network", "Skipping CURLMSG_DONE for removed handle");
                    continue;
                }
            }

            // Increment request count to track in-flight requests
            incrementRequestCount();

            // 🔍 Diagnostics: fetch the request URL
            char* url = nullptr;
            curl_easy_getinfo(handle, CURLINFO_EFFECTIVE_URL, &url);

            // 🔍 Diagnostics: gather response info
            long response_code = 0;
            curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &response_code);

            double total_time = 0;
            curl_easy_getinfo(handle, CURLINFO_TOTAL_TIME, &total_time);

            if (result != CURLE_OK) {
                Logger::warn("Network", "❌ Request FAILED:");
                Logger::warn("Network", "  URL: %s", url ? url : "unknown");
                Logger::warn("Network", "  Error: %s", curl_easy_strerror(result));
                Logger::warn("Network", "  Time: %.2f seconds", total_time);
            }

            // Retrieve the HTTPRequest and propagate the result
            void* privateData = nullptr;
            curl_easy_getinfo(handle, CURLINFO_PRIVATE, &privateData);

            // 🔒 CRASH FIX: strengthen privateData validation and ensure object lifetime
            if (privateData) {
                // Double-check that the handle is still valid before invoking the callback.
                // Note: not a perfect guard against use-after-free, but lowers the risk.

                // Attempt to retrieve it again and ensure the pointer matches
                void* verify = nullptr;
                CURLcode info_result = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &verify);

                if (info_result == CURLE_OK && verify == privateData) {
                    // 🔒 CRASH FIX: Process result directly instead of detached thread
                    //
                    // Issue: Creating detached threads with raw HTTPRequest* pointers caused
                    // use-after-free crashes when the HTTPRequest was destroyed before the
                    // detached thread executed.
                    //
                    // Solution: Process the result directly on this thread (network thread).
                    // This is safe because:
                    // 1. HTTPRequest objects are alive during processCURLMessages execution
                    // 2. handleHTTPRequestResult uses AsyncTask which properly dispatches
                    //    the callback to the correct RunLoop thread (main/UI thread)
                    // 3. Eliminates race conditions from detached thread lifetime issues

                    // Process result directly using external function (void* to avoid needing full type)
                    handleHTTPRequestResult(privateData, result);
                } else {
                    Logger::error("Network", "❌ privateData validity check failed (URL: %s, expected=%p, actual=%p)",
                                 url ? url : "unknown", privateData, verify);
                }
            } else {
                Logger::error("Network", "❌ No private data found for completed handle (URL: %s)", url ? url : "unknown");
            }

            // Decrement request count (always decrement after processing attempt)
            decrementRequestCount();
        }
    }
}

void CURLEventLoop::updateTimeout(long timeout_ms) {
    if (!loop_ || stopping_.load()) {
        return;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
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

void CURLEventLoop::cleanupHandles() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
        uv_poll_t* poll = it->second;
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
            uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
        }
    }
    active_handles_.clear();
}

void CURLEventLoop::logError(const char* function, const char* error) {
    Logger::error("Network", "Error in %s: %s", function, error);
}

} // namespace harmony
} // namespace mbgl
