#include "symbol_layer_harmony.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include "style/harmony_symbol_layer_properties.hpp"
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
    
// Set the default fonts for the Harmony platform
    auto defaultFonts = mbgl::style::harmony::getDefaultTextFont();
    layer->setTextFont(mbgl::style::PropertyValue<std::vector<std::string>>(defaultFonts));
    
    Logger::info("SymbolLayerNAPI", "SymbolLayer created: %s (source: %s) with Harmony fonts", 
                 layerId.c_str(), sourceId.c_str());
}

SymbolLayerNAPI::SymbolLayerNAPI(mbgl::style::SymbolLayer* layerPtr)
    : ownsLayer(false) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("SymbolLayerNAPI", "SymbolLayer created from existing layer (WeakPtr)");
    }
}


SymbolLayerNAPI::SymbolLayerNAPI(std::unique_ptr<mbgl::style::SymbolLayer> layer_)
    : layer(std::move(layer_)), ownsLayer(true) {
    Logger::info("SymbolLayerNAPI", "SymbolLayer created from existing layer");
}

SymbolLayerNAPI::~SymbolLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("SymbolLayerNAPI", "SymbolLayer destroyed");
}

void SymbolLayerNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
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
        
        // Visibility control
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Filter
        { "setFilter", nullptr, SetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFilter", nullptr, GetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layout properties - Icon (Expression supported)
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
        
        // Layout properties - Text (Expression supported)
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
        
        // Paint properties - Icon (Expression supported)
        { "setIconOpacity", nullptr, SetIconOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconOpacity", nullptr, GetIconOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconColor", nullptr, SetIconColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconColor", nullptr, GetIconColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconHaloColor", nullptr, SetIconHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconHaloColor", nullptr, GetIconHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconHaloWidth", nullptr, SetIconHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconHaloWidth", nullptr, GetIconHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Paint properties - Text (Expression supported)
        { "setTextOpacity", nullptr, SetTextOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextOpacity", nullptr, GetTextOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextColor", nullptr, SetTextColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextColor", nullptr, GetTextColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextHaloColor", nullptr, SetTextHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextHaloColor", nullptr, GetTextHaloColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextHaloWidth", nullptr, SetTextHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextHaloWidth", nullptr, GetTextHaloWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // New Icon layout properties
        { "setIconIgnorePlacement", nullptr, SetIconIgnorePlacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconIgnorePlacement", nullptr, GetIconIgnorePlacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconOptional", nullptr, SetIconOptional, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconOptional", nullptr, GetIconOptional, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconPadding", nullptr, SetIconPadding, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconPadding", nullptr, GetIconPadding, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconKeepUpright", nullptr, SetIconKeepUpright, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconKeepUpright", nullptr, GetIconKeepUpright, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconPitchAlignment", nullptr, SetIconPitchAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconPitchAlignment", nullptr, GetIconPitchAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconRotationAlignment", nullptr, SetIconRotationAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconRotationAlignment", nullptr, GetIconRotationAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconTextFit", nullptr, SetIconTextFit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconTextFit", nullptr, GetIconTextFit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconTextFitPadding", nullptr, SetIconTextFitPadding, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconTextFitPadding", nullptr, GetIconTextFitPadding, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // New Text layout properties
        { "setTextLetterSpacing", nullptr, SetTextLetterSpacing, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextLetterSpacing", nullptr, GetTextLetterSpacing, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextJustify", nullptr, SetTextJustify, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextJustify", nullptr, GetTextJustify, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextRadialOffset", nullptr, SetTextRadialOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextRadialOffset", nullptr, GetTextRadialOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextVariableAnchor", nullptr, SetTextVariableAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextVariableAnchor", nullptr, GetTextVariableAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextVariableAnchorOffset", nullptr, SetTextVariableAnchorOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextVariableAnchorOffset", nullptr, GetTextVariableAnchorOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextRotate", nullptr, SetTextRotate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextRotate", nullptr, GetTextRotate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextPadding", nullptr, SetTextPadding, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextPadding", nullptr, GetTextPadding, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextKeepUpright", nullptr, SetTextKeepUpright, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextKeepUpright", nullptr, GetTextKeepUpright, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextTransform", nullptr, SetTextTransform, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextTransform", nullptr, GetTextTransform, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextMaxAngle", nullptr, SetTextMaxAngle, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextMaxAngle", nullptr, GetTextMaxAngle, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextRotationAlignment", nullptr, SetTextRotationAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextRotationAlignment", nullptr, GetTextRotationAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextPitchAlignment", nullptr, SetTextPitchAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextPitchAlignment", nullptr, GetTextPitchAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextLineHeight", nullptr, SetTextLineHeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextLineHeight", nullptr, GetTextLineHeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextWritingMode", nullptr, SetTextWritingMode, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextWritingMode", nullptr, GetTextWritingMode, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextIgnorePlacement", nullptr, SetTextIgnorePlacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextIgnorePlacement", nullptr, GetTextIgnorePlacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextOptional", nullptr, SetTextOptional, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextOptional", nullptr, GetTextOptional, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Symbol common layout properties
        { "setSymbolPlacement", nullptr, SetSymbolPlacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSymbolPlacement", nullptr, GetSymbolPlacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSymbolSpacing", nullptr, SetSymbolSpacing, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSymbolSpacing", nullptr, GetSymbolSpacing, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSymbolAvoidEdges", nullptr, SetSymbolAvoidEdges, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSymbolAvoidEdges", nullptr, GetSymbolAvoidEdges, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSymbolSortKey", nullptr, SetSymbolSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSymbolSortKey", nullptr, GetSymbolSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSymbolZOrder", nullptr, SetSymbolZOrder, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSymbolZOrder", nullptr, GetSymbolZOrder, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // New Paint properties
        { "setIconHaloBlur", nullptr, SetIconHaloBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconHaloBlur", nullptr, GetIconHaloBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconTranslate", nullptr, SetIconTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconTranslate", nullptr, GetIconTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIconTranslateAnchor", nullptr, SetIconTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getIconTranslateAnchor", nullptr, GetIconTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextHaloBlur", nullptr, SetTextHaloBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextHaloBlur", nullptr, GetTextHaloBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextTranslate", nullptr, SetTextTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextTranslate", nullptr, GetTextTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTextTranslateAnchor", nullptr, SetTextTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTextTranslateAnchor", nullptr, GetTextTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
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
    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "SymbolLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, jsThis, "_TYPE_", typeValue);
    return jsThis;
}

napi_value SymbolLayerNAPI::CreateInstance(napi_env env, mbgl::style::SymbolLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("SymbolLayerNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create a plain object and set its prototype (avoid invoking the JS constructor)
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor prototype
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Set the object's prototype
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create the NAPI wrapper (using the WeakPtr constructor)
    SymbolLayerNAPI* napiObj = new SymbolLayerNAPI(layerPtr);
    
    // Wrap into the JS object
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("SymbolLayerNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Add the _TYPE_ property
    napi_value typeValue;
    napi_create_string_utf8(env, "SymbolLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}


// ============================================================================
// Basic Layer Methods
// ============================================================================

napi_value SymbolLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string id = layerObj->getLayer()->getID();
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
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string sourceId = layerObj->getLayer()->getSourceID();
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
    
    if (!layerObj || !layerObj->getLayer()) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layerObj->getLayer()->setSourceLayer(sourceLayer);
    }
    return thisVar;
}

napi_value SymbolLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string sourceLayer = layerObj->getLayer()->getSourceLayer();
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
    
    if (!layerObj || !layerObj->getLayer()) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layerObj->getLayer()->setMinZoom(minZoom);
    }
    return thisVar;
}

napi_value SymbolLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }
    
    float minZoom = layerObj->getLayer()->getMinZoom();
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
    
    if (!layerObj || !layerObj->getLayer()) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layerObj->getLayer()->setMaxZoom(maxZoom);
    }
    return thisVar;
}

napi_value SymbolLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }
    
    float maxZoom = layerObj->getLayer()->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

// ============================================================================
// Layout Properties - Icon (Expression supported)
// ============================================================================

napi_value SymbolLayerNAPI::SetIconImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setDataDrivenLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), argv[0], "icon-image",
        &mbgl::style::SymbolLayer::setIconImage
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconImage
    );
}

