#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/geojson_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * GeoJsonSourceNAPI - NAPI wrapper for GeoJSON Source
 * 
 * 封装 mbgl::style::GeoJSONSource，提供面向对象的 GeoJSON 数据源接口
 * 类似于 Android 的 GeoJsonSource 类
 */
class GeoJsonSourceNAPI {
public:
    GeoJsonSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::GeoJSONSource> source);
    ~GeoJsonSourceNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    
    // 构造函数回调
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 析构函数回调
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    
    // 数据管理
    static napi_value SetGeoJson(napi_env env, napi_callback_info info);
    static napi_value SetGeoJsonSync(napi_env env, napi_callback_info info);
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // 查询功能
    static napi_value QuerySourceFeatures(napi_env env, napi_callback_info info);
    
    // 聚类功能
    static napi_value GetClusterChildren(napi_env env, napi_callback_info info);
    static napi_value GetClusterLeaves(napi_env env, napi_callback_info info);
    static napi_value GetClusterExpansionZoom(napi_env env, napi_callback_info info);
    
    // 内部方法
    std::string getId() const { return id; }
    mbgl::style::GeoJSONSource* getSource() const { return source.get(); }
    
    // 释放所有权（用于 Style.addSource）
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        return std::move(source);
    }
    
    // 构造函数引用
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::GeoJSONSource> source;
    bool ownsSource;  // 标记是否拥有 source 所有权
};

} // namespace harmony
} // namespace maplibre

