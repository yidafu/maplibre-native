#include "rect_harmony.hpp"
#include "../logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value RectHarmony::CreateRectObject(napi_env env, double left, double top, double right, double bottom) {
    napi_value obj;
    napi_status status = napi_create_object(env, &obj);
    if (status != napi_ok) {
        Logger::error("RectHarmony", "Failed to create Rect object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 创建 left 属性
    napi_value leftValue;
    napi_create_double(env, left, &leftValue);
    napi_set_named_property(env, obj, "left", leftValue);
    
    // 创建 top 属性
    napi_value topValue;
    napi_create_double(env, top, &topValue);
    napi_set_named_property(env, obj, "top", topValue);
    
    // 创建 right 属性
    napi_value rightValue;
    napi_create_double(env, right, &rightValue);
    napi_set_named_property(env, obj, "right", rightValue);
    
    // 创建 bottom 属性
    napi_value bottomValue;
    napi_create_double(env, bottom, &bottomValue);
    napi_set_named_property(env, obj, "bottom", bottomValue);
    
    Logger::debug("RectHarmony", "Created Rect object: left=%f, top=%f, right=%f, bottom=%f", 
                  left, top, right, bottom);
    
    return obj;
}

bool RectHarmony::ParseRect(napi_env env, napi_value value, 
                           double& outLeft, double& outTop, 
                           double& outRight, double& outBottom) {
    // 检查是否为对象
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("RectHarmony", "Value is not an object");
        return false;
    }
    
    // 获取 left 属性
    napi_value leftValue;
    status = napi_get_named_property(env, value, "left", &leftValue);
    if (status != napi_ok || napi_get_value_double(env, leftValue, &outLeft) != napi_ok) {
        Logger::error("RectHarmony", "Failed to parse left");
        return false;
    }
    
    // 获取 top 属性
    napi_value topValue;
    status = napi_get_named_property(env, value, "top", &topValue);
    if (status != napi_ok || napi_get_value_double(env, topValue, &outTop) != napi_ok) {
        Logger::error("RectHarmony", "Failed to parse top");
        return false;
    }
    
    // 获取 right 属性
    napi_value rightValue;
    status = napi_get_named_property(env, value, "right", &rightValue);
    if (status != napi_ok || napi_get_value_double(env, rightValue, &outRight) != napi_ok) {
        Logger::error("RectHarmony", "Failed to parse right");
        return false;
    }
    
    // 获取 bottom 属性
    napi_value bottomValue;
    status = napi_get_named_property(env, value, "bottom", &bottomValue);
    if (status != napi_ok || napi_get_value_double(env, bottomValue, &outBottom) != napi_ok) {
        Logger::error("RectHarmony", "Failed to parse bottom");
        return false;
    }
    
    Logger::debug("RectHarmony", "Parsed Rect: left=%f, top=%f, right=%f, bottom=%f", 
                  outLeft, outTop, outRight, outBottom);
    
    return true;
}

bool RectHarmony::ParseAsEdgeInsets(napi_env env, napi_value value, mbgl::EdgeInsets& outInsets) {
    double left, top, right, bottom;
    if (ParseRect(env, value, left, top, right, bottom)) {
        // Rect 的边界值直接对应 EdgeInsets
        outInsets = mbgl::EdgeInsets{top, left, bottom, right};
        return true;
    }
    return false;
}

} // namespace harmony
} // namespace mbgl

