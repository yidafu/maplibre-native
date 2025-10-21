#include "curl_event_loop.hpp"

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

// HarmonyOS HiLog integration
#include <hilog/log.h>

#define CURL_LOG_DEBUG(...) OH_LOG_Print(LOG_APP, LOG_DEBUG, 0x0000, "CURLEventLoop", __VA_ARGS__)
#define CURL_LOG_INFO(...) OH_LOG_Print(LOG_APP, LOG_INFO, 0x0000, "CURLEventLoop", __VA_ARGS__)
#define CURL_LOG_WARN(...) OH_LOG_Print(LOG_APP, LOG_WARN, 0x0000, "CURLEventLoop", __VA_ARGS__)
#define CURL_LOG_ERROR(...) OH_LOG_Print(LOG_APP, LOG_ERROR, 0x0000, "CURLEventLoop", __VA_ARGS__)

namespace mbgl {
namespace harmony {

CURLEventLoop::CURLEventLoop() 
    : loop_(nullptr)
    , thread_(nullptr)
    , running_(false)
    , stopping_(false)
    , multi_(nullptr)
    , timeout_timer_(nullptr)
    , holder_(nullptr) {
    
    CURL_LOG_INFO("========== CURLEventLoop Constructor START ==========");
    
    // 创建独立的libuv事件循环
    loop_ = new uv_loop_t;
    if (int err = uv_loop_init(loop_); err != 0) {
        CURL_LOG_ERROR("Failed to initialize libuv loop: %{public}s", uv_strerror(err));
        delete loop_;
        loop_ = nullptr;
        throw std::runtime_error("Failed to initialize libuv loop: " + std::string(uv_strerror(err)));
    }
    CURL_LOG_INFO("libuv loop initialized successfully");
    
    // 创建holder async handle以保持loop运行
    holder_ = new uv_async_t;
    if (int err = uv_async_init(loop_, holder_, [](uv_async_t*) {}); err != 0) {
        CURL_LOG_ERROR("Failed to initialize holder async: %{public}s", uv_strerror(err));
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
        delete holder_;
        holder_ = nullptr;
        throw std::runtime_error("Failed to initialize holder async: " + std::string(uv_strerror(err)));
    }
    CURL_LOG_INFO("Holder async initialized successfully");
    
    // 创建CURL multi handle
    multi_ = curl_multi_init();
    if (!multi_) {
        CURL_LOG_ERROR("Failed to initialize CURL multi handle");
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), nullptr);
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
        delete holder_;
        holder_ = nullptr;
        throw std::runtime_error("Failed to initialize CURL multi handle");
    }
    CURL_LOG_INFO("CURL multi handle initialized successfully");
    
    // 设置CURL回调
    curl_multi_setopt(multi_, CURLMOPT_SOCKETFUNCTION, handleSocket);
    curl_multi_setopt(multi_, CURLMOPT_SOCKETDATA, this);
    curl_multi_setopt(multi_, CURLMOPT_TIMERFUNCTION, handleTimer);
    curl_multi_setopt(multi_, CURLMOPT_TIMERDATA, this);
    
    CURL_LOG_INFO("========== CURLEventLoop Constructor COMPLETE ==========");
}

CURLEventLoop::~CURLEventLoop() {
    CURL_LOG_INFO("========== CURLEventLoop Destructor START ==========");
    
    // 确保事件循环已停止
    if (running_.load()) {
        stop();
    }
    
    // 清理CURL multi handle
    if (multi_) {
        CURL_LOG_DEBUG("Cleaning up CURL multi handle...");
        curl_multi_cleanup(multi_);
        multi_ = nullptr;
        CURL_LOG_DEBUG("CURL multi handle cleaned up");
    }
    
    // 清理holder（如果还没被清理）
    if (holder_) {
        CURL_LOG_DEBUG("Cleaning up remaining holder...");
        delete holder_;
        holder_ = nullptr;
    }
    
    // 清理libuv事件循环
    if (loop_) {
        CURL_LOG_DEBUG("Cleaning up libuv loop...");
        uv_loop_close(loop_);
        delete loop_;
        loop_ = nullptr;
        CURL_LOG_DEBUG("libuv loop cleaned up");
    }
    
    CURL_LOG_INFO("========== CURLEventLoop Destructor COMPLETE ==========");
}

