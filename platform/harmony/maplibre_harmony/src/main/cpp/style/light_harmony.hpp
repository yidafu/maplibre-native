#pragma once

#include <napi/native_api.h>
#include <mbgl/style/light.hpp>
#include <mbgl/map/map.hpp>
#include <mbgl/util/noncopyable.hpp>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * LightHarmony - NAPI wrapper for Light
 * 
 * This class wraps a mbgl::style::Light object and exposes it to ETS/TypeScript via NAPI.
 * It manages light properties like anchor, position, color, and intensity.
 */
class LightHarmony : private mbgl::util::noncopyable {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor - wraps the light of the given map's current style
    explicit LightHarmony(mbgl::Map& coreMap);

    // Destructor
    ~LightHarmony();

    // Factory method to create NAPI wrapper
    static napi_value CreateLightPeer(napi_env env, mbgl::Map& map);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property getters and setters
    static napi_value GetAnchor(napi_env env, napi_callback_info info);
    static napi_value SetAnchor(napi_env env, napi_callback_info info);
    
    static napi_value GetPosition(napi_env env, napi_callback_info info);
    static napi_value SetPosition(napi_env env, napi_callback_info info);
    static napi_value GetPositionTransition(napi_env env, napi_callback_info info);
    static napi_value SetPositionTransition(napi_env env, napi_callback_info info);
    
    static napi_value GetColor(napi_env env, napi_callback_info info);
    static napi_value SetColor(napi_env env, napi_callback_info info);
    static napi_value GetColorTransition(napi_env env, napi_callback_info info);
    static napi_value SetColorTransition(napi_env env, napi_callback_info info);
    
    static napi_value GetIntensity(napi_env env, napi_callback_info info);
    static napi_value SetIntensity(napi_env env, napi_callback_info info);
    static napi_value GetIntensityTransition(napi_env env, napi_callback_info info);
    static napi_value SetIntensityTransition(napi_env env, napi_callback_info info);

private:
    static napi_ref constructor;
    static napi_env constructorEnv;

    // The Light is owned by the Style and is destroyed on style reload or map
    // teardown; holding a bare reference across calls is a dangling UAF. Keep
    // only the map and re-fetch the current light on every access.
    mbgl::Map* map = nullptr;

    // Returns the style's current light, or nullptr when the map/style/light
    // is gone; callers must null-check before any access.
    mbgl::style::Light* currentLight() const;
};

} // namespace harmony
} // namespace mbgl

