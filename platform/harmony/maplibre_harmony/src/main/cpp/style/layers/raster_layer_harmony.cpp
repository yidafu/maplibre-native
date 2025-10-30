#include "raster_layer_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
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
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->layer.get(), argv[0], "raster-opacity",
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
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->layer.get(), argv[0], "raster-hue-rotate",
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
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->layer.get(), argv[0], "raster-brightness-min",
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
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->layer.get(), argv[0], "raster-brightness-max",
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
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->layer.get(), argv[0], "raster-saturation",
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
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->layer.get(), argv[0], "raster-contrast",
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
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, float>(
        env, layerObj->layer.get(), argv[0], "raster-fade-duration",
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
        env, layerObj->layer.get(), &mbgl::style::RasterLayer::getRasterFadeDuration
    );
}

napi_value RasterLayerNAPI::SetRasterResampling(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::RasterLayer, mbgl::style::RasterResamplingType>(
        env, layerObj->layer.get(), argv[0], "raster-resampling",
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
        env, layerObj->layer.get(), &mbgl::style::RasterLayer::getRasterResampling
    );
}

} // namespace harmony
} // namespace mbgl
