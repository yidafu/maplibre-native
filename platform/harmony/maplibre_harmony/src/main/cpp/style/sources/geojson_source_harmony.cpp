#include "geojson_source_harmony.hpp"
#include "../../napi_utils.h"
#include "../../napi_args.hpp"
#include "../../logger.h"
#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/style/conversion/geojson_options.hpp>
#include <mbgl/util/geojson.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

napi_value GeoJsonSourceHarmony::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_STATIC_FUNCTION("create", Create),
        DECLARE_NAPI_STATIC_FUNCTION("setGeoJson", SetGeoJson),
        DECLARE_NAPI_STATIC_FUNCTION("setGeoJsonSync", SetGeoJsonSync),
        DECLARE_NAPI_STATIC_FUNCTION("setUrl", SetUrl),
        DECLARE_NAPI_STATIC_FUNCTION("getUrl", GetUrl),
        DECLARE_NAPI_STATIC_FUNCTION("querySourceFeatures", QuerySourceFeatures),
        DECLARE_NAPI_STATIC_FUNCTION("getClusterChildren", GetClusterChildren),
        DECLARE_NAPI_STATIC_FUNCTION("getClusterLeaves", GetClusterLeaves),
        DECLARE_NAPI_STATIC_FUNCTION("getClusterExpansionZoom", GetClusterExpansionZoom),
    };

    napi_value geoJsonSourceObject;
    napi_create_object(env, &geoJsonSourceObject);
    napi_define_properties(env, geoJsonSourceObject,
        sizeof(properties) / sizeof(properties[0]),
        properties);

    napi_set_named_property(env, exports, "GeoJsonSource", geoJsonSourceObject);

    return exports;
}

napi_value GeoJsonSourceHarmony::Create(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return CreateInt64Value(env, 0);

    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) return CreateInt64Value(env, 0);

    try {
        // 解析GeoJSON选项
        Immutable<mbgl::style::GeoJSONOptions> options = mbgl::style::GeoJSONOptions::defaultOptions();
        
        if (args.Count() >= 2) {
            std::string optionsJson = args.GetStringOr(1, "");
            if (!optionsJson.empty()) {
                // 解析选项JSON
                mbgl::style::conversion::Error error;
                auto convertedOptions = mbgl::style::conversion::convertJSON<mbgl::style::GeoJSONOptions>(optionsJson, error);
                if (convertedOptions) {
                    options = makeMutable<mbgl::style::GeoJSONOptions>(std::move(*convertedOptions));
                } else {
                    LOGW("Failed to parse GeoJSON options: %s", error.message.c_str());
                }
            }
        }

        // 创建GeoJSONSource实例
        auto source = std::make_unique<mbgl::style::GeoJSONSource>(sourceId, std::move(options));
        
        // 返回源指针
        int64_t sourcePtr = reinterpret_cast<int64_t>(source.release());
        LOGI("GeoJsonSource.Create: %s (ptr: %lld)", sourceId.c_str(), sourcePtr);
        
        return CreateInt64Value(env, sourcePtr);
    } catch (const std::exception& e) {
        LOGE("GeoJsonSource.Create failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

napi_value GeoJsonSourceHarmony::SetGeoJson(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t sourcePtr = args.GetInt64(0, "sourcePtr");
    std::string geoJsonStr = args.GetString(1, "geoJson");
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    auto* source = reinterpret_cast<mbgl::style::GeoJSONSource*>(sourcePtr);
    if (!source) {
        LOGE("GeoJsonSource.SetGeoJson: invalid source pointer");
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    try {
        // 解析GeoJSON字符串
        mbgl::style::conversion::Error error;
        auto geoJson = mbgl::style::conversion::convertJSON<mbgl::GeoJSON>(geoJsonStr, error);
        
        if (geoJson) {
            // 设置GeoJSON数据
            source->setGeoJSON(*geoJson);
            LOGI("GeoJsonSource.SetGeoJson: success (%zu bytes)", geoJsonStr.length());
        } else {
            LOGE("GeoJsonSource.SetGeoJson: failed to parse GeoJSON: %s", error.message.c_str());
        }
    } catch (const std::exception& e) {
        LOGE("GeoJsonSource.SetGeoJson failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value GeoJsonSourceHarmony::SetGeoJsonSync(napi_env env, napi_callback_info info) {
    // 实现与SetGeoJson类似，但使用同步方式
    return SetGeoJson(env, info);
}

napi_value GeoJsonSourceHarmony::SetUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    int64_t sourcePtr = args.GetInt64(0, "sourcePtr");
    std::string url = args.GetString(1, "url");
    if (args.HasError()) {
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    auto* source = reinterpret_cast<mbgl::style::GeoJSONSource*>(sourcePtr);
    if (!source) {
        LOGE("GeoJsonSource.SetUrl: invalid source pointer");
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    }

    try {
        source->setURL(url);
        LOGI("GeoJsonSource.SetUrl: %s", url.c_str());
    } catch (const std::exception& e) {
        LOGE("GeoJsonSource.SetUrl failed: %s", e.what());
    }

    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value GeoJsonSourceHarmony::GetUrl(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        return CreateStringValue(env, "");
    }

    int64_t sourcePtr = GetInt64FromValue(env, args[0]);
    auto* source = reinterpret_cast<mbgl::style::GeoJSONSource*>(sourcePtr);
    
    if (!source) {
        return CreateStringValue(env, "");
    }

    try {
        auto url = source->getURL();
        if (url) {
            return CreateStringValue(env, *url);
        }
    } catch (const std::exception& e) {
        LOGE("GeoJsonSource.GetUrl failed: %s", e.what());
    }

    return CreateStringValue(env, "");
}

napi_value GeoJsonSourceHarmony::QuerySourceFeatures(napi_env env, napi_callback_info info) {
    // TODO: 实现查询要素
    napi_value result;
    napi_create_string_utf8(env, "[]", 2, &result);
    return result;
}

napi_value GeoJsonSourceHarmony::GetClusterChildren(napi_env env, napi_callback_info info) {
    // TODO: 实现获取聚类子项
    napi_value result;
    napi_create_string_utf8(env, "[]", 2, &result);
    return result;
}

napi_value GeoJsonSourceHarmony::GetClusterLeaves(napi_env env, napi_callback_info info) {
    // TODO: 实现获取聚类叶子节点
    napi_value result;
    napi_create_string_utf8(env, "[]", 2, &result);
    return result;
}

napi_value GeoJsonSourceHarmony::GetClusterExpansionZoom(napi_env env, napi_callback_info info) {
    // TODO: 实现获取聚类展开缩放级别
    napi_value result;
    napi_create_int32(env, 0, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

