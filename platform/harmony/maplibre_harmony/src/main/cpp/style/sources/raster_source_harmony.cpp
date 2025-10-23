#include "raster_source_harmony.hpp"
#include "../../napi_utils.h"
#include "../../logger.h"
#include <mbgl/style/sources/raster_source.hpp>
#include <mbgl/util/tileset.hpp>
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion/tileset.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

napi_value RasterSourceHarmony::Init(napi_env env, napi_value exports) {
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_STATIC_FUNCTION("createWithUrl", CreateWithUrl),
        DECLARE_NAPI_STATIC_FUNCTION("createWithTileSet", CreateWithTileSet),
    };

    napi_value rasterSourceObject;
    napi_create_object(env, &rasterSourceObject);
    napi_define_properties(env, rasterSourceObject,
        sizeof(properties) / sizeof(properties[0]),
        properties);

    napi_set_named_property(env, exports, "RasterSource", rasterSourceObject);

    return exports;
}

napi_value RasterSourceHarmony::CreateWithUrl(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 3) {
        LOGE("RasterSource.CreateWithUrl: missing arguments");
        return CreateInt64Value(env, 0);
    }

    std::string sourceId = GetStringFromValue(env, args[0]);
    std::string url = GetStringFromValue(env, args[1]);
    double tileSize = GetDoubleFromValue(env, args[2]);

    try {
        auto source = std::make_unique<mbgl::style::RasterSource>(
            sourceId, 
            url, 
            static_cast<uint16_t>(tileSize)
        );
        int64_t sourcePtr = reinterpret_cast<int64_t>(source.release());
        LOGI("RasterSource.CreateWithUrl: %s (url: %s, tileSize: %d)", 
             sourceId.c_str(), url.c_str(), static_cast<int>(tileSize));
        return CreateInt64Value(env, sourcePtr);
    } catch (const std::exception& e) {
        LOGE("RasterSource.CreateWithUrl failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

napi_value RasterSourceHarmony::CreateWithTileSet(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 3) {
        LOGE("RasterSource.CreateWithTileSet: missing arguments");
        return CreateInt64Value(env, 0);
    }

    std::string sourceId = GetStringFromValue(env, args[0]);
    std::string tileSetJson = GetStringFromValue(env, args[1]);
    double tileSize = GetDoubleFromValue(env, args[2]);

    try {
        mbgl::style::conversion::Error error;
        auto tileset = mbgl::style::conversion::convertJSON<mbgl::Tileset>(tileSetJson, error);
        
        if (tileset) {
            auto source = std::make_unique<mbgl::style::RasterSource>(
                sourceId, 
                *tileset, 
                static_cast<uint16_t>(tileSize)
            );
            int64_t sourcePtr = reinterpret_cast<int64_t>(source.release());
            LOGI("RasterSource.CreateWithTileSet: %s", sourceId.c_str());
            return CreateInt64Value(env, sourcePtr);
        } else {
            LOGE("RasterSource.CreateWithTileSet: failed to parse tileset: %s", error.message.c_str());
            return CreateInt64Value(env, 0);
        }
    } catch (const std::exception& e) {
        LOGE("RasterSource.CreateWithTileSet failed: %s", e.what());
        return CreateInt64Value(env, 0);
    }
}

} // namespace harmony
} // namespace mbgl

