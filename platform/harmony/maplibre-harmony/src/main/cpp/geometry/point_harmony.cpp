#include "point_harmony.hpp"
#include "napi_double_props.hpp"
#include "utils/logger.h"

namespace mln {
namespace harmony {

using Logger = mln::harmony::Logger;

napi_value PointHarmony::CreatePointObject(napi_env env, double x, double y) {
    return CreateDoublePropsObject(env, "PointHarmony", {{"x", x}, {"y", y}});
}

napi_value PointHarmony::CreatePointObject(napi_env env, const mln::ScreenCoordinate& coord) {
    return CreatePointObject(env, coord.x, coord.y);
}

bool PointHarmony::ParsePoint(napi_env env, napi_value value, double& outX, double& outY) {
    return ParseDoubleProps(env, value, "PointHarmony", {{"x", &outX}, {"y", &outY}});
}

bool PointHarmony::ParseScreenCoordinate(napi_env env, napi_value value, mln::ScreenCoordinate& outCoord) {
    double x, y;
    if (ParsePoint(env, value, x, y)) {
        outCoord = mln::ScreenCoordinate{x, y};
        return true;
    }
    return false;
}

} // namespace harmony
} // namespace mln

