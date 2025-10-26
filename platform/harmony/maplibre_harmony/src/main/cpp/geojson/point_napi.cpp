#include "point_napi.hpp"
#include "util.hpp"
#include "../logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value PointNAPI::New(napi_env env, const mbgl::Point<double>& point) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 coordinates [lng, lat]
    napi_value coordinates;
    napi_create_array_with_length(env, 2, &coordinates);
    
    napi_value lng, lat;
    napi_create_double(env, point.x, &lng);
    napi_create_double(env, point.y, &lat);
    
    napi_set_element(env, coordinates, 0, lng);
    napi_set_element(env, coordinates, 1, lat);
    
    napi_set_named_property(env, obj, "coordinates", coordinates);
    
    return obj;
}

mbgl::Point<double> PointNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("Point must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("Point coordinates must be an array");
    }
    
    auto coords = NapiArrayToDoubleVector(env, coordinates);
    
    if (coords.size() < 2) {
        throw std::runtime_error("Point coordinates must have at least 2 elements [lng, lat]");
    }
    
    return mbgl::Point<double>{coords[0], coords[1]};
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

