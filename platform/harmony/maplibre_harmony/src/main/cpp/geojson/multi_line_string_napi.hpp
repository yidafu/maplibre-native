#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * MultiLineStringNAPI - MultiLineString 几何体 NAPI 转换
 */
class MultiLineStringNAPI {
public:
    static constexpr const char* Type() { return "MultiLineString"; }
    
    /**
     * 将 mbgl::MultiLineString 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::MultiLineString<double>& multiLineString);
    
    /**
     * 将 NAPI 对象转换为 mbgl::MultiLineString
     */
    static mbgl::MultiLineString<double> convert(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

