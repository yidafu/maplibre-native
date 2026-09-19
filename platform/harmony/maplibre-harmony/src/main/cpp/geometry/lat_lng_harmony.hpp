#pragma once

#include <napi/native_api.h>
#include <mln/util/geo.hpp>
#include "napi/core/napi_args.hpp"

namespace mln {
namespace harmony {

/**
 * LatLng conversion utilities.
 * Bridges between C++ mln::LatLng and ETS object literals.
 */
class LatLngHarmony {
public:
    /**
     * Create a NAPI LatLng object.
     */
    static napi_value CreateLatLngObject(napi_env env, const mln::LatLng& latLng);
    
    /**
     * Parse a LatLng from a NAPI value.
     */
    static bool ParseLatLng(napi_env env, napi_value value, mln::LatLng& outLatLng);
    
    /**
     * Parse a LatLng using NapiArgs.
     */
    static bool ParseLatLngWithArgs(mln::harmony::napi::NapiArgs& args, napi_value obj, mln::LatLng& outLatLng);
    
    /**
     * Parse a LatLng with a default fallback.
     */
    static mln::LatLng ParseLatLngOr(napi_env env, napi_value value, const mln::LatLng& defaultValue);
};

} // namespace harmony
} // namespace mln

