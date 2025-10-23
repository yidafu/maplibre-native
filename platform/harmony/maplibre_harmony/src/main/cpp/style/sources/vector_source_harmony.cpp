#include "vector_source_harmony.hpp"
#include "../../napi_utils.h"
#include "../../logger.h"
#include <mbgl/style/sources/vector_source.hpp>
#include <mbgl/util/tileset.hpp>
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion/tileset.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

napi_value VectorSourceHarmony::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_STATIC_FUNCTION("createWithUrl", CreateWithUrl),
        DECLARE_NAPI_STATIC_FUNCTION("createWithTileSet", CreateWithTileSet),
        DECLARE_NAPI_STATIC_FUNCTION("querySourceFeatures", QuerySourceFeatures),
    };

    napi_value vectorSourceObject;
    napi_create_object(env, &vectorSourceObject);
    napi_define_properties(env, vectorSourceObject,
        sizeof(properties) / sizeof(properties[0]),
        properties);

    napi_set_named_property(env, exports, "VectorSource", vectorSourceObject);

    return exports;
}

napi_value VectorSourceHarmony::CreateWithUrl(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        LOGE("VectorSource.CreateWithUrl: missing arguments");
        return CreateInt64Value(env, 0);
    }

    std::string sourceId = GetStringFromValue(env, args[0]);
    std::string url = GetStringFromValue(env, args[1]);

    try {
        auto source = std::make_unique<mbgl::style::VectorSource>(sourceId, url);
        int64_t sourcePtr = reinterpret_cast<int64_t>(source.release());
        LOGI("VectorSource.CreateWithUrl: %s (url: %s)", sourceId.c_str(), url.c_str());
        return CreateInt64Value(env, sourcePtr);
    } catch (const std::exception& e) {
        LOGE("VectorSource.CreateWithUrl failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

napi_value VectorSourceHarmony::CreateWithTileSet(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        LOGE("VectorSource.CreateWithTileSet: missing arguments");
        return CreateInt64Value(env, 0);
    }

    std::string sourceId = GetStringFromValue(env, args[0]);
    std::string tileSetJson = GetStringFromValue(env, args[1]);

    try {
        // 解析TileSet JSON
        mbgl::style::conversion::Error error;
        auto tileset = mbgl::style::conversion::convertJSON<mbgl::Tileset>(tileSetJson, error);
        
        if (tileset) {
            auto source = std::make_unique<mbgl::style::VectorSource>(sourceId, *tileset);
            int64_t sourcePtr = reinterpret_cast<int64_t>(source.release());
            LOGI("VectorSource.CreateWithTileSet: %s", sourceId.c_str());
            return CreateInt64Value(env, sourcePtr);
        } else {
            LOGE("VectorSource.CreateWithTileSet: failed to parse tileset: %s", error.message.c_str());
            return CreateInt64Value(env, 0);
        }
    } catch (const std::exception& e) {
        LOGE("VectorSource.CreateWithTileSet failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

napi_value VectorSourceHarmony::QuerySourceFeatures(napi_env env, napi_callback_info info) {
    // TODO: 实现查询要素
    return CreateStringValue(env, "[]");
}

} // namespace harmony
} // namespace mbgl

