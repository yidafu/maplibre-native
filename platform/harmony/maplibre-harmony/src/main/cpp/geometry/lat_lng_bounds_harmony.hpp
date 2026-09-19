#pragma once

#include <napi/native_api.h>
#include <mln/util/geo.hpp>

namespace mln {
namespace harmony {

/**
 * LatLngBounds NAPI conversion helper
 *
 * Bridges mln::LatLngBounds (C++) with ETS LatLngBounds objects.
 * ETS definition: { north: number, east: number, south: number, west: number }
 */
class LatLngBoundsHarmony {
public:
    /**
     * Create a LatLngBounds NAPI object.
     * @param env NAPI environment
     * @param bounds mln::LatLngBounds C++ object
     * @return NAPI object { north, east, south, west: number }
     */
    static napi_value CreateLatLngBoundsObject(napi_env env, const mln::LatLngBounds& bounds);
    
    /**
     * Parse LatLngBounds from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outBounds Output mln::LatLngBounds
     * @return Whether parsing succeeded
     */
    static bool ParseLatLngBounds(napi_env env, napi_value value, mln::LatLngBounds& outBounds);
};

} // namespace harmony
} // namespace mln

