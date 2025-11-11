#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>
#include "napi/core/napi_args.hpp"

namespace mbgl {
namespace harmony {

/**
 * LatLng conversion utilities.
 * Bridges between C++ mbgl::LatLng and ETS object literals.
 */
class LatLngHarmony {
public:
    /**
     * Create a NAPI LatLng object.
     */
    static napi_value CreateLatLngObject(napi_env env, const mbgl::LatLng& latLng);
    
    /**
     * Parse a LatLng from a NAPI value.
     */
    static bool ParseLatLng(napi_env env, napi_value value, mbgl::LatLng& outLatLng);
    
    /**
     * Parse a LatLng using NapiArgs.
     */
    static bool ParseLatLngWithArgs(mbgl::harmony::napi::NapiArgs& args, napi_value obj, mbgl::LatLng& outLatLng);
    
    /**
     * Parse a LatLng with a default fallback.
     */
    static mbgl::LatLng ParseLatLngOr(napi_env env, napi_value value, const mbgl::LatLng& defaultValue);
};

} // namespace harmony
} // namespace mbgl

