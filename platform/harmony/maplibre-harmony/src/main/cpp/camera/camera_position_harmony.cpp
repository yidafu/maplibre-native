#include "camera_position_harmony.hpp"
#include "geometry/lat_lng_harmony.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value CameraPositionHarmony::CreateCameraPositionObject(napi_env env, const mbgl::CameraOptions& options, float pixelRatio) {
    napi_value obj;
    napi_status status = napi_create_object(env, &obj);
    if (status != napi_ok) {
        Logger::error("CameraPositionHarmony", "Failed to create CameraPosition object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Create target (LatLng)
    if (options.center) {
        auto center = options.center.value();
        center.wrap();  // Wrap latitude/longitude into valid range
        napi_value targetValue = LatLngHarmony::CreateLatLngObject(env, center);
        napi_set_named_property(env, obj, "target", targetValue);
    }
    
    // Create zoom
    napi_value zoomValue;
    napi_create_double(env, options.zoom.value_or(0.0), &zoomValue);
    napi_set_named_property(env, obj, "zoom", zoomValue);
    
    // Create bearing (normalize to 0-360 degrees)
    double bearing = options.bearing.value_or(0.0);
    while (bearing > 360.0) bearing -= 360.0;
    while (bearing < 0.0) bearing += 360.0;
    napi_value bearingValue;
    napi_create_double(env, bearing, &bearingValue);
    napi_set_named_property(env, obj, "bearing", bearingValue);
    
    // Create tilt (aka pitch)
    napi_value tiltValue;
    napi_create_double(env, options.pitch.value_or(0.0), &tiltValue);
    napi_set_named_property(env, obj, "tilt", tiltValue);
    
    // Create padding (EdgeInsets)
    auto insets = options.padding.value_or(mbgl::EdgeInsets{0, 0, 0, 0});
    napi_value paddingObj;
    napi_create_object(env, &paddingObj);
    
    napi_value leftValue, topValue, rightValue, bottomValue;
    napi_create_double(env, insets.left() * pixelRatio, &leftValue);
    napi_create_double(env, insets.top() * pixelRatio, &topValue);
    napi_create_double(env, insets.right() * pixelRatio, &rightValue);
    napi_create_double(env, insets.bottom() * pixelRatio, &bottomValue);
    
    napi_set_named_property(env, paddingObj, "left", leftValue);
    napi_set_named_property(env, paddingObj, "top", topValue);
    napi_set_named_property(env, paddingObj, "right", rightValue);
    napi_set_named_property(env, paddingObj, "bottom", bottomValue);
    
    napi_set_named_property(env, obj, "padding", paddingObj);
    
    return obj;
}

bool CameraPositionHarmony::ParseCameraOptions(napi_env env, napi_value value, float pixelRatio, mbgl::CameraOptions& outOptions) {
    // Ensure value is an object
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("CameraPositionHarmony", "Value is not an object");
        return false;
    }
    
    // Parse target (LatLng)
    napi_value targetValue;
    status = napi_get_named_property(env, value, "target", &targetValue);
    if (status == napi_ok) {
        mbgl::LatLng center;
        if (LatLngHarmony::ParseLatLng(env, targetValue, center)) {
            outOptions.center = center;
        }
    }
    
    // Parse zoom
    napi_value zoomValue;
    status = napi_get_named_property(env, value, "zoom", &zoomValue);
    if (status == napi_ok) {
        double zoom;
        if (napi_get_value_double(env, zoomValue, &zoom) == napi_ok) {
            outOptions.zoom = zoom;
        }
    }
    
    // Parse bearing
    napi_value bearingValue;
    status = napi_get_named_property(env, value, "bearing", &bearingValue);
    if (status == napi_ok) {
        double bearing;
        if (napi_get_value_double(env, bearingValue, &bearing) == napi_ok) {
            outOptions.bearing = bearing;
        }
    }
    
    // Parse tilt (maps to pitch)
    napi_value tiltValue;
    status = napi_get_named_property(env, value, "tilt", &tiltValue);
    if (status == napi_ok) {
        double tilt;
        if (napi_get_value_double(env, tiltValue, &tilt) == napi_ok) {
            outOptions.pitch = tilt;
        }
    }
    
    // Parse padding (EdgeInsets)
    napi_value paddingValue;
    status = napi_get_named_property(env, value, "padding", &paddingValue);
    if (status == napi_ok) {
        napi_valuetype paddingType;
        napi_typeof(env, paddingValue, &paddingType);
        if (paddingType == napi_object) {
            double left, top, right, bottom;
            
            napi_value leftVal, topVal, rightVal, bottomVal;
            if (napi_get_named_property(env, paddingValue, "left", &leftVal) == napi_ok &&
                napi_get_named_property(env, paddingValue, "top", &topVal) == napi_ok &&
                napi_get_named_property(env, paddingValue, "right", &rightVal) == napi_ok &&
                napi_get_named_property(env, paddingValue, "bottom", &bottomVal) == napi_ok) {
                
                if (napi_get_value_double(env, leftVal, &left) == napi_ok &&
                    napi_get_value_double(env, topVal, &top) == napi_ok &&
                    napi_get_value_double(env, rightVal, &right) == napi_ok &&
                    napi_get_value_double(env, bottomVal, &bottom) == napi_ok) {
                    
                    // Divide by pixelRatio to convert back to logical pixels
                    outOptions.padding = mbgl::EdgeInsets{
                        top / pixelRatio,
                        left / pixelRatio,
                        bottom / pixelRatio,
                        right / pixelRatio
                    };
                }
            }
        }
    }
    
    return true;
}

} // namespace harmony
} // namespace mbgl

