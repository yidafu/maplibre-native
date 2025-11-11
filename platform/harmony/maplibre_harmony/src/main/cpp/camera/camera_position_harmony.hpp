#pragma once

#include <napi/native_api.h>
#include <mbgl/map/camera.hpp>

namespace mbgl {
namespace harmony {

/**
 * CameraPosition NAPI conversion helper
 *
 * Bridges mbgl::CameraOptions (C++) with ETS CameraPosition objects.
 * ETS definition: { target: LatLng, zoom: number, bearing: number, tilt: number, padding: EdgeInsets }
 * EdgeInsets: { left: number, top: number, right: number, bottom: number }
 */
class CameraPositionHarmony {
public:
    /**
     * Create a CameraPosition NAPI object.
     * @param env NAPI environment
     * @param options mbgl::CameraOptions C++ object
     * @param pixelRatio Pixel ratio (used to scale padding)
     * @return NAPI object
     */
    static napi_value CreateCameraPositionObject(napi_env env, const mbgl::CameraOptions& options, float pixelRatio);
    
    /**
     * Parse CameraOptions from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param pixelRatio Pixel ratio (used to scale padding)
     * @param outOptions Output mbgl::CameraOptions
     * @return Whether parsing succeeded
     */
    static bool ParseCameraOptions(napi_env env, napi_value value, float pixelRatio, mbgl::CameraOptions& outOptions);
};

} // namespace harmony
} // namespace mbgl

