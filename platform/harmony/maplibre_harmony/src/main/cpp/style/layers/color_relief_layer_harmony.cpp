#include "color_relief_layer_harmony.hpp"
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

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref ColorReliefLayerNAPI::constructor = nullptr;

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
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_value cons;
    napi_status status = napi_define_class(env, "ColorReliefLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);

    if (status != napi_ok) return nullptr;

    napi_create_reference(env, cons, 1, &constructor);
    napi_set_named_property(env, exports, "ColorReliefLayer", cons);

    Logger::info("ColorReliefLayerNAPI", "ColorReliefLayer NAPI class registered");
    return exports;
}

napi_value ColorReliefLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;

    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return nullptr;

    ColorReliefLayerNAPI* layerObj = new ColorReliefLayerNAPI(layerId, sourceId);
    napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);

    napi_value typeValue;
    napi_create_string_utf8(env, "ColorReliefLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);

    return thisVar;
}

napi_value ColorReliefLayerNAPI::CreateInstance(napi_env env, mbgl::style::ColorReliefLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("ColorReliefLayerNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    ColorReliefLayerNAPI* napiObj = new ColorReliefLayerNAPI(layerPtr);

    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("ColorReliefLayerNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value typeValue;
    napi_create_string_utf8(env, "ColorReliefLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);

    return instance;
}

// ============================================================================
// Paint Property Setters
// ============================================================================

napi_value ColorReliefLayerNAPI::SetColorReliefColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    // colorReliefColor uses ColorRampPropertyValue (same pattern as heatmap-color)
    try {
        NapiValue napiValue(env, argv[0]);
        mbgl::style::conversion::Error error;
        auto converted = mbgl::style::conversion::convert<mbgl::style::ColorRampPropertyValue>(
            std::move(napiValue), error
        );

        if (converted) {
            layerObj->getLayer()->setColorReliefColor(*converted);
        } else {
            Logger::error("ColorReliefLayerNAPI", "Failed to convert colorReliefColor: %s", error.message.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("ColorReliefLayerNAPI", "Exception setting colorReliefColor: %s", e.what());
    }

    return thisVar;
}

napi_value ColorReliefLayerNAPI::SetColorReliefOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::ColorReliefLayer, float>(
        env, layerObj->getLayer(), argv[0], "colorReliefOpacity",
        &mbgl::style::ColorReliefLayer::setColorReliefOpacity
    );
    return thisVar;
}

// ============================================================================
// Paint Property Getters
// ============================================================================

napi_value ColorReliefLayerNAPI::GetColorReliefColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    // colorReliefColor is ColorRampPropertyValue
    const auto& colorRamp = layer->getColorReliefColor();
    auto result = mbgl::harmony::conversion::colorRampPropertyValueToNapi(env, colorRamp);
    if (result) {
        return *result;
    }
    napi_value null_value;
    napi_get_null(env, &null_value);
    return null_value;
}

napi_value ColorReliefLayerNAPI::GetColorReliefOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::ColorReliefLayer, float>(
        env, layer, &mbgl::style::ColorReliefLayer::getColorReliefOpacity
    );
}

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value ColorReliefLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    std::string id = layerObj->getLayer()->getID();
    napi_value result;
    napi_create_string_utf8(env, id.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value ColorReliefLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "color-relief", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value ColorReliefLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    std::string sourceId = layerObj->getLayer()->getSourceID();
    napi_value result;
    napi_create_string_utf8(env, sourceId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value ColorReliefLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj || !layerObj->getLayer()) return thisVar;

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string visibility = args.GetString(0, "visibility");
        if (visibility == "visible") {
            layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::Visible);
        } else if (visibility == "none") {
            layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::None);
        }
    }
    return thisVar;
}

napi_value ColorReliefLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    auto visibility = layerObj->getLayer()->getVisibility();
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";

    napi_value result;
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value ColorReliefLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) return thisVar;

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) return thisVar;

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layer->setMinZoom(minZoom);
    }
    return thisVar;
}

napi_value ColorReliefLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }

    float minZoom = layer->getMinZoom();
    napi_value result;
    napi_create_double(env, minZoom, &result);
    return result;
}

napi_value ColorReliefLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) return thisVar;

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) return thisVar;

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layer->setMaxZoom(maxZoom);
    }
    return thisVar;
}

napi_value ColorReliefLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }

    float maxZoom = layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value ColorReliefLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) {
        return thisVar;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layer->setSourceLayer(sourceLayer);
    }

    return thisVar;
}

napi_value ColorReliefLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    std::string sourceLayer = layer->getSourceLayer();
    napi_value result;
    napi_create_string_utf8(env, sourceLayer.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// Filter
// ============================================================================

napi_value ColorReliefLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj || argc < 1) {
        return thisVar;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }

    auto filter = mbgl::harmony::napiArrayToFilter(env, argv[0]);
    if (filter) {
        layer->setFilter(*filter);
    }

    return thisVar;
}

napi_value ColorReliefLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<ColorReliefLayerNAPI>(env, thisVar);

    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    mbgl::style::ColorReliefLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    auto filter = layer->getFilter();
    return mbgl::harmony::filterToNapiArray(env, filter);
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
