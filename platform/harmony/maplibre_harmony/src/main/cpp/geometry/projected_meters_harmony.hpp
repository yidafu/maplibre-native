#pragma once

#include <napi/native_api.h>
#include <mbgl/util/projection.hpp>

namespace mbgl {
namespace harmony {

/**
 * ProjectedMeters NAPI 转换辅助类
 * 
 * 用于在 mbgl::ProjectedMeters (C++) 和 ETS ProjectedMeters 对象之间进行转换
 * ETS 定义: { northing: number, easting: number }
 */
class ProjectedMetersHarmony {
public:
    /**
     * 创建 NAPI ProjectedMeters 对象
     * @param env NAPI 环境
     * @param projectedMeters mbgl::ProjectedMeters C++ 对象
     * @return NAPI 对象 { northing: number, easting: number }
     */
    static napi_value CreateProjectedMetersObject(napi_env env, const mbgl::ProjectedMeters& projectedMeters);
    
    /**
     * 从 NAPI 值解析 ProjectedMeters
     * @param env NAPI 环境
     * @param value NAPI 对象
     * @param outProjectedMeters 输出的 mbgl::ProjectedMeters
     * @return 解析是否成功
     */
    static bool ParseProjectedMeters(napi_env env, napi_value value, mbgl::ProjectedMeters& outProjectedMeters);
};

} // namespace harmony
} // namespace mbgl

