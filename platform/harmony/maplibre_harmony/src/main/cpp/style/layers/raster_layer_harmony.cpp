#include "raster_layer_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include "style/filter_conversion.hpp"
#include <mbgl/style/layers/raster_layer.hpp>
#include <mbgl/style/property_value.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref RasterLayerNAPI::constructor = nullptr;

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
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "RasterLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) return nullptr;
    
    napi_create_reference(env, cons, 1, &constructor);
    napi_set_named_property(env, exports, "RasterLayer", cons);
    
    Logger::info("RasterLayerNAPI", "RasterLayer NAPI class registered successfully");
    return exports;
}

napi_value RasterLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return nullptr;
    
    RasterLayerNAPI* layerObj = new RasterLayerNAPI(layerId, sourceId);
    napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    
    // 添加 _TYPE_ 属性用于 ETS 层的类型判断
    napi_value typeValue;
    napi_create_string_utf8(env, "RasterLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    
    return thisVar;
}

napi_value RasterLayerNAPI::CreateInstance(napi_env env, mbgl::style::RasterLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("RasterLayerNAPI", "Failed to get constructor reference");
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
    RasterLayerNAPI* napiObj = new RasterLayerNAPI(layerPtr);
    
    // 包装到 JS 对象
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("RasterLayerNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 添加 _TYPE_ 属性
    napi_value typeValue;
    napi_create_string_utf8(env, "RasterLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}


napi_value RasterLayerNAPI::SetRasterOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), argv[0], "raster-opacity",
        &mbgl::style::RasterLayer::setRasterOpacity
    );
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterHueRotate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), argv[0], "raster-hue-rotate",
        &mbgl::style::RasterLayer::setRasterHueRotate
    );
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterBrightnessMin(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), argv[0], "raster-brightness-min",
        &mbgl::style::RasterLayer::setRasterBrightnessMin
    );
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterBrightnessMax(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), argv[0], "raster-brightness-max",
        &mbgl::style::RasterLayer::setRasterBrightnessMax
    );
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterSaturation(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), argv[0], "raster-saturation",
        &mbgl::style::RasterLayer::setRasterSaturation
    );
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterContrast(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), argv[0], "raster-contrast",
        &mbgl::style::RasterLayer::setRasterContrast
    );
    return thisVar;
}

napi_value RasterLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    std::string id = layerObj->layer->getID();
    napi_value result;
    napi_create_string_utf8(env, id.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value RasterLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "raster", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value RasterLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    std::string sourceId = layerObj->layer->getSourceID();
    napi_value result;
    napi_create_string_utf8(env, sourceId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// New Properties
// ============================================================================

napi_value RasterLayerNAPI::SetRasterFadeDuration(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), argv[0], "raster-fade-duration",
        &mbgl::style::RasterLayer::setRasterFadeDuration
    );
    return thisVar;
}

napi_value RasterLayerNAPI::GetRasterFadeDuration(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::RasterLayer::getRasterFadeDuration
    );
}

napi_value RasterLayerNAPI::SetRasterResampling(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, mbgl::style::RasterResamplingType>(
        env, layerObj->getLayer(), argv[0], "raster-resampling",
        &mbgl::style::RasterLayer::setRasterResampling
    );
    return thisVar;
}

napi_value RasterLayerNAPI::GetRasterResampling(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::RasterLayer, mbgl::style::RasterResamplingType>(
        env, layerObj->getLayer(), &mbgl::style::RasterLayer::getRasterResampling
    );
}

// ============================================================================
// Visibility
// ============================================================================

napi_value RasterLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return thisVar;
    }
    
    std::string visibility = args.GetString(0, "visibility");
    if (visibility == "visible") {
        layerObj->layer->setVisibility(mbgl::style::VisibilityType::Visible);
    } else if (visibility == "none") {
        layerObj->layer->setVisibility(mbgl::style::VisibilityType::None);
    }
    
    return thisVar;
}

napi_value RasterLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    auto visibility = layerObj->layer->getVisibility();
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";
    
    napi_value result;
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// Zoom Range
// ============================================================================

napi_value RasterLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layerObj->layer->setMinZoom(minZoom);
    }
    
    return thisVar;
}

napi_value RasterLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
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

napi_value RasterLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layerObj->layer->setMaxZoom(maxZoom);
    }
    
    return thisVar;
}

napi_value RasterLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }
    
    float maxZoom = layerObj->layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value RasterLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layerObj->layer->setSourceLayer(sourceLayer);
    }
    
    return thisVar;
}

napi_value RasterLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    std::string sourceLayer = layerObj->layer->getSourceLayer();
    napi_value result;
    napi_create_string_utf8(env, sourceLayer.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// Filter
// ============================================================================

napi_value RasterLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    auto filter = mbgl::harmony::napiArrayToFilter(env, argv[0]);
    if (filter) {
        layerObj->layer->setFilter(*filter);
    }
    
    return thisVar;
}

napi_value RasterLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    auto filter = layerObj->layer->getFilter();
    return mbgl::harmony::filterToNapiArray(env, filter);
}

} // namespace harmony
} // namespace mbgl
