#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * PolygonNAPI - Polygon 几何体 NAPI 转换
 */
class PolygonNAPI {
public:
    static constexpr const char* Type() { return "Polygon"; }
    
    /**
     * 将 mbgl::Polygon 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::Polygon<double>& polygon);
    
    /**
     * 将 NAPI 对象转换为 mbgl::Polygon
     */
    static mbgl::Polygon<double> convert(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

