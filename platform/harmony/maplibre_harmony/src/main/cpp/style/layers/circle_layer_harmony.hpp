#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/circle_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * CircleLayer NAPI绑定类
 */
class CircleLayerHarmony {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value Create(napi_env env, napi_callback_info info);
    static napi_value SetCircleRadius(napi_env env, napi_callback_info info);
    static napi_value SetCircleColor(napi_env env, napi_callback_info info);
    static napi_value SetCircleOpacity(napi_env env, napi_callback_info info);
    static napi_value SetCircleBlur(napi_env env, napi_callback_info info);
    static napi_value SetCircleStrokeWidth(napi_env env, napi_callback_info info);
    static napi_value SetCircleStrokeColor(napi_env env, napi_callback_info info);
    static napi_value SetCircleStrokeOpacity(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

