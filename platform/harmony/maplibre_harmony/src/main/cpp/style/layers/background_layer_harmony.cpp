#include "background_layer_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include <mbgl/style/layers/background_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref BackgroundLayerNAPI::constructor = nullptr;

BackgroundLayerNAPI::BackgroundLayerNAPI(const std::string& layerId)
    : layer(std::make_unique<mbgl::style::BackgroundLayer>(layerId)) {
    Logger::debug("BackgroundLayerNAPI", "BackgroundLayer created: %s", layerId.c_str());
}

BackgroundLayerNAPI::~BackgroundLayerNAPI() {
    Logger::debug("BackgroundLayerNAPI", "BackgroundLayer destroyed");
}

void BackgroundLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    BackgroundLayerNAPI* obj = static_cast<BackgroundLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value BackgroundLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("BackgroundLayerNAPI", "Initializing BackgroundLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods
        { "setBackgroundColor", nullptr, SetBackgroundColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBackgroundOpacity", nullptr, SetBackgroundOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBackgroundPattern", nullptr, SetBackgroundPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods
        { "getBackgroundColor", nullptr, GetBackgroundColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getBackgroundOpacity", nullptr, GetBackgroundOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "BackgroundLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("BackgroundLayerNAPI", "Failed to define BackgroundLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("BackgroundLayerNAPI", "Failed to create reference to BackgroundLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "BackgroundLayer", cons);
    if (status != napi_ok) {
        Logger::error("BackgroundLayerNAPI", "Failed to export BackgroundLayer class");
        return nullptr;
    }
    
    Logger::info("BackgroundLayerNAPI", "BackgroundLayer NAPI class registered successfully");
    return exports;
}

napi_value BackgroundLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    // Require 1 argument: layerId
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) {
        return nullptr;
    }
    
    // Create BackgroundLayerNAPI instance
    BackgroundLayerNAPI* layerObj = new BackgroundLayerNAPI(layerId);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("BackgroundLayerNAPI", "Failed to wrap BackgroundLayer object");
        return nullptr;
    }
    
    return thisVar;
}

napi_value BackgroundLayerNAPI::SetBackgroundColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    BackgroundLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("BackgroundLayerNAPI", "Failed to unwrap BackgroundLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string colorStr = args.GetString(0, "color");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            layerObj->layer->setBackgroundColor(mbgl::style::PropertyValue<mbgl::Color>(*color));
            Logger::debug("BackgroundLayerNAPI", "BackgroundColor set to %s", colorStr.c_str());
        } else {
            Logger::error("BackgroundLayerNAPI", "Invalid color format: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("BackgroundLayerNAPI", "setBackgroundColor failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value BackgroundLayerNAPI::SetBackgroundOpacity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    BackgroundLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("BackgroundLayerNAPI", "Failed to unwrap BackgroundLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double opacity = args.GetDouble(0, "opacity");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setBackgroundOpacity(mbgl::style::PropertyValue<float>(static_cast<float>(opacity)));
        Logger::debug("BackgroundLayerNAPI", "BackgroundOpacity set to %f", opacity);
    } catch (const std::exception& e) {
        Logger::error("BackgroundLayerNAPI", "setBackgroundOpacity failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value BackgroundLayerNAPI::SetBackgroundPattern(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    BackgroundLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("BackgroundLayerNAPI", "Failed to unwrap BackgroundLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string pattern = args.GetString(0, "pattern");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setBackgroundPattern(mbgl::style::PropertyValue<mbgl::style::expression::Image>(
            mbgl::style::expression::Image(pattern)));
        Logger::debug("BackgroundLayerNAPI", "BackgroundPattern set to %s", pattern.c_str());
    } catch (const std::exception& e) {
        Logger::error("BackgroundLayerNAPI", "setBackgroundPattern failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value BackgroundLayerNAPI::GetBackgroundColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    BackgroundLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getBackgroundColor();
    if (value.isConstant()) {
        const auto& color = value.asConstant();
        std::string colorStr = color.stringify();
        napi_value result;
        napi_create_string_utf8(env, colorStr.c_str(), NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value BackgroundLayerNAPI::GetBackgroundOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    BackgroundLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getBackgroundOpacity();
    if (value.isConstant()) {
        napi_value result;
        napi_create_double(env, static_cast<double>(value.asConstant()), &result);
        return result;
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value BackgroundLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    BackgroundLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const std::string& id = layerObj->layer->getID();
    napi_value result;
    napi_create_string_utf8(env, id.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value BackgroundLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "background", NAPI_AUTO_LENGTH, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

