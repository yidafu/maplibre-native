#include "projected_meters_harmony.hpp"
#include "napi_double_props.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value ProjectedMetersHarmony::CreateProjectedMetersObject(napi_env env, const mbgl::ProjectedMeters& projectedMeters) {
    return CreateDoublePropsObject(env, "ProjectedMetersHarmony",
                                   {{"northing", projectedMeters.northing()},
                                    {"easting", projectedMeters.easting()}});
}

bool ProjectedMetersHarmony::ParseProjectedMeters(napi_env env, napi_value value, mbgl::ProjectedMeters& outProjectedMeters) {
    double northing = 0.0;
    double easting = 0.0;
    if (!ParseDoubleProps(env, value, "ProjectedMetersHarmony",
                          {{"northing", &northing}, {"easting", &easting}})) {
        return false;
    }

    outProjectedMeters = mbgl::ProjectedMeters(northing, easting);
    return true;
}

} // namespace harmony
} // namespace mbgl

