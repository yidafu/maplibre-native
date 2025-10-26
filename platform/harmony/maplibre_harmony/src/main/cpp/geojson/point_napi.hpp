#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * PointNAPI - Point 几何体 NAPI 转换
 */
class PointNAPI {
public:
    static constexpr const char* Type() { return "Point"; }
    
    /**
     * 将 mbgl::Point 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::Point<double>& point);
    
    /**
     * 将 NAPI 对象转换为 mbgl::Point
     */
    static mbgl::Point<double> convert(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

