#include "raster_source_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref RasterSourceNAPI::constructor = nullptr;

RasterSourceNAPI::RasterSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("RasterSourceNAPI", "RasterSource instance created: %s", id.c_str());
}

RasterSourceNAPI::~RasterSourceNAPI() {
    Logger::info("RasterSourceNAPI", "RasterSource instance destroyed: %s", id.c_str());
}

void RasterSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    Logger::debug("RasterSourceNAPI", "Destructor called");
    RasterSourceNAPI* sourceNapi = static_cast<RasterSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value RasterSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("RasterSourceNAPI", "Initializing RasterSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTileSize", nullptr, SetTileSize, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "RasterSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("RasterSourceNAPI", "Failed to define RasterSource class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("RasterSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "RasterSource", cons);
    if (status != napi_ok) {
        Logger::error("RasterSourceNAPI", "Failed to set RasterSource property");
        return nullptr;
    }
    
    Logger::info("RasterSourceNAPI", "RasterSource NAPI class initialized successfully");
    return exports;
}

napi_value RasterSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "RasterSource requires sourceId argument");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // RasterSource 需要 urlOrTileset 和 tileSize 参数
        // 使用空字符串和默认 tile size (512)
        mbgl::variant<std::string, mbgl::Tileset> urlOrTileset = std::string("");
        uint16_t tileSize = 512;
        auto source = std::make_unique<mbgl::style::RasterSource>(
            sourceId,
            std::move(urlOrTileset),
            tileSize
        );
        
        RasterSourceNAPI* sourceNapi = new RasterSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap RasterSource object");
            return nullptr;
        }
        
        Logger::info("RasterSourceNAPI", "RasterSource created: %s", sourceId.c_str());
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("RasterSourceNAPI", "Failed to create RasterSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value RasterSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

napi_value RasterSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        return CreateStringValue(env, "");
    }
    
    try {
        auto url = source->getURL();
        if (url) {
            return CreateStringValue(env, *url);
        }
    } catch (const std::exception& e) {
        Logger::error("RasterSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

napi_value RasterSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi || !sourceNapi->source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string url = args.GetString(0, "url");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    // NOTE: RasterSource 的 URL 在构造时设置，不能后续修改
    // 如果需要更改 URL，需要重新创建 Source 对象
    // TODO: 实现重新创建 Source 的逻辑
    Logger::warn("RasterSourceNAPI", "SetUrl is not supported for RasterSource. URL must be set during construction.");
    napi_throw_error(env, nullptr, "SetUrl is not supported. Please recreate the source with the new URL.");
    
    return nullptr;
}

napi_value RasterSourceNAPI::SetTileSize(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetTileSize requires tileSize argument");
        return nullptr;
    }
    
    uint32_t tileSize = 0;
    napi_get_value_uint32(env, args[0], &tileSize);
    
    if (tileSize == 0 || tileSize > 1024) {
        napi_throw_error(env, nullptr, "Invalid tile size (must be between 1 and 1024)");
        return nullptr;
    }
    
    // Note: RasterSource does not support changing tile size after creation.
    // Tile size must be specified in the constructor.
    Logger::info("RasterSourceNAPI", "SetTileSize not supported - tile size is immutable after source creation");
    napi_throw_error(env, nullptr, "RasterSource does not support changing tile size after creation. Please recreate the source with the desired tile size.");
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

