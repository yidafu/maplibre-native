#include "heatmap_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include "style/conversion/property_value.hpp"
#include "style/conversion/harmony_conversion.hpp"
#include <mbgl/style/layers/heatmap_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/color_ramp_property_value.hpp>
#include <mbgl/style/conversion/color_ramp_property_value.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref HeatmapLayerNAPI::constructor = nullptr;
napi_env HeatmapLayerNAPI::constructorEnv = nullptr;

HeatmapLayerNAPI::HeatmapLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::HeatmapLayer>(layerId, sourceId)) {
}

HeatmapLayerNAPI::HeatmapLayerNAPI(mbgl::style::HeatmapLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("HeatmapLayerNAPI", "HeatmapLayer created from existing layer (WeakPtr)");
    }
}


HeatmapLayerNAPI::~HeatmapLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void HeatmapLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    HeatmapLayerNAPI* obj = static_cast<HeatmapLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value HeatmapLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("HeatmapLayerNAPI", "Initializing HeatmapLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setHeatmapRadius", nullptr, SetHeatmapRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHeatmapWeight", nullptr, SetHeatmapWeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHeatmapIntensity", nullptr, SetHeatmapIntensity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHeatmapColor", nullptr, SetHeatmapColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHeatmapOpacity", nullptr, SetHeatmapOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
        { "getHeatmapRadius", nullptr, GetHeatmapRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHeatmapWeight", nullptr, GetHeatmapWeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHeatmapIntensity", nullptr, GetHeatmapIntensity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHeatmapColor", nullptr, GetHeatmapColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHeatmapOpacity", nullptr, GetHeatmapOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        LAYER_BASE_PROPERTY_DESCRIPTORS
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "HeatmapLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "HeatmapLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("HeatmapLayerNAPI", "HeatmapLayer NAPI class registered successfully");
    return exports;
}

DEFINE_LAYER_NEW(HeatmapLayerNAPI, "HeatmapLayer", 2, new HeatmapLayerNAPI(layerId, sourceId),
        std::string layerId = args.GetString(0, "layerId");
        std::string sourceId = args.GetString(1, "sourceId");)

napi_value HeatmapLayerNAPI::CreateInstance(napi_env env, mbgl::style::HeatmapLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "HeatmapLayer",
                                layerPtr ? new HeatmapLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Paint Property Setters (with Expression support)
// ============================================================================

DEFINE_LAYER_SETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, SetHeatmapRadius, setPaintProperty, "heatmap-radius", setHeatmapRadius, float)

DEFINE_LAYER_SETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, SetHeatmapWeight, setPaintProperty, "heatmap-weight", setHeatmapWeight, float)

DEFINE_LAYER_SETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, SetHeatmapIntensity, setPaintProperty, "heatmap-intensity", setHeatmapIntensity, float)

DEFINE_LAYER_COLORRAMP_SETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, SetHeatmapColor, "heatmap-color", setHeatmapColor)

DEFINE_LAYER_SETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, SetHeatmapOpacity, setPaintProperty, "heatmap-opacity", setHeatmapOpacity, float)

// ============================================================================
// Property Getters
// ============================================================================

DEFINE_LAYER_GETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, GetHeatmapRadius, getHeatmapRadius, float)

DEFINE_LAYER_GETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, GetHeatmapWeight, getHeatmapWeight, float)

DEFINE_LAYER_GETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, GetHeatmapIntensity, getHeatmapIntensity, float)

DEFINE_LAYER_COLORRAMP_GETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, GetHeatmapColor, getHeatmapColor)

DEFINE_LAYER_GETTER(HeatmapLayerNAPI, mbgl::style::HeatmapLayer, GetHeatmapOpacity, getHeatmapOpacity, float)

// ============================================================================
// Base Layer Methods (common pattern)
// ============================================================================

napi_value HeatmapLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "heatmap");
}

napi_value HeatmapLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<HeatmapLayerNAPI>(env, info);
}

napi_value HeatmapLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<HeatmapLayerNAPI>(env, info);
}

// ==================== Generic Property Methods ====================

napi_value HeatmapLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<HeatmapLayerNAPI, mbgl::style::HeatmapLayer>(env, info);
}

napi_value HeatmapLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<HeatmapLayerNAPI, mbgl::style::HeatmapLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
