#include "node_feature.hpp"
#include "napi_utils.hpp"
#include <node_api.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mapbox/geometry/geometry.hpp>

namespace node_mbgl {

using namespace mapbox::geometry;

using Value = mbgl::Value;
using Feature = mbgl::Feature;
using FeatureIdentifier = mbgl::FeatureIdentifier;
using Geometry = mbgl::Feature::geometry_type;
using GeometryCollection = mapbox::geometry::geometry_collection<double>;
using Properties = mbgl::PropertyMap;

template <class T>
struct ToType {
public:
    napi_env env;
    
    ToType(napi_env e) : env(e) {}
    
    napi_value operator()(const empty&) { return type("Empty"); }

    napi_value operator()(const point<T>&) { return type("Point"); }

    napi_value operator()(const line_string<T>&) { return type("LineString"); }

    napi_value operator()(const polygon<T>&) { return type("Polygon"); }

    napi_value operator()(const multi_point<T>&) { return type("MultiPoint"); }

    napi_value operator()(const multi_line_string<T>&) { return type("MultiLineString"); }

    napi_value operator()(const multi_polygon<T>&) { return type("MultiPolygon"); }

    napi_value operator()(const geometry_collection<T>&) { return type("GeometryCollection"); }

private:
    napi_value type(const char* type_) {
        return node_mbgl::napi_utils::createString(env, type_);
    }
};

template <class T>
struct ToCoordinatesOrGeometries {
public:
    napi_env env;
    
    ToCoordinatesOrGeometries(napi_env e) : env(e) {}
    
    // Handles line_string, polygon, multi_point, multi_line_string,
    // multi_polygon, and geometry_collection.
    template <class E>
    napi_value operator()(const std::vector<E>& vector) {
        napi_value result = node_mbgl::napi_utils::createArray(env);
        for (std::size_t i = 0; i < vector.size(); ++i) {
            node_mbgl::napi_utils::setArrayElement(env, result, static_cast<uint32_t>(i), operator()(vector[i]));
        }
        return result;
    }

    napi_value operator()(const point<T>& point) {
        napi_value result = node_mbgl::napi_utils::createArray(env);
        node_mbgl::napi_utils::setArrayElement(env, result, 0, node_mbgl::napi_utils::createNumber(env, point.x));
        node_mbgl::napi_utils::setArrayElement(env, result, 1, node_mbgl::napi_utils::createNumber(env, point.y));
        return result;
    }

    napi_value operator()(const geometry<T>& geometry) { return toJS(env, geometry); }
};

struct ToValue {
    napi_env env;
    
    ToValue(napi_env e) : env(e) {}
    
    napi_value operator()(mbgl::NullValue) {
        return node_mbgl::napi_utils::createNull(env);
    }

    napi_value operator()(bool t) {
        return node_mbgl::napi_utils::createBoolean(env, t);
    }

    napi_value operator()(int64_t t) { return operator()(static_cast<double>(t)); }

    napi_value operator()(uint64_t t) { return operator()(static_cast<double>(t)); }

    napi_value operator()(double t) {
        return node_mbgl::napi_utils::createNumber(env, t);
    }

    napi_value operator()(const std::string& t) {
        return node_mbgl::napi_utils::createString(env, t);
    }

    napi_value operator()(const std::vector<mbgl::Value>& array) {
        napi_value result = node_mbgl::napi_utils::createArray(env);
        for (std::size_t i = 0; i < array.size(); i++) {
            node_mbgl::napi_utils::setArrayElement(env, result, static_cast<uint32_t>(i), toJS(env, array[i]));
        }
        return result;
    }

    napi_value operator()(const std::unordered_map<std::string, mbgl::Value>& map) { return toJS(env, map); }
};

napi_value toJS(napi_env env, const Geometry& geometry) {
    napi_value result = node_mbgl::napi_utils::createObject(env);

    node_mbgl::napi_utils::setProperty(env, result, "type", Geometry::visit(geometry, ToType<double>(env)));

    node_mbgl::napi_utils::setProperty(
        env,
        result,
        geometry.is<GeometryCollection>() ? "geometries" : "coordinates",
        Geometry::visit(geometry, ToCoordinatesOrGeometries<double>(env))
    );

    return result;
}

napi_value toJS(napi_env env, const Value& value) {
    return Value::visit(value, ToValue(env));
}

napi_value toJS(napi_env env, const Properties& properties) {
    napi_value result = node_mbgl::napi_utils::createObject(env);
    for (const auto& property : properties) {
        node_mbgl::napi_utils::setProperty(env, result, property.first.c_str(), toJS(env, property.second));
    }

    return result;
}

napi_value toJS(napi_env env, const Feature& feature) {
    napi_value result = node_mbgl::napi_utils::createObject(env);

    node_mbgl::napi_utils::setProperty(env, result, "type", node_mbgl::napi_utils::createString(env, "Feature"));
    node_mbgl::napi_utils::setProperty(env, result, "geometry", toJS(env, feature.geometry));
    node_mbgl::napi_utils::setProperty(env, result, "properties", toJS(env, feature.properties));

    if (!feature.id.is<mbgl::NullValue>()) {
        node_mbgl::napi_utils::setProperty(env, result, "id", FeatureIdentifier::visit(feature.id, ToValue(env)));
    }

    node_mbgl::napi_utils::setProperty(env, result, "source", toJS(env, feature.source));
    if (!feature.sourceLayer.empty()) {
        node_mbgl::napi_utils::setProperty(env, result, "sourceLayer", toJS(env, feature.sourceLayer));
    }
    node_mbgl::napi_utils::setProperty(env, result, "state", toJS(env, feature.state));

    return result;
}

} // namespace node_mbgl
