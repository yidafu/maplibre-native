#pragma once

#include <napi/native_api.h>
#include <mbgl/util/projection.hpp>

namespace mbgl {
namespace harmony {

/**
 * ProjectedMeters NAPI conversion helper
 *
 * Bridges mbgl::ProjectedMeters (C++) with ETS ProjectedMeters objects.
 * ETS definition: { northing: number, easting: number }
 */
class ProjectedMetersHarmony {
public:
    /**
     * Create a ProjectedMeters NAPI object.
     * @param env NAPI environment
     * @param projectedMeters mbgl::ProjectedMeters C++ object
     * @return NAPI object { northing: number, easting: number }
     */
    static napi_value CreateProjectedMetersObject(napi_env env, const mbgl::ProjectedMeters& projectedMeters);
    
    /**
     * Parse ProjectedMeters from a NAPI value.
     * @param env NAPI environment
     * @param value NAPI object
     * @param outProjectedMeters Output mbgl::ProjectedMeters
     * @return Whether parsing succeeded
     */
    static bool ParseProjectedMeters(napi_env env, napi_value value, mbgl::ProjectedMeters& outProjectedMeters);
};

} // namespace harmony
} // namespace mbgl

