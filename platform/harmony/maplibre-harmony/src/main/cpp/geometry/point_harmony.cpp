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
    
    // Create x property
    napi_value xValue;
    napi_create_double(env, x, &xValue);
    napi_set_named_property(env, obj, "x", xValue);
    
    // Create y property
    napi_value yValue;
    napi_create_double(env, y, &yValue);
    napi_set_named_property(env, obj, "y", yValue);
    
    return obj;
}

napi_value PointHarmony::CreatePointObject(napi_env env, const mbgl::ScreenCoordinate& coord) {
    return CreatePointObject(env, coord.x, coord.y);
}

bool PointHarmony::ParsePoint(napi_env env, napi_value value, double& outX, double& outY) {
// Ensure value is an object
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("PointHarmony", "Value is not an object");
        return false;
    }
    
    // Retrieve x property
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
    
    // Retrieve y property
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

