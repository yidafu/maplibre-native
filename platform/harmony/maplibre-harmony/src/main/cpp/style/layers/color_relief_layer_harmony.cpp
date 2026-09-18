#include "color_relief_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include "style/filter_conversion.hpp"
#include "style/conversion/property_value.hpp"
#include "style/conversion/harmony_conversion.hpp"
#include <mbgl/style/color_ramp_property_value.hpp>
#include <mbgl/style/conversion/color_ramp_property_value.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref ColorReliefLayerNAPI::constructor = nullptr;
napi_env ColorReliefLayerNAPI::constructorEnv = nullptr;

ColorReliefLayerNAPI::ColorReliefLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::ColorReliefLayer>(layerId, sourceId)) {
}

ColorReliefLayerNAPI::ColorReliefLayerNAPI(mbgl::style::ColorReliefLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("ColorReliefLayerNAPI", "ColorReliefLayer created from existing layer (WeakPtr)");
    }
}

ColorReliefLayerNAPI::~ColorReliefLayerNAPI() {
}

void ColorReliefLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    delete static_cast<ColorReliefLayerNAPI*>(nativeObject);
}

napi_value ColorReliefLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("ColorReliefLayerNAPI", "Initializing ColorReliefLayer NAPI class");

    napi_property_descriptor properties[] = {
        { "setColorReliefColor", nullptr, SetColorReliefColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setColorReliefOpacity", nullptr, SetColorReliefOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getColorReliefColor", nullptr, GetColorReliefColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getColorReliefOpacity", nullptr, GetColorReliefOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        LAYER_BASE_PROPERTY_DESCRIPTORS
    };

    napi_value cons = RegisterNapiClass(env, exports, "ColorReliefLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "ColorReliefLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("ColorReliefLayerNAPI", "ColorReliefLayer NAPI class registered");
    return exports;
}

DEFINE_LAYER_NEW(ColorReliefLayerNAPI, "ColorReliefLayer", 2, new ColorReliefLayerNAPI(layerId, sourceId),
        std::string layerId = args.GetString(0, "layerId");
        std::string sourceId = args.GetString(1, "sourceId");)

napi_value ColorReliefLayerNAPI::CreateInstance(napi_env env, mbgl::style::ColorReliefLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "ColorReliefLayer",
                                layerPtr ? new ColorReliefLayerNAPI(layerPtr) : nullptr);
}

// ============================================================================
// Paint Property Setters
// ============================================================================

DEFINE_LAYER_COLORRAMP_SETTER(ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer, SetColorReliefColor, "colorReliefColor", setColorReliefColor)

DEFINE_LAYER_SETTER(ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer, SetColorReliefOpacity, setPaintProperty, "colorReliefOpacity", setColorReliefOpacity, float)

// ============================================================================
// Paint Property Getters
// ============================================================================

DEFINE_LAYER_COLORRAMP_GETTER(ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer, GetColorReliefColor, getColorReliefColor)

DEFINE_LAYER_GETTER(ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer, GetColorReliefOpacity, getColorReliefOpacity, float)

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value ColorReliefLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "color-relief", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value ColorReliefLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<ColorReliefLayerNAPI>(env, info);
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value ColorReliefLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<ColorReliefLayerNAPI>(env, info);
}

// ============================================================================
// Filter
// ============================================================================

napi_value ColorReliefLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<ColorReliefLayerNAPI>(env, info);
}

napi_value ColorReliefLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<ColorReliefLayerNAPI>(env, info);
}

// ==================== Generic Property Methods ====================

napi_value ColorReliefLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer>(env, info);
}

napi_value ColorReliefLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
