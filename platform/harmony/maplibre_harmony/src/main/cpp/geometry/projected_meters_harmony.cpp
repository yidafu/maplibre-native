#include "projected_meters_harmony.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value ProjectedMetersHarmony::CreateProjectedMetersObject(napi_env env, const mbgl::ProjectedMeters& projectedMeters) {
    napi_value obj;
    napi_status status = napi_create_object(env, &obj);
    if (status != napi_ok) {
        Logger::error("ProjectedMetersHarmony", "Failed to create ProjectedMeters object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 创建 northing 属性
    napi_value northingValue;
    napi_create_double(env, projectedMeters.northing(), &northingValue);
    napi_set_named_property(env, obj, "northing", northingValue);
    
    // 创建 easting 属性
    napi_value eastingValue;
    napi_create_double(env, projectedMeters.easting(), &eastingValue);
    napi_set_named_property(env, obj, "easting", eastingValue);
    
    return obj;
}

bool ProjectedMetersHarmony::ParseProjectedMeters(napi_env env, napi_value value, mbgl::ProjectedMeters& outProjectedMeters) {
    // 检查是否为对象
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("ProjectedMetersHarmony", "Value is not an object");
        return false;
    }
    
    // 获取 northing 属性
    napi_value northingValue;
    status = napi_get_named_property(env, value, "northing", &northingValue);
    if (status != napi_ok) {
        Logger::error("ProjectedMetersHarmony", "Failed to get northing property");
        return false;
    }
    
    double northing;
    status = napi_get_value_double(env, northingValue, &northing);
    if (status != napi_ok) {
        Logger::error("ProjectedMetersHarmony", "Failed to parse northing as double");
        return false;
    }
    
    // 获取 easting 属性
    napi_value eastingValue;
    status = napi_get_named_property(env, value, "easting", &eastingValue);
    if (status != napi_ok) {
        Logger::error("ProjectedMetersHarmony", "Failed to get easting property");
        return false;
    }
    
    double easting;
    status = napi_get_value_double(env, eastingValue, &easting);
    if (status != napi_ok) {
        Logger::error("ProjectedMetersHarmony", "Failed to parse easting as double");
        return false;
    }
    
    outProjectedMeters = mbgl::ProjectedMeters(northing, easting);
    return true;
}

} // namespace harmony
} // namespace mbgl

