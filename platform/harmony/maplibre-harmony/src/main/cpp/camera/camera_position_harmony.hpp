#pragma once

#include <napi/native_api.h>
#include <mln/map/camera.hpp>

namespace mln {
namespace harmony {

/**
 * CameraPosition NAPI conversion helper
 *
 * Bridges mln::CameraOptions (C++) with ETS CameraPosition objects.
 * ETS definition: { target: LatLng, zoom: number, bearing: number, tilt: number, padding: EdgeInsets }
 * EdgeInsets: { left: number, top: number, right: number, bottom: number }
 */
class CameraPositionHarmony {
public:
    /**
     * Create a CameraPosition NAPI object.
     * @param env NAPI environment
     * @param options mln::CameraOptions C++ object
     * @param pixelRatio Pixel ratio (used to scale padding)
     * @return NAPI object
     */
    static napi_value CreateCameraPositionObject(napi_env env, const mln::CameraOptions& options, float pixelRatio);
    
    /**
     * Parse CameraOptions from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param pixelRatio Pixel ratio (used to scale padding)
     * @param outOptions Output mln::CameraOptions
     * @return Whether parsing succeeded
     */
    static bool ParseCameraOptions(napi_env env, napi_value value, float pixelRatio, mln::CameraOptions& outOptions);
};

} // namespace harmony
} // namespace mln

