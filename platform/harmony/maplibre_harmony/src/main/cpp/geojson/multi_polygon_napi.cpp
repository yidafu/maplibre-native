#include "multi_polygon_napi.hpp"
#include "util.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value MultiPolygonNAPI::New(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 coordinates
    napi_value coordinates = PolygonVectorToNapiArray(env, multiPolygon);
    napi_set_named_property(env, obj, "coordinates", coordinates);
    
    return obj;
}

mbgl::MultiPolygon<double> MultiPolygonNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("MultiPolygon must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("MultiPolygon coordinates must be an array");
    }
    
    return NapiArrayToPolygonVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

