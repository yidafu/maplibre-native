#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * MultiPointNAPI - MultiPoint 几何体 NAPI 转换
 */
class MultiPointNAPI {
public:
    static constexpr const char* Type() { return "MultiPoint"; }
    
    /**
     * 将 mbgl::MultiPoint 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::MultiPoint<double>& multiPoint);
    
    /**
     * 将 NAPI 对象转换为 mbgl::MultiPoint
     */
    static mbgl::MultiPoint<double> convert(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

