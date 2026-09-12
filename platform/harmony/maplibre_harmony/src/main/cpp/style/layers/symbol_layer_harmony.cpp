#include "symbol_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
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
#include "napi/core/napi_wrap_instance.hpp"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

// Static member initialization
napi_ref SymbolLayerNAPI::constructor = nullptr;
napi_env SymbolLayerNAPI::constructorEnv = nullptr;

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


// ============================================================================
// Property accessors (generated)
//
// Every Set*/Get* below forwards to the shared setLayoutProperty /
// setPaintProperty / setDataDrivenLayoutProperty / getProperty helpers; the
// bodies used to be hand-duplicated per property (~2400 lines). The macros
// take the helper, the property key and the native member functions, and the
// value type as a variadic tail so comma-bearing types like
// std::array<float, 2> survive.
// ============================================================================

#define DEFINE_SYMBOL_SETTER(Fn, Helper, PropName, SetFn, ...)                 \
    napi_value SymbolLayerNAPI::Fn(napi_env env, napi_callback_info info) {    \
        napi_value thisVar;                                                    \
        size_t argc = 1;                                                       \
        napi_value argv[1];                                                    \
        napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);           \
        auto* layerObj = NapiArgs::Unwrap<SymbolLayerNAPI>(env, thisVar);      \
        if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;    \
        mbgl::harmony::Helper<mbgl::style::SymbolLayer, __VA_ARGS__>(          \
            env, layerObj->getLayer(), argv[0], PropName,                      \
            &mbgl::style::SymbolLayer::SetFn);                                 \
        return thisVar;                                                        \
    }

#define DEFINE_SYMBOL_GETTER(Fn, GetFn, ...)                                   \
    napi_value SymbolLayerNAPI::Fn(napi_env env, napi_callback_info info) {    \
        napi_value thisVar;                                                    \
        napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);      \
        auto* layerObj = NapiArgs::Unwrap<SymbolLayerNAPI>(env, thisVar);      \
        if (!layerObj || !layerObj->getLayer()) {                              \
            napi_value null_value;                                             \
            napi_get_null(env, &null_value);                                   \
            return null_value;                                                 \
        }                                                                      \
        return mbgl::harmony::getProperty<mbgl::style::SymbolLayer, __VA_ARGS__>( \
            env, layerObj->getLayer(), &mbgl::style::SymbolLayer::GetFn);      \
    }

// --- Generated property accessors ---

