#include "symbol_layer_harmony.hpp"
#include "../napi_args.hpp"
#include "../napi_utils.h"
#include "../logger.h"
#include "../value_conversion.hpp"
#include <mbgl/style/layers/symbol_layer.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref SymbolLayerNAPI::constructor = nullptr;

SymbolLayerNAPI::SymbolLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : ownsLayer(true) {
    layer = std::make_unique<mbgl::style::SymbolLayer>(layerId, sourceId);
    Logger::info("SymbolLayerNAPI", "SymbolLayer created: %s (source: %s)", layerId.c_str(), sourceId.c_str());
}

SymbolLayerNAPI::SymbolLayerNAPI(std::unique_ptr<mbgl::style::SymbolLayer> layer_)
    : layer(std::move(layer_)), ownsLayer(true) {
    Logger::info("SymbolLayerNAPI", "SymbolLayer created from existing layer");
}

SymbolLayerNAPI::~SymbolLayerNAPI() {
    Logger::info("SymbolLayerNAPI", "SymbolLayer destroyed");
}

void SymbolLayerNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    Logger::debug("SymbolLayerNAPI", "Destructor called");
    SymbolLayerNAPI* layerNapi = static_cast<SymbolLayerNAPI*>(nativeObject);
    delete layerNapi;
}

napi_value SymbolLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("SymbolLayerNAPI", "Initializing SymbolLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Basic methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSourceLayer", nullptr, SetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceLayer", nullptr, GetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layout properties - Icon
        { "setIconImage", nullptr, SetIconImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconImage", nullptr, GetIconImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconSize", nullptr, SetIconSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconSize", nullptr, GetIconSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconRotate", nullptr, SetIconRotate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconRotate", nullptr, GetIconRotate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconOffset", nullptr, SetIconOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconOffset", nullptr, GetIconOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconAnchor", nullptr, SetIconAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconAnchor", nullptr, GetIconAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconAllowOverlap", nullptr, SetIconAllowOverlap, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconAllowOverlap", nullptr, GetIconAllowOverlap, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layout properties - Text
        { "setTextField", nullptr, SetTextField, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextField", nullptr, GetTextField, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextFont", nullptr, SetTextFont, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextFont", nullptr, GetTextFont, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextSize", nullptr, SetTextSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextSize", nullptr, GetTextSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextMaxWidth", nullptr, SetTextMaxWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextMaxWidth", nullptr, GetTextMaxWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextOffset", nullptr, SetTextOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextOffset", nullptr, GetTextOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextAnchor", nullptr, SetTextAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextAnchor", nullptr, GetTextAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextAllowOverlap", nullptr, SetTextAllowOverlap, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextAllowOverlap", nullptr, GetTextAllowOverlap, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Paint properties - Icon
        { "setIconOpacity", nullptr, SetIconOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconOpacity", nullptr, GetIconOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconColor", nullptr, SetIconColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconColor", nullptr, GetIconColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconHaloColor", nullptr, SetIconHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconHaloColor", nullptr, GetIconHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconHaloWidth", nullptr, SetIconHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconHaloWidth", nullptr, GetIconHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Paint properties - Text
        { "setTextOpacity", nullptr, SetTextOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextOpacity", nullptr, GetTextOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextColor", nullptr, SetTextColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextColor", nullptr, GetTextColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextHaloColor", nullptr, SetTextHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextHaloColor", nullptr, GetTextHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextHaloWidth", nullptr, SetTextHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextHaloWidth", nullptr, GetTextHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "SymbolLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("SymbolLayerNAPI", "Failed to define SymbolLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("SymbolLayerNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "SymbolLayer", cons);
    if (status != napi_ok) {
        Logger::error("SymbolLayerNAPI", "Failed to set SymbolLayer property");
        return nullptr;
    }
    
    Logger::info("SymbolLayerNAPI", "SymbolLayer NAPI class initialized successfully");
    return exports;
}

napi_value SymbolLayerNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "SymbolLayer requires layerId and sourceId arguments");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    std::string layerId = napiArgs.GetString(0, "layerId");
    std::string sourceId = napiArgs.GetString(1, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse arguments");
        return nullptr;
    }
    
    try {
        SymbolLayerNAPI* layerNapi = new SymbolLayerNAPI(layerId, sourceId);
        
        napi_status status = napi_wrap(env, jsThis, layerNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete layerNapi;
            napi_throw_error(env, nullptr, "Failed to wrap SymbolLayer object");
            return nullptr;
        }
        
        Logger::info("SymbolLayerNAPI", "SymbolLayer created: %s", layerId.c_str());
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("SymbolLayerNAPI", "Failed to create SymbolLayer: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// ==================== Basic Methods ====================

napi_value SymbolLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, layerNapi->layer->getID());
}

napi_value SymbolLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return CreateStringValue(env, "symbol");
}

napi_value SymbolLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, layerNapi->layer->getSourceID());
}

