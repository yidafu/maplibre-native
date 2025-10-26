#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * LineStringNAPI - LineString 几何体 NAPI 转换
 */
class LineStringNAPI {
public:
    static constexpr const char* Type() { return "LineString"; }
    
    /**
     * 将 mbgl::LineString 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::LineString<double>& lineString);
    
    /**
     * 将 NAPI 对象转换为 mbgl::LineString
     */
    static mbgl::LineString<double> convert(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

