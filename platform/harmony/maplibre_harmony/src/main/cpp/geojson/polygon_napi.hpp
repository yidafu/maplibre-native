#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * PolygonNAPI - Polygon 几何体 NAPI 类
 */
class PolygonNAPI {
public:
    PolygonNAPI() noexcept;
    explicit PolygonNAPI(const mbgl::Polygon<double>& polygon);
    explicit PolygonNAPI(const std::vector<mbgl::LinearRing<double>>& rings);
    ~PolygonNAPI();
    
    static constexpr const char* Type() { return "Polygon"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    
    // 构造函数回调
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 工厂方法：从 mbgl::Polygon 创建 NAPI 实例
    static napi_value New(napi_env env, const mbgl::Polygon<double>& polygon);
    
    // 析构函数回调
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetCoordinates(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 转换方法（用于内部转换）
    static mbgl::Polygon<double> convert(napi_env env, napi_value value);
    
    // 内部方法
    const std::vector<mbgl::LinearRing<double>>& getRings() const { return rings_; }
    mbgl::Polygon<double> toMbglPolygon() const { return mbgl::Polygon<double>(rings_); }
    
private:
    static napi_ref constructor;
    std::vector<mbgl::LinearRing<double>> rings_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
