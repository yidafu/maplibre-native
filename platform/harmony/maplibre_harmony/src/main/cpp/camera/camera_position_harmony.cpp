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
    
    // 创建 target (LatLng)
    if (options.center) {
        auto center = options.center.value();
        center.wrap();  // 包裹经纬度到有效范围
        napi_value targetValue = LatLngHarmony::CreateLatLngObject(env, center);
        napi_set_named_property(env, obj, "target", targetValue);
    }
    
    // 创建 zoom
    napi_value zoomValue;
    napi_create_double(env, options.zoom.value_or(0.0), &zoomValue);
    napi_set_named_property(env, obj, "zoom", zoomValue);
    
    // 创建 bearing (转换为 0-360 度)
    double bearing = options.bearing.value_or(0.0);
    while (bearing > 360.0) bearing -= 360.0;
    while (bearing < 0.0) bearing += 360.0;
    napi_value bearingValue;
    napi_create_double(env, bearing, &bearingValue);
    napi_set_named_property(env, obj, "bearing", bearingValue);
    
    // 创建 tilt (即 pitch)
    napi_value tiltValue;
    napi_create_double(env, options.pitch.value_or(0.0), &tiltValue);
    napi_set_named_property(env, obj, "tilt", tiltValue);
    
    // 创建 padding (EdgeInsets)
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
    
    Logger::debug("CameraPositionHarmony", "Created CameraPosition object: zoom=%f, bearing=%f, tilt=%f", 
                  options.zoom.value_or(0.0), bearing, options.pitch.value_or(0.0));
    
    return obj;
}

bool CameraPositionHarmony::ParseCameraOptions(napi_env env, napi_value value, float pixelRatio, mbgl::CameraOptions& outOptions) {
    // 检查是否为对象
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("CameraPositionHarmony", "Value is not an object");
        return false;
    }
    
    // 解析 target (LatLng)
    napi_value targetValue;
    status = napi_get_named_property(env, value, "target", &targetValue);
    if (status == napi_ok) {
        mbgl::LatLng center;
        if (LatLngNapi::ParseLatLng(env, targetValue, center)) {
            outOptions.center = center;
        }
    }
    
    // 解析 zoom
    napi_value zoomValue;
    status = napi_get_named_property(env, value, "zoom", &zoomValue);
    if (status == napi_ok) {
        double zoom;
        if (napi_get_value_double(env, zoomValue, &zoom) == napi_ok) {
            outOptions.zoom = zoom;
        }
    }
    
    // 解析 bearing
    napi_value bearingValue;
    status = napi_get_named_property(env, value, "bearing", &bearingValue);
    if (status == napi_ok) {
        double bearing;
        if (napi_get_value_double(env, bearingValue, &bearing) == napi_ok) {
            outOptions.bearing = bearing;
        }
    }
    
    // 解析 tilt (对应 pitch)
    napi_value tiltValue;
    status = napi_get_named_property(env, value, "tilt", &tiltValue);
    if (status == napi_ok) {
        double tilt;
        if (napi_get_value_double(env, tiltValue, &tilt) == napi_ok) {
            outOptions.pitch = tilt;
        }
    }
    
    // 解析 padding (EdgeInsets)
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
                    
                    // 除以 pixelRatio 转换回逻辑像素
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
    
    Logger::debug("CameraPositionHarmony", "Parsed CameraOptions successfully");
    
    return true;
}

} // namespace harmony
} // namespace mbgl