napi_value SymbolLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string sourceLayer = args.GetString(0, "sourceLayer");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setSourceLayer(sourceLayer);
    return nullptr;
}

napi_value SymbolLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, layerNapi->layer->getSourceLayer());
}

napi_value SymbolLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float minZoom = args.GetFloat(0, "minZoom");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setMinZoom(minZoom);
    return nullptr;
}

napi_value SymbolLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 0.0f);
    }
    
    return CreateNumberValue(env, layerNapi->layer->getMinZoom());
}

napi_value SymbolLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float maxZoom = args.GetFloat(0, "maxZoom");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setMaxZoom(maxZoom);
    return nullptr;
}

napi_value SymbolLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 22.0f);
    }
    
    return CreateNumberValue(env, layerNapi->layer->getMaxZoom());
}

// ==================== Layout Properties - Icon ====================

napi_value SymbolLayerNAPI::SetIconImage(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string iconImage = args.GetString(0, "iconImage");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setIconImage(mbgl::style::PropertyValue<std::string>(iconImage));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconImage(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "");
    }
    
    auto value = layerNapi->layer->getIconImage();
    if (value.isConstant()) {
        return CreateStringValue(env, value.asConstant());
    }
    
    return CreateStringValue(env, "");
}

napi_value SymbolLayerNAPI::SetIconSize(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float size = args.GetFloat(0, "iconSize");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setIconSize(mbgl::style::PropertyValue<float>(size));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconSize(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 1.0f);
    }
    
    auto value = layerNapi->layer->getIconSize();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 1.0f);
}

napi_value SymbolLayerNAPI::SetIconRotate(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float rotate = args.GetFloat(0, "iconRotate");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setIconRotate(mbgl::style::PropertyValue<float>(rotate));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconRotate(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 0.0f);
    }
    
    auto value = layerNapi->layer->getIconRotate();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 0.0f);
}

napi_value SymbolLayerNAPI::SetIconOffset(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    // Expecting [x, y] array
    // For simplicity, we'll accept two separate arguments
    float x = args.GetFloat(0, "offsetX");
    float y = args.GetFloat(1, "offsetY");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    std::array<float, 2> offset = {x, y};
    layerNapi->layer->setIconOffset(mbgl::style::PropertyValue<std::array<float, 2>>(offset));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconOffset(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_value array;
        napi_create_array_with_length(env, 2, &array);
        napi_value zero;
        napi_create_double(env, 0.0, &zero);
        napi_set_element(env, array, 0, zero);
        napi_set_element(env, array, 1, zero);
        return array;
    }
    
    auto value = layerNapi->layer->getIconOffset();
    if (value.isConstant()) {
        auto offset = value.asConstant();
        napi_value array;
        napi_create_array_with_length(env, 2, &array);
        napi_value x, y;
        napi_create_double(env, offset[0], &x);
        napi_create_double(env, offset[1], &y);
        napi_set_element(env, array, 0, x);
        napi_set_element(env, array, 1, y);
        return array;
    }
    
    napi_value array;
    napi_create_array_with_length(env, 2, &array);
    napi_value zero;
    napi_create_double(env, 0.0, &zero);
    napi_set_element(env, array, 0, zero);
    napi_set_element(env, array, 1, zero);
    return array;
}

