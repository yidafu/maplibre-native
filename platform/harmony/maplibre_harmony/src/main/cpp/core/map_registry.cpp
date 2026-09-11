#include "map_registry.hpp"

#include "../utils/logger.h"
#include <map>
#include <mutex>
#include <utility>

namespace mbgl {
namespace harmony {

namespace {
struct MapEntry {
    std::shared_ptr<MapToken> token;
    MapRegistry::Dispatcher dispatcher;
};

std::mutex& registryMutex() {
    static std::mutex mutex;
    return mutex;
}

std::map<uintptr_t, MapEntry>& registryMap() {
    static std::map<uintptr_t, MapEntry> map;
    return map;
}
} // namespace

void MapRegistry::registerMap(uintptr_t mapAddr,
                              std::shared_ptr<MapToken> token,
                              Dispatcher dispatcher) {
    if (mapAddr == 0 || !token) {
        return;
    }
    std::lock_guard<std::mutex> lock(registryMutex());
    auto it = registryMap().find(mapAddr);
    if (it != registryMap().end() && it->second.token != token) {
        // Address reuse (ABA): an entry still sits at this address but a
        // different map now owns it. Invalidate the stale token so wrappers
        // holding the old numeric pointer fail cleanly instead of silently
        // binding to the new map.
        mbgl::harmony::Logger::warn("MapRegistry",
            "registerMap: address %p already registered by another owner; invalidating stale token",
            reinterpret_cast<void*>(mapAddr));
        it->second.token->valid.store(false, std::memory_order_release);
    }
    registryMap()[mapAddr] = MapEntry{std::move(token), std::move(dispatcher)};
}

void MapRegistry::unregisterMap(uintptr_t mapAddr) {
    std::lock_guard<std::mutex> lock(registryMutex());
    registryMap().erase(mapAddr);
}

std::shared_ptr<MapToken> MapRegistry::resolveToken(uintptr_t mapAddr) {
    std::lock_guard<std::mutex> lock(registryMutex());
    auto it = registryMap().find(mapAddr);
    if (it == registryMap().end()) {
        return nullptr;
    }
    return it->second.token;
}

MapRegistry::Dispatcher MapRegistry::resolveDispatcher(uintptr_t mapAddr) {
    std::lock_guard<std::mutex> lock(registryMutex());
    auto it = registryMap().find(mapAddr);
    if (it == registryMap().end()) {
        return nullptr;
    }
    return it->second.dispatcher;
}

} // namespace harmony
} // namespace mbgl
