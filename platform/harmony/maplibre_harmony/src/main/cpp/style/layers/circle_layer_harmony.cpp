#include "circle_layer_harmony.hpp"
#include "../../napi_utils.h"
#include "../../logger.h"
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/util/color.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

using namespace mbgl::style;

napi_value CircleLayerHarmony::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_STATIC_FUNCTION("create", Create),
        DECLARE_NAPI_STATIC_FUNCTION("setCircleRadius", SetCircleRadius),
        DECLARE_NAPI_STATIC_FUNCTION("setCircleColor", SetCircleColor),
        DECLARE_NAPI_STATIC_FUNCTION("setCircleOpacity", SetCircleOpacity),
        DECLARE_NAPI_STATIC_FUNCTION("setCircleBlur", SetCircleBlur),
        DECLARE_NAPI_STATIC_FUNCTION("setCircleStrokeWidth", SetCircleStrokeWidth),
        DECLARE_NAPI_STATIC_FUNCTION("setCircleStrokeColor", SetCircleStrokeColor),
        DECLARE_NAPI_STATIC_FUNCTION("setCircleStrokeOpacity", SetCircleStrokeOpacity),
    };

    napi_value circleLayerObject;
    napi_create_object(env, &circleLayerObject);
    napi_define_properties(env, circleLayerObject,
        sizeof(properties) / sizeof(properties[0]),
        properties);

    napi_set_named_property(env, exports, "CircleLayer", circleLayerObject);

    return exports;
}

napi_value CircleLayerHarmony::Create(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        LOGE("CircleLayer.Create: missing arguments");
        return CreateInt64Value(env, 0);
    }

    std::string layerId = GetStringFromValue(env, args[0]);
    std::string sourceId = GetStringFromValue(env, args[1]);

    try {
        auto layer = std::make_unique<mbgl::style::CircleLayer>(layerId, sourceId);
        int64_t layerPtr = reinterpret_cast<int64_t>(layer.release());
        LOGI("CircleLayer.Create: %s (source: %s)", layerId.c_str(), sourceId.c_str());
        return CreateInt64Value(env, layerPtr);
    } catch (const std::exception& e) {
        LOGE("CircleLayer.Create failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

napi_value CircleLayerHarmony::SetCircleRadius(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::CircleLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double radius = GetDoubleFromValue(env, args[1]);

    try {
        layer->setCircleRadius(PropertyValue<float>(static_cast<float>(radius)));
        LOGI("CircleLayer.SetCircleRadius: %f", radius);
    } catch (const std::exception& e) {
        LOGE("CircleLayer.SetCircleRadius failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value CircleLayerHarmony::SetCircleColor(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::CircleLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    std::string colorStr = GetStringFromValue(env, args[1]);

    try {
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            layer->setCircleColor(PropertyValue<Color>(*color));
            LOGI("CircleLayer.SetCircleColor: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("CircleLayer.SetCircleColor failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value CircleLayerHarmony::SetCircleOpacity(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::CircleLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double opacity = GetDoubleFromValue(env, args[1]);

    try {
        layer->setCircleOpacity(PropertyValue<float>(static_cast<float>(opacity)));
        LOGI("CircleLayer.SetCircleOpacity: %f", opacity);
    } catch (const std::exception& e) {
        LOGE("CircleLayer.SetCircleOpacity failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value CircleLayerHarmony::SetCircleBlur(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::CircleLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double blur = GetDoubleFromValue(env, args[1]);

    try {
        layer->setCircleBlur(PropertyValue<float>(static_cast<float>(blur)));
        LOGI("CircleLayer.SetCircleBlur: %f", blur);
    } catch (const std::exception& e) {
        LOGE("CircleLayer.SetCircleBlur failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value CircleLayerHarmony::SetCircleStrokeWidth(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::CircleLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double width = GetDoubleFromValue(env, args[1]);

    try {
        layer->setCircleStrokeWidth(PropertyValue<float>(static_cast<float>(width)));
        LOGI("CircleLayer.SetCircleStrokeWidth: %f", width);
    } catch (const std::exception& e) {
        LOGE("CircleLayer.SetCircleStrokeWidth failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value CircleLayerHarmony::SetCircleStrokeColor(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::CircleLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    std::string colorStr = GetStringFromValue(env, args[1]);

    try {
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            layer->setCircleStrokeColor(PropertyValue<Color>(*color));
            LOGI("CircleLayer.SetCircleStrokeColor: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("CircleLayer.SetCircleStrokeColor failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value CircleLayerHarmony::SetCircleStrokeOpacity(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::CircleLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double opacity = GetDoubleFromValue(env, args[1]);

    try {
        layer->setCircleStrokeOpacity(PropertyValue<float>(static_cast<float>(opacity)));
        LOGI("CircleLayer.SetCircleStrokeOpacity: %f", opacity);
    } catch (const std::exception& e) {
        LOGE("CircleLayer.SetCircleStrokeOpacity failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