napi_value SymbolLayerNAPI::SetIconSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "icon-size",
        &mbgl::style::SymbolLayer::setIconSize
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconSize
    );
}

napi_value SymbolLayerNAPI::SetIconRotate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setDataDrivenLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "icon-rotate",
        &mbgl::style::SymbolLayer::setIconRotate
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconRotate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconRotate
    );
}

napi_value SymbolLayerNAPI::SetIconOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), argv[0], "icon-offset",
        &mbgl::style::SymbolLayer::setIconOffset
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconOffset
    );
}

napi_value SymbolLayerNAPI::SetIconAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->getLayer(), argv[0], "icon-anchor",
        &mbgl::style::SymbolLayer::setIconAnchor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconAnchor
    );
}

napi_value SymbolLayerNAPI::SetIconAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    // 🔍 Debug log: inspect the provided value
    bool result = mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "icon-allow-overlap",
        &mbgl::style::SymbolLayer::setIconAllowOverlap
    );
    Logger::info("SymbolLayerNAPI", "SetIconAllowOverlap called, result=%d", result);
    
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconAllowOverlap
    );
}

// ============================================================================
// Layout Properties - Text (Expression supported)
// ============================================================================

napi_value SymbolLayerNAPI::SetTextField(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    // text-field supports data-driven expressions
    mbgl::harmony::setDataDrivenLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Formatted>(
        env, layerObj->getLayer(), argv[0], "text-field",
        &mbgl::style::SymbolLayer::setTextField
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextField(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::expression::Formatted>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextField
    );
}

napi_value SymbolLayerNAPI::SetTextFont(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::vector<std::string>>(
        env, layerObj->getLayer(), argv[0], "text-font",
        &mbgl::style::SymbolLayer::setTextFont
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextFont(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::vector<std::string>>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextFont
    );
}

napi_value SymbolLayerNAPI::SetTextSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-size",
        &mbgl::style::SymbolLayer::setTextSize
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextSize
    );
}

