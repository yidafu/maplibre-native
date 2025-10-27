#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>
#include <string>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * GeometryNAPI - 几何体 NAPI 转换基类
 * 使用 visitor 模式处理不同的几何类型
 */
class GeometryNAPI {
public:
    /**
     * 将 mbgl::Geometry 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::Geometry<double>& geometry);
    
    /**
     * 将 NAPI 对象转换为 mbgl::Geometry
     */
    static mbgl::Geometry<double> convert(napi_env env, napi_value value);
    
    /**
     * 从 NAPI 对象获取几何类型
     */
    static std::string getType(napi_env env, napi_value obj);
};

/**
 * GeometryEvaluator - visitor 模式实现
 * 用于将 mbgl::Geometry 转换为 NAPI 对象
 */
class GeometryEvaluator {
public:
    napi_env env;
    
    explicit GeometryEvaluator(napi_env e) : env(e) {}
    
    napi_value operator()(const mbgl::EmptyGeometry& geometry) const;
    napi_value operator()(const mbgl::Point<double>& geometry) const;
    napi_value operator()(const mbgl::LineString<double>& geometry) const;
    napi_value operator()(const mbgl::Polygon<double>& geometry) const;
    napi_value operator()(const mbgl::MultiPoint<double>& geometry) const;
    napi_value operator()(const mbgl::MultiLineString<double>& geometry) const;
    napi_value operator()(const mbgl::MultiPolygon<double>& geometry) const;
    napi_value operator()(const mapbox::geometry::geometry_collection<double>& geometry) const;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

