#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/geojson_source.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * GeoJsonSource NAPI绑定类
 * 
 * 封装 mbgl::style::GeoJSONSource
 */
class GeoJsonSourceHarmony {
public:
    /**
     * 初始化GeoJsonSource类的NAPI绑定
     */
    static napi_value Init(napi_env env, napi_value exports);

    /**
     * 创建GeoJsonSource实例
     * 参数: id, optionsJson
     */
    static napi_value Create(napi_env env, napi_callback_info info);

    /**
     * 设置GeoJSON数据（异步）
     * 参数: sourcePtr, geoJsonString
     */
    static napi_value SetGeoJson(napi_env env, napi_callback_info info);

    /**
     * 设置GeoJSON数据（同步）
     * 参数: sourcePtr, geoJsonString
     */
    static napi_value SetGeoJsonSync(napi_env env, napi_callback_info info);

    /**
     * 设置URL
     * 参数: sourcePtr, url
     */
    static napi_value SetUrl(napi_env env, napi_callback_info info);

    /**
     * 获取URL
     * 参数: sourcePtr
     */
    static napi_value GetUrl(napi_env env, napi_callback_info info);

    /**
     * 查询数据源要素
     * 参数: sourcePtr, filterJson
     */
    static napi_value QuerySourceFeatures(napi_env env, napi_callback_info info);

    /**
     * 获取聚类子项
     * 参数: sourcePtr, clusterJson
     */
    static napi_value GetClusterChildren(napi_env env, napi_callback_info info);

    /**
     * 获取聚类叶子节点
     * 参数: sourcePtr, clusterJson, limit, offset
     */
    static napi_value GetClusterLeaves(napi_env env, napi_callback_info info);

    /**
     * 获取聚类展开缩放级别
     * 参数: sourcePtr, clusterJson
     */
    static napi_value GetClusterExpansionZoom(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

