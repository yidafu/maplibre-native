#include "hillshade_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include "style/filter_conversion.hpp"
#include <mbgl/style/layers/hillshade_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref HillshadeLayerNAPI::constructor = nullptr;
napi_env HillshadeLayerNAPI::constructorEnv = nullptr;

HillshadeLayerNAPI::HillshadeLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::HillshadeLayer>(layerId, sourceId)) {
}

HillshadeLayerNAPI::HillshadeLayerNAPI(mbgl::style::HillshadeLayer* layerPtr) {
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
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
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
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "HillshadeLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "HillshadeLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("HillshadeLayerNAPI", "HillshadeLayer NAPI class registered");
    return exports;
}

napi_value HillshadeLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return nullptr;
    
    HillshadeLayerNAPI* layerObj = new HillshadeLayerNAPI(layerId, sourceId);
    napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "HillshadeLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    
    return thisVar;
}

napi_value HillshadeLayerNAPI::CreateInstance(napi_env env, mbgl::style::HillshadeLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "HillshadeLayer",
                                layerPtr ? new HillshadeLayerNAPI(layerPtr) : nullptr);
}


DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, SetHillshadeIlluminationDirection, setPaintProperty, "hillshade-illumination-direction", setHillshadeIlluminationDirection, std::vector<float>)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, SetHillshadeIlluminationAnchor, setPaintProperty, "hillshade-illumination-anchor", setHillshadeIlluminationAnchor, mbgl::style::HillshadeIlluminationAnchorType)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, SetHillshadeExaggeration, setPaintProperty, "hillshade-exaggeration", setHillshadeExaggeration, float)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, SetHillshadeShadowColor, setPaintProperty, "hillshade-shadow-color", setHillshadeShadowColor, std::vector<mbgl::Color>)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, SetHillshadeHighlightColor, setPaintProperty, "hillshade-highlight-color", setHillshadeHighlightColor, std::vector<mbgl::Color>)

DEFINE_LAYER_SETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, SetHillshadeAccentColor, setPaintProperty, "hillshade-accent-color", setHillshadeAccentColor, mbgl::Color)

DEFINE_LAYER_GETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, GetHillshadeIlluminationDirection, getHillshadeIlluminationDirection, std::vector<float>)

DEFINE_LAYER_GETTER(HillshadeLayerNAPI, mbgl::style::HillshadeLayer, GetHillshadeExaggeration, getHillshadeExaggeration, float)

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
    return SetPropertyImpl<HillshadeLayerNAPI, mbgl::style::HillshadeLayer>(env, info);
}

napi_value HillshadeLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<HillshadeLayerNAPI, mbgl::style::HillshadeLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
