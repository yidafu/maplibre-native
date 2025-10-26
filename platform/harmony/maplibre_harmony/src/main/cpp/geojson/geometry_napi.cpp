#include "geometry_napi.hpp"
#include "point_napi.hpp"
#include "line_string_napi.hpp"
#include "polygon_napi.hpp"
#include "multi_point_napi.hpp"
#include "multi_line_string_napi.hpp"
#include "multi_polygon_napi.hpp"
#include "geometry_collection_napi.hpp"
#include "util.hpp"
#include "../logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value GeometryNAPI::New(napi_env env, const mbgl::Geometry<double>& geometry) {
    GeometryEvaluator evaluator(env);
    return mbgl::Geometry<double>::visit(geometry, evaluator);
}

mbgl::Geometry<double> GeometryNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("Geometry must be an object");
    }
    
    std::string type = getType(env, value);
    
    if (type == "Point") {
        return PointNAPI::convert(env, value);
    } else if (type == "LineString") {
        return LineStringNAPI::convert(env, value);
    } else if (type == "Polygon") {
        return PolygonNAPI::convert(env, value);
    } else if (type == "MultiPoint") {
        return MultiPointNAPI::convert(env, value);
    } else if (type == "MultiLineString") {
        return MultiLineStringNAPI::convert(env, value);
    } else if (type == "MultiPolygon") {
        return MultiPolygonNAPI::convert(env, value);
    } else if (type == "GeometryCollection") {
        return GeometryCollectionNAPI::convert(env, value);
    }
    
    throw std::runtime_error("Unsupported geometry type: " + type);
}

std::string GeometryNAPI::getType(napi_env env, napi_value obj) {
    if (!HasProperty(env, obj, "type")) {
        return "";
    }
    return GetStringProperty(env, obj, "type");
}

// GeometryEvaluator implementations

napi_value GeometryEvaluator::operator()(const mbgl::Point<double>& geometry) const {
    return PointNAPI::New(env, geometry);
}

napi_value GeometryEvaluator::operator()(const mbgl::LineString<double>& geometry) const {
    return LineStringNAPI::New(env, geometry);
}

napi_value GeometryEvaluator::operator()(const mbgl::Polygon<double>& geometry) const {
    return PolygonNAPI::New(env, geometry);
}

napi_value GeometryEvaluator::operator()(const mbgl::MultiPoint<double>& geometry) const {
    return MultiPointNAPI::New(env, geometry);
}

napi_value GeometryEvaluator::operator()(const mbgl::MultiLineString<double>& geometry) const {
    return MultiLineStringNAPI::New(env, geometry);
}

napi_value GeometryEvaluator::operator()(const mbgl::MultiPolygon<double>& geometry) const {
    return MultiPolygonNAPI::New(env, geometry);
}

napi_value GeometryEvaluator::operator()(const mapbox::geometry::geometry_collection<double>& geometry) const {
    return GeometryCollectionNAPI::New(env, geometry);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

