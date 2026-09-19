#include "circle_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mln/style/layers/circle_layer.hpp>
#include <mln/style/property_value.hpp>
#include <mln/style/types.hpp>
#include <mln/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mln {
namespace harmony {

using namespace mln::harmony::napi;
using mln::harmony::Logger;

// Static member initialization
napi_ref CircleLayerNAPI::constructor = nullptr;
napi_env CircleLayerNAPI::constructorEnv = nullptr;

CircleLayerNAPI::CircleLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mln::style::CircleLayer>(layerId, sourceId)) {
}

CircleLayerNAPI::CircleLayerNAPI(mln::style::CircleLayer* layerPtr) {
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
        LAYER_BASE_PROPERTY_DESCRIPTORS
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "CircleLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "CircleLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("CircleLayerNAPI", "CircleLayer NAPI class registered successfully");
    return exports;
}

DEFINE_LAYER_NEW(CircleLayerNAPI, "CircleLayer", 2, new CircleLayerNAPI(layerId, sourceId),
        std::string layerId = args.GetString(0, "layerId");
        std::string sourceId = args.GetString(1, "sourceId");)

napi_value CircleLayerNAPI::CreateInstance(napi_env env, mln::style::CircleLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "CircleLayer",
                                layerPtr ? new CircleLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Paint Property Setters (Expression supported)
// ============================================================================

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleRadius, setPaintProperty, "circle-radius", setCircleRadius, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleColor, setPaintProperty, "circle-color", setCircleColor, mln::Color)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleOpacity, setPaintProperty, "circle-opacity", setCircleOpacity, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleBlur, setPaintProperty, "circle-blur", setCircleBlur, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleStrokeWidth, setPaintProperty, "circle-stroke-width", setCircleStrokeWidth, float)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleStrokeColor, setPaintProperty, "circle-stroke-color", setCircleStrokeColor, mln::Color)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleStrokeOpacity, setPaintProperty, "circle-stroke-opacity", setCircleStrokeOpacity, float)

// ============================================================================
// Property Getters (return constants or Expressions)
// ============================================================================

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCircleRadius, getCircleRadius, float)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCircleColor, getCircleColor, mln::Color)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCircleOpacity, getCircleOpacity, float)

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

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleTranslate, setPaintProperty, "circle-translate", setCircleTranslate, std::array<float,2>)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCircleTranslate, getCircleTranslate, std::array<float,2>)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleTranslateAnchor, setPaintProperty, "circle-translate-anchor", setCircleTranslateAnchor, mln::style::TranslateAnchorType)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCircleTranslateAnchor, getCircleTranslateAnchor, mln::style::TranslateAnchorType)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCirclePitchScale, setPaintProperty, "circle-pitch-scale", setCirclePitchScale, mln::style::CirclePitchScaleType)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCirclePitchScale, getCirclePitchScale, mln::style::CirclePitchScaleType)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCirclePitchAlignment, setLayoutProperty, "circle-pitch-alignment", setCirclePitchAlignment, mln::style::AlignmentType)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCirclePitchAlignment, getCirclePitchAlignment, mln::style::AlignmentType)

DEFINE_LAYER_SETTER(CircleLayerNAPI, mln::style::CircleLayer, SetCircleSortKey, setLayoutProperty, "circle-sort-key", setCircleSortKey, float)

DEFINE_LAYER_GETTER(CircleLayerNAPI, mln::style::CircleLayer, GetCircleSortKey, getCircleSortKey, float)

// ==================== Generic Property Methods ====================

napi_value CircleLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<CircleLayerNAPI, mln::style::CircleLayer>(env, info);
}

napi_value CircleLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<CircleLayerNAPI, mln::style::CircleLayer>(env, info);
}

} // namespace harmony
} // namespace mln
