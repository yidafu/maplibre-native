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
    
    stopping_.store(true);
    
    {
        std::lock_guard<std::mutex> lock(mutex_);
        
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
        for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
            uv_poll_t* poll = it->second;
            if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
                uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
            }
        }
        active_handles_.clear();
    }
    
    // Close the holder handle to stop the loop
    if (holder_) {
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), [](uv_handle_t* h) {
            delete reinterpret_cast<uv_async_t*>(h);
        });
        holder_ = nullptr;
    }
    
    // Wait for the thread to finish
    if (thread_ && thread_->joinable()) {
        thread_->join();
    }
    
    thread_.reset();
    running_.store(false);
}

bool CURLEventLoop::addHandle(CURL* handle) {
    if (!handle || !multi_ || !running_.load()) {
        Logger::error("Network", "Invalid parameters or event loop not running");
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    CURLMcode result = curl_multi_add_handle(multi_, handle);
    if (result != CURLM_OK) {
        Logger::error("Network", "Failed to add CURL handle: %s", curl_multi_strerror(result));
        return false;
    }
    
    // In event-driven mode, prompt CURL to process this handle
    if (mode_ == Mode::EventDriven) {
        int running_handles = 0;
        result = curl_multi_socket_action(multi_, CURL_SOCKET_TIMEOUT, 0, &running_handles);
        if (result != CURLM_OK) {
            Logger::error("Network", "Failed to kick off CURL handle: %s", curl_multi_strerror(result));
        }
        processCURLMessages();
    }
    
    return true;
}

bool CURLEventLoop::removeHandle(CURL* handle) {
    if (!handle || !multi_) {
        Logger::error("Network", "Invalid parameters");
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    // Remove the libuv poll handle
    auto it = active_handles_.find(handle);
    if (it != active_handles_.end()) {
        uv_poll_t* poll = it->second;
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
            uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
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

// getActiveHandleCount removed; no longer required

void CURLEventLoop::eventLoopThread() {
    uv_run(loop_, UV_RUN_DEFAULT);
}

// libuv callback function
void CURLEventLoop::onSocketEvent(uv_poll_t* poll, int status, int events) {
    auto* eventLoop = static_cast<CURLEventLoop*>(poll->data);
    
    if (status < 0) {
        Logger::error("Network", "Socket event error: %s", uv_strerror(status));
        return;
    }
    
    // 🔒 Thread-safety: guard access to multi_ with a lock
    std::lock_guard<std::mutex> lock(eventLoop->mutex_);
    
    if (!eventLoop->multi_) {
        return;
    }
    
    // Obtain the socket file descriptor
    uv_os_fd_t fd;
    uv_fileno(reinterpret_cast<uv_handle_t*>(poll), &fd);
    
    // Map libuv events to CURL events
    int curl_events = 0;
    if (events & UV_READABLE) {
        curl_events |= CURL_CSELECT_IN;
    }
    if (events & UV_WRITABLE) {
        curl_events |= CURL_CSELECT_OUT;
    }
    
    // Notify CURL
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(eventLoop->multi_, fd, curl_events, &running_handles);
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_socket_action failed: %s", curl_multi_strerror(result));
        return;
    }
    
    // Handle CURL messages (lock already held)
    eventLoop->processCURLMessages();
}

void CURLEventLoop::onTimeout(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);
    
    // 🔒 Thread-safety: guard access to multi_ with a lock
    std::lock_guard<std::mutex> lock(eventLoop->mutex_);
    
    if (!eventLoop->multi_) {
        return;
    }
    
    // Notify CURL about a timeout
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(eventLoop->multi_, CURL_SOCKET_TIMEOUT, 0, &running_handles);
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_socket_action timeout failed: %s", curl_multi_strerror(result));
        return;
    }
    
    // Handle CURL messages (lock already held)
    eventLoop->processCURLMessages();
}

// Simple polling callback (SimplePolling mode)
void CURLEventLoop::onPolling(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);
    
    if (eventLoop->stopping_.load()) {
        return;
    }
    
    // 🔒 Thread-safety: guard access to multi_ with a lock
    std::lock_guard<std::mutex> lock(eventLoop->mutex_);
    
    if (!eventLoop->multi_) {
        return;
    }
    
    // Execute CURL processing
    int running_handles = 0;
    CURLMcode result = curl_multi_perform(eventLoop->multi_, &running_handles);
    
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_perform failed: %s", curl_multi_strerror(result));
        return;
    }
    
    // Process completed requests (lock already held)
    eventLoop->processCURLMessages();
}

void CURLEventLoop::onClose(uv_handle_t* handle) {
    // Poll handle closed - no logging needed
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
            // Create or update the poll handle
            uv_poll_t* poll = nullptr;
            
            // Check whether it already exists
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
            // Remove the poll handle
            auto it = eventLoop->active_handles_.find(handle);
            if (it != eventLoop->active_handles_.end()) {
                uv_poll_t* poll = it->second;
                uv_poll_stop(poll);
                uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
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
    CURLMsg* msg;
    int msgs_left;
    
    while ((msg = curl_multi_info_read(multi_, &msgs_left))) {
        if (msg->msg == CURLMSG_DONE) {
            CURL* handle = msg->easy_handle;
            CURLcode result = msg->data.result;
            
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
            
            // 🔒 CRASH FIX: strengthen privateData validation
            if (privateData) {
                // Double-check that the handle is still valid before invoking the callback.
                // Note: not a perfect guard against use-after-free, but lowers the risk.
                
                // Attempt to retrieve it again and ensure the pointer matches
                void* verify = nullptr;
                CURLcode info_result = curl_easy_getinfo(handle, CURLINFO_PRIVATE, &verify);
                
                if (info_result == CURLE_OK && verify == privateData) {
                    // Invoke the external function to process the result
                    handleHTTPRequestResult(privateData, result);
                } else {
                    Logger::error("Network", "❌ privateData validity check failed (URL: %s, expected=%p, actual=%p)", 
                                 url ? url : "unknown", privateData, verify);
                }
            } else {
                Logger::error("Network", "❌ No private data found for completed handle (URL: %s)", url ? url : "unknown");
            }
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
