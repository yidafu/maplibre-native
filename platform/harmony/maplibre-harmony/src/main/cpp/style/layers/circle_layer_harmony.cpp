#include "circle_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref CircleLayerNAPI::constructor = nullptr;
napi_env CircleLayerNAPI::constructorEnv = nullptr;

CircleLayerNAPI::CircleLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::CircleLayer>(layerId, sourceId)) {
}

CircleLayerNAPI::CircleLayerNAPI(mbgl::style::CircleLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("CircleLayerNAPI", "CircleLayer created from existing layer (WeakPtr)");
    }
}


CircleLayerNAPI::~CircleLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void CircleLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    CircleLayerNAPI* obj = static_cast<CircleLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value CircleLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("CircleLayerNAPI", "Initializing CircleLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setCircleRadius", nullptr, SetCircleRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleColor", nullptr, SetCircleColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleOpacity", nullptr, SetCircleOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleBlur", nullptr, SetCircleBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeWidth", nullptr, SetCircleStrokeWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeColor", nullptr, SetCircleStrokeColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeOpacity", nullptr, SetCircleStrokeOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
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
        
        // New properties
        { "setCircleTranslate", nullptr, SetCircleTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCircleTranslate", nullptr, GetCircleTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleTranslateAnchor", nullptr, SetCircleTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCircleTranslateAnchor", nullptr, GetCircleTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCirclePitchScale", nullptr, SetCirclePitchScale, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCirclePitchScale", nullptr, GetCirclePitchScale, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCirclePitchAlignment", nullptr, SetCirclePitchAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCirclePitchAlignment", nullptr, GetCirclePitchAlignment, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleSortKey", nullptr, SetCircleSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCircleSortKey", nullptr, GetCircleSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "CircleLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "CircleLayerNAPI");
    if (!cons) return nullptr;

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
    

    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "CircleLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return thisVar;
}

napi_value CircleLayerNAPI::CreateInstance(napi_env env, mbgl::style::CircleLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "CircleLayer",
                                layerPtr ? new CircleLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Paint Property Setters (Expression supported)
// ============================================================================

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleRadius, setPaintProperty, "circle-radius", setCircleRadius, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleColor, setPaintProperty, "circle-color", setCircleColor, mbgl::Color)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleOpacity, setPaintProperty, "circle-opacity", setCircleOpacity, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleBlur, setPaintProperty, "circle-blur", setCircleBlur, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleStrokeWidth, setPaintProperty, "circle-stroke-width", setCircleStrokeWidth, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleStrokeColor, setPaintProperty, "circle-stroke-color", setCircleStrokeColor, mbgl::Color)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleStrokeOpacity, setPaintProperty, "circle-stroke-opacity", setCircleStrokeOpacity, float)

// ============================================================================
// Property Getters (return constants or Expressions)
// ============================================================================

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCircleRadius, getCircleRadius, float)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCircleColor, getCircleColor, mbgl::Color)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCircleOpacity, getCircleOpacity, float)

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value CircleLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<CircleLayerNAPI>(env, info);
}

napi_value CircleLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "circle");
}

napi_value CircleLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<CircleLayerNAPI>(env, info);
}

// ============================================================================
// Visibility
// ============================================================================

napi_value CircleLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<CircleLayerNAPI>(env, info);
}

napi_value CircleLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<CircleLayerNAPI>(env, info);
}

// ============================================================================
// Zoom Range
// ============================================================================

napi_value CircleLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<CircleLayerNAPI>(env, info);
}

napi_value CircleLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<CircleLayerNAPI>(env, info);
}

napi_value CircleLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<CircleLayerNAPI>(env, info);
}

napi_value CircleLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<CircleLayerNAPI>(env, info);
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value CircleLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<CircleLayerNAPI>(env, info);
}

napi_value CircleLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<CircleLayerNAPI>(env, info);
}

// ============================================================================
// Filter
// ============================================================================

napi_value CircleLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<CircleLayerNAPI>(env, info);
}

napi_value CircleLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<CircleLayerNAPI>(env, info);
}

// ============================================================================
// New Properties
// ============================================================================

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleTranslate, setPaintProperty, "circle-translate", setCircleTranslate, std::array<float,2>)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCircleTranslate, getCircleTranslate, std::array<float,2>)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleTranslateAnchor, setPaintProperty, "circle-translate-anchor", setCircleTranslateAnchor, mbgl::style::TranslateAnchorType)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCircleTranslateAnchor, getCircleTranslateAnchor, mbgl::style::TranslateAnchorType)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCirclePitchScale, setPaintProperty, "circle-pitch-scale", setCirclePitchScale, mbgl::style::CirclePitchScaleType)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCirclePitchScale, getCirclePitchScale, mbgl::style::CirclePitchScaleType)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCirclePitchAlignment, setLayoutProperty, "circle-pitch-alignment", setCirclePitchAlignment, mbgl::style::AlignmentType)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCirclePitchAlignment, getCirclePitchAlignment, mbgl::style::AlignmentType)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mbgl::style::CircleLayer, SetCircleSortKey, setLayoutProperty, "circle-sort-key", setCircleSortKey, float)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mbgl::style::CircleLayer, GetCircleSortKey, getCircleSortKey, float)

// ==================== Generic Property Methods ====================

napi_value CircleLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<CircleLayerNAPI, mbgl::style::CircleLayer>(env, info);
}

napi_value CircleLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<CircleLayerNAPI, mbgl::style::CircleLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
