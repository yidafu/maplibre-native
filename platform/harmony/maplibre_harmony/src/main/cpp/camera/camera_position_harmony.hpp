#pragma once

#include <napi/native_api.h>
#include <mbgl/map/camera.hpp>

namespace mbgl {
namespace harmony {

/**
 * CameraPosition NAPI 转换辅助类
 * 
 * 用于在 mbgl::CameraOptions (C++) 和 ETS CameraPosition 对象之间进行转换
 * ETS 定义: { target: LatLng, zoom: number, bearing: number, tilt: number, padding: EdgeInsets }
 * EdgeInsets: { left: number, top: number, right: number, bottom: number }
 */
class CameraPositionHarmony {
public:
    /**
     * 创建 NAPI CameraPosition 对象
     * @param env NAPI 环境
     * @param options mbgl::CameraOptions C++ 对象
     * @param pixelRatio 像素比例（用于转换 padding）
     * @return NAPI 对象
     */
    static napi_value CreateCameraPositionObject(napi_env env, const mbgl::CameraOptions& options, float pixelRatio);
    
    /**
     * 从 NAPI 值解析 CameraOptions
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param pixelRatio 像素比例（用于转换 padding）
     * @param outOptions 输出的 mbgl::CameraOptions
     * @return 解析是否成功
     */
    static bool ParseCameraOptions(napi_env env, napi_value value, float pixelRatio, mbgl::CameraOptions& outOptions);
};

} // namespace harmony
} // namespace mbgl

