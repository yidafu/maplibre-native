#pragma once

#include <curl/curl.h>

#include <atomic>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <queue>
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
 * 2. All curl_multi_* operations execute exclusively on the CURLEventLoop thread
 * 3. Cross-thread communication via operation queue + uv_async_send
 * 4. Graceful shutdown mechanism
 * 5. Loosely coupled to HTTPFileSource
 *
 * Supports two modes:
 * - Simple polling: 20 ms timer polling (fallback mode)
 * - Event-driven: socket-driven events (high performance, default)
 */
class CURLEventLoop {
public:
    enum class Mode {
        SimplePolling,   // 20 ms timer polling (fallback mode)
        EventDriven      // Socket-driven events (high performance, default)
    };

    CURLEventLoop(Mode mode = Mode::EventDriven);
    ~CURLEventLoop();

    // Start the event loop
    void start();

    // Stop the event loop (blocks until fully stopped)
    void stop();

    // Add a CURL handle to the event loop (blocks until operation completes on CURLEventLoop thread)
    bool addHandle(CURL* handle);

    // Remove a CURL handle from the event loop (blocks until operation completes on CURLEventLoop thread)
    bool removeHandle(CURL* handle);

    // Remove all active CURL handles without triggering callbacks
    // Must be called before stop() to prevent callbacks during shutdown
    void removeAllHandles();

    // Check whether the loop is running
    bool isRunning() const { return running_.load(); }

    // Check whether the loop is stopping (for lifecycle management)
    bool isStopping() const { return stopping_.load(std::memory_order_acquire); }

    // Get active request count (for lifecycle management)
    size_t getActiveRequestCount() const { return activeRequestCount_.load(std::memory_order_acquire); }

    // Increment active request count
    void incrementRequestCount() { activeRequestCount_.fetch_add(1, std::memory_order_acquire); }

    // Decrement active request count
    void decrementRequestCount() { activeRequestCount_.fetch_sub(1, std::memory_order_release); }

    // Expose the multi handle accessor
    CURLM* getMultiHandle() const { return multi_; }

private:
    // --- Operation dispatch types ---

    // Operation types that can be dispatched from main thread to CURLEventLoop thread
    enum class OperationType {
        AddHandle,        // curl_multi_add_handle + kick-off + processCURLMessages
        RemoveHandle,     // curl_multi_remove_handle + close uv_poll_t
        RemoveAllHandles, // Bulk remove all handles (pre-stop cleanup)
    };

    // A single pending operation with synchronization primitives for synchronous callers.
    // done_mutex/done_cv/done_flag are pointers to locals on the caller's (main thread) stack.
    // This is safe because the caller is blocked on done_cv.wait() until the operation completes.
    struct PendingOperation {
        OperationType type;
        CURL* handle;              // valid for AddHandle/RemoveHandle; nullptr otherwise
        std::mutex* done_mutex;    // caller-local mutex for synchronization
        std::condition_variable* done_cv;
        bool* done_flag;           // set to true when operation completes
        bool* success_flag;        // set to true/false indicating operation result
    };

    // libuv event loop
    uv_loop_t* loop_;
    std::unique_ptr<std::thread> thread_;

    // Run state
    std::atomic<bool> running_;
    std::atomic<bool> stopping_;

    // Active request count (tracks requests being processed to prevent use-after-free)
    std::atomic<size_t> activeRequestCount_;

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

    // Async handle for cross-thread operation dispatch.
    // uv_async_send() is thread-safe per libuv docs.
    uv_async_t* operation_signal_;

    // Queue of pending operations from the main thread.
    // Protected by operation_queue_mutex_. Only pushed from main thread,
    // only popped/processed from CURLEventLoop thread (in onOperationSignal).
    std::queue<PendingOperation> pending_operations_;
    std::mutex operation_queue_mutex_;

    // Active CURL handles and their uv_poll_t watchers (EventDriven mode).
    // Only accessed from the CURLEventLoop thread — no mutex needed.
    std::unordered_map<CURL*, uv_poll_t*> active_handles_;

    // Reverse map: uv_poll_t* → CURL* for O(1) validity verification.
    // Used in onSocketEvent to verify a poll handle is still associated with
    // an actively tracked CURL handle before calling curl_multi_socket_action.
    // Only accessed from the CURLEventLoop thread — no mutex needed.
    std::unordered_map<uv_poll_t*, CURL*> handle_by_poll_;

    // Event-loop thread entry point
    void eventLoopThread();

    // libuv callbacks
    static void onSocketEvent(uv_poll_t* poll, int status, int events);
    static void onTimeout(uv_timer_t* timer);
    static void onPolling(uv_timer_t* timer);  // Simple polling callback
    static void onClose(uv_handle_t* handle);

    // Operation signal callback — runs on CURLEventLoop thread, processes the pending queue
    static void onOperationSignal(uv_async_t* async);

    // CURL callbacks
    static int handleSocket(CURL* handle, curl_socket_t s, int action, void* userp, void* socketp);
    static int handleTimer(CURLM* multi, long timeout_ms, void* userp);

    // Internal helpers
    void processCURLMessages();
    void updateTimeout(long timeout_ms);

    // Process a single pending operation on the CURLEventLoop thread
    bool processOperation(const PendingOperation& op);

    // Perform graceful shutdown on the CURLEventLoop thread.
    // Closes all uv handles; uv_run returns naturally after all close callbacks fire.
    void performShutdown();

    // Error handling
    void logError(const char* function, const char* error);
};

} // namespace harmony
} // namespace mbgl
