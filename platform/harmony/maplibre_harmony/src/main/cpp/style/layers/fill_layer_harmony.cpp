#include "fill_layer_harmony.hpp"
#include "../../napi_args.hpp"
#include "../../logger.h"
#include "../filter_conversion.hpp"
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref FillLayerNAPI::constructor = nullptr;

FillLayerNAPI::FillLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::FillLayer>(layerId, sourceId)) {
    Logger::debug("FillLayerNAPI", "FillLayer created: %s (source: %s)", layerId.c_str(), sourceId.c_str());
}

FillLayerNAPI::~FillLayerNAPI() {
    Logger::debug("FillLayerNAPI", "FillLayer destroyed");
}

void FillLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    FillLayerNAPI* obj = static_cast<FillLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value FillLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("FillLayerNAPI", "Initializing FillLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods
        { "setFillColor", nullptr, SetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillOpacity", nullptr, SetFillOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillOutlineColor", nullptr, SetFillOutlineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillPattern", nullptr, SetFillPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillAntialias", nullptr, SetFillAntialias, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillTranslate", nullptr, SetFillTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods
        { "getFillColor", nullptr, GetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillOpacity", nullptr, GetFillOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
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
    napi_status status = napi_define_class(env, "FillLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("FillLayerNAPI", "Failed to define FillLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("FillLayerNAPI", "Failed to create reference to FillLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "FillLayer", cons);
    if (status != napi_ok) {
        Logger::error("FillLayerNAPI", "Failed to export FillLayer class");
        return nullptr;
    }
    
    Logger::info("FillLayerNAPI", "FillLayer NAPI class registered successfully");
    return exports;
}

napi_value FillLayerNAPI::New(napi_env env, napi_callback_info info) {
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
    
    // Create FillLayerNAPI instance
    FillLayerNAPI* layerObj = new FillLayerNAPI(layerId, sourceId);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("FillLayerNAPI", "Failed to wrap FillLayer object");
        return nullptr;
    }
    
    return thisVar;
}

napi_value FillLayerNAPI::SetFillColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("FillLayerNAPI", "Failed to unwrap FillLayer object");
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
            layerObj->layer->setFillColor(mbgl::style::PropertyValue<mbgl::Color>(*color));
            Logger::debug("FillLayerNAPI", "FillColor set to %s", colorStr.c_str());
        } else {
            Logger::error("FillLayerNAPI", "Invalid color format: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("FillLayerNAPI", "setFillColor failed: %s", e.what());
    }

    return thisVar;  // Return this for chaining
}

napi_value FillLayerNAPI::SetFillOpacity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("FillLayerNAPI", "Failed to unwrap FillLayer object");
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
        layerObj->layer->setFillOpacity(mbgl::style::PropertyValue<float>(static_cast<float>(opacity)));
        Logger::debug("FillLayerNAPI", "FillOpacity set to %f", opacity);
    } catch (const std::exception& e) {
        Logger::error("FillLayerNAPI", "setFillOpacity failed: %s", e.what());
    }

    return thisVar;  // Return this for chaining
}

