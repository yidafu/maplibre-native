#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * MultiPointNAPI - MultiPoint 几何体 NAPI 类
 */
class MultiPointNAPI {
public:
    MultiPointNAPI();
    explicit MultiPointNAPI(const mbgl::MultiPoint<double>& multiPoint);
    explicit MultiPointNAPI(const std::vector<mbgl::Point<double>>& points);
    ~MultiPointNAPI();
    
    static constexpr const char* Type() { return "MultiPoint"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 工厂方法：从 mbgl::MultiPoint 创建 NAPI 实例
    static napi_value New(napi_env env, const mbgl::MultiPoint<double>& multiPoint);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetCoordinates(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 静态工厂方法
    static napi_value FromMbglMultiPoint(napi_env env, const mbgl::MultiPoint<double>& multiPoint);
    
    // 转换方法
    static mbgl::MultiPoint<double> convert(napi_env env, napi_value value);
    
    // 内部方法
    mbgl::MultiPoint<double> toMbglMultiPoint() const { return points_; }
    
    static napi_ref constructor;
    
private:
    mbgl::MultiPoint<double> points_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
