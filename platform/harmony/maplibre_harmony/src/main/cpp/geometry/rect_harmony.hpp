#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>

namespace mbgl {
namespace harmony {

/**
 * Rect NAPI 转换辅助类
 * 
 * 用于在 C++ 矩形坐标和 ETS Rect 对象之间进行转换
 * ETS 定义: { left: number, top: number, right: number, bottom: number }
 * 对应 Android 的 RectF
 */
class RectHarmony {
public:
    /**
     * 创建 NAPI Rect 对象
     * @param env NAPI 环境
     * @param left 左边界
     * @param top 上边界
     * @param right 右边界
     * @param bottom 下边界
     * @return NAPI 对象 { left, top, right, bottom: number }
     */
    static napi_value CreateRectObject(napi_env env, double left, double top, double right, double bottom);
    
    /**
     * 从 NAPI 值解析 Rect
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outLeft 输出左边界
     * @param outTop 输出上边界
     * @param outRight 输出右边界
     * @param outBottom 输出下边界
     * @return 解析是否成功
     */
    static bool ParseRect(napi_env env, napi_value value, 
                         double& outLeft, double& outTop, 
                         double& outRight, double& outBottom);
    
    /**
     * 从 NAPI 值解析为 EdgeInsets
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outInsets 输出的 EdgeInsets
     * @return 解析是否成功
     */
    static bool ParseAsEdgeInsets(napi_env env, napi_value value, mbgl::EdgeInsets& outInsets);
};

} // namespace harmony
} // namespace mbgl