void CURLEventLoop::start() {
    CURL_LOG_INFO("========== start() START ==========");
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (running_.load()) {
        CURL_LOG_WARN("Event loop is already running");
        return;
    }
    
    if (!loop_ || !multi_) {
        CURL_LOG_ERROR("Event loop or multi handle is null");
        throw std::runtime_error("Event loop or multi handle is null");
    }
    
    running_.store(true);
    stopping_.store(false);
    
    // 启动事件循环线程
    thread_ = std::make_unique<std::thread>(&CURLEventLoop::eventLoopThread, this);
    
    CURL_LOG_INFO("Event loop thread started");
    CURL_LOG_INFO("========== start() COMPLETE ==========");
}

void CURLEventLoop::stop() {
    CURL_LOG_INFO("========== stop() START ==========");
    
    if (!running_.load()) {
        CURL_LOG_WARN("Event loop is not running");
        return;
    }
    
    // 设置停止标志
    stopping_.store(true);
    
    {
        std::lock_guard<std::mutex> lock(mutex_);
        
        // 停止并清理timer
        if (timeout_timer_) {
            uv_timer_stop(timeout_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(timeout_timer_), [](uv_handle_t* h) {
                CURL_LOG_DEBUG("Timer closed");
                delete reinterpret_cast<uv_timer_t*>(h);
            });
            timeout_timer_ = nullptr;
            CURL_LOG_DEBUG("Timer close scheduled");
        }
        
        // 关闭所有active handles
        for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
            uv_poll_t* poll = it->second;
            if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
                uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
            }
        }
        active_handles_.clear();
        CURL_LOG_DEBUG("All active handles closed");
    }
    
    // 关闭holder handle以停止loop
    if (holder_) {
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), [](uv_handle_t* h) {
            CURL_LOG_DEBUG("Holder async closed");
            delete reinterpret_cast<uv_async_t*>(h);
        });
        holder_ = nullptr;
        CURL_LOG_DEBUG("Holder async close scheduled");
    }
    
    // 等待线程结束
    if (thread_ && thread_->joinable()) {
        CURL_LOG_DEBUG("Waiting for event loop thread to finish...");
        thread_->join();
        CURL_LOG_DEBUG("Event loop thread finished");
    }
    
    thread_.reset();
    running_.store(false);
    
    CURL_LOG_INFO("========== stop() COMPLETE ==========");
}