napi_value SymbolLayerNAPI::SetTextMaxWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-max-width",
        &mbgl::style::SymbolLayer::setTextMaxWidth
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextMaxWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextMaxWidth
    );
}

napi_value SymbolLayerNAPI::SetTextOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), argv[0], "text-offset",
        &mbgl::style::SymbolLayer::setTextOffset
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextOffset
    );
}

napi_value SymbolLayerNAPI::SetTextAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->getLayer(), argv[0], "text-anchor",
        &mbgl::style::SymbolLayer::setTextAnchor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolAnchorType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextAnchor
    );
}

napi_value SymbolLayerNAPI::SetTextAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    // 🔍 Debug log: inspect the provided value
    bool result = mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "text-allow-overlap",
        &mbgl::style::SymbolLayer::setTextAllowOverlap
    );
    Logger::info("SymbolLayerNAPI", "SetTextAllowOverlap called, result=%d", result);
    
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextAllowOverlap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextAllowOverlap
    );
}

// ============================================================================
// Paint Properties - Icon (Expression supported)
// ============================================================================

napi_value SymbolLayerNAPI::SetIconOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "icon-opacity",
        &mbgl::style::SymbolLayer::setIconOpacity
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconOpacity
    );
}

napi_value SymbolLayerNAPI::SetIconColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "icon-color",
        &mbgl::style::SymbolLayer::setIconColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconColor
    );
}

