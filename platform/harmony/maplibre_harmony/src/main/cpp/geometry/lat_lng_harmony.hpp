#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>
#include "../napi_args.hpp"

namespace mbgl {
namespace harmony {

/**
 * LatLng NAPI 转换辅助类
 * 
 * 用于在 mbgl::LatLng (C++) 和 ETS LatLng 对象之间进行转换
 * ETS 定义: { latitude: number, longitude: number }
 */
class LatLngHarmony {
public:
    /**
     * 创建 NAPI LatLng 对象
     * @param env NAPI 环境
     * @param latLng mbgl::LatLng C++ 对象
     * @return NAPI 对象 { latitude: number, longitude: number }
     */
    static napi_value CreateLatLngObject(napi_env env, const mbgl::LatLng& latLng);
    
    /**
     * 从 NAPI 值解析 LatLng
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outLatLng 输出的 mbgl::LatLng
     * @return 解析是否成功
     */
    static bool ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng);
    
    /**
     * 使用 NapiArgs 从 NAPI 值解析 LatLng
     * @param args NapiArgs 实例
     * @param obj NAPI 对象
     * @param outLatLng 输出的 mbgl::LatLng
     * @return 解析是否成功
     */
    static bool ParseLatLngWithArgs(mbgl::harmony::napi::NapiArgs& args, napi_value obj, mbgl::LatLng& outLatLng);
    
    /**
     * 从 NAPI 值解析 LatLng（带默认值）
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param defaultValue 默认值
     * @return mbgl::LatLng 对象
     */
    static mbgl::LatLng ParseLatLngOr(napi_env env, napi_value value, const mbgl::LatLng& defaultValue);
};

} // namespace harmony
} // namespace mbgl

