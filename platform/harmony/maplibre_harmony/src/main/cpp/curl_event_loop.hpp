#pragma once

#include <curl/curl.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <thread>
#include <unordered_map>

// Forward declarations for libuv types
struct uv_loop_s;
typedef struct uv_loop_s uv_loop_t;

struct uv_timer_s;
typedef struct uv_timer_s uv_timer_t;

struct uv_poll_s;
typedef struct uv_poll_s uv_poll_t;

struct uv_handle_s;
typedef struct uv_handle_s uv_handle_t;

struct uv_async_s;
typedef struct uv_async_s uv_async_t;

typedef int uv_file;
typedef uv_file curl_socket_t;

namespace mbgl {
namespace harmony {

/**
 * 独立的CURL事件循环管理器
 * 
 * 这个类专门处理CURL的网络请求，使用独立的libuv事件循环，
 * 与mbgl::RunLoop完全解耦，避免生命周期冲突。
 * 
 * 设计原则：
 * 1. 独立的线程和事件循环
 * 2. 原子操作确保线程安全
 * 3. 优雅的关闭机制
 * 4. 与HTTPFileSource松耦合
 */
class CURLEventLoop {
public:
    CURLEventLoop();
    ~CURLEventLoop();

    // 启动事件循环
    void start();
    
    // 停止事件循环（阻塞直到完全停止）
    void stop();
    
    // 添加CURL句柄到事件循环
    bool addHandle(CURL* handle);
    
    // 从事件循环移除CURL句柄
    bool removeHandle(CURL* handle);
    
    // 检查是否正在运行
    bool isRunning() const { return running_.load(); }
    
    // 添加获取multi handle的方法
    CURLM* getMultiHandle() const { return multi_; }

private:
    // libuv事件循环
    uv_loop_t* loop_;
    std::unique_ptr<std::thread> thread_;
    
    // 运行状态
    std::atomic<bool> running_;
    std::atomic<bool> stopping_;
    
    // CURL multi handle
    CURLM* multi_;
    
    // 定时器用于CURL超时处理（使用指针避免不完整类型问题）
    uv_timer_t* timeout_timer_;
    
    // Holder async handle用于保持loop运行
    uv_async_t* holder_;
    
    // 同步原语
    mutable std::mutex mutex_;
    std::condition_variable cv_;
    
    // 活跃的CURL句柄
    std::unordered_map<CURL*, uv_poll_t*> active_handles_;
    
    // 事件循环线程主函数
    void eventLoopThread();
    
    // libuv回调函数
    static void onSocketEvent(uv_poll_t* poll, int status, int events);
    static void onTimeout(uv_timer_t* timer);
    static void onClose(uv_handle_t* handle);
    
    // CURL回调函数
    static int handleSocket(CURL* handle, curl_socket_t s, int action, void* userp, void* socketp);
    static int handleTimer(CURLM* multi, long timeout_ms, void* userp);
    
    // 内部辅助方法
    void processCURLMessages();
    void updateTimeout(long timeout_ms);
    void cleanupHandles();
    
    // 错误处理
    void logError(const char* function, const char* error);
};

} // namespace harmony
} // namespace mbgl