napi_value SymbolLayerNAPI::SetIconHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "icon-halo-color",
        &mbgl::style::SymbolLayer::setIconHaloColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconHaloColor
    );
}

napi_value SymbolLayerNAPI::SetIconHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "icon-halo-width",
        &mbgl::style::SymbolLayer::setIconHaloWidth
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconHaloWidth
    );
}

// ============================================================================
// Paint Properties - Text (Expression supported)
// ============================================================================

napi_value SymbolLayerNAPI::SetTextOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-opacity",
        &mbgl::style::SymbolLayer::setTextOpacity
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextOpacity
    );
}

napi_value SymbolLayerNAPI::SetTextColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "text-color",
        &mbgl::style::SymbolLayer::setTextColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextColor
    );
}

napi_value SymbolLayerNAPI::SetTextHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "text-halo-color",
        &mbgl::style::SymbolLayer::setTextHaloColor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextHaloColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Color>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextHaloColor
    );
}

napi_value SymbolLayerNAPI::SetTextHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-halo-width",
        &mbgl::style::SymbolLayer::setTextHaloWidth
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextHaloWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextHaloWidth
    );
}

// ============================================================================
// New Icon Layout Properties
// ============================================================================

napi_value SymbolLayerNAPI::SetIconIgnorePlacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "icon-ignore-placement",
        &mbgl::style::SymbolLayer::setIconIgnorePlacement
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconIgnorePlacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconIgnorePlacement
    );
}

napi_value SymbolLayerNAPI::SetIconOptional(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "icon-optional",
        &mbgl::style::SymbolLayer::setIconOptional
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconOptional(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconOptional
    );
}

napi_value SymbolLayerNAPI::SetIconPadding(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::Padding>(
        env, layerObj->getLayer(), argv[0], "icon-padding",
        &mbgl::style::SymbolLayer::setIconPadding
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconPadding(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::Padding>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconPadding
    );
}

napi_value SymbolLayerNAPI::SetIconKeepUpright(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "icon-keep-upright",
        &mbgl::style::SymbolLayer::setIconKeepUpright
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconKeepUpright(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconKeepUpright
    );
}

napi_value SymbolLayerNAPI::SetIconPitchAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), argv[0], "icon-pitch-alignment",
        &mbgl::style::SymbolLayer::setIconPitchAlignment
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconPitchAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconPitchAlignment
    );
}

napi_value SymbolLayerNAPI::SetIconRotationAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), argv[0], "icon-rotation-alignment",
        &mbgl::style::SymbolLayer::setIconRotationAlignment
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconRotationAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconRotationAlignment
    );
}

napi_value SymbolLayerNAPI::SetIconTextFit(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::IconTextFitType>(
        env, layerObj->getLayer(), argv[0], "icon-text-fit",
        &mbgl::style::SymbolLayer::setIconTextFit
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconTextFit(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::IconTextFitType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconTextFit
    );
}

napi_value SymbolLayerNAPI::SetIconTextFitPadding(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::array<float, 4>>(
        env, layerObj->getLayer(), argv[0], "icon-text-fit-padding",
        &mbgl::style::SymbolLayer::setIconTextFitPadding
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconTextFitPadding(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::array<float, 4>>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconTextFitPadding
    );
}

// ============================================================================
// New Text Layout Properties
// ============================================================================

napi_value SymbolLayerNAPI::SetTextLetterSpacing(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-letter-spacing",
        &mbgl::style::SymbolLayer::setTextLetterSpacing
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextLetterSpacing(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextLetterSpacing
    );
}

napi_value SymbolLayerNAPI::SetTextJustify(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::TextJustifyType>(
        env, layerObj->getLayer(), argv[0], "text-justify",
        &mbgl::style::SymbolLayer::setTextJustify
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextJustify(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::TextJustifyType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextJustify
    );
}

napi_value SymbolLayerNAPI::SetTextRadialOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-radial-offset",
        &mbgl::style::SymbolLayer::setTextRadialOffset
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextRadialOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextRadialOffset
    );
}

napi_value SymbolLayerNAPI::SetTextVariableAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::vector<mbgl::style::TextVariableAnchorType>>(
        env, layerObj->getLayer(), argv[0], "text-variable-anchor",
        &mbgl::style::SymbolLayer::setTextVariableAnchor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextVariableAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    // TextVariableAnchorType vector requires special conversion - return undefined for now
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value SymbolLayerNAPI::SetTextRotate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-rotate",
        &mbgl::style::SymbolLayer::setTextRotate
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextRotate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextRotate
    );
}

