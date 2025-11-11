#pragma once

#include <mbgl/util/run_loop.hpp>
#include <string>
#include <map>
#include <mutex>
#include <thread>
#include <chrono>
#include <vector>
#include <optional>
#include <functional>

namespace mbgl {
namespace harmony {

/**
 * HarmonyRendererThreadManager
 *
 * Centralizes management of all rendering threads, providing lookup, registration,
 * and cross-thread invocation.
 *
 * Design principles:
 * 1. Singleton - single global instance
 * 2. Thread-safe - mutex-protected operations
 * 3. Multi-instance support - each renderer registers independently
 * 4. Debug-friendly - exposes detailed thread information
 */
class HarmonyRendererThreadManager {
public:
    /**
     * Metadata describing a render thread.
     */
    struct ThreadInfo {
        util::RunLoop* runLoop;                              // RunLoop pointer
        std::thread::id threadId;                            // Thread ID
        std::chrono::steady_clock::time_point createdAt;     // Creation time
        bool active;                                         // Active flag
        
        ThreadInfo()
            : runLoop(nullptr)
            , threadId()
            , createdAt(std::chrono::steady_clock::now())
            , active(true) {}
            
        ThreadInfo(util::RunLoop* loop, std::thread::id tid)
            : runLoop(loop)
            , threadId(tid)
            , createdAt(std::chrono::steady_clock::now())
            , active(true) {}
    };
    
    /**
     * Retrieve the singleton instance.
     */
    static HarmonyRendererThreadManager& getInstance();
    
    /**
     * Register a render thread.
     *
     * @param instanceId Unique instance identifier
     * @param runLoop Pointer to the RunLoop
     * @param threadId Thread ID
     */
    void registerRendererThread(const std::string& instanceId,
                                util::RunLoop* runLoop,
                                std::thread::id threadId);
    
    /**
     * Unregister a render thread.
     *
     * @param instanceId Unique instance identifier
     */
    void unregisterRendererThread(const std::string& instanceId);
    
    /**
     * Execute a task on the specified render thread.
     *
     * @param instanceId Target instance ID
     * @param fn Function to execute
     * @return True if dispatch succeeded (thread exists)
     */
    bool invokeOnThread(const std::string& instanceId, std::function<void()>&& fn);
    
    /**
     * Check whether the current thread is the render thread for the given instance.
     *
     * @param instanceId Instance ID
     * @return True if the current thread matches that instance's render thread
     */
    bool isOnRendererThread(const std::string& instanceId) const;
    
    /**
     * Obtain the instance ID for the current thread (if it is a render thread).
     *
     * @return Instance ID, or nullopt if the current thread is not a render thread
     */
    std::optional<std::string> getCurrentInstanceId() const;
    
    /**
     * Fetch thread information for a given instance.
     *
     * @param instanceId Instance ID
     * @return Thread info, or nullopt if not found
     */
    std::optional<ThreadInfo> getThreadInfo(const std::string& instanceId) const;
    
    /**
     * Return the number of active render threads.
     */
    size_t getThreadCount() const;
    
    /**
     * Retrieve a list of all registered instance IDs.
     */
    std::vector<std::string> getAllInstanceIds() const;
    
    /**
     * Debug helper: print the status of all threads.
     */
    void dumpAllThreads() const;
    
private:
    // Private constructor (singleton)
    HarmonyRendererThreadManager() = default;
    ~HarmonyRendererThreadManager() = default;
    
    // Disallow copy and assignment
    HarmonyRendererThreadManager(const HarmonyRendererThreadManager&) = delete;
    HarmonyRendererThreadManager& operator=(const HarmonyRendererThreadManager&) = delete;
    
    // Thread info map
    mutable std::mutex mutex_;
    std::map<std::string, ThreadInfo> threads_;
};

} // namespace harmony
} // namespace mbgl

