#include "lat_lng_harmony.hpp"
#include "napi_double_props.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include <cmath>

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// ==================== LatLngHarmony Helper Implementation ====================

napi_value LatLngHarmony::CreateLatLngObject(napi_env env, const mbgl::LatLng& latLng) {
    // Object literal {latitude, longitude}
    return CreateDoublePropsObject(env, "LatLngHarmony",
                                   {{"latitude", latLng.latitude()},
                                    {"longitude", latLng.longitude()}});
}

bool LatLngHarmony::ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng) {
    double latitude = 0.0;
    double longitude = 0.0;
    if (!ParseDoubleProps(env, value, "LatLngHarmony",
                          {{"latitude", &latitude}, {"longitude", &longitude}})) {
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

