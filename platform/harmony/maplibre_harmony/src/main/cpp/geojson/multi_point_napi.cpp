#include "multi_point_napi.hpp"
#include "util.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value MultiPointNAPI::New(napi_env env, const mbgl::MultiPoint<double>& multiPoint) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 coordinates
    napi_value coordinates = PointVectorToNapiArray(env, multiPoint);
    napi_set_named_property(env, obj, "coordinates", coordinates);
    
    return obj;
}

mbgl::MultiPoint<double> MultiPointNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("MultiPoint must be an object");
    }
    
    // 获取 coordinates
    napi_value coordinates = GetObjectProperty(env, value, "coordinates");
    
    if (!IsArray(env, coordinates)) {
        throw std::runtime_error("MultiPoint coordinates must be an array");
    }
    
    return NapiArrayToPointVector(env, coordinates);
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

