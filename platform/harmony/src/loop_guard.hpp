/**
 * LoopGuard — tracks the liveness of RunLoop-owned uv loops.
 *
 * uv_async_send into a loop that is being (or has been) torn down is a
 * use-after-free; the sender may run on a foreign thread whose destruction
 * ordering vs. the loop owner is not guaranteed. Every RunLoop registers a
 * LoopGuard for its loop and retires it before the loop is closed/freed;
 * AsyncTasks capture the shared token at creation and refuse to send once it
 * is retired. Header-only, mutex-protected registry keyed by uv_loop_t*.
 */
#pragma once

#include <atomic>
#include <memory>
#include <mutex>
#include <unordered_map>

#include <uv.h>

namespace mbgl {
namespace harmony {

struct LoopGuard {
    std::atomic<bool> alive{true};
};

inline std::mutex& loopGuardMutex() {
    static std::mutex mutex;
    return mutex;
}

inline std::unordered_map<uv_loop_t*, std::shared_ptr<LoopGuard>>& loopGuardMap() {
    static std::unordered_map<uv_loop_t*, std::shared_ptr<LoopGuard>> map;
    return map;
}

inline std::shared_ptr<LoopGuard> registerLoopGuard(uv_loop_t* loop) {
    std::lock_guard<std::mutex> lock(loopGuardMutex());
    auto guard = std::make_shared<LoopGuard>();
    loopGuardMap()[loop] = guard;
    return guard;
}

inline std::shared_ptr<LoopGuard> acquireLoopGuard(uv_loop_t* loop) {
    std::lock_guard<std::mutex> lock(loopGuardMutex());
    auto it = loopGuardMap().find(loop);
    return it == loopGuardMap().end() ? nullptr : it->second;
}

// Marks the loop dead and drops the registry entry. Callers holding copies of
// the guard observe alive == false from this point on.
inline void retireLoopGuard(uv_loop_t* loop) {
    std::lock_guard<std::mutex> lock(loopGuardMutex());
    auto it = loopGuardMap().find(loop);
    if (it != loopGuardMap().end()) {
        it->second->alive.store(false, std::memory_order_release);
        loopGuardMap().erase(it);
    }
}

} // namespace harmony
} // namespace mbgl
