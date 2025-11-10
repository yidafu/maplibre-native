#include "light_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>
#include <mbgl/style/transition_options.hpp>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

// Static member initialization
napi_ref LightHarmony::constructor = nullptr;

LightHarmony::LightHarmony(mbgl::Map& coreMap, mbgl::style::Light& coreLight)
    : light(coreLight), map(&coreMap) {
    Logger::info("LightHarmony", "Light wrapper created");
}

LightHarmony::~LightHarmony() {
    Logger::info("LightHarmony", "Light wrapper destroyed");
}

void LightHarmony::Destructor(napi_env env, void* nativeObject, void* hint) {
    LightHarmony* lightHarmony = static_cast<LightHarmony*>(nativeObject);
    delete lightHarmony;
}

napi_value LightHarmony::Init(napi_env env, napi_value exports) {
    Logger::info("LightHarmony", "Initializing Light NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getAnchor", nullptr, GetAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setAnchor", nullptr, SetAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getPosition", nullptr, GetPosition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setPosition", nullptr, SetPosition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getPositionTransition", nullptr, GetPositionTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setPositionTransition", nullptr, SetPositionTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getColor", nullptr, GetColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setColor", nullptr, SetColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getColorTransition", nullptr, GetColorTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setColorTransition", nullptr, SetColorTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIntensity", nullptr, GetIntensity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIntensity", nullptr, SetIntensity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIntensityTransition", nullptr, GetIntensityTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIntensityTransition", nullptr, SetIntensityTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Light", NAPI_AUTO_LENGTH, 
        [](napi_env env, napi_callback_info info) -> napi_value {
            napi_value jsThis;
            napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
            return jsThis;
        }, 
        nullptr, sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("LightHarmony", "Failed to define Light class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("LightHarmony", "Failed to create Light constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Light", cons);
    if (status != napi_ok) {
        Logger::error("LightHarmony", "Failed to export Light class");
        return nullptr;
    }
    
    Logger::info("LightHarmony", "Light NAPI class initialized successfully");
    return exports;
}

napi_value LightHarmony::CreateLightPeer(napi_env env, mbgl::Map& map, mbgl::style::Light& coreLight) {
    if (constructor == nullptr) {
        Logger::error("LightHarmony", "Light constructor not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value cons;
    napi_get_reference_value(env, constructor, &cons);
    
    napi_value instance;
    napi_status status = napi_new_instance(env, cons, 0, nullptr, &instance);
    if (status != napi_ok) {
        Logger::error("LightHarmony", "Failed to create Light instance");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Create native wrapper
    LightHarmony* lightHarmony = new LightHarmony(map, coreLight);
    
    // Wrap native object
    status = napi_wrap(env, instance, lightHarmony, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        Logger::error("LightHarmony", "Failed to wrap Light instance");
        delete lightHarmony;
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    Logger::info("LightHarmony", "Light peer created successfully");
    return instance;
}

napi_value LightHarmony::GetAnchor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    auto anchorType = lightHarmony->light.getAnchor();
    const char* anchorStr = (anchorType == style::LightAnchorType::Map) ? "map" : "viewport";
    
    napi_value result;
    napi_create_string_utf8(env, anchorStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value LightHarmony::SetAnchor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    std::string anchorStr = args.GetString(0, "anchor");
    if (args.HasError()) {
        return nullptr;
    }
    
    if (anchorStr == "map") {
        lightHarmony->light.setAnchor(style::LightAnchorType::Map);
    } else if (anchorStr == "viewport") {
        lightHarmony->light.setAnchor(style::LightAnchorType::Viewport);
    }
    
    return args.Undefined();
}

napi_value LightHarmony::GetPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    auto position = lightHarmony->light.getPosition().asConstant();
    auto spherical = position.getSpherical();
    
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value radialValue, azimuthalValue, polarValue;
    napi_create_double(env, spherical[0], &radialValue);
    napi_create_double(env, spherical[1], &azimuthalValue);
    napi_create_double(env, spherical[2], &polarValue);
    
    napi_set_named_property(env, result, "radial", radialValue);
    napi_set_named_property(env, result, "azimuthal", azimuthalValue);
    napi_set_named_property(env, result, "polar", polarValue);
    
    return result;
}

napi_value LightHarmony::SetPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    napi_value positionObj = args.GetObject(0, "position");
    if (args.HasError()) {
        return nullptr;
    }

    // Parse position object {radial, azimuthal, polar}
    napi_value radialValue, azimuthalValue, polarValue;
    double radial = 0.0, azimuthal = 0.0, polar = 0.0;
    
    napi_get_named_property(env, positionObj, "radial", &radialValue);
    napi_get_named_property(env, positionObj, "azimuthal", &azimuthalValue);
    napi_get_named_property(env, positionObj, "polar", &polarValue);
    
    napi_get_value_double(env, radialValue, &radial);
    napi_get_value_double(env, azimuthalValue, &azimuthal);
    napi_get_value_double(env, polarValue, &polar);
    
    std::array<float, 3> positionArray = {
        static_cast<float>(radial), 
        static_cast<float>(azimuthal), 
        static_cast<float>(polar)
    };
    style::Position position(positionArray);
    lightHarmony->light.setPosition(position);
    
    return args.Undefined();
}

napi_value LightHarmony::GetPositionTransition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    auto transition = lightHarmony->light.getPositionTransition();
    
    napi_value result;
    napi_create_object(env, &result);
    
    if (transition.duration) {
        napi_value durationValue;
        napi_create_int64(env, transition.duration->count(), &durationValue);
        napi_set_named_property(env, result, "duration", durationValue);
    }
    
    if (transition.delay) {
        napi_value delayValue;
        napi_create_int64(env, transition.delay->count(), &delayValue);
        napi_set_named_property(env, result, "delay", delayValue);
    }
    
    return result;
}

napi_value LightHarmony::SetPositionTransition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    int64_t duration = args.GetInt64(0, "duration");
    int64_t delay = args.GetInt64(1, "delay");
    if (args.HasError()) {
        return nullptr;
    }
    
    style::TransitionOptions options;
    options.duration.emplace(mbgl::Milliseconds(duration));
    options.delay.emplace(mbgl::Milliseconds(delay));
    lightHarmony->light.setPositionTransition(options);
    
    return args.Undefined();
}

napi_value LightHarmony::GetColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    auto color = lightHarmony->light.getColor().asConstant();
    std::string colorStr = color.stringify();
    
    napi_value result;
    napi_create_string_utf8(env, colorStr.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value LightHarmony::SetColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    std::string colorStr = args.GetString(0, "color");
    if (args.HasError()) {
        return nullptr;
    }
    
    auto color = Color::parse(colorStr.c_str());
    if (color) {
        lightHarmony->light.setColor(*color);
    }
    
    return args.Undefined();
}

napi_value LightHarmony::GetColorTransition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    auto transition = lightHarmony->light.getColorTransition();
    
    napi_value result;
    napi_create_object(env, &result);
    
    if (transition.duration) {
        napi_value durationValue;
        napi_create_int64(env, transition.duration->count(), &durationValue);
        napi_set_named_property(env, result, "duration", durationValue);
    }
    
    if (transition.delay) {
        napi_value delayValue;
        napi_create_int64(env, transition.delay->count(), &delayValue);
        napi_set_named_property(env, result, "delay", delayValue);
    }
    
    return result;
}

napi_value LightHarmony::SetColorTransition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    int64_t duration = args.GetInt64(0, "duration");
    int64_t delay = args.GetInt64(1, "delay");
    if (args.HasError()) {
        return nullptr;
    }
    
    style::TransitionOptions options;
    options.duration.emplace(mbgl::Milliseconds(duration));
    options.delay.emplace(mbgl::Milliseconds(delay));
    lightHarmony->light.setColorTransition(options);
    
    return args.Undefined();
}

