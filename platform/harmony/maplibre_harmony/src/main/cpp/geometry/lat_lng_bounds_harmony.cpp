#include "lat_lng_bounds_harmony.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value LatLngBoundsHarmony::CreateLatLngBoundsObject(napi_env env, const mbgl::LatLngBounds& bounds) {
    napi_value obj;
    napi_status status = napi_create_object(env, &obj);
    if (status != napi_ok) {
        Logger::error("LatLngBoundsHarmony", "Failed to create LatLngBounds object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Create north property
    napi_value northValue;
    napi_create_double(env, bounds.north(), &northValue);
    napi_set_named_property(env, obj, "north", northValue);
    
    // Create east property
    napi_value eastValue;
    napi_create_double(env, bounds.east(), &eastValue);
    napi_set_named_property(env, obj, "east", eastValue);
    
    // Create south property
    napi_value southValue;
    napi_create_double(env, bounds.south(), &southValue);
    napi_set_named_property(env, obj, "south", southValue);
    
    // Create west property
    napi_value westValue;
    napi_create_double(env, bounds.west(), &westValue);
    napi_set_named_property(env, obj, "west", westValue);
    
    return obj;
}

bool LatLngBoundsHarmony::ParseLatLngBounds(napi_env env, napi_value value, mbgl::LatLngBounds& outBounds) {
    // Ensure the value is an object
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("LatLngBoundsHarmony", "Value is not an object");
        return false;
    }
    
    // Retrieve north property
    napi_value northValue;
    double north;
    status = napi_get_named_property(env, value, "north", &northValue);
    if (status != napi_ok || napi_get_value_double(env, northValue, &north) != napi_ok) {
        Logger::error("LatLngBoundsHarmony", "Failed to parse north");
        return false;
    }
    
    // Retrieve east property
    napi_value eastValue;
    double east;
    status = napi_get_named_property(env, value, "east", &eastValue);
    if (status != napi_ok || napi_get_value_double(env, eastValue, &east) != napi_ok) {
        Logger::error("LatLngBoundsHarmony", "Failed to parse east");
        return false;
    }
    
    // Retrieve south property
    napi_value southValue;
    double south;
    status = napi_get_named_property(env, value, "south", &southValue);
    if (status != napi_ok || napi_get_value_double(env, southValue, &south) != napi_ok) {
        Logger::error("LatLngBoundsHarmony", "Failed to parse south");
        return false;
    }
    
    // Retrieve west property
    napi_value westValue;
    double west;
    status = napi_get_named_property(env, value, "west", &westValue);
    if (status != napi_ok || napi_get_value_double(env, westValue, &west) != napi_ok) {
        Logger::error("LatLngBoundsHarmony", "Failed to parse west");
        return false;
    }
    
    // Validate range
    if (north < -90.0 || north > 90.0 || south < -90.0 || south > 90.0) {
        Logger::error("LatLngBoundsHarmony", "Latitude out of range");
        return false;
    }
    if (east < -180.0 || east > 180.0 || west < -180.0 || west > 180.0) {
        Logger::error("LatLngBoundsHarmony", "Longitude out of range");
        return false;
    }
    if (north < south) {
        Logger::error("LatLngBoundsHarmony", "North must be >= south");
        return false;
    }
    
    // Build bounds (using northeast and southwest corners)
    outBounds = mbgl::LatLngBounds::hull(
        mbgl::LatLng(north, east),  // Northeast corner
        mbgl::LatLng(south, west)   // Southwest corner
    );
    
    return true;
}

} // namespace harmony
} // namespace mbgl

