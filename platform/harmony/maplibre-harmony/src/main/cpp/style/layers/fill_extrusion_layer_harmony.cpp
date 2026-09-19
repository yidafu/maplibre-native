#include "fill_extrusion_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mln/style/layers/fill_extrusion_layer.hpp>
#include <mln/style/property_value.hpp>
#include <mln/style/expression/image.hpp>
#include <mln/style/types.hpp>
#include <mln/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mln {
namespace harmony {

using namespace mln::harmony::napi;
using mln::harmony::Logger;

napi_ref FillExtrusionLayerNAPI::constructor = nullptr;
napi_env FillExtrusionLayerNAPI::constructorEnv = nullptr;

FillExtrusionLayerNAPI::FillExtrusionLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mln::style::FillExtrusionLayer>(layerId, sourceId)) {
}

FillExtrusionLayerNAPI::FillExtrusionLayerNAPI(mln::style::FillExtrusionLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("FillExtrusionLayerNAPI", "FillExtrusionLayer created from existing layer (WeakPtr)");
    }
}


FillExtrusionLayerNAPI::~FillExtrusionLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void FillExtrusionLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    delete static_cast<FillExtrusionLayerNAPI*>(nativeObject);
}

napi_value FillExtrusionLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("FillExtrusionLayerNAPI", "Initializing FillExtrusionLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        { "setFillExtrusionColor", nullptr, SetFillExtrusionColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionOpacity", nullptr, SetFillExtrusionOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionHeight", nullptr, SetFillExtrusionHeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionBase", nullptr, SetFillExtrusionBase, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionPattern", nullptr, SetFillExtrusionPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionTranslate", nullptr, SetFillExtrusionTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionRoundedCornerDistance", nullptr, SetFillExtrusionRoundedCornerDistance, nullptr, nullptr, nullptr, napi_default, nullptr },
        LAYER_BASE_PROPERTY_DESCRIPTORS
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "FillExtrusionLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "FillExtrusionLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("FillExtrusionLayerNAPI", "FillExtrusionLayer NAPI class registered");
    return exports;
}

DEFINE_LAYER_NEW(FillExtrusionLayerNAPI, "FillExtrusionLayer", 2, new FillExtrusionLayerNAPI(layerId, sourceId),
        std::string layerId = args.GetString(0, "layerId");
        std::string sourceId = args.GetString(1, "sourceId");)

napi_value FillExtrusionLayerNAPI::CreateInstance(napi_env env, mln::style::FillExtrusionLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "FillExtrusionLayer",
                                layerPtr ? new FillExtrusionLayerNAPI(layerPtr) : nullptr);
}


DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionColor, setPaintProperty, "fill-extrusion-color", setFillExtrusionColor, mln::Color)

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionOpacity, setPaintProperty, "fill-extrusion-opacity", setFillExtrusionOpacity, float)

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionHeight, setPaintProperty, "fill-extrusion-height", setFillExtrusionHeight, float)

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionBase, setPaintProperty, "fill-extrusion-base", setFillExtrusionBase, float)

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionPattern, setPaintProperty, "fill-extrusion-pattern", setFillExtrusionPattern, mln::style::expression::Image)

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionTranslate, setPaintProperty, "fill-extrusion-translate", setFillExtrusionTranslate, std::array<float,2>)

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionRoundedCornerDistance, setPaintProperty, "fill-extrusion-rounded-corner-distance", setFillExtrusionRoundedCornerDistance, float)

// Common layer methods
napi_value FillExtrusionLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "fill-extrusion", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<FillExtrusionLayerNAPI>(env, info);
}

napi_value FillExtrusionLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<FillExtrusionLayerNAPI>(env, info);
}

// ============================================================================
// New Properties
// ============================================================================

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionTranslateAnchor, setPaintProperty, "fill-extrusion-translate-anchor", setFillExtrusionTranslateAnchor, mln::style::TranslateAnchorType)

DEFINE_LAYER_GETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, GetFillExtrusionTranslateAnchor, getFillExtrusionTranslateAnchor, mln::style::TranslateAnchorType)

DEFINE_LAYER_SETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, SetFillExtrusionVerticalGradient, setPaintProperty, "fill-extrusion-vertical-gradient", setFillExtrusionVerticalGradient, bool)

DEFINE_LAYER_GETTER(FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer, GetFillExtrusionVerticalGradient, getFillExtrusionVerticalGradient, bool)

// ==================== Generic Property Methods ====================

napi_value FillExtrusionLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<FillExtrusionLayerNAPI, mln::style::FillExtrusionLayer>(env, info);
}

} // namespace harmony
} // namespace mln
