#include "raster_layer_harmony.hpp"
#include "../../napi_args.hpp"
#include "../../logger.h"
#include <mbgl/style/layers/raster_layer.hpp>
#include <mbgl/style/property_value.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref RasterLayerNAPI::constructor = nullptr;

RasterLayerNAPI::RasterLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::RasterLayer>(layerId, sourceId)) {
    Logger::debug("RasterLayerNAPI", "RasterLayer created: %s", layerId.c_str());
}

RasterLayerNAPI::~RasterLayerNAPI() {
    Logger::debug("RasterLayerNAPI", "RasterLayer destroyed");
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
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double opacity = args.GetDouble(0, "opacity");
    if (!args.HasError()) {
        layerObj->layer->setRasterOpacity(mbgl::style::PropertyValue<float>(static_cast<float>(opacity)));
    }
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterHueRotate(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double hue = args.GetDouble(0, "hueRotate");
    if (!args.HasError()) {
        layerObj->layer->setRasterHueRotate(mbgl::style::PropertyValue<float>(static_cast<float>(hue)));
    }
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterBrightnessMin(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double brightness = args.GetDouble(0, "brightnessMin");
    if (!args.HasError()) {
        layerObj->layer->setRasterBrightnessMin(mbgl::style::PropertyValue<float>(static_cast<float>(brightness)));
    }
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterBrightnessMax(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double brightness = args.GetDouble(0, "brightnessMax");
    if (!args.HasError()) {
        layerObj->layer->setRasterBrightnessMax(mbgl::style::PropertyValue<float>(static_cast<float>(brightness)));
    }
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterSaturation(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double saturation = args.GetDouble(0, "saturation");
    if (!args.HasError()) {
        layerObj->layer->setRasterSaturation(mbgl::style::PropertyValue<float>(static_cast<float>(saturation)));
    }
    return thisVar;
}

napi_value RasterLayerNAPI::SetRasterContrast(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    double contrast = args.GetDouble(0, "contrast");
    if (!args.HasError()) {
        layerObj->layer->setRasterContrast(mbgl::style::PropertyValue<float>(static_cast<float>(contrast)));
    }
    return thisVar;
}

napi_value RasterLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    RasterLayerNAPI* layerObj;
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value result;
    napi_create_string_utf8(env, layerObj->layer->getID().c_str(), NAPI_AUTO_LENGTH, &result);
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
    if (napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj)) != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value result;
    napi_create_string_utf8(env, layerObj->layer->getSourceID().c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

