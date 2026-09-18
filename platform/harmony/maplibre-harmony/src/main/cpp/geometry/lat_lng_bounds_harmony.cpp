#include "lat_lng_bounds_harmony.hpp"
#include "napi_double_props.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value LatLngBoundsHarmony::CreateLatLngBoundsObject(napi_env env, const mbgl::LatLngBounds& bounds) {
    return CreateDoublePropsObject(env, "LatLngBoundsHarmony",
                                   {{"north", bounds.north()},
                                    {"east", bounds.east()},
                                    {"south", bounds.south()},
                                    {"west", bounds.west()}});
}

bool LatLngBoundsHarmony::ParseLatLngBounds(napi_env env, napi_value value, mbgl::LatLngBounds& outBounds) {
    double north = 0.0;
    double east = 0.0;
    double south = 0.0;
    double west = 0.0;
    if (!ParseDoubleProps(env, value, "LatLngBoundsHarmony",
                          {{"north", &north}, {"east", &east}, {"south", &south}, {"west", &west}})) {
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

