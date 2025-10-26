#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * GeometryCollectionNAPI - GeometryCollection 几何体 NAPI 转换
 */
class GeometryCollectionNAPI {
public:
    static constexpr const char* Type() { return "GeometryCollection"; }
    
    /**
     * 将 geometry_collection 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mapbox::geometry::geometry_collection<double>& collection);
    
    /**
     * 将 NAPI 对象转换为 geometry_collection
     */
    static mapbox::geometry::geometry_collection<double> convert(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

