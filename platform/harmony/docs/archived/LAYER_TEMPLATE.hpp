// 此文件是Layer NAPI绑定的模板
// 替换 {{LAYER_NAME}} 为实际的图层名称（如Symbol, Raster等）
// 替换 {{layer_name}} 为小写形式（如symbol, raster等）

#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/{{layer_name}}_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * {{LAYER_NAME}}Layer NAPI绑定类
 */
class {{LAYER_NAME}}LayerHarmony {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value Create(napi_env env, napi_callback_info info);
    // 根据具体图层类型添加属性设置方法
    // 例如: static napi_value SetPropertyName(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