napi_value LightHarmony::GetIntensity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    float intensity = lightHarmony->light.getIntensity().asConstant();
    
    napi_value result;
    napi_create_double(env, intensity, &result);
    return result;
}

napi_value LightHarmony::SetIntensity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    double intensity = args.GetDouble(0, "intensity");
    if (args.HasError()) {
        return nullptr;
    }
    
    lightHarmony->light.setIntensity(static_cast<float>(intensity));
    
    return args.Undefined();
}

napi_value LightHarmony::GetIntensityTransition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    auto transition = lightHarmony->light.getIntensityTransition();
    
    napi_value result;
    napi_create_object(env, &result);
    
    if (transition.duration) {
        napi_value durationValue;
        napi_create_int64(env, transition.duration->count(), &durationValue);
        napi_set_named_property(env, result, "duration", durationValue);
    }
    
    if (transition.delay) {
        napi_value delayValue;
        napi_create_int64(env, transition.delay->count(), &delayValue);
        napi_set_named_property(env, result, "delay", delayValue);
    }
    
    return result;
}

napi_value LightHarmony::SetIntensityTransition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value jsThis = args.This();
    LightHarmony* lightHarmony = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&lightHarmony));
    
    if (!lightHarmony) {
        return args.Undefined();
    }
    
    int64_t duration = args.GetInt64(0, "duration");
    int64_t delay = args.GetInt64(1, "delay");
    if (args.HasError()) {
        return nullptr;
    }
    
    style::TransitionOptions options;
    options.duration.emplace(mbgl::Milliseconds(duration));
    options.delay.emplace(mbgl::Milliseconds(delay));
    lightHarmony->light.setIntensityTransition(options);
    
    return args.Undefined();
}

} // namespace harmony
} // namespace mbgl

