#include "heatmap_layer_harmony.hpp"
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

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref HeatmapLayerNAPI::constructor = nullptr;

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
    
    status = napi_create_reference(env, cons, 1, &constructor);
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
    

    
    // 添加 _TYPE_ 属性用于 ETS 层的类型判断
    napi_value typeValue;
    napi_create_string_utf8(env, "HeatmapLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return thisVar;
}

napi_value HeatmapLayerNAPI::CreateInstance(napi_env env, mbgl::style::HeatmapLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("HeatmapLayerNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建空对象并设置原型（避免调用 JS 构造函数）
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数的原型
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 设置对象的原型
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建 NAPI wrapper（使用 WeakPtr 构造函数）
    HeatmapLayerNAPI* napiObj = new HeatmapLayerNAPI(layerPtr);
    
    // 包装到 JS 对象
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("HeatmapLayerNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 添加 _TYPE_ 属性
    napi_value typeValue;
    napi_create_string_utf8(env, "HeatmapLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}


// ============================================================================
// Paint Property Setters (支持 Expression)
// ============================================================================

napi_value HeatmapLayerNAPI::SetHeatmapRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
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
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
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
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
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
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    // heatmap-color uses ColorRampPropertyValue, special handling
    // For now, we use the existing conversion approach
    // TODO: Implement full ColorRampPropertyValue conversion if needed
    try {
        NapiValue napiValue(env, argv[0]);
        mbgl::style::conversion::Error error;
        auto converted = mbgl::style::conversion::convert<mbgl::style::ColorRampPropertyValue>(
            std::move(napiValue), error
        );
        
        if (converted) {
            layerObj->layer->setHeatmapColor(*converted);
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
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
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
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::HeatmapLayer::getHeatmapRadius
    );
}

napi_value HeatmapLayerNAPI::GetHeatmapWeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::HeatmapLayer::getHeatmapWeight
    );
}

napi_value HeatmapLayerNAPI::GetHeatmapIntensity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::HeatmapLayer::getHeatmapIntensity
    );
}

napi_value HeatmapLayerNAPI::GetHeatmapColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    // heatmap-color is ColorRampPropertyValue
    const auto& colorRamp = layerObj->layer->getHeatmapColor();
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
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::HeatmapLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::HeatmapLayer::getHeatmapOpacity
    );
}

// ============================================================================
// Base Layer Methods (common pattern)
// ============================================================================

napi_value HeatmapLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
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

napi_value HeatmapLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "heatmap", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value HeatmapLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
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

napi_value HeatmapLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
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

napi_value HeatmapLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
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

napi_value HeatmapLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layerObj->layer->setMinZoom(minZoom);
    }
    return thisVar;
}

napi_value HeatmapLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }
    
    float minZoom = layerObj->layer->getMinZoom();
    napi_value result;
    napi_create_double(env, minZoom, &result);
    return result;
}

napi_value HeatmapLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layerObj->layer->setMaxZoom(maxZoom);
    }
    return thisVar;
}

napi_value HeatmapLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }
    
    float maxZoom = layerObj->layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

napi_value HeatmapLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layerObj->layer->setSourceLayer(sourceLayer);
    }
    return thisVar;
}

napi_value HeatmapLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string sourceLayer = layerObj->layer->getSourceLayer();
    napi_value result;
    napi_create_string_utf8(env, sourceLayer.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value HeatmapLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    auto filter = napiArrayToFilter(env, argv[0]);
    if (filter) {
        layerObj->layer->setFilter(*filter);
    }
    return thisVar;
}

napi_value HeatmapLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    HeatmapLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    const auto& filter = layerObj->layer->getFilter();
    return filterToNapiArray(env, filter);
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
