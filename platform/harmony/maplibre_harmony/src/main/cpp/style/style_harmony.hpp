#pragma once

#include <napi/native_api.h>
#include <mbgl/style/style.hpp>
#include <mbgl/map/map.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * Style NAPI绑定类
 * 
 * 封装 mbgl::style::Style 核心类，提供给ArkTS层调用
 */
class StyleHarmony {
public:
    StyleHarmony() = default;
    ~StyleHarmony() = default;

    /**
     * 初始化Style类的NAPI绑定
     */
    static napi_value Init(napi_env env, napi_value exports);

    /**
     * 获取样式URI
     */
    static napi_value GetStyleUri(napi_env env, napi_callback_info info);

    /**
     * 获取样式JSON
     */
    static napi_value GetStyleJson(napi_env env, napi_callback_info info);

    /**
     * 添加数据源
     */
    static napi_value AddSource(napi_env env, napi_callback_info info);

    /**
     * 移除数据源
     */
    static napi_value RemoveSource(napi_env env, napi_callback_info info);

    /**
     * 获取数据源
     */
    static napi_value GetSource(napi_env env, napi_callback_info info);

    /**
     * 获取所有数据源
     */
    static napi_value GetSources(napi_env env, napi_callback_info info);

    /**
     * 添加图层
     */
    static napi_value AddLayer(napi_env env, napi_callback_info info);

    /**
     * 在指定图层下方添加图层
     */
    static napi_value AddLayerBelow(napi_env env, napi_callback_info info);

    /**
     * 在指定图层上方添加图层
     */
    static napi_value AddLayerAbove(napi_env env, napi_callback_info info);

    /**
     * 在指定索引添加图层
     */
    static napi_value AddLayerAt(napi_env env, napi_callback_info info);

    /**
     * 移除图层
     */
    static napi_value RemoveLayer(napi_env env, napi_callback_info info);

    /**
     * 移除指定索引的图层
     */
    static napi_value RemoveLayerAt(napi_env env, napi_callback_info info);

    /**
     * 获取图层
     */
    static napi_value GetLayer(napi_env env, napi_callback_info info);

    /**
     * 获取所有图层
     */
    static napi_value GetLayers(napi_env env, napi_callback_info info);

    /**
     * 添加图片
     */
    static napi_value AddImage(napi_env env, napi_callback_info info);

    /**
     * 移除图片
     */
    static napi_value RemoveImage(napi_env env, napi_callback_info info);

    /**
     * 获取图片
     */
    static napi_value GetImage(napi_env env, napi_callback_info info);

    /**
     * 获取光照
     */
    static napi_value GetLight(napi_env env, napi_callback_info info);

    /**
     * 设置光照
     */
    static napi_value SetLight(napi_env env, napi_callback_info info);

    /**
     * 获取过渡选项
     */
    static napi_value GetTransition(napi_env env, napi_callback_info info);

    /**
     * 设置过渡选项
     */
    static napi_value SetTransition(napi_env env, napi_callback_info info);

private:
    // 工具方法：从NAPI值提取Map指针
    static mbgl::Map* GetMapFromArgs(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

