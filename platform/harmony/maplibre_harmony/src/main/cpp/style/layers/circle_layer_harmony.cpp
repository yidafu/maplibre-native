#include "circle_layer_harmony.hpp"
#include "../../napi_args.hpp"
#include "../../logger.h"
#include "../filter_conversion.hpp"
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref CircleLayerNAPI::constructor = nullptr;

CircleLayerNAPI::CircleLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::CircleLayer>(layerId, sourceId)) {
    Logger::debug("CircleLayerNAPI", "CircleLayer created: %s (source: %s)", layerId.c_str(), sourceId.c_str());
}

CircleLayerNAPI::~CircleLayerNAPI() {
    Logger::debug("CircleLayerNAPI", "CircleLayer destroyed");
}

void CircleLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    CircleLayerNAPI* obj = static_cast<CircleLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value CircleLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("CircleLayerNAPI", "Initializing CircleLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods
        { "setCircleRadius", nullptr, SetCircleRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleColor", nullptr, SetCircleColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleOpacity", nullptr, SetCircleOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleBlur", nullptr, SetCircleBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeWidth", nullptr, SetCircleStrokeWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeColor", nullptr, SetCircleStrokeColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeOpacity", nullptr, SetCircleStrokeOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods
        { "getCircleRadius", nullptr, GetCircleRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCircleColor", nullptr, GetCircleColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCircleOpacity", nullptr, GetCircleOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Visibility control
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Zoom range control
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Source layer
        { "setSourceLayer", nullptr, SetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceLayer", nullptr, GetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Filter
        { "setFilter", nullptr, SetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFilter", nullptr, GetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "CircleLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("CircleLayerNAPI", "Failed to define CircleLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("CircleLayerNAPI", "Failed to create reference to CircleLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "CircleLayer", cons);
    if (status != napi_ok) {
        Logger::error("CircleLayerNAPI", "Failed to export CircleLayer class");
        return nullptr;
    }
    
    Logger::info("CircleLayerNAPI", "CircleLayer NAPI class registered successfully");
    return exports;
}

napi_value CircleLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    // Require 2 arguments: layerId and sourceId
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) {
        return nullptr;
    }
    
    // Create CircleLayerNAPI instance
    CircleLayerNAPI* layerObj = new CircleLayerNAPI(layerId, sourceId);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("CircleLayerNAPI", "Failed to wrap CircleLayer object");
        return nullptr;
    }
    
    return thisVar;
}

napi_value CircleLayerNAPI::SetCircleRadius(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    double radius = args.GetDouble(0, "radius");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setCircleRadius(mbgl::style::PropertyValue<float>(static_cast<float>(radius)));
        Logger::debug("CircleLayerNAPI", "CircleRadius set to %f", radius);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setCircleRadius failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::SetCircleColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
            layerObj->layer->setCircleColor(mbgl::style::PropertyValue<mbgl::Color>(*color));
            Logger::debug("CircleLayerNAPI", "CircleColor set to %s", colorStr.c_str());
        } else {
            Logger::error("CircleLayerNAPI", "Invalid color format: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setCircleColor failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::SetCircleOpacity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
        layerObj->layer->setCircleOpacity(mbgl::style::PropertyValue<float>(static_cast<float>(opacity)));
        Logger::debug("CircleLayerNAPI", "CircleOpacity set to %f", opacity);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setCircleOpacity failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::SetCircleBlur(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    double blur = args.GetDouble(0, "blur");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setCircleBlur(mbgl::style::PropertyValue<float>(static_cast<float>(blur)));
        Logger::debug("CircleLayerNAPI", "CircleBlur set to %f", blur);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setCircleBlur failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::SetCircleStrokeWidth(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    double width = args.GetDouble(0, "width");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setCircleStrokeWidth(mbgl::style::PropertyValue<float>(static_cast<float>(width)));
        Logger::debug("CircleLayerNAPI", "CircleStrokeWidth set to %f", width);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setCircleStrokeWidth failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::SetCircleStrokeColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
            layerObj->layer->setCircleStrokeColor(mbgl::style::PropertyValue<mbgl::Color>(*color));
            Logger::debug("CircleLayerNAPI", "CircleStrokeColor set to %s", colorStr.c_str());
        } else {
            Logger::error("CircleLayerNAPI", "Invalid color format: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setCircleStrokeColor failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::SetCircleStrokeOpacity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
        layerObj->layer->setCircleStrokeOpacity(mbgl::style::PropertyValue<float>(static_cast<float>(opacity)));
        Logger::debug("CircleLayerNAPI", "CircleStrokeOpacity set to %f", opacity);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setCircleStrokeOpacity failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::GetCircleRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Get property value (this is simplified - may need more complex handling for expressions)
    const auto& value = layerObj->layer->getCircleRadius();
    if (value.isConstant()) {
    napi_value result;
        napi_create_double(env, static_cast<double>(value.asConstant()), &result);
    return result;
}

    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value CircleLayerNAPI::GetCircleColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getCircleColor();
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

napi_value CircleLayerNAPI::GetCircleOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getCircleOpacity();
    if (value.isConstant()) {
        napi_value result;
        napi_create_double(env, static_cast<double>(value.asConstant()), &result);
        return result;
    }

    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value CircleLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::GetType(napi_env env, napi_callback_info info) {
        napi_value result;
    napi_create_string_utf8(env, "circle", NAPI_AUTO_LENGTH, &result);
        return result;
    }

napi_value CircleLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const std::string& sourceId = layerObj->layer->getSourceID();
        napi_value result;
    napi_create_string_utf8(env, sourceId.c_str(), NAPI_AUTO_LENGTH, &result);
        return result;
}

napi_value CircleLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    std::string visibilityStr = args.GetString(0, "visibility");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::style::VisibilityType visibility = mbgl::style::VisibilityType::Visible;
        if (visibilityStr == "none") {
            visibility = mbgl::style::VisibilityType::None;
        } else if (visibilityStr != "visible") {
            Logger::error("CircleLayerNAPI", "Invalid visibility value: %s (expected 'visible' or 'none')", 
                         visibilityStr.c_str());
        }
        
        layerObj->layer->setVisibility(visibility);
        Logger::debug("CircleLayerNAPI", "Visibility set to %s", visibilityStr.c_str());
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setVisibility failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::VisibilityType visibility = layerObj->layer->getVisibility();
    const char* visibilityStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";

    napi_value result;
    napi_create_string_utf8(env, visibilityStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value CircleLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    double zoom = args.GetDouble(0, "minZoom");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setMinZoom(static_cast<float>(zoom));
        Logger::debug("CircleLayerNAPI", "MinZoom set to %f", zoom);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setMinZoom failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    float minZoom = layerObj->layer->getMinZoom();
    napi_value result;
    napi_create_double(env, static_cast<double>(minZoom), &result);
    return result;
}

napi_value CircleLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    double zoom = args.GetDouble(0, "maxZoom");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setMaxZoom(static_cast<float>(zoom));
        Logger::debug("CircleLayerNAPI", "MaxZoom set to %f", zoom);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setMaxZoom failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    float maxZoom = layerObj->layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, static_cast<double>(maxZoom), &result);
    return result;
}

napi_value CircleLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    std::string sourceLayer = args.GetString(0, "sourceLayer");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setSourceLayer(sourceLayer);
        Logger::debug("CircleLayerNAPI", "SourceLayer set to %s", sourceLayer.c_str());
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "setSourceLayer failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const std::string& sourceLayer = layerObj->layer->getSourceLayer();
    napi_value result;
    napi_create_string_utf8(env, sourceLayer.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value CircleLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
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
    
    napi_value filterArray = args.GetArray(0, "filter");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    auto filter = napiArrayToFilter(env, filterArray);
    if (filter) {
        try {
            layerObj->layer->setFilter(*filter);
            Logger::debug("CircleLayerNAPI", "Filter set successfully");
        } catch (const std::exception& e) {
            Logger::error("CircleLayerNAPI", "setFilter failed: %s", e.what());
        }
    } else {
        Logger::error("CircleLayerNAPI", "Failed to convert filter array");
    }
    
    return thisVar;  // Return this for chaining
}

napi_value CircleLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("CircleLayerNAPI", "Failed to unwrap CircleLayer object");
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
    
    try {
        const mbgl::style::Filter& filter = layerObj->layer->getFilter();
        return filterToNapiArray(env, filter);
    } catch (const std::exception& e) {
        Logger::error("CircleLayerNAPI", "getFilter failed: %s", e.what());
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
}

} // namespace harmony
} // namespace mbgl
