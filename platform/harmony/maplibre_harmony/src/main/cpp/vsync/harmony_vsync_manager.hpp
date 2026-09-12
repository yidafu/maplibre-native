#pragma once

#include <native_vsync/native_vsync.h>
#include <functional>
#include <atomic>
#include <condition_variable>
#include <mutex>

namespace mbgl {

namespace util {
class RunLoop;
}

namespace harmony {

/**
 * HarmonyOS VSync manager.
 *
 * Wraps the HarmonyOS native VSync API to achieve system-level render synchronization,
 * similar to Android's Choreographer or iOS's CADisplayLink.
 *
 * References:
 * - https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/native-vsync-guidelines
 * - https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-nativevsync
 */
class HarmonyVSyncManager {
public:
    using FrameCallback = std::function<void()>;
    // Identifier of the owning renderer instance (for logging)
    void setOwnerInstanceId(uint64_t id) { ownerInstanceId_ = id; }
    
    /**
     * Assign the render thread RunLoop used to schedule callbacks.
     *
     * @param runLoop Pointer to the render thread's RunLoop
     */
    void setRunLoop(util::RunLoop* runLoop);
    
    /**
     * Constructor - creates and initializes the OH_NativeVSync instance.
     */
    HarmonyVSyncManager();
    
    /**
     * Destructor - cleans up VSync resources.
     */
    ~HarmonyVSyncManager();
    
    /**
     * Request the next frame callback.
     *
     * Invokes the callback on the next VSync signal.
     * Debounced: ignored if a request is already pending.
     *
     * @param callback Function to execute on VSync
     */
    void requestFrame(FrameCallback callback);
    
    /**
     * Stop VSync callbacks.
     */
    void stop();
    
    /**
     * Check whether VSync is available.
     */
    bool isAvailable() const { return vsync_ != nullptr; }

private:
    OH_NativeVSync* vsync_ = nullptr;
    util::RunLoop* renderRunLoop_ = nullptr;  // Render thread RunLoop
    std::atomic<bool> frameRequested_{false};
    FrameCallback pendingCallback_;
    std::mutex callbackMutex_;
    std::atomic<bool> stopped_{false};
    // executeCallback runs on the system VSync thread and calls into the raw
    // render-thread RunLoop pointer; stop() must wait this counter out before
    // letting the owner destroy that RunLoop. The counter is incremented at the
    // very top of onVSync — before any member is read — so a callback that has
    // been entered is always accounted for.
    std::atomic<int> inFlightDispatches_{0};
    std::mutex dispatchMutex_;
    std::condition_variable dispatchCv_;
    uint64_t ownerInstanceId_{0};
    
    /**
     * VSync callback invoked by the system.
     *
     * @param timestamp VSync timestamp in nanoseconds
     * @param data User pointer (points to HarmonyVSyncManager instance)
     */
    static void onVSync(long long timestamp, void* data);
    
    /**
     * Execute the pending callback.
     */
    void executeCallback();

    /**
     * Decrement the in-flight dispatch counter; wakes stop() when it reaches zero.
     */
    void finishDispatch();

    /**
     * Block until all in-flight VSync dispatches have drained (bounded safety timeout).
     */
    void waitForDispatches();
};

} // namespace harmony
} // namespace mbgl

