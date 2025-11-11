#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geo.hpp>

namespace mbgl {
namespace harmony {

/**
 * Rect NAPI conversion helper
 *
 * Bridges C++ rectangle coordinates with ETS Rect objects.
 * ETS definition: { left: number, top: number, right: number, bottom: number }
 * Equivalent to Android's RectF.
 */
class RectHarmony {
public:
    /**
     * Create a Rect NAPI object.
     * @param env NAPI environment
     * @param left Left edge
     * @param top Top edge
     * @param right Right edge
     * @param bottom Bottom edge
     * @return NAPI object { left, top, right, bottom: number }
     */
    static napi_value CreateRectObject(napi_env env, double left, double top, double right, double bottom);
    
    /**
     * Parse a Rect from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outLeft Output left edge
     * @param outTop Output top edge
     * @param outRight Output right edge
     * @param outBottom Output bottom edge
     * @return Whether parsing succeeded
     */
    static bool ParseRect(napi_env env, napi_value value, 
                         double& outLeft, double& outTop, 
                         double& outRight, double& outBottom);
    
    /**
     * Parse a NAPI value into EdgeInsets.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outInsets Output EdgeInsets
     * @return Whether parsing succeeded
     */
    static bool ParseAsEdgeInsets(napi_env env, napi_value value, mbgl::EdgeInsets& outInsets);
};

} // namespace harmony
} // namespace mbgl

