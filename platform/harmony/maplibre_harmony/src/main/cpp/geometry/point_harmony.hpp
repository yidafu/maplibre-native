#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>

namespace mbgl {
namespace harmony {

/**
 * Point NAPI 转换辅助类
 * 
 * 用于在 mbgl::ScreenCoordinate (C++) 和 ETS Point 对象之间进行转换
 * ETS 定义: { x: number, y: number }
 * 对应 Android 的 PointF
 */
class PointHarmony {
public:
    /**
     * 创建 NAPI Point 对象
     * @param env NAPI 环境
     * @param x X 坐标
     * @param y Y 坐标
     * @return NAPI 对象 { x: number, y: number }
     */
    static napi_value CreatePointObject(napi_env env, double x, double y);
    
    /**
     * 创建 NAPI Point 对象（从 ScreenCoordinate）
     * @param env NAPI 环境
     * @param coord 屏幕坐标
     * @return NAPI 对象 { x: number, y: number }
     */
    static napi_value CreatePointObject(napi_env env, const mbgl::ScreenCoordinate& coord);
    
    /**
     * 从 NAPI 值解析 Point
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outX 输出 X 坐标
     * @param outY 输出 Y 坐标
     * @return 解析是否成功
     */
    static bool ParsePoint(napi_env env, napi_value value, double& outX, double& outY);
    
    /**
     * 从 NAPI 值解析 ScreenCoordinate
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outCoord 输出的 ScreenCoordinate
     * @return 解析是否成功
     */
    static bool ParseScreenCoordinate(napi_env env, napi_value value, mbgl::ScreenCoordinate& outCoord);
};

} // namespace harmony
} // namespace mbgl

