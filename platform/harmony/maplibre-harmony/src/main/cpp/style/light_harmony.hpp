#pragma once

#include <napi/native_api.h>
#include <mln/style/light.hpp>
#include <mln/map/map.hpp>
#include <mln/util/noncopyable.hpp>
#include <memory>

namespace mln {
namespace harmony {

/**
 * LightHarmony - NAPI wrapper for Light
 * 
 * This class wraps a mln::style::Light object and exposes it to ETS/TypeScript via NAPI.
 * It manages light properties like anchor, position, color, and intensity.
 */
class LightHarmony : private mln::util::noncopyable {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor - wraps the light of the given map's current style
    explicit LightHarmony(mln::Map& coreMap);

    // Destructor
    ~LightHarmony();

    // Factory method to create NAPI wrapper
    static napi_value CreateLightPeer(napi_env env, mln::Map& map);
    
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

    // Unwraps the wrapper from `this` and returns the style's current light,
    // or nullptr when either is gone; the NAPI methods return Undefined then.
    static mln::style::Light* ResolveLight(napi_env env, napi_value jsThis);

    // Shared bodies of the six *Transition bindings. The getter template takes
    // a mln::style::Light member returning TransitionOptions, the setter
    // template one accepting a const TransitionOptions&.
    template <typename Getter>
    static napi_value GetTransitionImpl(napi_env env, napi_callback_info info, Getter getter);

    template <typename Setter>
    static napi_value SetTransitionImpl(napi_env env, napi_callback_info info, Setter setter);

    // 属性 getter/setter 的共同前导：解析参数（requireArg 时要求 ≥1 个）、
    // ResolveLight，成功后以 (args, light) 调用 fn 并返回其结果。
    template <typename Fn>
    static napi_value WithLight(napi_env env, napi_callback_info info, bool requireArg, Fn fn);

    // The Light is owned by the Style and is destroyed on style reload or map
    // teardown; holding a bare reference across calls is a dangling UAF. Keep
    // only the map and re-fetch the current light on every access.
    mln::Map* map = nullptr;

    // Returns the style's current light, or nullptr when the map/style/light
    // is gone; callers must null-check before any access.
    mln::style::Light* currentLight() const;
};

} // namespace harmony
} // namespace mln

