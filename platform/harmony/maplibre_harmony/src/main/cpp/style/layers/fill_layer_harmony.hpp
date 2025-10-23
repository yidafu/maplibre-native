#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/fill_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * FillLayer NAPI绑定类
 * 
 * 封装 mbgl::style::FillLayer
 */
class FillLayerHarmony {
public:
    /**
     * 初始化FillLayer类的NAPI绑定
     */
    static napi_value Init(napi_env env, napi_value exports);

    /**
     * 创建FillLayer实例
     * 参数: layerId, sourceId
     */
    static napi_value Create(napi_env env, napi_callback_info info);

    /**
     * 设置填充颜色
     * 参数: layerPtr, color
     */
    static napi_value SetFillColor(napi_env env, napi_callback_info info);

    /**
     * 设置填充透明度
     * 参数: layerPtr, opacity
     */
    static napi_value SetFillOpacity(napi_env env, napi_callback_info info);

    /**
     * 设置填充轮廓颜色
     * 参数: layerPtr, color
     */
    static napi_value SetFillOutlineColor(napi_env env, napi_callback_info info);

    /**
     * 设置填充图案
     * 参数: layerPtr, pattern
     */
    static napi_value SetFillPattern(napi_env env, napi_callback_info info);

    /**
     * 设置抗锯齿
     * 参数: layerPtr, antialias
     */
    static napi_value SetFillAntialias(napi_env env, napi_callback_info info);

    /**
     * 设置填充偏移
     * 参数: layerPtr, translate
     */
    static napi_value SetFillTranslate(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

