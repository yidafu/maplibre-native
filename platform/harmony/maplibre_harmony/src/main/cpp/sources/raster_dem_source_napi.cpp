#include "raster_dem_source_napi.hpp"
#include "../napi_args.hpp"
#include "../napi_utils.h"
#include "../logger.h"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

napi_ref RasterDemSourceNAPI::constructor = nullptr;

RasterDemSourceNAPI::RasterDemSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterDEMSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("RasterDemSourceNAPI", "RasterDemSource instance created: %s", id.c_str());
}

RasterDemSourceNAPI::~RasterDemSourceNAPI() {
    Logger::info("RasterDemSourceNAPI", "RasterDemSource instance destroyed: %s", id.c_str());
}

void RasterDemSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    RasterDemSourceNAPI* sourceNapi = static_cast<RasterDemSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value RasterDemSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("RasterDemSourceNAPI", "Initializing RasterDemSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "RasterDemSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("RasterDemSourceNAPI", "Failed to define RasterDemSource class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("RasterDemSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "RasterDemSource", cons);
    if (status != napi_ok) {
        Logger::error("RasterDemSourceNAPI", "Failed to set RasterDemSource property");
        return nullptr;
    }
    
    Logger::info("RasterDemSourceNAPI", "RasterDemSource NAPI class initialized successfully");
    return exports;
}

napi_value RasterDemSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "RasterDemSource requires sourceId argument");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // RasterDEMSource 需要 urlOrTileset, tileSize 和 options 参数
        // 使用空字符串和默认值
        mbgl::variant<std::string, mbgl::Tileset> urlOrTileset = std::string("");
        uint16_t tileSize = 512;
        std::optional<mbgl::style::RasterDEMOptions> options = std::nullopt;
        auto source = std::make_unique<mbgl::style::RasterDEMSource>(
            sourceId,
            std::move(urlOrTileset),
            tileSize,
            std::move(options)
        );
        RasterDemSourceNAPI* sourceNapi = new RasterDemSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap RasterDemSource object");
            return nullptr;
        }
        
        Logger::info("RasterDemSourceNAPI", "RasterDemSource created: %s", sourceId.c_str());
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("RasterDemSourceNAPI", "Failed to create RasterDemSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value RasterDemSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterDemSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

napi_value RasterDemSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterDemSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi || !sourceNapi->source) {
        return CreateStringValue(env, "");
    }
    
    try {
        auto url = sourceNapi->source->getURL();
        if (url) {
            return CreateStringValue(env, *url);
        }
    } catch (const std::exception& e) {
        Logger::error("RasterDemSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

napi_value RasterDemSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterDemSourceNAPI* sourceNapi = nullptr;
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
    
    // NOTE: RasterDEMSource 的 URL 在构造时设置，不能后续修改
    // 如果需要更改 URL，需要重新创建 Source 对象
    // TODO: 实现重新创建 Source 的逻辑
    Logger::warn("RasterDemSourceNAPI", "SetUrl is not supported for RasterDEMSource. URL must be set during construction.");
    napi_throw_error(env, nullptr, "SetUrl is not supported. Please recreate the source with the new URL.");
    
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

