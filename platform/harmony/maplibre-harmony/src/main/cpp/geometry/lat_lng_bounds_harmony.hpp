#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>

namespace mbgl {
namespace harmony {

/**
 * LatLngBounds NAPI conversion helper
 *
 * Bridges mbgl::LatLngBounds (C++) with ETS LatLngBounds objects.
 * ETS definition: { north: number, east: number, south: number, west: number }
 */
class LatLngBoundsHarmony {
public:
    /**
     * Create a LatLngBounds NAPI object.
     * @param env NAPI environment
     * @param bounds mbgl::LatLngBounds C++ object
     * @return NAPI object { north, east, south, west: number }
     */
    static napi_value CreateLatLngBoundsObject(napi_env env, const mbgl::LatLngBounds& bounds);
    
    /**
     * Parse LatLngBounds from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outBounds Output mbgl::LatLngBounds
     * @return Whether parsing succeeded
     */
    static bool ParseLatLngBounds(napi_env env, napi_value value, mbgl::LatLngBounds& outBounds);
};

} // namespace harmony
} // namespace mbgl

