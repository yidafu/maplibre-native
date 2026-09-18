#include "raster_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include "style/filter_conversion.hpp"
#include <mbgl/style/layers/raster_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref RasterLayerNAPI::constructor = nullptr;
napi_env RasterLayerNAPI::constructorEnv = nullptr;

RasterLayerNAPI::RasterLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::RasterLayer>(layerId, sourceId)) {
}

RasterLayerNAPI::RasterLayerNAPI(mbgl::style::RasterLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("RasterLayerNAPI", "RasterLayer created from existing layer (WeakPtr)");
    }
}


RasterLayerNAPI::~RasterLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void RasterLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    delete static_cast<RasterLayerNAPI*>(nativeObject);
}

napi_value RasterLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("RasterLayerNAPI", "Initializing RasterLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        { "setRasterOpacity", nullptr, SetRasterOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setRasterHueRotate", nullptr, SetRasterHueRotate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setRasterBrightnessMin", nullptr, SetRasterBrightnessMin, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setRasterBrightnessMax", nullptr, SetRasterBrightnessMax, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setRasterSaturation", nullptr, SetRasterSaturation, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setRasterContrast", nullptr, SetRasterContrast, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // New properties
        { "setRasterFadeDuration", nullptr, SetRasterFadeDuration, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getRasterFadeDuration", nullptr, GetRasterFadeDuration, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setRasterResampling", nullptr, SetRasterResampling, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getRasterResampling", nullptr, GetRasterResampling, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        LAYER_BASE_PROPERTY_DESCRIPTORS
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "RasterLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "RasterLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("RasterLayerNAPI", "RasterLayer NAPI class registered successfully");
    return exports;
}

DEFINE_LAYER_NEW(RasterLayerNAPI, "RasterLayer", 2, new RasterLayerNAPI(layerId, sourceId),
        std::string layerId = args.GetString(0, "layerId");
        std::string sourceId = args.GetString(1, "sourceId");)

napi_value RasterLayerNAPI::CreateInstance(napi_env env, mbgl::style::RasterLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "RasterLayer",
                                layerPtr ? new RasterLayerNAPI(layerPtr) : nullptr);
}


DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterOpacity, setPaintProperty, "raster-opacity", setRasterOpacity, float)

DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterHueRotate, setPaintProperty, "raster-hue-rotate", setRasterHueRotate, float)

DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterBrightnessMin, setPaintProperty, "raster-brightness-min", setRasterBrightnessMin, float)

DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterBrightnessMax, setPaintProperty, "raster-brightness-max", setRasterBrightnessMax, float)

DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterSaturation, setPaintProperty, "raster-saturation", setRasterSaturation, float)

DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterContrast, setPaintProperty, "raster-contrast", setRasterContrast, float)

napi_value RasterLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<RasterLayerNAPI>(env, info);
}

napi_value RasterLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "raster");
}

napi_value RasterLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<RasterLayerNAPI>(env, info);
}

// ============================================================================
// New Properties
// ============================================================================

DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterFadeDuration, setPaintProperty, "raster-fade-duration", setRasterFadeDuration, float)

DEFINE_LAYER_GETTER(RasterLayerNAPI, mbgl::style::RasterLayer, GetRasterFadeDuration, getRasterFadeDuration, float)

DEFINE_LAYER_SETTER(RasterLayerNAPI, mbgl::style::RasterLayer, SetRasterResampling, setPaintProperty, "raster-resampling", setRasterResampling, mbgl::style::RasterResamplingType)

DEFINE_LAYER_GETTER(RasterLayerNAPI, mbgl::style::RasterLayer, GetRasterResampling, getRasterResampling, mbgl::style::RasterResamplingType)

// ============================================================================
// Visibility
// ============================================================================

napi_value RasterLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<RasterLayerNAPI>(env, info);
}

napi_value RasterLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<RasterLayerNAPI>(env, info);
}

// ============================================================================
// Zoom Range
// ============================================================================

napi_value RasterLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<RasterLayerNAPI>(env, info);
}

napi_value RasterLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<RasterLayerNAPI>(env, info);
}

napi_value RasterLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<RasterLayerNAPI>(env, info);
}

napi_value RasterLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<RasterLayerNAPI>(env, info);
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value RasterLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<RasterLayerNAPI>(env, info);
}

napi_value RasterLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<RasterLayerNAPI>(env, info);
}

// ============================================================================
// Filter
// ============================================================================

napi_value RasterLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<RasterLayerNAPI>(env, info);
}

napi_value RasterLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<RasterLayerNAPI>(env, info);
}

// ==================== Generic Property Methods ====================

napi_value RasterLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<RasterLayerNAPI, mbgl::style::RasterLayer>(env, info);
}

napi_value RasterLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<RasterLayerNAPI, mbgl::style::RasterLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
