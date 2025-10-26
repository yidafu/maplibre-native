#include "geometry_collection_napi.hpp"
#include "geometry_napi.hpp"
#include "util.hpp"
#include "../logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value GeometryCollectionNAPI::New(napi_env env, const mapbox::geometry::geometry_collection<double>& collection) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 geometries
    napi_value geometries;
    napi_create_array_with_length(env, collection.size(), &geometries);
    
    for (size_t i = 0; i < collection.size(); i++) {
        napi_value geometry = GeometryNAPI::New(env, collection[i]);
        napi_set_element(env, geometries, i, geometry);
    }
    
    napi_set_named_property(env, obj, "geometries", geometries);
    
    return obj;
}

mapbox::geometry::geometry_collection<double> GeometryCollectionNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("GeometryCollection must be an object");
    }
    
    // 获取 geometries
    napi_value geometries = GetObjectProperty(env, value, "geometries");
    
    if (!IsArray(env, geometries)) {
        throw std::runtime_error("GeometryCollection geometries must be an array");
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, geometries, &length);
    
    mapbox::geometry::geometry_collection<double> collection;
    collection.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, geometries, i, &element);
        collection.push_back(GeometryNAPI::convert(env, element));
    }
    
    return collection;
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

