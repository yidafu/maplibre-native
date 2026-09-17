#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>

namespace mbgl {
namespace harmony {

/**
 * Point NAPI conversion helper.
 *
 * Converts between mbgl::ScreenCoordinate (C++) and ETS Point objects.
 * ETS definition: { x: number, y: number }
 * Equivalent to Android's PointF.
 */
class PointHarmony {
public:
    /**
     * Create a NAPI Point object.
     * @param env NAPI environment
     * @param x X coordinate
     * @param y Y coordinate
     * @return NAPI object { x: number, y: number }
     */
    static napi_value CreatePointObject(napi_env env, double x, double y);
    
    /**
     * Create a NAPI Point object from a ScreenCoordinate.
     * @param env NAPI environment
     * @param coord Screen coordinate
     * @return NAPI object { x: number, y: number }
     */
    static napi_value CreatePointObject(napi_env env, const mbgl::ScreenCoordinate& coord);
    
    /**
     * Parse a Point from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outX Output X coordinate
     * @param outY Output Y coordinate
     * @return True if parsing succeeded
     */
    static bool ParsePoint(napi_env env, napi_value value, double& outX, double& outY);
    
    /**
     * Parse a ScreenCoordinate from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outCoord Output ScreenCoordinate
     * @return True if parsing succeeded
     */
    static bool ParseScreenCoordinate(napi_env env, napi_value value, mbgl::ScreenCoordinate& outCoord);
};

} // namespace harmony
} // namespace mbgl

