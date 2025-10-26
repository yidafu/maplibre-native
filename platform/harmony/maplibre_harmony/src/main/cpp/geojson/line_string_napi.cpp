#include "line_string_napi.hpp"
#include "util.hpp"
#include "../logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value LineStringNAPI::New(napi_env env, const mbgl::LineString<double>& lineString) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 coordinates
    napi_value coordinates = PointVectorToNapiArray(env, lineString);
    napi_set_named_property(env, obj, "coordinates", coordinates);
    
    return obj;
}

mbgl::LineString<double> LineStringNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("LineString must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("LineString coordinates must be an array");
    }
    
    return NapiArrayToPointVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