napi_value SymbolLayerNAPI::SetIconAnchor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string anchor = args.GetString(0, "iconAnchor");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    // Convert string to enum
    mbgl::style::SymbolAnchorType anchorType = mbgl::style::SymbolAnchorType::Center;
    if (anchor == "center") anchorType = mbgl::style::SymbolAnchorType::Center;
    else if (anchor == "left") anchorType = mbgl::style::SymbolAnchorType::Left;
    else if (anchor == "right") anchorType = mbgl::style::SymbolAnchorType::Right;
    else if (anchor == "top") anchorType = mbgl::style::SymbolAnchorType::Top;
    else if (anchor == "bottom") anchorType = mbgl::style::SymbolAnchorType::Bottom;
    else if (anchor == "top-left") anchorType = mbgl::style::SymbolAnchorType::TopLeft;
    else if (anchor == "top-right") anchorType = mbgl::style::SymbolAnchorType::TopRight;
    else if (anchor == "bottom-left") anchorType = mbgl::style::SymbolAnchorType::BottomLeft;
    else if (anchor == "bottom-right") anchorType = mbgl::style::SymbolAnchorType::BottomRight;
    
    layerNapi->layer->setIconAnchor(mbgl::style::PropertyValue<mbgl::style::SymbolAnchorType>(anchorType));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconAnchor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "center");
    }
    
    auto value = layerNapi->layer->getIconAnchor();
    if (value.isConstant()) {
        auto anchor = value.asConstant();
        switch (anchor) {
            case mbgl::style::SymbolAnchorType::Center: return CreateStringValue(env, "center");
            case mbgl::style::SymbolAnchorType::Left: return CreateStringValue(env, "left");
            case mbgl::style::SymbolAnchorType::Right: return CreateStringValue(env, "right");
            case mbgl::style::SymbolAnchorType::Top: return CreateStringValue(env, "top");
            case mbgl::style::SymbolAnchorType::Bottom: return CreateStringValue(env, "bottom");
            case mbgl::style::SymbolAnchorType::TopLeft: return CreateStringValue(env, "top-left");
            case mbgl::style::SymbolAnchorType::TopRight: return CreateStringValue(env, "top-right");
            case mbgl::style::SymbolAnchorType::BottomLeft: return CreateStringValue(env, "bottom-left");
            case mbgl::style::SymbolAnchorType::BottomRight: return CreateStringValue(env, "bottom-right");
        }
    }
    
    return CreateStringValue(env, "center");
}

napi_value SymbolLayerNAPI::SetIconAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    bool allowOverlap = args.GetBoolean(0, "iconAllowOverlap");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setIconAllowOverlap(mbgl::style::PropertyValue<bool>(allowOverlap));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateBooleanValue(env, false);
    }
    
    auto value = layerNapi->layer->getIconAllowOverlap();
    if (value.isConstant()) {
        return CreateBooleanValue(env, value.asConstant());
    }
    
    return CreateBooleanValue(env, false);
}

// ==================== Layout Properties - Text ====================

napi_value SymbolLayerNAPI::SetTextField(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string textField = args.GetString(0, "textField");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    // TODO: Support Formatted text
    layerNapi->layer->setTextField(mbgl::style::PropertyValue<std::string>(textField));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextField(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "");
    }
    
    // TODO: Handle Formatted text
    return CreateStringValue(env, "");
}

napi_value SymbolLayerNAPI::SetTextFont(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    // TODO: Accept array of font names
    NapiArgs args(env, info);
    std::string font = args.GetString(0, "textFont");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    std::vector<std::string> fonts = {font};
    layerNapi->layer->setTextFont(mbgl::style::PropertyValue<std::vector<std::string>>(fonts));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextFont(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_value array;
        napi_create_array_with_length(env, 0, &array);
        return array;
    }
    
    auto value = layerNapi->layer->getTextFont();
    if (value.isConstant()) {
        auto fonts = value.asConstant();
        napi_value array;
        napi_create_array_with_length(env, fonts.size(), &array);
        for (size_t i = 0; i < fonts.size(); i++) {
            napi_value font = CreateStringValue(env, fonts[i]);
            napi_set_element(env, array, i, font);
        }
        return array;
    }
    
    napi_value array;
    napi_create_array_with_length(env, 0, &array);
    return array;
}

napi_value SymbolLayerNAPI::SetTextSize(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float size = args.GetFloat(0, "textSize");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setTextSize(mbgl::style::PropertyValue<float>(size));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextSize(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 16.0f);
    }
    
    auto value = layerNapi->layer->getTextSize();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 16.0f);
}

