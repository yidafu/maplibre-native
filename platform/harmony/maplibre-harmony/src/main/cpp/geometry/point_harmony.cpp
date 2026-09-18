#include "point_harmony.hpp"
#include "napi_double_props.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value PointHarmony::CreatePointObject(napi_env env, double x, double y) {
    return CreateDoublePropsObject(env, "PointHarmony", {{"x", x}, {"y", y}});
}

napi_value PointHarmony::CreatePointObject(napi_env env, const mbgl::ScreenCoordinate& coord) {
    return CreatePointObject(env, coord.x, coord.y);
}

bool PointHarmony::ParsePoint(napi_env env, napi_value value, double& outX, double& outY) {
    return ParseDoubleProps(env, value, "PointHarmony", {{"x", &outX}, {"y", &outY}});
}

bool PointHarmony::ParseScreenCoordinate(napi_env env, napi_value value, mbgl::ScreenCoordinate& outCoord) {
    double x, y;
    if (ParsePoint(env, value, x, y)) {
        outCoord = mbgl::ScreenCoordinate{x, y};
        return true;
    }
    return false;
}

} // namespace harmony
} // namespace mbgl

