#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * LineStringNAPI - LineString 几何体 NAPI 类
 */
class LineStringNAPI {
public:
    LineStringNAPI();
    explicit LineStringNAPI(const mbgl::LineString<double>& lineString);
    explicit LineStringNAPI(const std::vector<mbgl::Point<double>>& points);
    ~LineStringNAPI();
    
    static constexpr const char* Type() { return "LineString"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 工厂方法：从 mbgl::LineString 创建 NAPI 实例
    static napi_value New(napi_env env, const mbgl::LineString<double>& lineString);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetCoordinates(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    static napi_value AddPoint(napi_env env, napi_callback_info info);
    static napi_value GetPointCount(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 转换方法
    static mbgl::LineString<double> convert(napi_env env, napi_value value);
    
    // 内部方法
    mbgl::LineString<double> toMbglLineString() const { return points_; }
    
    static napi_ref constructor;
    
private:
    mbgl::LineString<double> points_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
