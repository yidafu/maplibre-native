#include "harmony_vsync_manager.hpp"
#include "utils/logger.h"
#include <mbgl/util/run_loop.hpp>
#include <chrono>
#include <thread>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

HarmonyVSyncManager::HarmonyVSyncManager() {
    Logger::info("HarmonyVSyncManager", "========== Constructor START (ownerInstanceId=%llu) ==========",
                 static_cast<unsigned long long>(ownerInstanceId_));
    
    try {
        // Create VSync instance
        // Parameter: name - identifier for VSync instance
        vsync_ = OH_NativeVSync_Create("MapLibreVSync", 0);
        
        if (!vsync_) {
            Logger::error("HarmonyVSyncManager", "Failed to create OH_NativeVSync instance");
            throw std::runtime_error("Failed to create OH_NativeVSync");
        }
        
        Logger::info("HarmonyVSyncManager", "VSync created successfully: %p (ownerInstanceId=%llu)",
                     vsync_, static_cast<unsigned long long>(ownerInstanceId_));
    } catch (const std::exception& e) {
        Logger::error("HarmonyVSyncManager", "Exception during construction: %s", e.what());
        throw;
    }
    
}

HarmonyVSyncManager::~HarmonyVSyncManager() {
    Logger::info("HarmonyVSyncManager", "========== Destructor START (ownerInstanceId=%llu) ==========",
                 static_cast<unsigned long long>(ownerInstanceId_));
    
    stop();
    
    if (vsync_) {
        OH_NativeVSync_Destroy(vsync_);
        vsync_ = nullptr;
        Logger::info("HarmonyVSyncManager", "VSync destroyed");
    }

    // OH_NativeVSync_Destroy does not wait for a callback that was already
    // running on the VSync thread; drain once more before this object is freed.
    waitForDispatches();
}

void HarmonyVSyncManager::setRunLoop(util::RunLoop* runLoop) {
    std::lock_guard<std::mutex> lock(callbackMutex_);
    renderRunLoop_ = runLoop;
}

void HarmonyVSyncManager::requestFrame(FrameCallback callback) {
    if (stopped_.load()) {
        Logger::warn("HarmonyVSyncManager", "requestFrame() - VSync already stopped, ignoring request");
        return;
    }
    
    if (!vsync_) {
        Logger::error("HarmonyVSyncManager", "requestFrame() - VSync not initialized");
        return;
    }
    
    // Check whether RunLoop is set (prevents requests before initialization completes)
    // Fast path: no lock required (will be rechecked when storing the callback)
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        if (!renderRunLoop_) {
            Logger::warn("HarmonyVSyncManager",
                "requestFrame() - RunLoop not set, ignoring request to avoid threading issue");
            return;
        }
        
        // Debounce: if a callback is already pending, ignore the new request
        if (pendingCallback_) {
            return;
        }
        
        // Store callback function
        pendingCallback_ = std::move(callback);
    }
    
    // Debounce: if a frame request is pending, ignore the new request
    bool expected = false;
    if (!frameRequested_.compare_exchange_strong(expected, true)) {
        // A request already exists; discard the newly stored callback
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = nullptr;
        return;
    }
    
    // Request the next frame VSync callback
    // Parameters:
    // - vsync_: VSync instance
    // - onVSync: callback function
    // - this: user data passed to callback
    int ret = OH_NativeVSync_RequestFrame(vsync_, onVSync, this);
    
    if (ret != 0) {
        Logger::error("HarmonyVSyncManager", "OH_NativeVSync_RequestFrame failed: %d", ret);
        frameRequested_ = false;  // Reset flag
        
        // Clear callback
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = nullptr;
        return;
    }
}

void HarmonyVSyncManager::stop() {
    Logger::info("HarmonyVSyncManager", "stop() called");

    // Set stop flag first to block new requests
    stopped_.store(true);

    // Clear pending callback and RunLoop reference (thread safe)
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        pendingCallback_ = nullptr;
        renderRunLoop_ = nullptr;  // Clear RunLoop pointer to prevent dangling reference
    }

    frameRequested_ = false;

    // Wait out any in-flight dispatch: it copied the raw RunLoop pointer
    // before we cleared it and is about to call runLoop->invoke(). The owner
    // destroys that RunLoop right after stop() returns.
    waitForDispatches();
}

void HarmonyVSyncManager::finishDispatch() {
    if (inFlightDispatches_.fetch_sub(1, std::memory_order_acq_rel) == 1) {
        std::lock_guard<std::mutex> lock(dispatchMutex_);
        dispatchCv_.notify_all();
    }
}

void HarmonyVSyncManager::waitForDispatches() {
    std::unique_lock<std::mutex> lock(dispatchMutex_);
    // The dispatch window is short (runLoop->invoke() only posts an event), so a
    // generous safety timeout should never be hit; log loudly if it is.
    if (!dispatchCv_.wait_for(lock, std::chrono::seconds(1), [this] {
            return inFlightDispatches_.load(std::memory_order_acquire) == 0;
        })) {
        Logger::error("HarmonyVSyncManager",
                      "⚠️  in-flight VSync dispatch did not drain within 1 s");
    }
}

void HarmonyVSyncManager::onVSync(long long timestamp, void* data) {
    auto* manager = static_cast<HarmonyVSyncManager*>(data);

    if (!manager) {
        return;
    }

    // Mark in flight BEFORE touching any member, so stop()/destruction can never
    // overtake a callback that has already been entered.
    manager->inFlightDispatches_.fetch_add(1, std::memory_order_acq_rel);

    if (manager->stopped_.load(std::memory_order_acquire)) {
        manager->finishDispatch();
        return;
    }

    // Reset frame-request flag
    manager->frameRequested_ = false;

    // Execute callback
    manager->executeCallback();
}

void HarmonyVSyncManager::executeCallback() {
    // Dispatch callback to render thread via RunLoop
    // Ensures callback executes on the proper render thread, aligned with other actor messages
    // Note: the in-flight counter was already incremented at the top of onVSync(),
    // covering the window between callback entry and these checks.

    // Double-check stopped flag and RunLoop validity
    if (stopped_.load(std::memory_order_acquire)) {
        finishDispatch();
        return;
    }

    FrameCallback callback;
    util::RunLoop* runLoop = nullptr;

    // Acquire callback and RunLoop pointers under mutex protection
    {
        std::lock_guard<std::mutex> lock(callbackMutex_);
        callback = std::move(pendingCallback_);
        pendingCallback_ = nullptr;
        runLoop = renderRunLoop_;  // Copy RunLoop pointer locally
    }

    if (!callback) {
        Logger::warn("HarmonyVSyncManager", "No callback to execute");
        finishDispatch();
        return;
    }

    // Verify RunLoop validity (avoid touching a destroyed RunLoop)
    if (!runLoop) {
        Logger::warn("HarmonyVSyncManager",
            "⚠️  RunLoop not set, skipping VSync callback (would cause thread safety violation)");
        finishDispatch();
        return;
    }

    if (stopped_.load(std::memory_order_acquire)) {
        finishDispatch();
        return;
    }

    // Dispatch through RunLoop to render thread (ensures thread safety)
    // Note: use local runLoop variable inside lambda to avoid accessing members
    runLoop->invoke([callback]() {
        try {
            callback();
        } catch (const std::exception& e) {
            Logger::error("HarmonyVSyncManager", "Exception in VSync callback: %s", e.what());
        }
    });

    finishDispatch();
}

} // namespace harmony
} // namespace mbgl

