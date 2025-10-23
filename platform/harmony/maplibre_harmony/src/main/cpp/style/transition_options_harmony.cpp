#include "transition_options_harmony.hpp"
#include "../logger.h"
#include <mbgl/util/chrono.hpp>

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

napi_value TransitionOptionsHarmony::CreateTransitionOptionsObject(napi_env env, const mbgl::style::TransitionOptions& options) {
    napi_value obj;
    napi_status status = napi_create_object(env, &obj);
    if (status != napi_ok) {
        Logger::error("TransitionOptionsHarmony", "Failed to create TransitionOptions object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 创建 duration 属性（转换为毫秒）
    const auto durationMs = std::chrono::duration_cast<std::chrono::milliseconds>(
        options.duration.value_or(mbgl::Duration::zero())
    ).count();
    napi_value durationValue;
    napi_create_double(env, static_cast<double>(durationMs), &durationValue);
    napi_set_named_property(env, obj, "duration", durationValue);
    
    // 创建 delay 属性（转换为毫秒）
    const auto delayMs = std::chrono::duration_cast<std::chrono::milliseconds>(
        options.delay.value_or(mbgl::Duration::zero())
    ).count();
    napi_value delayValue;
    napi_create_double(env, static_cast<double>(delayMs), &delayValue);
    napi_set_named_property(env, obj, "delay", delayValue);
    
    Logger::debug("TransitionOptionsHarmony", "Created TransitionOptions object: duration=%lld ms, delay=%lld ms", 
                  durationMs, delayMs);
    
    return obj;
}

bool TransitionOptionsHarmony::ParseTransitionOptions(napi_env env, napi_value value, mbgl::style::TransitionOptions& outOptions) {
    // 检查是否为对象
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok || type != napi_object) {
        Logger::error("TransitionOptionsHarmony", "Value is not an object");
        return false;
    }
    
    // 解析 duration
    napi_value durationValue;
    status = napi_get_named_property(env, value, "duration", &durationValue);
    if (status == napi_ok) {
        double duration;
        if (napi_get_value_double(env, durationValue, &duration) == napi_ok) {
            outOptions.duration = mbgl::Duration(mbgl::Milliseconds(static_cast<int64_t>(duration)));
        }
    }
    
    // 解析 delay
    napi_value delayValue;
    status = napi_get_named_property(env, value, "delay", &delayValue);
    if (status == napi_ok) {
        double delay;
        if (napi_get_value_double(env, delayValue, &delay) == napi_ok) {
            outOptions.delay = mbgl::Duration(mbgl::Milliseconds(static_cast<int64_t>(delay)));
        }
    }
    
    // 解析 enablePlacementTransitions (可选，默认为 true)
    napi_value enableValue;
    status = napi_get_named_property(env, value, "enablePlacementTransitions", &enableValue);
    if (status == napi_ok) {
        bool enable;
        if (napi_get_value_bool(env, enableValue, &enable) == napi_ok) {
            outOptions.enablePlacementTransitions = enable;
        }
    }
    
    Logger::debug("TransitionOptionsHarmony", "Parsed TransitionOptions successfully");
    
    return true;
}

} // namespace harmony
} // namespace mbgl

