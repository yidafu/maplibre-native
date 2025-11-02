#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>
#include "napi/core/napi_args.hpp"

namespace mbgl {
namespace harmony {

/**
 * LatLng 转换辅助类
 * 用于在 C++ mbgl::LatLng 和 ETS 对象字面量之间进行转换
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

