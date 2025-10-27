#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * GeometryCollectionNAPI - GeometryCollection 几何体 NAPI 类
 */
class GeometryCollectionNAPI {
public:
    GeometryCollectionNAPI();
    explicit GeometryCollectionNAPI(const mapbox::geometry::geometry_collection<double>& collection);
    ~GeometryCollectionNAPI();
    
    static constexpr const char* Type() { return "GeometryCollection"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 工厂方法：从 geometry_collection 创建 NAPI 实例
    static napi_value New(napi_env env, const mapbox::geometry::geometry_collection<double>& collection);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetGeometries(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 静态工厂方法
    static napi_value FromMbglGeometryCollection(napi_env env, const mapbox::geometry::geometry_collection<double>& collection);
    
    // 转换方法
    static mapbox::geometry::geometry_collection<double> convert(napi_env env, napi_value value);
    
    // 内部方法
    mapbox::geometry::geometry_collection<double> toMbglGeometryCollection() const { return geometries_; }
    
    static napi_ref constructor;
    
private:
    mapbox::geometry::geometry_collection<double> geometries_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
