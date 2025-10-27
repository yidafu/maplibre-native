#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>
#include "napi/core/napi_args.hpp"

namespace mbgl {
namespace harmony {

/**
 * LatLng NAPI 类
 * 
 * 导出为 ETS 类，提供经纬度坐标功能
 */
class LatLngNapi {
public:
    // 构造函数
    explicit LatLngNapi(double latitude, double longitude);
    explicit LatLngNapi(const mbgl::LatLng& latLng);
    ~LatLngNapi() = default;
    
    // Getter
    double GetLatitude() const { return latLng_.latitude(); }
    double GetLongitude() const { return latLng_.longitude(); }
    mbgl::LatLng GetLatLng() const { return latLng_; }
    
    // NAPI 类注册
    static napi_value Init(napi_env env, napi_value exports);
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 创建实例
    static napi_value CreateInstance(napi_env env, const mbgl::LatLng& latLng);
    static napi_value Constructor(napi_env env, napi_callback_info info);
    
    // 属性访问器
    static napi_value GetLatitudeProperty(napi_env env, napi_callback_info info);
    static napi_value GetLongitudeProperty(napi_env env, napi_callback_info info);
    
    // 从 NAPI 值解析
    static bool ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng);
    
private:
    mbgl::LatLng latLng_;
    
    static napi_ref constructor_;
};

/**
 * LatLng NAPI 转换辅助类（保留向后兼容）
 */
class LatLngHarmony {
public:
    /**
     * 创建 NAPI LatLng 类实例
     */
    static napi_value CreateLatLngObject(napi_env env, const mbgl::LatLng& latLng);
    
    /**
     * 从 NAPI 值解析 LatLng
     */
    static bool ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng);
    
    /**
     * 使用 NapiArgs 从 NAPI 值解析 LatLng
     */
    static bool ParseLatLngWithArgs(mbgl::harmony::napi::NapiArgs& args, napi_value obj, mbgl::LatLng& outLatLng);
    
    /**
     * 从 NAPI 值解析 LatLng（带默认值）
     */
    static mbgl::LatLng ParseLatLngOr(napi_env env, napi_value value, const mbgl::LatLng& defaultValue);
};

} // namespace harmony
} // namespace mbgl

