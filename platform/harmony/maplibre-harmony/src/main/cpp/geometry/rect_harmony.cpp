#include "rect_harmony.hpp"
#include "napi_double_props.hpp"
#include "utils/logger.h"

namespace mln {
namespace harmony {

using Logger = mln::harmony::Logger;

napi_value RectHarmony::CreateRectObject(napi_env env, double left, double top, double right, double bottom) {
    return CreateDoublePropsObject(env, "RectHarmony",
                                   {{"left", left}, {"top", top}, {"right", right}, {"bottom", bottom}});
}

bool RectHarmony::ParseRect(napi_env env, napi_value value,
                           double& outLeft, double& outTop,
                           double& outRight, double& outBottom) {
    return ParseDoubleProps(env, value, "RectHarmony",
                            {{"left", &outLeft}, {"top", &outTop}, {"right", &outRight}, {"bottom", &outBottom}});
}

bool RectHarmony::ParseAsEdgeInsets(napi_env env, napi_value value, mln::EdgeInsets& outInsets) {
    double left, top, right, bottom;
    if (ParseRect(env, value, left, top, right, bottom)) {
        // Rect extents map directly to EdgeInsets
        outInsets = mln::EdgeInsets{top, left, bottom, right};
        return true;
    }
    return false;
}

} // namespace harmony
} // namespace mln

