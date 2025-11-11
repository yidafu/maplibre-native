#pragma once

#include <napi/native_api.h>
#include <mbgl/map/map.hpp>
#include <mbgl/style/style.hpp>
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
    
    // Constructor reference (used to create instances)
    static napi_ref constructor;
    
private:
    mbgl::Map* map;  // Holds a Map pointer (not owned)
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

