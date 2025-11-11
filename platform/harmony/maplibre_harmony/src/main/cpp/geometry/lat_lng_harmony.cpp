#include "lat_lng_harmony.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include <cmath>

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// ==================== LatLngHarmony Helper Implementation ====================

napi_value LatLngHarmony::CreateLatLngObject(napi_env env, const mbgl::LatLng& latLng) {
    // Create object literal {latitude, longitude}
    napi_value obj;
    napi_status status = napi_create_object(env, &obj);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to create LatLng object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Set latitude property
    napi_value latValue;
    napi_create_double(env, latLng.latitude(), &latValue);
    napi_set_named_property(env, obj, "latitude", latValue);
    
    // Set longitude property
    napi_value lngValue;
    napi_create_double(env, latLng.longitude(), &lngValue);
    napi_set_named_property(env, obj, "longitude", lngValue);
    
    return obj;
}

bool LatLngHarmony::ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng) {
    // Ensure the value is an object
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("LatLngHarmony", "Value is not an object");
        return false;
    }
    
    // Retrieve latitude property
    napi_value latValue;
    status = napi_get_named_property(env, value, "latitude", &latValue);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to get latitude property");
        return false;
    }
    
    double latitude;
    status = napi_get_value_double(env, latValue, &latitude);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to parse latitude as double");
        return false;
    }
    
    // Retrieve longitude property
    napi_value lngValue;
    status = napi_get_named_property(env, value, "longitude", &lngValue);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to get longitude property");
        return false;
    }
    
    double longitude;
    status = napi_get_value_double(env, lngValue, &longitude);
    if (status != napi_ok) {
        Logger::error("LatLngHarmony", "Failed to parse longitude as double");
        return false;
    }
    
    // Validate range
    if (latitude < -90.0 || latitude > 90.0) {
        Logger::error("LatLngHarmony", "Latitude out of range: %f", latitude);
        return false;
    }
    if (longitude < -180.0 || longitude > 180.0) {
        Logger::error("LatLngHarmony", "Longitude out of range: %f", longitude);
        return false;
    }
    
    outLatLng = mbgl::LatLng(latitude, longitude);
    return true;
}

bool LatLngHarmony::ParseLatLngWithArgs(mbgl::harmony::napi::NapiArgs& args, napi_value obj, mbgl::LatLng& outLatLng) {
    // Use NapiArgs helper methods to parse object properties
    double latitude = args.GetDoubleProperty(obj, "latitude", 0.0);
    double longitude = args.GetDoubleProperty(obj, "longitude", 0.0);
    
    if (args.HasError()) {
        Logger::error("LatLngHarmony", "Failed to parse LatLng properties: %s", args.GetError().c_str());
        return false;
    }
    
    // Validate range
    if (latitude < -90.0 || latitude > 90.0) {
        Logger::error("LatLngHarmony", "Latitude out of range: %f", latitude);
        return false;
    }
    if (longitude < -180.0 || longitude > 180.0) {
        Logger::error("LatLngHarmony", "Longitude out of range: %f", longitude);
        return false;
    }
    
    outLatLng = mbgl::LatLng(latitude, longitude);
    return true;
}

mbgl::LatLng LatLngHarmony::ParseLatLngOr(napi_env env, napi_value value, const mbgl::LatLng& defaultValue) {
    mbgl::LatLng result;
    if (ParseLatLng(env, value, result)) {
        return result;
    }
    return defaultValue;
}

} // namespace harmony
} // namespace mbgl

