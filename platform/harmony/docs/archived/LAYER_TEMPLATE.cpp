// 此文件是Layer NAPI绑定的模板
// 替换 {{LAYER_NAME}} 为实际的图层名称（如Symbol, Raster等）
// 替换 {{layer_name}} 为小写形式（如symbol, raster等）

#include "{{layer_name}}_layer_harmony.hpp"
#include "../../napi_utils.h"
#include "../../logger.h"
#include <mbgl/style/layers/{{layer_name}}_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/util/color.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

using namespace mbgl::style;

napi_value {{LAYER_NAME}}LayerHarmony::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_STATIC_FUNCTION("create", Create),
        // 添加其他方法，例如:
        // DECLARE_NAPI_STATIC_FUNCTION("setPropertyName", SetPropertyName),
    };

    napi_value {{layer_name}}LayerObject;
    napi_create_object(env, &{{layer_name}}LayerObject);
    napi_define_properties(env, {{layer_name}}LayerObject,
        sizeof(properties) / sizeof(properties[0]),
        properties);

    napi_set_named_property(env, exports, "{{LAYER_NAME}}Layer", {{layer_name}}LayerObject);

    return exports;
}

napi_value {{LAYER_NAME}}LayerHarmony::Create(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        LOGE("{{LAYER_NAME}}Layer.Create: missing arguments");
        return CreateInt64Value(env, 0);
    }

    std::string layerId = GetStringFromValue(env, args[0]);
    std::string sourceId = GetStringFromValue(env, args[1]);

    try {
        auto layer = std::make_unique<mbgl::style::{{LAYER_NAME}}Layer>(layerId, sourceId);
        int64_t layerPtr = reinterpret_cast<int64_t>(layer.release());
        LOGI("{{LAYER_NAME}}Layer.Create: %s (source: %s)", layerId.c_str(), sourceId.c_str());
        return CreateInt64Value(env, layerPtr);
    } catch (const std::exception& e) {
        LOGE("{{LAYER_NAME}}Layer.Create failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

// 属性设置方法示例:
// napi_value {{LAYER_NAME}}LayerHarmony::SetPropertyName(napi_env env, napi_callback_info info) {
//     size_t argc = 2;
//     napi_value args[2];
//     napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
// 
//     if (argc < 2) {
//         napi_value result;
//         napi_get_undefined(env, &result);
//         return result;
//     }
// 
//     int64_t layerPtr = GetInt64FromValue(env, args[0]);
//     auto* layer = reinterpret_cast<mbgl::style::{{LAYER_NAME}}Layer*>(layerPtr);
//     
//     if (!layer) {
//         napi_value result;
//         napi_get_undefined(env, &result);
//         return result;
//     }
// 
//     // 根据属性类型获取值
//     // double value = GetDoubleFromValue(env, args[1]);
//     // std::string value = GetStringFromValue(env, args[1]);
//     // bool value = GetBoolFromValue(env, args[1]);
// 
//     try {
//         // layer->setPropertyName(PropertyValue<Type>(value));
//         LOGI("{{LAYER_NAME}}Layer.SetPropertyName: ...");
//     } catch (const std::exception& e) {
//         LOGE("{{LAYER_NAME}}Layer.SetPropertyName failed: %s", e.what());
//     }
// 
//     napi_value result;
//     napi_get_undefined(env, &result);
//     return result;
// }

} // namespace harmony
} // namespace mbgl