bool CURLEventLoop::addHandle(CURL* handle) {
    if (!handle || !multi_ || !running_.load()) {
        CURL_LOG_ERROR("Invalid parameters or event loop not running");
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    CURLMcode result = curl_multi_add_handle(multi_, handle);
    if (result != CURLM_OK) {
        CURL_LOG_ERROR("Failed to add CURL handle: %{public}s", curl_multi_strerror(result));
        return false;
    }
    
    CURL_LOG_DEBUG("CURL handle added successfully: %{public}p", handle);
    
    // 触发CURL开始处理这个句柄
    // 这会调用handleSocket回调来注册socket监听
    int running_handles = 0;
    result = curl_multi_socket_action(multi_, CURL_SOCKET_TIMEOUT, 0, &running_handles);
    if (result != CURLM_OK) {
        CURL_LOG_ERROR("Failed to kick off CURL handle: %{public}s", curl_multi_strerror(result));
    } else {
        CURL_LOG_DEBUG("CURL handle kicked off, running_handles=%{public}d", running_handles);
    }
    
    // 处理可能已完成的消息
    processCURLMessages();
    
    return true;
}

bool CURLEventLoop::removeHandle(CURL* handle) {
    if (!handle || !multi_) {
        CURL_LOG_ERROR("Invalid parameters");
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 移除libuv poll handle
    auto it = active_handles_.find(handle);
    if (it != active_handles_.end()) {
        uv_poll_t* poll = it->second;
        if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
            uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
        }
        active_handles_.erase(it);
    }
    
    // 移除CURL handle
    CURLMcode result = curl_multi_remove_handle(multi_, handle);
    if (result != CURLM_OK) {
        CURL_LOG_ERROR("Failed to remove CURL handle: %{public}s", curl_multi_strerror(result));
        return false;
    }
    
    CURL_LOG_DEBUG("CURL handle removed successfully: %{public}p", handle);
    return true;
}

// getActiveHandleCount方法已移除，不再需要

void CURLEventLoop::eventLoopThread() {
    CURL_LOG_INFO("Event loop thread started");
    
    // 运行事件循环
    int result = uv_run(loop_, UV_RUN_DEFAULT);
    
    CURL_LOG_INFO("Event loop thread finished with result: %{public}d", result);
}

// libuv回调函数
void CURLEventLoop::onSocketEvent(uv_poll_t* poll, int status, int events) {
    auto* eventLoop = static_cast<CURLEventLoop*>(poll->data);
    
    if (status < 0) {
        CURL_LOG_ERROR("Socket event error: %{public}s", uv_strerror(status));
        return;
    }
    
    if (!eventLoop->multi_) {
        CURL_LOG_WARN("Multi handle is null, ignoring socket event");
        return;
    }
    
    // 获取socket文件描述符
    uv_os_fd_t fd;
    uv_fileno(reinterpret_cast<uv_handle_t*>(poll), &fd);
    
    // 转换事件类型
    int curl_events = 0;
    if (events & UV_READABLE) {
        curl_events |= CURL_CSELECT_IN;
    }
    if (events & UV_WRITABLE) {
        curl_events |= CURL_CSELECT_OUT;
    }
    
    // 通知CURL
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(eventLoop->multi_, fd, curl_events, &running_handles);
    if (result != CURLM_OK) {
        CURL_LOG_ERROR("curl_multi_socket_action failed: %{public}s", curl_multi_strerror(result));
        return;
    }
    
    // 处理CURL消息
    eventLoop->processCURLMessages();
}

void CURLEventLoop::onTimeout(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);
    
    if (!eventLoop->multi_) {
        CURL_LOG_WARN("Multi handle is null, ignoring timeout");
        return;
    }
    
    // 通知CURL超时
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(eventLoop->multi_, CURL_SOCKET_TIMEOUT, 0, &running_handles);
    if (result != CURLM_OK) {
        CURL_LOG_ERROR("curl_multi_socket_action timeout failed: %{public}s", curl_multi_strerror(result));
        return;
    }
    
    // 处理CURL消息
    eventLoop->processCURLMessages();
}

void CURLEventLoop::onClose(uv_handle_t* handle) {
    CURL_LOG_DEBUG("Poll handle closed: %{public}p", handle);
}

