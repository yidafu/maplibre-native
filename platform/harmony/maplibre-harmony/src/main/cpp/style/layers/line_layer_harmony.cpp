#include "line_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include "style/conversion/property_value.hpp"
#include "style/conversion/harmony_conversion.hpp"
#include <mbgl/style/layers/line_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/color_ramp_property_value.hpp>
#include <mbgl/style/conversion/color_ramp_property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref LineLayerNAPI::constructor = nullptr;
napi_env LineLayerNAPI::constructorEnv = nullptr;

LineLayerNAPI::LineLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::LineLayer>(layerId, sourceId)) {
}

LineLayerNAPI::LineLayerNAPI(mbgl::style::LineLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("LineLayerNAPI", "LineLayer created from existing layer (WeakPtr)");
    }
}


LineLayerNAPI::~LineLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void LineLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    LineLayerNAPI* obj = static_cast<LineLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value LineLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("LineLayerNAPI", "Initializing LineLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setLineColor", nullptr, SetLineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineWidth", nullptr, SetLineWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineOpacity", nullptr, SetLineOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLinePattern", nullptr, SetLinePattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineGapWidth", nullptr, SetLineGapWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineDasharray", nullptr, SetLineDasharray, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineBlur", nullptr, SetLineBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineOffset", nullptr, SetLineOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineCap", nullptr, SetLineCap, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineJoin", nullptr, SetLineJoin, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
        { "getLineColor", nullptr, GetLineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineWidth", nullptr, GetLineWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineOpacity", nullptr, GetLineOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Visibility, zoom, source layer, filter - common to all layers
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSourceLayer", nullptr, SetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceLayer", nullptr, GetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFilter", nullptr, SetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFilter", nullptr, GetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // New properties
        { "setLineTranslate", nullptr, SetLineTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineTranslate", nullptr, GetLineTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineTranslateAnchor", nullptr, SetLineTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineTranslateAnchor", nullptr, GetLineTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineMiterLimit", nullptr, SetLineMiterLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineMiterLimit", nullptr, GetLineMiterLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineRoundLimit", nullptr, SetLineRoundLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineRoundLimit", nullptr, GetLineRoundLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineGradient", nullptr, SetLineGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineGradient", nullptr, GetLineGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineSortKey", nullptr, SetLineSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineSortKey", nullptr, GetLineSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "LineLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "LineLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("LineLayerNAPI", "LineLayer NAPI class registered successfully");
    return exports;
}

napi_value LineLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) {
        return nullptr;
    }
    
    LineLayerNAPI* layerObj = new LineLayerNAPI(layerId, sourceId);
    
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("LineLayerNAPI", "Failed to wrap LineLayer object");
        return nullptr;
    }
    

    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "LineLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return thisVar;
}

napi_value LineLayerNAPI::CreateInstance(napi_env env, mbgl::style::LineLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "LineLayer",
                                layerPtr ? new LineLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Paint Property Setters (Expression supported)
// ============================================================================

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineColor, setPaintProperty, "line-color", setLineColor, mbgl::Color)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineWidth, setPaintProperty, "line-width", setLineWidth, float)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineOpacity, setPaintProperty, "line-opacity", setLineOpacity, float)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLinePattern, setPaintProperty, "line-pattern", setLinePattern, mbgl::style::expression::Image)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineGapWidth, setPaintProperty, "line-gap-width", setLineGapWidth, float)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineDasharray, setPaintProperty, "line-dasharray", setLineDasharray, std::vector<float>)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineBlur, setPaintProperty, "line-blur", setLineBlur, float)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineOffset, setPaintProperty, "line-offset", setLineOffset, float)

// ============================================================================
// Layout Property Setters
// ============================================================================

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineCap, setLayoutProperty, "line-cap", setLineCap, mbgl::style::LineCapType)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineJoin, setLayoutProperty, "line-join", setLineJoin, mbgl::style::LineJoinType)

// ============================================================================
// Property Getters (return constants or Expressions)
// ============================================================================

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineColor, getLineColor, mbgl::Color)

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineWidth, getLineWidth, float)

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineOpacity, getLineOpacity, float)

// ============================================================================
// Base Layer Methods (common to all layers)
// ============================================================================

napi_value LineLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "line");
}

napi_value LineLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<LineLayerNAPI>(env, info);
}

napi_value LineLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<LineLayerNAPI>(env, info);
}

// ============================================================================
// New Properties
// ============================================================================

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineTranslate, setPaintProperty, "line-translate", setLineTranslate, std::array<float,2>)

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineTranslate, getLineTranslate, std::array<float,2>)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineTranslateAnchor, setPaintProperty, "line-translate-anchor", setLineTranslateAnchor, mbgl::style::TranslateAnchorType)

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineTranslateAnchor, getLineTranslateAnchor, mbgl::style::TranslateAnchorType)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineMiterLimit, setLayoutProperty, "line-miter-limit", setLineMiterLimit, float)

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineMiterLimit, getLineMiterLimit, float)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineRoundLimit, setLayoutProperty, "line-round-limit", setLineRoundLimit, float)

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineRoundLimit, getLineRoundLimit, float)

DEFINE_LAYER_COLORRAMP_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineGradient, "line-gradient", setLineGradient)

DEFINE_LAYER_COLORRAMP_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineGradient, getLineGradient)

DEFINE_LAYER_SETTER(LineLayerNAPI, mbgl::style::LineLayer, SetLineSortKey, setLayoutProperty, "line-sort-key", setLineSortKey, float)

DEFINE_LAYER_GETTER(LineLayerNAPI, mbgl::style::LineLayer, GetLineSortKey, getLineSortKey, float)

// ==================== Generic Property Methods ====================

napi_value LineLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<LineLayerNAPI, mbgl::style::LineLayer>(env, info);
}

napi_value LineLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<LineLayerNAPI, mbgl::style::LineLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
