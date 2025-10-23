#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>

namespace mbgl {
namespace harmony {

/**
 * LatLngBounds NAPI 转换辅助类
 * 
 * 用于在 mbgl::LatLngBounds (C++) 和 ETS LatLngBounds 对象之间进行转换
 * ETS 定义: { north: number, east: number, south: number, west: number }
 */
class LatLngBoundsHarmony {
public:
    /**
     * 创建 NAPI LatLngBounds 对象
     * @param env NAPI 环境
     * @param bounds mbgl::LatLngBounds C++ 对象
     * @return NAPI 对象 { north, east, south, west: number }
     */
    static napi_value CreateLatLngBoundsObject(napi_env env, const mbgl::LatLngBounds& bounds);
    
    /**
     * 从 NAPI 值解析 LatLngBounds
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outBounds 输出的 mbgl::LatLngBounds
     * @return 解析是否成功
     */
    static bool ParseLatLngBounds(napi_env env, napi_value value, mbgl::LatLngBounds& outBounds);
};

} // namespace harmony
} // namespace mbgl

