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
    
    napi_value cons;
    napi_status status = napi_define_class(env, "HeatmapLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("HeatmapLayerNAPI", "Failed to define HeatmapLayer class");
        return nullptr;
    }
    
    status = mbgl::harmony::RefreshConstructorRef(env, cons, constructor, constructorEnv);
    if (status != napi_ok) {
        Logger::error("HeatmapLayerNAPI", "Failed to create reference to HeatmapLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "HeatmapLayer", cons);
    if (status != napi_ok) {
        Logger::error("HeatmapLayerNAPI", "Failed to export HeatmapLayer class");
        return nullptr;
    }
    
    Logger::info("HeatmapLayerNAPI", "HeatmapLayer NAPI class registered successfully");
    return exports;
}

napi_value HeatmapLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }

    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) {
        return nullptr;
    }
    
    HeatmapLayerNAPI* layerObj = new HeatmapLayerNAPI(layerId, sourceId);
    
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("HeatmapLayerNAPI", "Failed to wrap HeatmapLayer object");
        return nullptr;
    }
    

    
    // Add the _TYPE_ property for type detection in the ETS layer
    napi_value typeValue;
    napi_create_string_utf8(env, "HeatmapLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return thisVar;
}

napi_value HeatmapLayerNAPI::CreateInstance(napi_env env, mbgl::style::HeatmapLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "HeatmapLayer",
                                layerPtr ? new HeatmapLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Paint Property Setters (with Expression support)
// ============================================================================

napi_value HeatmapLayerNAPI::SetHeatmapRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj || argc < 1) return thisVar;

    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), argv[0], "heatmap-radius",
        &mbgl::style::HeatmapLayer::setHeatmapRadius
    );
    return thisVar;
}

napi_value HeatmapLayerNAPI::SetHeatmapWeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj || argc < 1) return thisVar;

    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), argv[0], "heatmap-weight",
        &mbgl::style::HeatmapLayer::setHeatmapWeight
    );
    return thisVar;
}

napi_value HeatmapLayerNAPI::SetHeatmapIntensity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj || argc < 1) return thisVar;

    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), argv[0], "heatmap-intensity",
        &mbgl::style::HeatmapLayer::setHeatmapIntensity
    );
    return thisVar;
}

napi_value HeatmapLayerNAPI::SetHeatmapColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj || argc < 1) return thisVar;
    
    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }
    
    // heatmap-color uses ColorRampPropertyValue: converted through the core
    // Converter<ColorRampPropertyValue> (interpolation expressions via the
    // NapiValue -> Convertible bridge), same path as the other layers.
    try {
        NapiValue napiValue(env, argv[0]);
        mbgl::style::conversion::Error error;
        auto converted = mbgl::style::conversion::convert<mbgl::style::ColorRampPropertyValue>(
            std::move(napiValue), error
        );
        
        if (converted) {
            layer->setHeatmapColor(*converted);
        } else {
            Logger::error("HeatmapLayerNAPI", "Failed to convert heatmap-color: %s", error.message.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("HeatmapLayerNAPI", "Exception setting heatmap-color: %s", e.what());
    }
    
    return thisVar;
}

napi_value HeatmapLayerNAPI::SetHeatmapOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), argv[0], "heatmap-opacity",
        &mbgl::style::HeatmapLayer::setHeatmapOpacity
    );
    return thisVar;
}

// ============================================================================
// Property Getters
// ============================================================================

napi_value HeatmapLayerNAPI::GetHeatmapRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layer, &mbgl::style::HeatmapLayer::getHeatmapRadius
    );
}

napi_value HeatmapLayerNAPI::GetHeatmapWeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layer, &mbgl::style::HeatmapLayer::getHeatmapWeight
    );
}

napi_value HeatmapLayerNAPI::GetHeatmapIntensity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layer, &mbgl::style::HeatmapLayer::getHeatmapIntensity
    );
}

napi_value HeatmapLayerNAPI::GetHeatmapColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    // heatmap-color is ColorRampPropertyValue
    const auto& colorRamp = layer->getHeatmapColor();
    auto result = mbgl::harmony::conversion::colorRampPropertyValueToNapi(env, colorRamp);
    if (result) {
        return *result;
    } else {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
}

napi_value HeatmapLayerNAPI::GetHeatmapOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<HeatmapLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::HeatmapLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layer, &mbgl::style::HeatmapLayer::getHeatmapOpacity
    );
}

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