// CURL回调函数
int CURLEventLoop::handleSocket(CURL* handle, curl_socket_t s, int action, void* userp, void* /*socketp*/) {
    auto* eventLoop = static_cast<CURLEventLoop*>(userp);
    
    if (!eventLoop || !eventLoop->loop_) {
        CURL_LOG_ERROR("Event loop or loop is null");
        return -1;
    }
    
    switch (action) {
        case CURL_POLL_IN:
        case CURL_POLL_OUT:
        case CURL_POLL_INOUT: {
            // 创建或更新poll handle
            uv_poll_t* poll = nullptr;
            
            // 检查是否已存在
            auto it = eventLoop->active_handles_.find(handle);
            if (it != eventLoop->active_handles_.end()) {
                poll = it->second;
            } else {
                // 创建新的poll handle
                poll = new uv_poll_t;
                int err = uv_poll_init(eventLoop->loop_, poll, static_cast<int>(s));
                if (err != 0) {
                    CURL_LOG_ERROR("Failed to init poll handle: %{public}s", uv_strerror(err));
                    delete poll;
                    return -1;
                }
                poll->data = eventLoop;
                eventLoop->active_handles_[handle] = poll;
            }
            
            // 设置事件监听
            int events = 0;
            if (action == CURL_POLL_IN || action == CURL_POLL_INOUT) {
                events |= UV_READABLE;
            }
            if (action == CURL_POLL_OUT || action == CURL_POLL_INOUT) {
                events |= UV_WRITABLE;
            }
            
            int err = uv_poll_start(poll, events, onSocketEvent);
            if (err != 0) {
                CURL_LOG_ERROR("Failed to start poll: %{public}s", uv_strerror(err));
                return -1;
            }
            
            break;
        }
        case CURL_POLL_REMOVE: {
            // 移除poll handle
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
            CURL_LOG_ERROR("Unknown CURL socket action: %{public}d", action);
            return -1;
    }
    
    return 0;
}

int CURLEventLoop::handleTimer(CURLM* /*multi*/, long timeout_ms, void* userp) {
    auto* eventLoop = static_cast<CURLEventLoop*>(userp);
    
    if (!eventLoop || !eventLoop->loop_) {
        CURL_LOG_ERROR("Event loop or loop is null");
        return -1;
    }
    
    eventLoop->updateTimeout(timeout_ms);
    return 0;
}

void CURLEventLoop::processCURLMessages() {
    CURLMsg* msg;
    int msgs_left;
    
    while ((msg = curl_multi_info_read(multi_, &msgs_left))) {
        if (msg->msg == CURLMSG_DONE) {
            CURL* handle = msg->easy_handle;
            CURLcode result = msg->data.result;
            
            CURL_LOG_DEBUG("CURL request completed: handle=%{public}p, result=%{public}d", handle, result);
            
            // 获取HTTPRequest并通知结果
            void* privateData = nullptr;
            curl_easy_getinfo(handle, CURLINFO_PRIVATE, &privateData);
            
            if (privateData) {
                // HTTPRequest通过CURLOPT_PRIVATE存储了自己的指针
                // 这里需要跨边界调用HTTPRequest::handleResult
                // 注意：这需要在http_file_source_harmony.cpp中提供一个C风格的回调
                CURL_LOG_INFO("Notifying HTTPRequest: %{public}p", privateData);
                
                // HTTPRequest会通过CURL的回调机制自动处理结果
                // 不需要手动调用handleResult
            } else {
                CURL_LOG_WARN("No private data found for completed handle");
            }
        }
    }
}

void CURLEventLoop::updateTimeout(long timeout_ms) {
    // 线程安全检查
    if (!loop_ || stopping_.load()) {
        CURL_LOG_WARN("Cannot update timeout: loop is null or stopping");
        return;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (timeout_ms < 0) {
        // 停止定时器
        if (timeout_timer_) {
            int err = uv_timer_stop(timeout_timer_);
            if (err != 0) {
                CURL_LOG_WARN("Failed to stop timer: %{public}s", uv_strerror(err));
            }
        }
    } else {
        // 设置定时器
        if (!timeout_timer_) {
            timeout_timer_ = new uv_timer_t;
            timeout_timer_->data = this;
            
            // 初始化timer并检查错误
            int err = uv_timer_init(loop_, timeout_timer_);
            if (err != 0) {
                CURL_LOG_ERROR("Failed to initialize timer: %{public}s", uv_strerror(err));
                delete timeout_timer_;
                timeout_timer_ = nullptr;
                return;
            }
            CURL_LOG_DEBUG("Timer initialized successfully");
        }
        
        // 启动timer并检查错误
        int err = uv_timer_start(timeout_timer_, onTimeout, timeout_ms, 0);
        if (err != 0) {
            CURL_LOG_ERROR("Failed to start timer: %{public}s", uv_strerror(err));
            return;
        }
        CURL_LOG_DEBUG("Timer started: timeout=%{public}ldms", timeout_ms);
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
    CURL_LOG_ERROR("Error in %{public}s: %{public}s", function, error);
}

} // namespace harmony
} // namespace mbgl
