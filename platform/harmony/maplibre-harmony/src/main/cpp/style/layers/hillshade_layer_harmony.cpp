#include "hillshade_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include "style/filter_conversion.hpp"
#include <mln/style/layers/hillshade_layer.hpp>
#include <mln/style/property_value.hpp>
#include <mln/style/types.hpp>
#include <mln/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mln {
namespace harmony {

using namespace mln::harmony::napi;
using mln::harmony::Logger;

napi_ref HillshadeLayerNAPI::constructor = nullptr;
napi_env HillshadeLayerNAPI::constructorEnv = nullptr;

HillshadeLayerNAPI::HillshadeLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mln::style::HillshadeLayer>(layerId, sourceId)) {
}

HillshadeLayerNAPI::HillshadeLayerNAPI(mln::style::HillshadeLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("HillshadeLayerNAPI", "HillshadeLayer created from existing layer (WeakPtr)");
    }
}


HillshadeLayerNAPI::~HillshadeLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void HillshadeLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    delete static_cast<HillshadeLayerNAPI*>(nativeObject);
}

napi_value HillshadeLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("HillshadeLayerNAPI", "Initializing HillshadeLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        { "setHillshadeIlluminationDirection", nullptr, SetHillshadeIlluminationDirection, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHillshadeIlluminationAnchor", nullptr, SetHillshadeIlluminationAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHillshadeExaggeration", nullptr, SetHillshadeExaggeration, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHillshadeShadowColor", nullptr, SetHillshadeShadowColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHillshadeHighlightColor", nullptr, SetHillshadeHighlightColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setHillshadeAccentColor", nullptr, SetHillshadeAccentColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHillshadeIlluminationDirection", nullptr, GetHillshadeIlluminationDirection, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHillshadeExaggeration", nullptr, GetHillshadeExaggeration, nullptr, nullptr, nullptr, napi_default, nullptr },
        LAYER_BASE_PROPERTY_DESCRIPTORS
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "HillshadeLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "HillshadeLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("HillshadeLayerNAPI", "HillshadeLayer NAPI class registered");
    return exports;
}

DEFINE_LAYER_NEW(HillshadeLayerNAPI, "HillshadeLayer", 2, new HillshadeLayerNAPI(layerId, sourceId),
        std::string layerId = args.GetString(0, "layerId");
        std::string sourceId = args.GetString(1, "sourceId");)

napi_value HillshadeLayerNAPI::CreateInstance(napi_env env, mln::style::HillshadeLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "HillshadeLayer",
                                layerPtr ? new HillshadeLayerNAPI(layerPtr) : nullptr);
}


DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, SetHillshadeIlluminationDirection, setPaintProperty, "hillshade-illumination-direction", setHillshadeIlluminationDirection, std::vector<float>)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, SetHillshadeIlluminationAnchor, setPaintProperty, "hillshade-illumination-anchor", setHillshadeIlluminationAnchor, mln::style::HillshadeIlluminationAnchorType)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, SetHillshadeExaggeration, setPaintProperty, "hillshade-exaggeration", setHillshadeExaggeration, float)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, SetHillshadeShadowColor, setPaintProperty, "hillshade-shadow-color", setHillshadeShadowColor, std::vector<mln::Color>)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, SetHillshadeHighlightColor, setPaintProperty, "hillshade-highlight-color", setHillshadeHighlightColor, std::vector<mln::Color>)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, SetHillshadeAccentColor, setPaintProperty, "hillshade-accent-color", setHillshadeAccentColor, mln::Color)

DEFINE_LAYER_GETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, GetHillshadeIlluminationDirection, getHillshadeIlluminationDirection, std::vector<float>)

DEFINE_LAYER_GETTER(HillshadeLayerNAPI, mln::style::HillshadeLayer, GetHillshadeExaggeration, getHillshadeExaggeration, float)

napi_value HillshadeLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "hillshade");
}

napi_value HillshadeLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<HillshadeLayerNAPI>(env, info);
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value HillshadeLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<HillshadeLayerNAPI>(env, info);
}

// ============================================================================
// Filter
// ============================================================================

napi_value HillshadeLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<HillshadeLayerNAPI>(env, info);
}

napi_value HillshadeLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<HillshadeLayerNAPI>(env, info);
}

// ==================== Generic Property Methods ====================

napi_value HillshadeLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<HillshadeLayerNAPI, mln::style::HillshadeLayer>(env, info);
}

napi_value HillshadeLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<HillshadeLayerNAPI, mln::style::HillshadeLayer>(env, info);
}

} // namespace harmony
} // namespace mln
