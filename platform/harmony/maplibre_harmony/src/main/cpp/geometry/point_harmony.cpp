#include "point_harmony.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value PointHarmony::CreatePointObject(napi_env env, double x, double y) {
    napi_value obj;
    napi_status status = napi_create_object(env, &obj);
    if (status != napi_ok) {
        Logger::error("PointHarmony", "Failed to create Point object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 创建 x 属性
    napi_value xValue;
    napi_create_double(env, x, &xValue);
    napi_set_named_property(env, obj, "x", xValue);
    
    // 创建 y 属性
    napi_value yValue;
    napi_create_double(env, y, &yValue);
    napi_set_named_property(env, obj, "y", yValue);
    
    Logger::debug("PointHarmony", "Created Point object: x=%f, y=%f", x, y);
    
    return obj;
}

napi_value PointHarmony::CreatePointObject(napi_env env, const mbgl::ScreenCoordinate& coord) {
    return CreatePointObject(env, coord.x, coord.y);
}

bool PointHarmony::ParsePoint(napi_env env, napi_value value, double& outX, double& outY) {
    // 检查是否为对象
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("PointHarmony", "Value is not an object");
        return false;
    }
    
    // 获取 x 属性
    napi_value xValue;
    status = napi_get_named_property(env, value, "x", &xValue);
    if (status != napi_ok) {
        Logger::error("PointHarmony", "Failed to get x property");
        return false;
    }
    
    status = napi_get_value_double(env, xValue, &outX);
    if (status != napi_ok) {
        Logger::error("PointHarmony", "Failed to parse x as double");
        return false;
    }
    
    // 获取 y 属性
    napi_value yValue;
    status = napi_get_named_property(env, value, "y", &yValue);
    if (status != napi_ok) {
        Logger::error("PointHarmony", "Failed to get y property");
        return false;
    }
    
    status = napi_get_value_double(env, yValue, &outY);
    if (status != napi_ok) {
        Logger::error("PointHarmony", "Failed to parse y as double");
        return false;
    }
    
    Logger::debug("PointHarmony", "Parsed Point: x=%f, y=%f", outX, outY);
    
    return true;
}

bool PointHarmony::ParseScreenCoordinate(napi_env env, napi_value value, mbgl::ScreenCoordinate& outCoord) {
    double x, y;
    if (ParsePoint(env, value, x, y)) {
        outCoord = mbgl::ScreenCoordinate{x, y};
        return true;
    }
    return false;
}

} // namespace harmony
} // namespace mbgl