napi_value FillLayerNAPI::SetFillOutlineColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("FillLayerNAPI", "Failed to unwrap FillLayer object");
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
            layerObj->layer->setFillOutlineColor(mbgl::style::PropertyValue<mbgl::Color>(*color));
            Logger::debug("FillLayerNAPI", "FillOutlineColor set to %s", colorStr.c_str());
        } else {
            Logger::error("FillLayerNAPI", "Invalid color format: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("FillLayerNAPI", "setFillOutlineColor failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value FillLayerNAPI::SetFillPattern(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("FillLayerNAPI", "Failed to unwrap FillLayer object");
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
        layerObj->layer->setFillPattern(mbgl::style::PropertyValue<mbgl::style::expression::Image>(
            mbgl::style::expression::Image(pattern)));
        Logger::debug("FillLayerNAPI", "FillPattern set to %s", pattern.c_str());
    } catch (const std::exception& e) {
        Logger::error("FillLayerNAPI", "setFillPattern failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value FillLayerNAPI::SetFillAntialias(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("FillLayerNAPI", "Failed to unwrap FillLayer object");
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
    
    bool antialias = args.GetBool(0, "antialias");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setFillAntialias(mbgl::style::PropertyValue<bool>(antialias));
        Logger::debug("FillLayerNAPI", "FillAntialias set to %s", antialias ? "true" : "false");
    } catch (const std::exception& e) {
        Logger::error("FillLayerNAPI", "setFillAntialias failed: %s", e.what());
    }

    return thisVar;  // Return this for chaining
}

napi_value FillLayerNAPI::SetFillTranslate(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("FillLayerNAPI", "Failed to unwrap FillLayer object");
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
    
    napi_value arrayValue = args.GetArray(0, "translate");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        uint32_t length;
        napi_get_array_length(env, arrayValue, &length);
        
        if (length != 2) {
            Logger::error("FillLayerNAPI", "setFillTranslate requires array of length 2");
            return thisVar;
        }
        
        napi_value elem0, elem1;
        napi_get_element(env, arrayValue, 0, &elem0);
        napi_get_element(env, arrayValue, 1, &elem1);
        
        double x, y;
        napi_get_value_double(env, elem0, &x);
        napi_get_value_double(env, elem1, &y);
        
        std::array<float, 2> translate = {static_cast<float>(x), static_cast<float>(y)};
        layerObj->layer->setFillTranslate(mbgl::style::PropertyValue<std::array<float, 2>>(translate));
        Logger::debug("FillLayerNAPI", "FillTranslate set to [%f, %f]", x, y);
    } catch (const std::exception& e) {
        Logger::error("FillLayerNAPI", "setFillTranslate failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value FillLayerNAPI::GetFillColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getFillColor();
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

napi_value FillLayerNAPI::GetFillOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getFillOpacity();
    if (value.isConstant()) {
        napi_value result;
        napi_create_double(env, static_cast<double>(value.asConstant()), &result);
        return result;
    }

    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value FillLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
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

napi_value FillLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "fill", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
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

napi_value FillLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    std::string visibilityStr = args.GetString(0, "visibility");
    if (!args.HasError()) {
        mbgl::style::VisibilityType visibility = (visibilityStr == "none") 
            ? mbgl::style::VisibilityType::None 
            : mbgl::style::VisibilityType::Visible;
        layerObj->layer->setVisibility(visibility);
    }
    return thisVar;
}

napi_value FillLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const char* visibilityStr = (layerObj->layer->getVisibility() == mbgl::style::VisibilityType::Visible) 
        ? "visible" : "none";
    napi_value result;
    napi_create_string_utf8(env, visibilityStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double zoom = args.GetDouble(0, "minZoom");
    if (!args.HasError()) {
        layerObj->layer->setMinZoom(static_cast<float>(zoom));
    }
    return thisVar;
}

napi_value FillLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value result;
    napi_create_double(env, static_cast<double>(layerObj->layer->getMinZoom()), &result);
    return result;
}

napi_value FillLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double zoom = args.GetDouble(0, "maxZoom");
    if (!args.HasError()) {
        layerObj->layer->setMaxZoom(static_cast<float>(zoom));
    }
    return thisVar;
}

napi_value FillLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    napi_value result;
    napi_create_double(env, static_cast<double>(layerObj->layer->getMaxZoom()), &result);
    return result;
}

napi_value FillLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    std::string sourceLayer = args.GetString(0, "sourceLayer");
    if (!args.HasError()) {
        layerObj->layer->setSourceLayer(sourceLayer);
    }
    return thisVar;
}

napi_value FillLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value result;
    napi_create_string_utf8(env, layerObj->layer->getSourceLayer().c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    napi_value filterArray = args.GetArray(0, "filter");
    if (!args.HasError()) {
        auto filter = napiArrayToFilter(env, filterArray);
        if (filter) {
            layerObj->layer->setFilter(*filter);
            Logger::debug("FillLayerNAPI", "Filter set successfully");
        }
    }
    return thisVar;
}

napi_value FillLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value null;
        napi_get_null(env, &null);
        return null;
    }
    
    return filterToNapiArray(env, layerObj->layer->getFilter());
}

} // namespace harmony
} // namespace mbgl