napi_value SymbolLayerNAPI::SetTextMaxWidth(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float maxWidth = args.GetFloat(0, "textMaxWidth");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setTextMaxWidth(mbgl::style::PropertyValue<float>(maxWidth));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextMaxWidth(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 10.0f);
    }
    
    auto value = layerNapi->layer->getTextMaxWidth();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 10.0f);
}

napi_value SymbolLayerNAPI::SetTextOffset(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float x = args.GetFloat(0, "offsetX");
    float y = args.GetFloat(1, "offsetY");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    std::array<float, 2> offset = {x, y};
    layerNapi->layer->setTextOffset(mbgl::style::PropertyValue<std::array<float, 2>>(offset));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextOffset(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_value array;
        napi_create_array_with_length(env, 2, &array);
        napi_value zero;
        napi_create_double(env, 0.0, &zero);
        napi_set_element(env, array, 0, zero);
        napi_set_element(env, array, 1, zero);
        return array;
    }
    
    auto value = layerNapi->layer->getTextOffset();
    if (value.isConstant()) {
        auto offset = value.asConstant();
        napi_value array;
        napi_create_array_with_length(env, 2, &array);
        napi_value x, y;
        napi_create_double(env, offset[0], &x);
        napi_create_double(env, offset[1], &y);
        napi_set_element(env, array, 0, x);
        napi_set_element(env, array, 1, y);
        return array;
    }
    
    napi_value array;
    napi_create_array_with_length(env, 2, &array);
    napi_value zero;
    napi_create_double(env, 0.0, &zero);
    napi_set_element(env, array, 0, zero);
    napi_set_element(env, array, 1, zero);
    return array;
}

napi_value SymbolLayerNAPI::SetTextAnchor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string anchor = args.GetString(0, "textAnchor");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    mbgl::style::SymbolAnchorType anchorType = mbgl::style::SymbolAnchorType::Center;
    if (anchor == "center") anchorType = mbgl::style::SymbolAnchorType::Center;
    else if (anchor == "left") anchorType = mbgl::style::SymbolAnchorType::Left;
    else if (anchor == "right") anchorType = mbgl::style::SymbolAnchorType::Right;
    else if (anchor == "top") anchorType = mbgl::style::SymbolAnchorType::Top;
    else if (anchor == "bottom") anchorType = mbgl::style::SymbolAnchorType::Bottom;
    else if (anchor == "top-left") anchorType = mbgl::style::SymbolAnchorType::TopLeft;
    else if (anchor == "top-right") anchorType = mbgl::style::SymbolAnchorType::TopRight;
    else if (anchor == "bottom-left") anchorType = mbgl::style::SymbolAnchorType::BottomLeft;
    else if (anchor == "bottom-right") anchorType = mbgl::style::SymbolAnchorType::BottomRight;
    
    layerNapi->layer->setTextAnchor(mbgl::style::PropertyValue<mbgl::style::SymbolAnchorType>(anchorType));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextAnchor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "center");
    }
    
    auto value = layerNapi->layer->getTextAnchor();
    if (value.isConstant()) {
        auto anchor = value.asConstant();
        switch (anchor) {
            case mbgl::style::SymbolAnchorType::Center: return CreateStringValue(env, "center");
            case mbgl::style::SymbolAnchorType::Left: return CreateStringValue(env, "left");
            case mbgl::style::SymbolAnchorType::Right: return CreateStringValue(env, "right");
            case mbgl::style::SymbolAnchorType::Top: return CreateStringValue(env, "top");
            case mbgl::style::SymbolAnchorType::Bottom: return CreateStringValue(env, "bottom");
            case mbgl::style::SymbolAnchorType::TopLeft: return CreateStringValue(env, "top-left");
            case mbgl::style::SymbolAnchorType::TopRight: return CreateStringValue(env, "top-right");
            case mbgl::style::SymbolAnchorType::BottomLeft: return CreateStringValue(env, "bottom-left");
            case mbgl::style::SymbolAnchorType::BottomRight: return CreateStringValue(env, "bottom-right");
        }
    }
    
    return CreateStringValue(env, "center");
}

