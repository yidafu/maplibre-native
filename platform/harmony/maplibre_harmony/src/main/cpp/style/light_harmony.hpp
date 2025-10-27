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
    
    // Constructor - wraps existing light
    LightHarmony(mbgl::Map& coreMap, mbgl::style::Light& coreLight);
    
    // Destructor
    ~LightHarmony();
    
    // Factory method to create NAPI wrapper
    static napi_value CreateLightPeer(napi_env env, mbgl::Map& map, mbgl::style::Light& coreLight);
    
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
    
    // Reference to the core light object
    mbgl::style::Light& light;
    
    // Reference to the map
    mbgl::Map* map;
};

} // namespace harmony
} // namespace mbgl

