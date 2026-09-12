#include "fill_extrusion_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/fill_extrusion_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref FillExtrusionLayerNAPI::constructor = nullptr;
napi_env FillExtrusionLayerNAPI::constructorEnv = nullptr;

FillExtrusionLayerNAPI::FillExtrusionLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::FillExtrusionLayer>(layerId, sourceId)) {
}

FillExtrusionLayerNAPI::FillExtrusionLayerNAPI(mbgl::style::FillExtrusionLayer* layerPtr) {
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
        
        // New properties
        { "setFillExtrusionTranslateAnchor", nullptr, SetFillExtrusionTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillExtrusionTranslateAnchor", nullptr, GetFillExtrusionTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionVerticalGradient", nullptr, SetFillExtrusionVerticalGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillExtrusionVerticalGradient", nullptr, GetFillExtrusionVerticalGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "FillExtrusionLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) return nullptr;
    
    mbgl::harmony::RefreshConstructorRef(env, cons, constructor, constructorEnv);
    napi_set_named_property(env, exports, "FillExtrusionLayer", cons);
    
    Logger::info("FillExtrusionLayerNAPI", "FillExtrusionLayer NAPI class registered");
    return exports;
}

napi_value FillExtrusionLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return nullptr;
    
    FillExtrusionLayerNAPI* layerObj = new FillExtrusionLayerNAPI(layerId, sourceId);
    napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "FillExtrusionLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::CreateInstance(napi_env env, mbgl::style::FillExtrusionLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "FillExtrusionLayer",
                                layerPtr ? new FillExtrusionLayerNAPI(layerPtr) : nullptr);
}


napi_value FillExtrusionLayerNAPI::SetFillExtrusionColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-color",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionColor
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, float>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-opacity",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionOpacity
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionHeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, float>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-height",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionHeight
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionBase(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, float>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-base",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionBase
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionPattern(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-pattern",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionPattern
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-translate",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionTranslate
    );
    return thisVar;
}

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

napi_value FillExtrusionLayerNAPI::SetFillExtrusionTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-translate-anchor",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionTranslateAnchor
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetFillExtrusionTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::FillExtrusionLayer, mbgl::style::TranslateAnchorType>(
        env, layer, &mbgl::style::FillExtrusionLayer::getFillExtrusionTranslateAnchor
    );
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionVerticalGradient(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, bool>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-vertical-gradient",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionVerticalGradient
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetFillExtrusionVerticalGradient(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<FillExtrusionLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::FillExtrusionLayer, bool>(
        env, layer, &mbgl::style::FillExtrusionLayer::getFillExtrusionVerticalGradient
    );
}

// ==================== Generic Property Methods ====================

napi_value FillExtrusionLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<FillExtrusionLayerNAPI, mbgl::style::FillExtrusionLayer>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<FillExtrusionLayerNAPI, mbgl::style::FillExtrusionLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
