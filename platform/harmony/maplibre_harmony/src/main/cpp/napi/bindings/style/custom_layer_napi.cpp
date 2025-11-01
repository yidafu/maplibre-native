#include "custom_layer_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/custom_layer_harmony.hpp"
#include <mbgl/style/layers/custom_layer.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// 静态成员初始化
napi_ref CustomLayerNAPI::constructor = nullptr;

CustomLayerNAPI::CustomLayerNAPI(const std::string& layerId, 
                                 std::unique_ptr<mbgl::style::CustomLayer> layer,
                                 std::shared_ptr<ExampleCustomLayerHost> host)
    : layerId(layerId)
    , layer(std::move(layer))
    , host(host) {
    Logger::info("CustomLayerNAPI", "CustomLayer created: %s", layerId.c_str());
}

CustomLayerNAPI::~CustomLayerNAPI() {
    Logger::info("CustomLayerNAPI", "CustomLayer destroyed: %s", layerId.c_str());
}

void CustomLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    CustomLayerNAPI* obj = static_cast<CustomLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value CustomLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("CustomLayerNAPI", "Initializing CustomLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setColor", nullptr, SetColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getColor", nullptr, GetColor, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "CustomLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("CustomLayerNAPI", "Failed to define CustomLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("CustomLayerNAPI", "Failed to create reference to CustomLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "CustomLayer", cons);
    if (status != napi_ok) {
        Logger::error("CustomLayerNAPI", "Failed to export CustomLayer class");
        return nullptr;
    }
    
    Logger::info("CustomLayerNAPI", "CustomLayer NAPI class registered successfully");
    return exports;
}

napi_value CustomLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) {
        return nullptr;
    }
    
    // 创建 ExampleCustomLayerHost 实例
    auto host = std::make_shared<ExampleCustomLayerHost>();
    
    // 创建 CustomLayer 实例
    auto layer = std::make_unique<mbgl::style::CustomLayer>(layerId, std::move(host));
    
    // 创建 NAPI 包装对象
    CustomLayerNAPI* layerObj = new CustomLayerNAPI(layerId, std::move(layer), host);
    
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("CustomLayerNAPI", "Failed to wrap CustomLayer object");
        return nullptr;
    }
    
    return thisVar;
}

napi_value CustomLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    napi_value result;
    napi_create_string_utf8(env, layerObj->layerId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value CustomLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "custom", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value CustomLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
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

napi_value CustomLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
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

napi_value CustomLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
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

napi_value CustomLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
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

napi_value CustomLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
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

napi_value CustomLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
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

napi_value CustomLayerNAPI::SetColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->host) {
        return thisVar;
    }
    
    args.RequireMinArgs(4);
    if (args.HasError()) {
        return thisVar;
    }
    
    float r = static_cast<float>(args.GetDouble(0, "r"));
    float g = static_cast<float>(args.GetDouble(1, "g"));
    float b = static_cast<float>(args.GetDouble(2, "b"));
    float a = static_cast<float>(args.GetDouble(3, "a"));
    
    layerObj->host->setColor(r, g, b, a);
    
    return thisVar;
}

napi_value CustomLayerNAPI::GetColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CustomLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->host) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    float color[4];
    layerObj->host->getColor(color);
    
    napi_value result;
    napi_create_array_with_length(env, 4, &result);
    
    for (int i = 0; i < 4; i++) {
        napi_value value;
        napi_create_double(env, color[i], &value);
        napi_set_element(env, result, i, value);
    }
    
    return result;
}

} // namespace harmony
} // namespace mbgl

