#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * MultiPolygonNAPI - MultiPolygon 几何体 NAPI 类
 */
class MultiPolygonNAPI {
public:
    MultiPolygonNAPI();
    explicit MultiPolygonNAPI(const mbgl::MultiPolygon<double>& multiPolygon);
    explicit MultiPolygonNAPI(const std::vector<mbgl::Polygon<double>>& polygons);
    ~MultiPolygonNAPI();
    
    static constexpr const char* Type() { return "MultiPolygon"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 工厂方法：从 mbgl::MultiPolygon 创建 NAPI 实例
    static napi_value New(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetCoordinates(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 静态工厂方法
    static napi_value FromMbglMultiPolygon(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon);
    
    // 转换方法
    static mbgl::MultiPolygon<double> convert(napi_env env, napi_value value);
    
    // 内部方法
    mbgl::MultiPolygon<double> toMbglMultiPolygon() const { return polygons_; }
    
    static napi_ref constructor;
    
private:
    mbgl::MultiPolygon<double> polygons_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
