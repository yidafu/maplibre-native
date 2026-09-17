#pragma once

#include <atomic>
#include <functional>
#include <memory>
#include <stdint.h>

namespace mbgl {
class Map;
}

namespace mbgl {
namespace harmony {

/**
 * Liveness token for a raw mbgl::Map owned by a HarmonyMapRenderThread.
 *
 * The render thread can be torn down and rebuilt at any time (surface loss,
 * hardReset, font-family changes). Any wrapper that cached the raw Map pointer
 * across such a reset holds a dangling pointer. Holders keep the shared token
 * instead and can detect invalidation cheaply.
 */
struct MapToken {
    mbgl::Map* map = nullptr;
    std::atomic<bool> valid{true};
};

/**
 * Registry keyed by the raw Map pointer value.
 *
 * Why keyed by pointer: StyleNAPI receives the Map as a numeric pointer through
 * the existing JS API contract (ArkTS passes mapPtr). The registry lets such
 * wrappers resolve a liveness token and a thread dispatcher for that pointer
 * without changing the JS-facing signature.
 *
 * All methods must be called on the JS thread — the same thread that creates
 * and reinitializes renderers and constructs NAPI wrappers.
 */
class MapRegistry {
public:
    /// Execute op(map) on the map/render thread and return once it has run.
    using Dispatcher = std::function<void(std::function<void(mbgl::Map*)>&&)>;

    /// Publish the current Map of a view. Invalidates any previous entry
    /// registered under a different address for the same owner is the caller's
    /// responsibility (call unregisterMap for the old map first).
    static void registerMap(uintptr_t mapAddr,
                            std::shared_ptr<MapToken> token,
                            Dispatcher dispatcher);

    /// Invalidate and remove the entry for mapAddr. Wrappers holding the old
    /// token see isValid() == false afterwards.
    static void unregisterMap(uintptr_t mapAddr);

    /// Resolve the liveness token for a raw pointer, or nullptr when the map
    /// was never registered (or already unregistered).
    static std::shared_ptr<MapToken> resolveToken(uintptr_t mapAddr);

    /// Resolve the render-thread dispatcher for a raw pointer; nullptr when
    /// unregistered.
    static Dispatcher resolveDispatcher(uintptr_t mapAddr);
};

} // namespace harmony
} // namespace mbgl
