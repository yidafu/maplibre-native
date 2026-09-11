#pragma once

#include <napi/native_api.h>
#include <mbgl/map/map.hpp>
#include <mbgl/style/style.hpp>
#include "core/map_registry.hpp"
#include <functional>
#include <string>
#include <unordered_map>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * StyleNAPI - NAPI wrapper for Style
 *
 * Wraps mbgl::style::Style to provide an object-oriented style management API.
 * Mirrors the Android Style class.
 *
 * === THREAD SAFETY ===
 *
 * StyleNAPI methods are called from the main (UI/JS) thread while the render
 * thread reads the same mbgl::Style (layer/source collections) every frame.
 * Core style collections have no internal locking: the wrapper vector
 * (src/mbgl/style/collection.hpp) is a plain std::vector, so structural
 * mutations (addLayer/addSource/addImage/remove...) and collection iterations
 * on the JS thread race the renderer and crash (SIGSEGV @0x8 in
 * Style::Impl::addLayer when layer->baseImpl was accessed concurrently).
 *
 * Rule: every structural mutation and collection read goes through runOnMap(),
 * which dispatches to the render thread and waits (see below). Per-property
 * setters are safe without dispatch: core serializes them via copy-on-write
 * Immutable snapshots (the same mechanism Android/iOS rely on).
 *
 * === MAP POINTER LIFECYCLE ===
 *
 * The `map` member is a raw pointer to an mbgl::Map owned by
 * HarmonyMapRenderThread, received through the JS API as a numeric value. When
 * NativeMapView reinitializes the renderer (surface loss, hardReset, font
 * changes) that pointer dangles. Construction therefore resolves a MapToken
 * from MapRegistry (keyed by the pointer value); once
 * NativeMapView::detachMapRegistry() invalidates the token, all methods fail
 * cleanly with acquireMap() == nullptr instead of touching freed memory.
 */
class StyleNAPI {
public:
    StyleNAPI(mbgl::Map* map);
    ~StyleNAPI();
    
    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetUri(napi_env env, napi_callback_info info);
    static napi_value GetJson(napi_env env, napi_callback_info info);
    static napi_value IsFullyLoaded(napi_env env, napi_callback_info info);
    
    // Source management
    static napi_value AddSource(napi_env env, napi_callback_info info);
    static napi_value RemoveSource(napi_env env, napi_callback_info info);
    static napi_value GetSource(napi_env env, napi_callback_info info);
    static napi_value GetSources(napi_env env, napi_callback_info info);
    
    // Layer management
    static napi_value AddLayer(napi_env env, napi_callback_info info);
    static napi_value AddLayerBelow(napi_env env, napi_callback_info info);
    static napi_value AddLayerAbove(napi_env env, napi_callback_info info);
    static napi_value AddLayerAt(napi_env env, napi_callback_info info);
    static napi_value RemoveLayer(napi_env env, napi_callback_info info);
    static napi_value RemoveLayerAt(napi_env env, napi_callback_info info);
    static napi_value GetLayer(napi_env env, napi_callback_info info);
    static napi_value GetLayers(napi_env env, napi_callback_info info);
    
    // Image management
    static napi_value AddImage(napi_env env, napi_callback_info info);
    static napi_value AddImageAsync(napi_env env, napi_callback_info info);
    static napi_value AddImagesAsync(napi_env env, napi_callback_info info);
    static napi_value RemoveImage(napi_env env, napi_callback_info info);
    static napi_value GetImage(napi_env env, napi_callback_info info);
    
    // Light & Transition
    static napi_value GetLight(napi_env env, napi_callback_info info);
    static napi_value SetLight(napi_env env, napi_callback_info info);
    static napi_value GetTransition(napi_env env, napi_callback_info info);
    static napi_value SetTransition(napi_env env, napi_callback_info info);
    
    // Internal helpers
    void setFullyLoaded(bool loaded) { fullyLoaded = loaded; }
    bool isFullyLoaded() const { return fullyLoaded; }
    mbgl::Map* getMap() const { return map; }

    /**
     * Token-aware Map fetch. Returns nullptr once the renderer that owned the
     * map was torn down/rebuilt (the token is invalidated by
     * NativeMapView::detachMapRegistry). Falls back to the raw pointer for
     * wrappers constructed before any registry entry existed.
     */
    mbgl::Map* acquireMap() const;

    /**
     * Run op(map) serialized with the render thread. Structural style changes
     * (addLayer/addSource/addImage/...) and collection reads MUST go through
     * here: the render thread consumes the style's layer collection every
     * frame, and mutating/iterating it directly from the JS thread is the
     * documented SIGSEGV@0x8 data race (see the class comment above).
     *
     * Throws std::exception when op throws on the render thread or the
     * dispatch times out (5s). Returns false (does not throw) when the map is
     * gone or was never resolvable — callers should throw a JS error in that
     * case.
     */
    bool runOnMap(const std::function<void(mbgl::Map&)>& op);

    // Constructor reference (used to create instances)
    static napi_ref constructor;

private:
    mbgl::Map* map;  // Holds a Map pointer (not owned)
    // Liveness + dispatch channel resolved from MapRegistry at construction
    std::shared_ptr<mbgl::harmony::MapToken> token_;
    mbgl::harmony::MapRegistry::Dispatcher dispatcher_;
    bool fullyLoaded;
    
    // Caches (mirroring Android)
    // Only IDs are cached here; actual objects are owned by mbgl::style::Style
    std::unordered_map<std::string, bool> sources;  // sourceId -> exists
    std::unordered_map<std::string, bool> layers;   // layerId -> exists

public:
    std::unordered_map<std::string, bool> images;   // imageName -> exists
};

} // namespace harmony
} // namespace maplibre