napi_value SymbolLayerNAPI::SetTextAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    bool allowOverlap = args.GetBoolean(0, "textAllowOverlap");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setTextAllowOverlap(mbgl::style::PropertyValue<bool>(allowOverlap));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateBooleanValue(env, false);
    }
    
    auto value = layerNapi->layer->getTextAllowOverlap();
    if (value.isConstant()) {
        return CreateBooleanValue(env, value.asConstant());
    }
    
    return CreateBooleanValue(env, false);
}

// ==================== Paint Properties - Icon ====================

napi_value SymbolLayerNAPI::SetIconOpacity(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float opacity = args.GetFloat(0, "iconOpacity");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setIconOpacity(mbgl::style::PropertyValue<float>(opacity));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconOpacity(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 1.0f);
    }
    
    auto value = layerNapi->layer->getIconOpacity();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 1.0f);
}

napi_value SymbolLayerNAPI::SetIconColor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string colorStr = args.GetString(0, "iconColor");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    // Parse color string (simple implementation, supports "#RRGGBB" format)
    mbgl::Color color = mbgl::Color::black();
    // TODO: Implement proper color parsing
    
    layerNapi->layer->setIconColor(mbgl::style::PropertyValue<mbgl::Color>(color));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconColor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateStringValue(env, "#000000");
    }
    
    // TODO: Convert color to string
    return CreateStringValue(env, "#000000");
}

napi_value SymbolLayerNAPI::SetIconHaloColor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string colorStr = args.GetString(0, "iconHaloColor");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    mbgl::Color color = mbgl::Color::black();
    // TODO: Parse color
    
    layerNapi->layer->setIconHaloColor(mbgl::style::PropertyValue<mbgl::Color>(color));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconHaloColor(napi_env env, napi_callback_info info) {
    return CreateStringValue(env, "#000000");
}

napi_value SymbolLayerNAPI::SetIconHaloWidth(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float width = args.GetFloat(0, "iconHaloWidth");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setIconHaloWidth(mbgl::style::PropertyValue<float>(width));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetIconHaloWidth(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 0.0f);
    }
    
    auto value = layerNapi->layer->getIconHaloWidth();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 0.0f);
}

// ==================== Paint Properties - Text ====================

napi_value SymbolLayerNAPI::SetTextOpacity(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float opacity = args.GetFloat(0, "textOpacity");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setTextOpacity(mbgl::style::PropertyValue<float>(opacity));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextOpacity(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 1.0f);
    }
    
    auto value = layerNapi->layer->getTextOpacity();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 1.0f);
}

napi_value SymbolLayerNAPI::SetTextColor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string colorStr = args.GetString(0, "textColor");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    mbgl::Color color = mbgl::Color::black();
    // TODO: Parse color
    
    layerNapi->layer->setTextColor(mbgl::style::PropertyValue<mbgl::Color>(color));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextColor(napi_env env, napi_callback_info info) {
    return CreateStringValue(env, "#000000");
}

napi_value SymbolLayerNAPI::SetTextHaloColor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string colorStr = args.GetString(0, "textHaloColor");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    mbgl::Color color = mbgl::Color::black();
    // TODO: Parse color
    
    layerNapi->layer->setTextHaloColor(mbgl::style::PropertyValue<mbgl::Color>(color));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextHaloColor(napi_env env, napi_callback_info info) {
    return CreateStringValue(env, "#000000");
}

napi_value SymbolLayerNAPI::SetTextHaloWidth(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        napi_throw_error(env, nullptr, "Invalid layer");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    float width = args.GetFloat(0, "textHaloWidth");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    layerNapi->layer->setTextHaloWidth(mbgl::style::PropertyValue<float>(width));
    return nullptr;
}

napi_value SymbolLayerNAPI::GetTextHaloWidth(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    SymbolLayerNAPI* layerNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&layerNapi));
    
    if (!layerNapi || !layerNapi->layer) {
        return CreateNumberValue(env, 0.0f);
    }
    
    auto value = layerNapi->layer->getTextHaloWidth();
    if (value.isConstant()) {
        return CreateNumberValue(env, value.asConstant());
    }
    
    return CreateNumberValue(env, 0.0f);
}

} // namespace harmony
} // namespace maplibre

