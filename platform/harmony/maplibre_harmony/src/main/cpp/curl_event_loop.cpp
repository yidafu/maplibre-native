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
    
    CURL_LOG_INFO("========== CURLEventLoop Constructor START ==========");
    CURL_LOG_INFO("Mode: %{public}s", 
                  mode == Mode::SimplePolling ? "SimplePolling (100ms)" : "EventDriven");
    
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
    
    // 根据模式设置CURL回调
    if (mode_ == Mode::EventDriven) {
        // 事件驱动模式：使用 socket 和 timer 回调
        curl_multi_setopt(multi_, CURLMOPT_SOCKETFUNCTION, handleSocket);
        curl_multi_setopt(multi_, CURLMOPT_SOCKETDATA, this);
        curl_multi_setopt(multi_, CURLMOPT_TIMERFUNCTION, handleTimer);
        curl_multi_setopt(multi_, CURLMOPT_TIMERDATA, this);
        CURL_LOG_INFO("EventDriven mode: Socket callbacks registered");
    } else {
        // 简单轮询模式：不需要 socket 回调
        CURL_LOG_INFO("SimplePolling mode: Using 100ms timer polling");
    }
    
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
    
    // 清理轮询定时器（如果有）
    if (polling_timer_) {
        CURL_LOG_DEBUG("Cleaning up polling timer...");
        delete polling_timer_;
        polling_timer_ = nullptr;
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
    
    // 如果是简单轮询模式，启动轮询定时器
    if (mode_ == Mode::SimplePolling) {
        polling_timer_ = new uv_timer_t;
        polling_timer_->data = this;
        
        int err = uv_timer_init(loop_, polling_timer_);
        if (err != 0) {
            CURL_LOG_ERROR("Failed to initialize polling timer: %{public}s", uv_strerror(err));
            delete polling_timer_;
            polling_timer_ = nullptr;
            throw std::runtime_error("Failed to initialize polling timer: " + std::string(uv_strerror(err)));
        }
        
        // 启动 100ms 定时器
        err = uv_timer_start(polling_timer_, onPolling, 100, 100);
        if (err != 0) {
            CURL_LOG_ERROR("Failed to start polling timer: %{public}s", uv_strerror(err));
            throw std::runtime_error("Failed to start polling timer: " + std::string(uv_strerror(err)));
        }
        
        CURL_LOG_INFO("✅ SimplePolling mode: 100ms timer started");
    }
    
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
        
        // 停止并清理轮询定时器
        if (polling_timer_) {
            uv_timer_stop(polling_timer_);
            uv_close(reinterpret_cast<uv_handle_t*>(polling_timer_), [](uv_handle_t* h) {
                CURL_LOG_DEBUG("Polling timer closed");
                delete reinterpret_cast<uv_timer_t*>(h);
            });
            polling_timer_ = nullptr;
            CURL_LOG_DEBUG("Polling timer close scheduled");
        }
        
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
    
    // 在事件驱动模式下，触发CURL开始处理这个句柄
    if (mode_ == Mode::EventDriven) {
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
    } else {
        // 简单轮询模式：定时器会自动处理
        CURL_LOG_DEBUG("SimplePolling mode: Will be processed by 100ms timer");
    }
    
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

// 简单轮询回调（SimplePolling 模式）
void CURLEventLoop::onPolling(uv_timer_t* timer) {
    auto* eventLoop = static_cast<CURLEventLoop*>(timer->data);
    
    if (!eventLoop->multi_) {
        CURL_LOG_WARN("Multi handle is null, ignoring polling");
        return;
    }
    
    if (eventLoop->stopping_.load()) {
        CURL_LOG_DEBUG("Event loop is stopping, skip polling");
        return;
    }
    
    // 执行 CURL 处理（不带 socket，让 CURL 自己处理所有活跃的传输）
    int running_handles = 0;
    CURLMcode result = curl_multi_perform(eventLoop->multi_, &running_handles);
    
    if (result != CURLM_OK) {
        CURL_LOG_ERROR("curl_multi_perform failed: %{public}s", curl_multi_strerror(result));
        return;
    }
    
    // 处理完成的请求
    eventLoop->processCURLMessages();
    
    // 每10次轮询输出一次统计（避免日志过多）
    static int poll_count = 0;
    if (++poll_count % 10 == 0) {
        CURL_LOG_DEBUG("Polling: running_handles=%{public}d (count=%{public}d)", 
                      running_handles, poll_count);
    }
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

// 外部函数声明（在 http_file_source_harmony.cpp 中实现）
extern "C" void handleHTTPRequestResult(void* request, CURLcode code);

void CURLEventLoop::processCURLMessages() {
    CURLMsg* msg;
    int msgs_left;
    
    CURL_LOG_DEBUG("processCURLMessages() called");
    
    while ((msg = curl_multi_info_read(multi_, &msgs_left))) {
        CURL_LOG_INFO("🔔 Message from CURL: msg_type=%{public}d", msg->msg);
        
        if (msg->msg == CURLMSG_DONE) {
            CURL* handle = msg->easy_handle;
            CURLcode result = msg->data.result;
            
            CURL_LOG_INFO("================================================");
            CURL_LOG_INFO("CURL request COMPLETED!");
            CURL_LOG_INFO("Handle: %{public}p", handle);
            CURL_LOG_INFO("Result code: %{public}d", result);
            CURL_LOG_INFO("Result: %{public}s", curl_easy_strerror(result));
            CURL_LOG_INFO("================================================");
            
            // 获取HTTPRequest并通知结果
            void* privateData = nullptr;
            curl_easy_getinfo(handle, CURLINFO_PRIVATE, &privateData);
            
            if (privateData) {
                CURL_LOG_INFO("Private data found: %{public}p", privateData);
                CURL_LOG_INFO("Calling HTTPRequest::handleResult...");
                
                // 调用外部函数处理结果
                // privateData 是 HTTPRequest* 指针，直接传递即可
                handleHTTPRequestResult(privateData, result);
                
                CURL_LOG_INFO("HTTPRequest::handleResult called successfully");
            } else {
                CURL_LOG_ERROR("❌ No private data found for completed handle!");
            }
        }
        
        CURL_LOG_DEBUG("Messages left: %{public}d", msgs_left);
    }
    
    CURL_LOG_DEBUG("processCURLMessages() finished");
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
