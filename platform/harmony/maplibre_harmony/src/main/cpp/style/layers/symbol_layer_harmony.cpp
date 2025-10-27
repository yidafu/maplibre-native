#include "symbol_layer_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/symbol_layer.hpp>
#include <mbgl/style/expression/formatted.hpp>
#include <mbgl/style/expression/image.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {
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
        
        // Layout properties - Icon (支持 Expression)
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
        
        // Layout properties - Text (支持 Expression)
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
        
        // Paint properties - Icon (支持 Expression)
        { "setIconOpacity", nullptr, SetIconOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconOpacity", nullptr, GetIconOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconColor", nullptr, SetIconColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconColor", nullptr, GetIconColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconHaloColor", nullptr, SetIconHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconHaloColor", nullptr, GetIconHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconHaloWidth", nullptr, SetIconHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconHaloWidth", nullptr, GetIconHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Paint properties - Text (支持 Expression)
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
    NapiArgs args(env, info);
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) {
        return nullptr;
    }
    
    SymbolLayerNAPI* layerObj = new SymbolLayerNAPI(layerId, sourceId);
    napi_wrap(env, jsThis, layerObj, Destructor, nullptr, nullptr);
    return jsThis;
}

// ============================================================================
// Basic Layer Methods
// ============================================================================

napi_value SymbolLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string id = layerObj->layer->getID();
    napi_value result;
    napi_create_string_utf8(env, id.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value SymbolLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "symbol", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value SymbolLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string sourceId = layerObj->layer->getSourceID();
    napi_value result;
    napi_create_string_utf8(env, sourceId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value SymbolLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layerObj->layer->setSourceLayer(sourceLayer);
    }
    return thisVar;
}

napi_value SymbolLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string sourceLayer = layerObj->layer->getSourceLayer();
    napi_value result;
    napi_create_string_utf8(env, sourceLayer.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value SymbolLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layerObj->layer->setMinZoom(minZoom);
    }
    return thisVar;
}

napi_value SymbolLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }
    
    float minZoom = layerObj->layer->getMinZoom();
    napi_value result;
    napi_create_double(env, minZoom, &result);
    return result;
}

napi_value SymbolLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layerObj->layer->setMaxZoom(maxZoom);
    }
    return thisVar;
}

napi_value SymbolLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }
    
    float maxZoom = layerObj->layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

// ============================================================================
// Layout Properties - Icon (支持 Expression)
// ============================================================================

napi_value SymbolLayerNAPI::SetIconImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Image>(
        env, layerObj->layer.get(), argv[0], "icon-image",
        &mbgl::style::SymbolLayer::setIconImage
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Image>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconImage
    );
}

napi_value SymbolLayerNAPI::SetIconSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "icon-size",
        &mbgl::style::SymbolLayer::setIconSize
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconSize
    );
}

napi_value SymbolLayerNAPI::SetIconRotate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "icon-rotate",
        &mbgl::style::SymbolLayer::setIconRotate
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconRotate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconRotate
    );
}

napi_value SymbolLayerNAPI::SetIconOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->layer.get(), argv[0], "icon-offset",
        &mbgl::style::SymbolLayer::setIconOffset
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconOffset
    );
}

napi_value SymbolLayerNAPI::SetIconAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->layer.get(), argv[0], "icon-anchor",
        &mbgl::style::SymbolLayer::setIconAnchor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconAnchor
    );
}

napi_value SymbolLayerNAPI::SetIconAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->layer.get(), argv[0], "icon-allow-overlap",
        &mbgl::style::SymbolLayer::setIconAllowOverlap
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconAllowOverlap
    );
}

// ============================================================================
// Layout Properties - Text (支持 Expression)
// ============================================================================

napi_value SymbolLayerNAPI::SetTextField(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Formatted>(
        env, layerObj->layer.get(), argv[0], "text-field",
        &mbgl::style::SymbolLayer::setTextField
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextField(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Formatted>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextField
    );
}

napi_value SymbolLayerNAPI::SetTextFont(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::vector<std::string>>(
        env, layerObj->layer.get(), argv[0], "text-font",
        &mbgl::style::SymbolLayer::setTextFont
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextFont(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::vector<std::string>>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextFont
    );
}

napi_value SymbolLayerNAPI::SetTextSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "text-size",
        &mbgl::style::SymbolLayer::setTextSize
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextSize
    );
}

napi_value SymbolLayerNAPI::SetTextMaxWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "text-max-width",
        &mbgl::style::SymbolLayer::setTextMaxWidth
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextMaxWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextMaxWidth
    );
}

napi_value SymbolLayerNAPI::SetTextOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->layer.get(), argv[0], "text-offset",
        &mbgl::style::SymbolLayer::setTextOffset
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextOffset
    );
}

napi_value SymbolLayerNAPI::SetTextAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->layer.get(), argv[0], "text-anchor",
        &mbgl::style::SymbolLayer::setTextAnchor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextAnchor
    );
}

napi_value SymbolLayerNAPI::SetTextAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->layer.get(), argv[0], "text-allow-overlap",
        &mbgl::style::SymbolLayer::setTextAllowOverlap
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextAllowOverlap
    );
}

// ============================================================================
// Paint Properties - Icon (支持 Expression)
// ============================================================================

napi_value SymbolLayerNAPI::SetIconOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "icon-opacity",
        &mbgl::style::SymbolLayer::setIconOpacity
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconOpacity
    );
}

napi_value SymbolLayerNAPI::SetIconColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), argv[0], "icon-color",
        &mbgl::style::SymbolLayer::setIconColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconColor
    );
}

napi_value SymbolLayerNAPI::SetIconHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), argv[0], "icon-halo-color",
        &mbgl::style::SymbolLayer::setIconHaloColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconHaloColor
    );
}

napi_value SymbolLayerNAPI::SetIconHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "icon-halo-width",
        &mbgl::style::SymbolLayer::setIconHaloWidth
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getIconHaloWidth
    );
}

// ============================================================================
// Paint Properties - Text (支持 Expression)
// ============================================================================

napi_value SymbolLayerNAPI::SetTextOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "text-opacity",
        &mbgl::style::SymbolLayer::setTextOpacity
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextOpacity
    );
}

napi_value SymbolLayerNAPI::SetTextColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), argv[0], "text-color",
        &mbgl::style::SymbolLayer::setTextColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextColor
    );
}

napi_value SymbolLayerNAPI::SetTextHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), argv[0], "text-halo-color",
        &mbgl::style::SymbolLayer::setTextHaloColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextHaloColor
    );
}

napi_value SymbolLayerNAPI::SetTextHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), argv[0], "text-halo-width",
        &mbgl::style::SymbolLayer::setTextHaloWidth
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::SymbolLayer::getTextHaloWidth
    );
}

} // namespace harmony
} // namespace mbgl