DEFINE_SYMBOL_SETTER(SetIconImage, setDataDrivenLayoutProperty, "icon-image", setIconImage, mbgl::style::expression::Image)
DEFINE_SYMBOL_GETTER(GetIconImage, getIconImage, mbgl::style::expression::Image)
DEFINE_SYMBOL_SETTER(SetIconSize, setLayoutProperty, "icon-size", setIconSize, float)
DEFINE_SYMBOL_GETTER(GetIconSize, getIconSize, float)
DEFINE_SYMBOL_SETTER(SetIconRotate, setDataDrivenLayoutProperty, "icon-rotate", setIconRotate, float)
DEFINE_SYMBOL_GETTER(GetIconRotate, getIconRotate, float)
DEFINE_SYMBOL_SETTER(SetIconAnchor, setLayoutProperty, "icon-anchor", setIconAnchor, mbgl::style::SymbolAnchorType)
DEFINE_SYMBOL_GETTER(GetIconAnchor, getIconAnchor, mbgl::style::SymbolAnchorType)
DEFINE_SYMBOL_SETTER(SetIconAllowOverlap, setLayoutProperty, "icon-allow-overlap", setIconAllowOverlap, bool)
DEFINE_SYMBOL_GETTER(GetIconAllowOverlap, getIconAllowOverlap, bool)
DEFINE_SYMBOL_SETTER(SetTextField, setDataDrivenLayoutProperty, "text-field", setTextField, mbgl::style::expression::Formatted)
DEFINE_SYMBOL_GETTER(GetTextField, getTextField, mbgl::style::expression::Formatted)
DEFINE_SYMBOL_SETTER(SetTextSize, setLayoutProperty, "text-size", setTextSize, float)
DEFINE_SYMBOL_GETTER(GetTextSize, getTextSize, float)
DEFINE_SYMBOL_SETTER(SetTextMaxWidth, setLayoutProperty, "text-max-width", setTextMaxWidth, float)
DEFINE_SYMBOL_GETTER(GetTextMaxWidth, getTextMaxWidth, float)
DEFINE_SYMBOL_SETTER(SetTextAnchor, setLayoutProperty, "text-anchor", setTextAnchor, mbgl::style::SymbolAnchorType)
DEFINE_SYMBOL_GETTER(GetTextAnchor, getTextAnchor, mbgl::style::SymbolAnchorType)
DEFINE_SYMBOL_SETTER(SetTextAllowOverlap, setLayoutProperty, "text-allow-overlap", setTextAllowOverlap, bool)
DEFINE_SYMBOL_GETTER(GetTextAllowOverlap, getTextAllowOverlap, bool)
DEFINE_SYMBOL_SETTER(SetIconOpacity, setPaintProperty, "icon-opacity", setIconOpacity, float)
DEFINE_SYMBOL_GETTER(GetIconOpacity, getIconOpacity, float)
DEFINE_SYMBOL_SETTER(SetIconColor, setPaintProperty, "icon-color", setIconColor, mbgl::Color)
DEFINE_SYMBOL_GETTER(GetIconColor, getIconColor, mbgl::Color)
DEFINE_SYMBOL_SETTER(SetIconHaloColor, setPaintProperty, "icon-halo-color", setIconHaloColor, mbgl::Color)
DEFINE_SYMBOL_GETTER(GetIconHaloColor, getIconHaloColor, mbgl::Color)
DEFINE_SYMBOL_SETTER(SetIconHaloWidth, setPaintProperty, "icon-halo-width", setIconHaloWidth, float)
DEFINE_SYMBOL_GETTER(GetIconHaloWidth, getIconHaloWidth, float)
DEFINE_SYMBOL_SETTER(SetTextOpacity, setPaintProperty, "text-opacity", setTextOpacity, float)
DEFINE_SYMBOL_GETTER(GetTextOpacity, getTextOpacity, float)
DEFINE_SYMBOL_SETTER(SetTextColor, setPaintProperty, "text-color", setTextColor, mbgl::Color)
DEFINE_SYMBOL_GETTER(GetTextColor, getTextColor, mbgl::Color)
DEFINE_SYMBOL_SETTER(SetTextHaloColor, setPaintProperty, "text-halo-color", setTextHaloColor, mbgl::Color)
DEFINE_SYMBOL_GETTER(GetTextHaloColor, getTextHaloColor, mbgl::Color)
DEFINE_SYMBOL_SETTER(SetTextHaloWidth, setPaintProperty, "text-halo-width", setTextHaloWidth, float)
DEFINE_SYMBOL_GETTER(GetTextHaloWidth, getTextHaloWidth, float)
DEFINE_SYMBOL_SETTER(SetIconIgnorePlacement, setLayoutProperty, "icon-ignore-placement", setIconIgnorePlacement, bool)
DEFINE_SYMBOL_GETTER(GetIconIgnorePlacement, getIconIgnorePlacement, bool)
DEFINE_SYMBOL_SETTER(SetIconOptional, setLayoutProperty, "icon-optional", setIconOptional, bool)
DEFINE_SYMBOL_GETTER(GetIconOptional, getIconOptional, bool)
DEFINE_SYMBOL_SETTER(SetIconPadding, setLayoutProperty, "icon-padding", setIconPadding, mbgl::Padding)
DEFINE_SYMBOL_GETTER(GetIconPadding, getIconPadding, mbgl::Padding)
DEFINE_SYMBOL_SETTER(SetIconKeepUpright, setLayoutProperty, "icon-keep-upright", setIconKeepUpright, bool)
DEFINE_SYMBOL_GETTER(GetIconKeepUpright, getIconKeepUpright, bool)
DEFINE_SYMBOL_SETTER(SetIconPitchAlignment, setLayoutProperty, "icon-pitch-alignment", setIconPitchAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_GETTER(GetIconPitchAlignment, getIconPitchAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_SETTER(SetIconRotationAlignment, setLayoutProperty, "icon-rotation-alignment", setIconRotationAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_GETTER(GetIconRotationAlignment, getIconRotationAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_SETTER(SetIconTextFit, setLayoutProperty, "icon-text-fit", setIconTextFit, mbgl::style::IconTextFitType)
DEFINE_SYMBOL_GETTER(GetIconTextFit, getIconTextFit, mbgl::style::IconTextFitType)
DEFINE_SYMBOL_SETTER(SetTextLetterSpacing, setLayoutProperty, "text-letter-spacing", setTextLetterSpacing, float)
DEFINE_SYMBOL_GETTER(GetTextLetterSpacing, getTextLetterSpacing, float)
DEFINE_SYMBOL_SETTER(SetTextJustify, setLayoutProperty, "text-justify", setTextJustify, mbgl::style::TextJustifyType)
DEFINE_SYMBOL_GETTER(GetTextJustify, getTextJustify, mbgl::style::TextJustifyType)
DEFINE_SYMBOL_SETTER(SetTextRadialOffset, setLayoutProperty, "text-radial-offset", setTextRadialOffset, float)
DEFINE_SYMBOL_GETTER(GetTextRadialOffset, getTextRadialOffset, float)
DEFINE_SYMBOL_SETTER(SetTextRotate, setLayoutProperty, "text-rotate", setTextRotate, float)
DEFINE_SYMBOL_GETTER(GetTextRotate, getTextRotate, float)
DEFINE_SYMBOL_SETTER(SetTextPadding, setLayoutProperty, "text-padding", setTextPadding, float)
DEFINE_SYMBOL_GETTER(GetTextPadding, getTextPadding, float)
DEFINE_SYMBOL_SETTER(SetTextKeepUpright, setLayoutProperty, "text-keep-upright", setTextKeepUpright, bool)
DEFINE_SYMBOL_GETTER(GetTextKeepUpright, getTextKeepUpright, bool)
DEFINE_SYMBOL_SETTER(SetTextTransform, setLayoutProperty, "text-transform", setTextTransform, mbgl::style::TextTransformType)
DEFINE_SYMBOL_GETTER(GetTextTransform, getTextTransform, mbgl::style::TextTransformType)
DEFINE_SYMBOL_SETTER(SetTextMaxAngle, setLayoutProperty, "text-max-angle", setTextMaxAngle, float)
DEFINE_SYMBOL_GETTER(GetTextMaxAngle, getTextMaxAngle, float)
DEFINE_SYMBOL_SETTER(SetTextRotationAlignment, setLayoutProperty, "text-rotation-alignment", setTextRotationAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_GETTER(GetTextRotationAlignment, getTextRotationAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_SETTER(SetTextPitchAlignment, setLayoutProperty, "text-pitch-alignment", setTextPitchAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_GETTER(GetTextPitchAlignment, getTextPitchAlignment, mbgl::style::AlignmentType)
DEFINE_SYMBOL_SETTER(SetTextLineHeight, setLayoutProperty, "text-line-height", setTextLineHeight, float)
DEFINE_SYMBOL_GETTER(GetTextLineHeight, getTextLineHeight, float)
DEFINE_SYMBOL_SETTER(SetTextIgnorePlacement, setLayoutProperty, "text-ignore-placement", setTextIgnorePlacement, bool)
DEFINE_SYMBOL_GETTER(GetTextIgnorePlacement, getTextIgnorePlacement, bool)
DEFINE_SYMBOL_SETTER(SetTextOptional, setLayoutProperty, "text-optional", setTextOptional, bool)
DEFINE_SYMBOL_GETTER(GetTextOptional, getTextOptional, bool)
DEFINE_SYMBOL_SETTER(SetSymbolPlacement, setLayoutProperty, "symbol-placement", setSymbolPlacement, mbgl::style::SymbolPlacementType)
DEFINE_SYMBOL_GETTER(GetSymbolPlacement, getSymbolPlacement, mbgl::style::SymbolPlacementType)
DEFINE_SYMBOL_SETTER(SetSymbolSpacing, setLayoutProperty, "symbol-spacing", setSymbolSpacing, float)
DEFINE_SYMBOL_GETTER(GetSymbolSpacing, getSymbolSpacing, float)
DEFINE_SYMBOL_SETTER(SetSymbolAvoidEdges, setLayoutProperty, "symbol-avoid-edges", setSymbolAvoidEdges, bool)
DEFINE_SYMBOL_GETTER(GetSymbolAvoidEdges, getSymbolAvoidEdges, bool)
DEFINE_SYMBOL_SETTER(SetSymbolSortKey, setDataDrivenLayoutProperty, "symbol-sort-key", setSymbolSortKey, float)
DEFINE_SYMBOL_GETTER(GetSymbolSortKey, getSymbolSortKey, float)
DEFINE_SYMBOL_SETTER(SetSymbolZOrder, setLayoutProperty, "symbol-z-order", setSymbolZOrder, mbgl::style::SymbolZOrderType)
DEFINE_SYMBOL_GETTER(GetSymbolZOrder, getSymbolZOrder, mbgl::style::SymbolZOrderType)
DEFINE_SYMBOL_SETTER(SetIconHaloBlur, setPaintProperty, "icon-halo-blur", setIconHaloBlur, float)
DEFINE_SYMBOL_GETTER(GetIconHaloBlur, getIconHaloBlur, float)
DEFINE_SYMBOL_SETTER(SetIconTranslateAnchor, setPaintProperty, "icon-translate-anchor", setIconTranslateAnchor, mbgl::style::TranslateAnchorType)
DEFINE_SYMBOL_GETTER(GetIconTranslateAnchor, getIconTranslateAnchor, mbgl::style::TranslateAnchorType)
DEFINE_SYMBOL_SETTER(SetTextHaloBlur, setPaintProperty, "text-halo-blur", setTextHaloBlur, float)
DEFINE_SYMBOL_GETTER(GetTextHaloBlur, getTextHaloBlur, float)
DEFINE_SYMBOL_SETTER(SetTextTranslateAnchor, setPaintProperty, "text-translate-anchor", setTextTranslateAnchor, mbgl::style::TranslateAnchorType)
DEFINE_SYMBOL_GETTER(GetTextTranslateAnchor, getTextTranslateAnchor, mbgl::style::TranslateAnchorType)
DEFINE_SYMBOL_SETTER(SetTextVariableAnchorOffset, setLayoutProperty, "text-variable-anchor-offset", setTextVariableAnchorOffset, mbgl::VariableAnchorOffsetCollection)
DEFINE_SYMBOL_GETTER(GetTextVariableAnchorOffset, getTextVariableAnchorOffset, mbgl::VariableAnchorOffsetCollection)
DEFINE_SYMBOL_SETTER(SetIconOffset, setLayoutProperty, "icon-offset", setIconOffset, std::array<float, 2>)
DEFINE_SYMBOL_GETTER(GetIconOffset, getIconOffset, std::array<float, 2>)
DEFINE_SYMBOL_SETTER(SetTextFont, setLayoutProperty, "text-font", setTextFont, std::vector<std::string>)
DEFINE_SYMBOL_GETTER(GetTextFont, getTextFont, std::vector<std::string>)
DEFINE_SYMBOL_SETTER(SetTextOffset, setLayoutProperty, "text-offset", setTextOffset, std::array<float, 2>)
DEFINE_SYMBOL_GETTER(GetTextOffset, getTextOffset, std::array<float, 2>)
DEFINE_SYMBOL_SETTER(SetIconTextFitPadding, setLayoutProperty, "icon-text-fit-padding", setIconTextFitPadding, std::array<float, 4>)
DEFINE_SYMBOL_GETTER(GetIconTextFitPadding, getIconTextFitPadding, std::array<float, 4>)
DEFINE_SYMBOL_SETTER(SetTextVariableAnchor, setLayoutProperty, "text-variable-anchor", setTextVariableAnchor, std::vector<mbgl::style::TextVariableAnchorType>)
DEFINE_SYMBOL_SETTER(SetTextWritingMode, setLayoutProperty, "text-writing-mode", setTextWritingMode, std::vector<mbgl::style::TextWritingModeType>)
DEFINE_SYMBOL_SETTER(SetIconTranslate, setPaintProperty, "icon-translate", setIconTranslate, std::array<float, 2>)
DEFINE_SYMBOL_GETTER(GetIconTranslate, getIconTranslate, std::array<float, 2>)
DEFINE_SYMBOL_SETTER(SetTextTranslate, setPaintProperty, "text-translate", setTextTranslate, std::array<float, 2>)
DEFINE_SYMBOL_GETTER(GetTextTranslate, getTextTranslate, std::array<float, 2>)



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
    
    status = mbgl::harmony::RefreshConstructorRef(env, cons, constructor, constructorEnv);
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
    return WrapExistingInstance(env, constructor, Destructor, "SymbolLayer",
                                layerPtr ? new SymbolLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Basic Layer Methods
// ============================================================================

napi_value SymbolLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "symbol");
}

napi_value SymbolLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::GetTextVariableAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<SymbolLayerNAPI>(env, thisVar);
    
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

napi_value SymbolLayerNAPI::GetTextWritingMode(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<SymbolLayerNAPI>(env, thisVar);
    
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

// ============================================================================
// Visibility
// ============================================================================

napi_value SymbolLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<SymbolLayerNAPI>(env, info);
}

// ============================================================================
// Filter
// ============================================================================

napi_value SymbolLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<SymbolLayerNAPI>(env, info);
}

napi_value SymbolLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<SymbolLayerNAPI>(env, info);
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
