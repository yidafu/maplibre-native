#include "fill_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/property_value.hpp>
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
napi_ref FillLayerNAPI::constructor = nullptr;
napi_env FillLayerNAPI::constructorEnv = nullptr;

FillLayerNAPI::FillLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::FillLayer>(layerId, sourceId)) {
}

FillLayerNAPI::FillLayerNAPI(mbgl::style::FillLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("FillLayerNAPI", "FillLayer created from existing layer (WeakPtr)");
    }
}


FillLayerNAPI::~FillLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void FillLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    FillLayerNAPI* obj = static_cast<FillLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value FillLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("FillLayerNAPI", "Initializing FillLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setFillColor", nullptr, SetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillOpacity", nullptr, SetFillOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillOutlineColor", nullptr, SetFillOutlineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillPattern", nullptr, SetFillPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillAntialias", nullptr, SetFillAntialias, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillTranslate", nullptr, SetFillTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
        { "getFillColor", nullptr, GetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillOpacity", nullptr, GetFillOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
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
        { "setFillTranslateAnchor", nullptr, SetFillTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillTranslateAnchor", nullptr, GetFillTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillSortKey", nullptr, SetFillSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillSortKey", nullptr, GetFillSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "FillLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "FillLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("FillLayerNAPI", "FillLayer NAPI class registered successfully");
    return exports;
}

napi_value FillLayerNAPI::New(napi_env env, napi_callback_info info) {
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
    
    // Create FillLayerNAPI instance
    FillLayerNAPI* layerObj = new FillLayerNAPI(layerId, sourceId);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("FillLayerNAPI", "Failed to wrap FillLayer object");
        return nullptr;
    }
    

    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "FillLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return thisVar;
}

napi_value FillLayerNAPI::CreateInstance(napi_env env, mbgl::style::FillLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "FillLayer",
                                layerPtr ? new FillLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Paint Property Setters (Expression supported)
// ============================================================================

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillColor, setPaintProperty, "fill-color", setFillColor, mbgl::Color)

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillOpacity, setPaintProperty, "fill-opacity", setFillOpacity, float)

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillOutlineColor, setPaintProperty, "fill-outline-color", setFillOutlineColor, mbgl::Color)

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillPattern, setPaintProperty, "fill-pattern", setFillPattern, mbgl::style::expression::Image)

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillAntialias, setPaintProperty, "fill-antialias", setFillAntialias, bool)

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillTranslate, setPaintProperty, "fill-translate", setFillTranslate, std::array<float,2>)

// ============================================================================
// Property Getters (return constants or Expressions)
// ============================================================================

DEFINE_LAYER_GETTER(FillLayerNAPI, mbgl::style::FillLayer, GetFillColor, getFillColor, mbgl::Color)

DEFINE_LAYER_GETTER(FillLayerNAPI, mbgl::style::FillLayer, GetFillOpacity, getFillOpacity, float)

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value FillLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<FillLayerNAPI>(env, info);
}

napi_value FillLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "fill");
}

napi_value FillLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    return LayerGetSourceId<FillLayerNAPI>(env, info);
}

// ============================================================================
// Visibility
// ============================================================================

napi_value FillLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<FillLayerNAPI>(env, info);
}

napi_value FillLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<FillLayerNAPI>(env, info);
}

// ============================================================================
// Zoom Range
// ============================================================================

napi_value FillLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<FillLayerNAPI>(env, info);
}

napi_value FillLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<FillLayerNAPI>(env, info);
}

napi_value FillLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<FillLayerNAPI>(env, info);
}

napi_value FillLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<FillLayerNAPI>(env, info);
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value FillLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerSetSourceLayer<FillLayerNAPI>(env, info);
}

napi_value FillLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    return LayerGetSourceLayer<FillLayerNAPI>(env, info);
}

// ============================================================================
// Filter
// ============================================================================

napi_value FillLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    return LayerSetFilter<FillLayerNAPI>(env, info);
}

napi_value FillLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    return LayerGetFilter<FillLayerNAPI>(env, info);
}

// ============================================================================
// New Properties
// ============================================================================

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillTranslateAnchor, setPaintProperty, "fill-translate-anchor", setFillTranslateAnchor, mbgl::style::TranslateAnchorType)

DEFINE_LAYER_GETTER(FillLayerNAPI, mbgl::style::FillLayer, GetFillTranslateAnchor, getFillTranslateAnchor, mbgl::style::TranslateAnchorType)

DEFINE_LAYER_SETTER(FillLayerNAPI, mbgl::style::FillLayer, SetFillSortKey, setLayoutProperty, "fill-sort-key", setFillSortKey, float)

DEFINE_LAYER_GETTER(FillLayerNAPI, mbgl::style::FillLayer, GetFillSortKey, getFillSortKey, float)

// ==================== Generic Property Methods ====================

napi_value FillLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<FillLayerNAPI, mbgl::style::FillLayer>(env, info);
}

napi_value FillLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<FillLayerNAPI, mbgl::style::FillLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
