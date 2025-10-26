#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * MultiPolygonNAPI - MultiPolygon 几何体 NAPI 转换
 */
class MultiPolygonNAPI {
public:
    static constexpr const char* Type() { return "MultiPolygon"; }
    
    /**
     * 将 mbgl::MultiPolygon 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon);
    
    /**
     * 将 NAPI 对象转换为 mbgl::MultiPolygon
     */
    static mbgl::MultiPolygon<double> convert(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