napi_value SymbolLayerNAPI::SetTextPadding(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-padding",
        &mbgl::style::SymbolLayer::setTextPadding
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextPadding(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextPadding
    );
}

napi_value SymbolLayerNAPI::SetTextKeepUpright(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "text-keep-upright",
        &mbgl::style::SymbolLayer::setTextKeepUpright
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextKeepUpright(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextKeepUpright
    );
}

napi_value SymbolLayerNAPI::SetTextTransform(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::TextTransformType>(
        env, layerObj->getLayer(), argv[0], "text-transform",
        &mbgl::style::SymbolLayer::setTextTransform
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextTransform(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::TextTransformType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextTransform
    );
}

napi_value SymbolLayerNAPI::SetTextMaxAngle(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-max-angle",
        &mbgl::style::SymbolLayer::setTextMaxAngle
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextMaxAngle(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextMaxAngle
    );
}

napi_value SymbolLayerNAPI::SetTextRotationAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), argv[0], "text-rotation-alignment",
        &mbgl::style::SymbolLayer::setTextRotationAlignment
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextRotationAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextRotationAlignment
    );
}

napi_value SymbolLayerNAPI::SetTextPitchAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), argv[0], "text-pitch-alignment",
        &mbgl::style::SymbolLayer::setTextPitchAlignment
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextPitchAlignment(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::AlignmentType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextPitchAlignment
    );
}

napi_value SymbolLayerNAPI::SetTextLineHeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-line-height",
        &mbgl::style::SymbolLayer::setTextLineHeight
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextLineHeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextLineHeight
    );
}

napi_value SymbolLayerNAPI::SetTextWritingMode(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, std::vector<mbgl::style::TextWritingModeType>>(
        env, layerObj->getLayer(), argv[0], "text-writing-mode",
        &mbgl::style::SymbolLayer::setTextWritingMode
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextWritingMode(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    // TextWritingModeType vector requires special conversion - return undefined for now
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value SymbolLayerNAPI::SetTextIgnorePlacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "text-ignore-placement",
        &mbgl::style::SymbolLayer::setTextIgnorePlacement
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextIgnorePlacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextIgnorePlacement
    );
}

napi_value SymbolLayerNAPI::SetTextOptional(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "text-optional",
        &mbgl::style::SymbolLayer::setTextOptional
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextOptional(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextOptional
    );
}

// ============================================================================
// Symbol Common Layout Properties
// ============================================================================

napi_value SymbolLayerNAPI::SetSymbolPlacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolPlacementType>(
        env, layerObj->getLayer(), argv[0], "symbol-placement",
        &mbgl::style::SymbolLayer::setSymbolPlacement
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetSymbolPlacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolPlacementType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getSymbolPlacement
    );
}

napi_value SymbolLayerNAPI::SetSymbolSpacing(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "symbol-spacing",
        &mbgl::style::SymbolLayer::setSymbolSpacing
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetSymbolSpacing(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getSymbolSpacing
    );
}

napi_value SymbolLayerNAPI::SetSymbolAvoidEdges(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), argv[0], "symbol-avoid-edges",
        &mbgl::style::SymbolLayer::setSymbolAvoidEdges
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetSymbolAvoidEdges(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, bool>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getSymbolAvoidEdges
    );
}

