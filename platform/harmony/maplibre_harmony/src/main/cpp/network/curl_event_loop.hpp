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
 * Dedicated CURL event-loop manager.
 *
 * Handles CURL network requests using an independent libuv loop, fully decoupled
 * from mbgl::RunLoop to avoid lifecycle conflicts.
 *
 * Design principles:
 * 1. Independent thread and event loop
 * 2. Atomic operations ensure thread safety
 * 3. Graceful shutdown mechanism
 * 4. Loosely coupled to HTTPFileSource
 *
 * Supports two modes:
 * - Simple polling: 100 ms timer polling (default, stable)
 * - Event-driven: socket-driven events (higher performance)
 */
class CURLEventLoop {
public:
    enum class Mode {
        SimplePolling,   // 100 ms timer polling (default)
        EventDriven      // Socket-driven events (high performance)
    };
    
    CURLEventLoop(Mode mode = Mode::SimplePolling);
    ~CURLEventLoop();

    // Start the event loop
    void start();
    
    // Stop the event loop (blocks until fully stopped)
    void stop();
    
    // Add a CURL handle to the event loop
    bool addHandle(CURL* handle);
    
    // Remove a CURL handle from the event loop
    bool removeHandle(CURL* handle);
    
    // Check whether the loop is running
    bool isRunning() const { return running_.load(); }
    
    // Expose the multi handle accessor
    CURLM* getMultiHandle() const { return multi_; }

private:
    // libuv event loop
    uv_loop_t* loop_;
    std::unique_ptr<std::thread> thread_;
    
    // Run state
    std::atomic<bool> running_;
    std::atomic<bool> stopping_;
    
    // Operating mode
    Mode mode_;
    
    // CURL multi handle
    CURLM* multi_;
    
    // Timer for CURL timeouts (pointer avoids incomplete-type issues)
    uv_timer_t* timeout_timer_;
    
    // Polling timer for SimplePolling mode
    uv_timer_t* polling_timer_;
    
    // Holder async handle keeps the loop alive
    uv_async_t* holder_;
    
    // Synchronization primitives
    mutable std::mutex mutex_;
    std::condition_variable cv_;
    
    // Active CURL handles
    std::unordered_map<CURL*, uv_poll_t*> active_handles_;
    
    // Event-loop thread entry point
    void eventLoopThread();
    
    // libuv callbacks
    static void onSocketEvent(uv_poll_t* poll, int status, int events);
    static void onTimeout(uv_timer_t* timer);
    static void onPolling(uv_timer_t* timer);  // Simple polling callback
    static void onClose(uv_handle_t* handle);
    
    // CURL callbacks
    static int handleSocket(CURL* handle, curl_socket_t s, int action, void* userp, void* socketp);
    static int handleTimer(CURLM* multi, long timeout_ms, void* userp);
    
    // Internal helpers
    void processCURLMessages();
    void updateTimeout(long timeout_ms);
    void cleanupHandles();
    
    // Error handling
    void logError(const char* function, const char* error);
};

} // namespace harmony
} // namespace mbgl
