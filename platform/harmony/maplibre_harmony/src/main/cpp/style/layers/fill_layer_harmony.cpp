#include "fill_layer_harmony.hpp"
#include "../../napi_utils.h"
#include "../../napi_args.hpp"
#include "../../logger.h"
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/expression/dsl.hpp>
#include <mbgl/util/color.hpp>
#include <mbgl/style/property_value.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

using namespace mbgl::style;
using namespace mbgl::style::expression::dsl;

napi_value FillLayerHarmony::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_STATIC_FUNCTION("create", Create),
        DECLARE_NAPI_STATIC_FUNCTION("setFillColor", SetFillColor),
        DECLARE_NAPI_STATIC_FUNCTION("setFillOpacity", SetFillOpacity),
        DECLARE_NAPI_STATIC_FUNCTION("setFillOutlineColor", SetFillOutlineColor),
        DECLARE_NAPI_STATIC_FUNCTION("setFillPattern", SetFillPattern),
        DECLARE_NAPI_STATIC_FUNCTION("setFillAntialias", SetFillAntialias),
        DECLARE_NAPI_STATIC_FUNCTION("setFillTranslate", SetFillTranslate),
    };

    napi_value fillLayerObject;
    napi_create_object(env, &fillLayerObject);
    napi_define_properties(env, fillLayerObject,
        sizeof(properties) / sizeof(properties[0]),
        properties);

    napi_set_named_property(env, exports, "FillLayer", fillLayerObject);

    return exports;
}

napi_value FillLayerHarmony::Create(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return CreateInt64Value(env, 0);

    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return CreateInt64Value(env, 0);

    try {
        // 创建FillLayer实例
        auto layer = std::make_unique<mbgl::style::FillLayer>(layerId, sourceId);
        
        // 返回图层指针
        int64_t layerPtr = reinterpret_cast<int64_t>(layer.release());
        LOGI("FillLayer.Create: %s (source: %s, ptr: %lld)", layerId.c_str(), sourceId.c_str(), layerPtr);
        
        return CreateInt64Value(env, layerPtr);
    } catch (const std::exception& e) {
        LOGE("FillLayer.Create failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

napi_value FillLayerHarmony::SetFillColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = args.GetInt64(0, "layerPtr");
    std::string colorStr = args.GetString(1, "color");
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    auto* layer = reinterpret_cast<mbgl::style::FillLayer*>(layerPtr);
    if (!layer) {
        LOGE("FillLayer.SetFillColor: invalid layer pointer");
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    try {
        // 解析颜色字符串
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            // 设置填充颜色
            layer->setFillColor(PropertyValue<Color>(*color));
            LOGI("FillLayer.SetFillColor: %s", colorStr.c_str());
        } else {
            LOGE("FillLayer.SetFillColor: failed to parse color: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("FillLayer.SetFillColor failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value FillLayerHarmony::SetFillOpacity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = args.GetInt64(0, "layerPtr");
    double opacity = args.GetDouble(1, "opacity");
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    auto* layer = reinterpret_cast<mbgl::style::FillLayer*>(layerPtr);
    if (!layer) {
        LOGE("FillLayer.SetFillOpacity: invalid layer pointer");
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    try {
        // 设置填充透明度
        layer->setFillOpacity(PropertyValue<float>(static_cast<float>(opacity)));
        LOGI("FillLayer.SetFillOpacity: %f", opacity);
    } catch (const std::exception& e) {
        LOGE("FillLayer.SetFillOpacity failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value FillLayerHarmony::SetFillOutlineColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = args.GetInt64(0, "layerPtr");
    std::string colorStr = args.GetString(1, "color");
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    auto* layer = reinterpret_cast<mbgl::style::FillLayer*>(layerPtr);
    if (!layer) {
        LOGE("FillLayer.SetFillOutlineColor: invalid layer pointer");
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    try {
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            layer->setFillOutlineColor(PropertyValue<Color>(*color));
            LOGI("FillLayer.SetFillOutlineColor: %s", colorStr.c_str());
        } else {
            LOGE("FillLayer.SetFillOutlineColor: failed to parse color: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("FillLayer.SetFillOutlineColor failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value FillLayerHarmony::SetFillPattern(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr;
    napi_get_value_int64(env, args[0], &layerPtr);

    size_t patternLen;
    napi_get_value_string_utf8(env, args[1], nullptr, 0, &patternLen);
    std::string pattern(patternLen, '\0');
    napi_get_value_string_utf8(env, args[1], &pattern[0], patternLen + 1, &patternLen);

    try {
        // TODO: 设置填充图案
        LOGI("FillLayer.SetFillPattern: %s", pattern.c_str());
    } catch (const std::exception& e) {
        LOGE("FillLayer.SetFillPattern failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value FillLayerHarmony::SetFillAntialias(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t layerPtr = args.GetInt64(0, "layerPtr");
    bool antialias = args.GetBool(1, "antialias");
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    auto* layer = reinterpret_cast<mbgl::style::FillLayer*>(layerPtr);
    if (!layer) {
        LOGE("FillLayer.SetFillAntialias: invalid layer pointer");
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    try {
        layer->setFillAntialias(PropertyValue<bool>(antialias));
        LOGI("FillLayer.SetFillAntialias: %d", antialias);
    } catch (const std::exception& e) {
        LOGE("FillLayer.SetFillAntialias failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value FillLayerHarmony::SetFillTranslate(napi_env env, napi_callback_info info) {
    // TODO: 实现设置偏移
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