napi_value SymbolLayerNAPI::SetSymbolSortKey(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "symbol-sort-key",
        &mbgl::style::SymbolLayer::setSymbolSortKey
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetSymbolSortKey(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getSymbolSortKey
    );
}

napi_value SymbolLayerNAPI::SetSymbolZOrder(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolZOrderType>(
        env, layerObj->getLayer(), argv[0], "symbol-z-order",
        &mbgl::style::SymbolLayer::setSymbolZOrder
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetSymbolZOrder(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::SymbolZOrderType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getSymbolZOrder
    );
}

// ============================================================================
// New Paint Properties
// ============================================================================

napi_value SymbolLayerNAPI::SetIconHaloBlur(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "icon-halo-blur",
        &mbgl::style::SymbolLayer::setIconHaloBlur
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconHaloBlur(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconHaloBlur
    );
}

napi_value SymbolLayerNAPI::SetIconTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), argv[0], "icon-translate",
        &mbgl::style::SymbolLayer::setIconTranslate
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconTranslate
    );
}

napi_value SymbolLayerNAPI::SetIconTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->getLayer(), argv[0], "icon-translate-anchor",
        &mbgl::style::SymbolLayer::setIconTranslateAnchor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetIconTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getIconTranslateAnchor
    );
}

napi_value SymbolLayerNAPI::SetTextHaloBlur(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), argv[0], "text-halo-blur",
        &mbgl::style::SymbolLayer::setTextHaloBlur
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextHaloBlur(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextHaloBlur
    );
}

napi_value SymbolLayerNAPI::SetTextTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), argv[0], "text-translate",
        &mbgl::style::SymbolLayer::setTextTranslate
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextTranslate
    );
}

napi_value SymbolLayerNAPI::SetTextTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::SymbolLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->getLayer(), argv[0], "text-translate-anchor",
        &mbgl::style::SymbolLayer::setTextTranslateAnchor
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextTranslateAnchor
    );
}

// ============================================================================
// Visibility
// ============================================================================

napi_value SymbolLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return thisVar;
    }
    
    std::string visibility = args.GetString(0, "visibility");
    if (visibility == "visible") {
        layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::Visible);
    } else if (visibility == "none") {
        layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::None);
    }
    
    return thisVar;
}

napi_value SymbolLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    auto visibility = layerObj->getLayer()->getVisibility();
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";
    
    napi_value result;
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// Filter
// ============================================================================

napi_value SymbolLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    auto filter = mbgl::harmony::napiArrayToFilter(env, argv[0]);
    if (filter) {
        layerObj->getLayer()->setFilter(*filter);
    }
    
    return thisVar;
}

napi_value SymbolLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    auto filter = layerObj->getLayer()->getFilter();
    return mbgl::harmony::filterToNapiArray(env, filter);
}

// ============================================================================
// Text Variable Anchor Offset
// ============================================================================

napi_value SymbolLayerNAPI::SetTextVariableAnchorOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::SymbolLayer, mbgl::VariableAnchorOffsetCollection>(
        env, layerObj->getLayer(), argv[0], "text-variable-anchor-offset",
        &mbgl::style::SymbolLayer::setTextVariableAnchorOffset
    );
    return thisVar;
}

napi_value SymbolLayerNAPI::GetTextVariableAnchorOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    SymbolLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, mbgl::VariableAnchorOffsetCollection>(
        env, layerObj->getLayer(), &mbgl::style::SymbolLayer::getTextVariableAnchorOffset
    );
}

// ==================== Generic Property Methods ====================

napi_value SymbolLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<SymbolLayerNAPI, mbgl::style::SymbolLayer>(env, info);
}

napi_value SymbolLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<SymbolLayerNAPI, mbgl::style::SymbolLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
