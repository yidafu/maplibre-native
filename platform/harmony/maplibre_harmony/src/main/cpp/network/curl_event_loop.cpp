#include "curl_event_loop.hpp"
#include "../utils/logger.h"

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
    
    // 创建独立的libuv事件循环
    loop_ = new uv_loop_t;
    if (int err = uv_loop_init(loop_); err != 0) {
        Logger::error("Network", "Failed to initialize libuv loop: %s", uv_strerror(err));
        delete loop_;
        loop_ = nullptr;
        throw std::runtime_error("Failed to initialize libuv loop: " + std::string(uv_strerror(err)));
    }
    
    // 创建holder async handle以保持loop运行
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
    
    // 创建CURL multi handle
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
    
    // 根据模式设置CURL回调
    if (mode_ == Mode::EventDriven) {
        curl_multi_setopt(multi_, CURLMOPT_SOCKETFUNCTION, handleSocket);
        curl_multi_setopt(multi_, CURLMOPT_SOCKETDATA, this);
        curl_multi_setopt(multi_, CURLMOPT_TIMERFUNCTION, handleTimer);
        curl_multi_setopt(multi_, CURLMOPT_TIMERDATA, this);
    }
}

CURLEventLoop::~CURLEventLoop() {
    // 确保事件循环已停止
    if (running_.load()) {
        stop();
    }
    
    // 清理CURL multi handle
    if (multi_) {
        curl_multi_cleanup(multi_);
        multi_ = nullptr;
    }
    
    // 清理轮询定时器（如果有）
    if (polling_timer_) {
        delete polling_timer_;
        polling_timer_ = nullptr;
    }
    
    // 清理holder（如果还没被清理）
    if (holder_) {
        delete holder_;
        holder_ = nullptr;
    }
    
    // 清理libuv事件循环
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
    
    // 如果是简单轮询模式，启动轮询定时器
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
    
    // 启动事件循环线程
    thread_ = std::make_unique<std::thread>(&CURLEventLoop::eventLoopThread, this);
}

void CURLEventLoop::stop() {
    if (!running_.load()) {
        return;
    }
    
    stopping_.store(true);
    
    {
        std::lock_guard<std::mutex> lock(mutex_);
        
        // 停止并清理轮询定时器
        if (polling_timer_) {
            uv_timer_stop(polling_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(polling_timer_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_timer_t*>(h);
            });
            polling_timer_ = nullptr;
        }
        
        // 停止并清理timer
        if (timeout_timer_) {
            uv_timer_stop(timeout_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(timeout_timer_), [](uv_handle_t* h) {
                delete reinterpret_cast<uv_timer_t*>(h);
            });
            timeout_timer_ = nullptr;
        }
        
        // 关闭所有active handles
        for (auto it = active_handles_.begin(); it != active_handles_.end(); ++it) {
            uv_poll_t* poll = it->second;
            if (!uv_is_closing(reinterpret_cast<uv_handle_t*>(poll))) {
                uv_close(reinterpret_cast<uv_handle_t*>(poll), onClose);
            }
        }
        active_handles_.clear();
    }
    
    // 关闭holder handle以停止loop
    if (holder_) {
        uv_close(reinterpret_cast<uv_handle_t*>(holder_), [](uv_handle_t* h) {
            delete reinterpret_cast<uv_async_t*>(h);
        });
        holder_ = nullptr;
    }
    
    // 等待线程结束
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
    
    // 在事件驱动模式下，触发CURL开始处理这个句柄
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
        Logger::error("Network", "Failed to remove CURL handle: %s", curl_multi_strerror(result));
        return false;
    }
    
    return true;
}

// getActiveHandleCount方法已移除，不再需要

void CURLEventLoop::eventLoopThread() {
    uv_run(loop_, UV_RUN_DEFAULT);
}

// libuv回调函数
void CURLEventLoop::onSocketEvent(uv_poll_t* poll, int status, int events) {
    auto* eventLoop = static_cast<CURLEventLoop*>(poll->data);
    
    if (status < 0) {
        Logger::error("Network", "Socket event error: %s", uv_strerror(status));
        return;
    }
    
    // 🔒 线程安全：锁保护 multi_ 的访问
    std::lock_guard<std::mutex> lock(eventLoop->mutex_);
    
    if (!eventLoop->multi_) {
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
        Logger::error("Network", "curl_multi_socket_action failed: %s", curl_multi_strerror(result));
        return;
    }
    
    // 处理CURL消息（注意：这里已经持有锁）
    eventLoop->processCURLMessages();
}

void CURLEventLoop::onTimeout(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);
    
    // 🔒 线程安全：锁保护 multi_ 的访问
    std::lock_guard<std::mutex> lock(eventLoop->mutex_);
    
    if (!eventLoop->multi_) {
        return;
    }
    
    // 通知CURL超时
    int running_handles = 0;
    CURLMcode result = curl_multi_socket_action(eventLoop->multi_, CURL_SOCKET_TIMEOUT, 0, &running_handles);
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_socket_action timeout failed: %s", curl_multi_strerror(result));
        return;
    }
    
    // 处理CURL消息（注意：这里已经持有锁）
    eventLoop->processCURLMessages();
}

// 简单轮询回调（SimplePolling 模式）
void CURLEventLoop::onPolling(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);
    
    if (eventLoop->stopping_.load()) {
        return;
    }
    
    // 🔒 线程安全：锁保护 multi_ 的访问
    std::lock_guard<std::mutex> lock(eventLoop->mutex_);
    
    if (!eventLoop->multi_) {
        return;
    }
    
    // 执行 CURL 处理
    int running_handles = 0;
    CURLMcode result = curl_multi_perform(eventLoop->multi_, &running_handles);
    
    if (result != CURLM_OK) {
        Logger::error("Network", "curl_multi_perform failed: %s", curl_multi_strerror(result));
        return;
    }
    
    // 处理完成的请求（注意：这里已经持有锁）
    eventLoop->processCURLMessages();
}

void CURLEventLoop::onClose(uv_handle_t* handle) {
    // Poll handle closed - no logging needed
}

// CURL回调函数
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
                    Logger::error("Network", "Failed to init poll handle: %s", uv_strerror(err));
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
                Logger::error("Network", "Failed to start poll: %s", uv_strerror(err));
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

// 外部函数声明（在 http_file_source_harmony.cpp 中实现）
extern "C" void handleHTTPRequestResult(void* request, CURLcode code);

void CURLEventLoop::processCURLMessages() {
    CURLMsg* msg;
    int msgs_left;
    
    while ((msg = curl_multi_info_read(multi_, &msgs_left))) {
        if (msg->msg == CURLMSG_DONE) {
            CURL* handle = msg->easy_handle;
            CURLcode result = msg->data.result;
            
            if (result != CURLE_OK) {
                Logger::warn("Network", "Request completed with error: %s", curl_easy_strerror(result));
            }
            
            // 获取HTTPRequest并通知结果
            void* privateData = nullptr;
            curl_easy_getinfo(handle, CURLINFO_PRIVATE, &privateData);
            
            if (privateData) {
                // 调用外部函数处理结果
                handleHTTPRequestResult(privateData, result);
            } else {
                Logger::error("Network", "No private data found for completed handle");
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
        // 停止定时器
        if (timeout_timer_) {
            int err = uv_timer_stop(timeout_timer_);
            if (err != 0) {
                Logger::warn("Network", "Failed to stop timer: %s", uv_strerror(err));
            }
        }
    } else {
        // 设置定时器
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
