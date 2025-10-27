#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * PointNAPI - Point 几何体 NAPI 类
 */
class PointNAPI {
public:
    PointNAPI(double lng, double lat, double altitude = 0.0, bool hasAltitude = false);
    explicit PointNAPI(const mbgl::Point<double>& point);
    ~PointNAPI();
    
    static constexpr const char* Type() { return "Point"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    
    // 构造函数回调
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 工厂方法：从 mbgl::Point 创建 NAPI 实例
    static napi_value New(napi_env env, const mbgl::Point<double>& point);
    
    // 析构函数回调
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetCoordinates(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    static napi_value GetLongitude(napi_env env, napi_callback_info info);
    static napi_value GetLatitude(napi_env env, napi_callback_info info);
    static napi_value GetAltitude(napi_env env, napi_callback_info info);
    static napi_value SetLongitude(napi_env env, napi_callback_info info);
    static napi_value SetLatitude(napi_env env, napi_callback_info info);
    static napi_value SetAltitude(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 转换方法（用于内部转换）
    static mbgl::Point<double> convert(napi_env env, napi_value value);
    
    // 内部方法
    mbgl::Point<double> toMbglPoint() const { return mbgl::Point<double>(lng_, lat_); }
    
    // 构造函数引用
    static napi_ref constructor;
    
private:
    double lng_;
    double lat_;
    double altitude_;
    bool hasAltitude_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
