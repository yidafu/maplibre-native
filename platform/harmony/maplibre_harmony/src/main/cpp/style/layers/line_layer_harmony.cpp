#include "line_layer_harmony.hpp"
#include "../../napi_utils.h"
#include "../../logger.h"
#include <mbgl/style/layers/line_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/util/color.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

using namespace mbgl::style;

napi_value LineLayerHarmony::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_STATIC_FUNCTION("create", Create),
        DECLARE_NAPI_STATIC_FUNCTION("setLineColor", SetLineColor),
        DECLARE_NAPI_STATIC_FUNCTION("setLineWidth", SetLineWidth),
        DECLARE_NAPI_STATIC_FUNCTION("setLineOpacity", SetLineOpacity),
        DECLARE_NAPI_STATIC_FUNCTION("setLinePattern", SetLinePattern),
        DECLARE_NAPI_STATIC_FUNCTION("setLineGapWidth", SetLineGapWidth),
        DECLARE_NAPI_STATIC_FUNCTION("setLineDasharray", SetLineDasharray),
        DECLARE_NAPI_STATIC_FUNCTION("setLineBlur", SetLineBlur),
        DECLARE_NAPI_STATIC_FUNCTION("setLineCap", SetLineCap),
        DECLARE_NAPI_STATIC_FUNCTION("setLineJoin", SetLineJoin),
    };

    napi_value lineLayerObject;
    napi_create_object(env, &lineLayerObject);
    napi_define_properties(env, lineLayerObject,
        sizeof(properties) / sizeof(properties[0]),
        properties);

    napi_set_named_property(env, exports, "LineLayer", lineLayerObject);

    return exports;
}

napi_value LineLayerHarmony::Create(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        LOGE("LineLayer.Create: missing arguments");
        return CreateInt64Value(env, 0);
    }

    std::string layerId = GetStringFromValue(env, args[0]);
    std::string sourceId = GetStringFromValue(env, args[1]);

    try {
        auto layer = std::make_unique<mbgl::style::LineLayer>(layerId, sourceId);
        int64_t layerPtr = reinterpret_cast<int64_t>(layer.release());
        LOGI("LineLayer.Create: %s (source: %s)", layerId.c_str(), sourceId.c_str());
        return CreateInt64Value(env, layerPtr);
    } catch (const std::exception& e) {
        LOGE("LineLayer.Create failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

napi_value LineLayerHarmony::SetLineColor(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::LineLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    std::string colorStr = GetStringFromValue(env, args[1]);

    try {
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            layer->setLineColor(PropertyValue<Color>(*color));
            LOGI("LineLayer.SetLineColor: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("LineLayer.SetLineColor failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLineWidth(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::LineLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double width = GetDoubleFromValue(env, args[1]);

    try {
        layer->setLineWidth(PropertyValue<float>(static_cast<float>(width)));
        LOGI("LineLayer.SetLineWidth: %f", width);
    } catch (const std::exception& e) {
        LOGE("LineLayer.SetLineWidth failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLineOpacity(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::LineLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double opacity = GetDoubleFromValue(env, args[1]);

    try {
        layer->setLineOpacity(PropertyValue<float>(static_cast<float>(opacity)));
        LOGI("LineLayer.SetLineOpacity: %f", opacity);
    } catch (const std::exception& e) {
        LOGE("LineLayer.SetLineOpacity failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLinePattern(napi_env env, napi_callback_info info) {
    // TODO: 实现pattern设置
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLineGapWidth(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::LineLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double gapWidth = GetDoubleFromValue(env, args[1]);

    try {
        layer->setLineGapWidth(PropertyValue<float>(static_cast<float>(gapWidth)));
        LOGI("LineLayer.SetLineGapWidth: %f", gapWidth);
    } catch (const std::exception& e) {
        LOGE("LineLayer.SetLineGapWidth failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLineDasharray(napi_env env, napi_callback_info info) {
    // TODO: 实现dasharray设置
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLineBlur(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = GetInt64FromValue(env, args[0]);
    auto* layer = reinterpret_cast<mbgl::style::LineLayer*>(layerPtr);
    
    if (!layer) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    double blur = GetDoubleFromValue(env, args[1]);

    try {
        layer->setLineBlur(PropertyValue<float>(static_cast<float>(blur)));
        LOGI("LineLayer.SetLineBlur: %f", blur);
    } catch (const std::exception& e) {
        LOGE("LineLayer.SetLineBlur failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLineCap(napi_env env, napi_callback_info info) {
    // TODO: 实现lineCap设置
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value LineLayerHarmony::SetLineJoin(napi_env env, napi_callback_info info) {
    // TODO: 实现lineJoin设置
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

