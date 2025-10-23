#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/line_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * LineLayer NAPI绑定类
 */
class LineLayerHarmony {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value Create(napi_env env, napi_callback_info info);
    static napi_value SetLineColor(napi_env env, napi_callback_info info);
    static napi_value SetLineWidth(napi_env env, napi_callback_info info);
    static napi_value SetLineOpacity(napi_env env, napi_callback_info info);
    static napi_value SetLinePattern(napi_env env, napi_callback_info info);
    static napi_value SetLineGapWidth(napi_env env, napi_callback_info info);
    static napi_value SetLineDasharray(napi_env env, napi_callback_info info);
    static napi_value SetLineBlur(napi_env env, napi_callback_info info);
    static napi_value SetLineCap(napi_env env, napi_callback_info info);
    static napi_value SetLineJoin(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

