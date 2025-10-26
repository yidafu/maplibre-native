#include "vector_source_napi.hpp"
#include "../napi_args.hpp"
#include "../napi_utils.h"
#include "../logger.h"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref VectorSourceNAPI::constructor = nullptr;

VectorSourceNAPI::VectorSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::VectorSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("VectorSourceNAPI", "VectorSource instance created: %s", id.c_str());
}

VectorSourceNAPI::~VectorSourceNAPI() {
    Logger::info("VectorSourceNAPI", "VectorSource instance destroyed: %s", id.c_str());
}

void VectorSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    Logger::debug("VectorSourceNAPI", "Destructor called");
    VectorSourceNAPI* sourceNapi = static_cast<VectorSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value VectorSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("VectorSourceNAPI", "Initializing VectorSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTiles", nullptr, SetTiles, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "VectorSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("VectorSourceNAPI", "Failed to define VectorSource class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("VectorSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "VectorSource", cons);
    if (status != napi_ok) {
        Logger::error("VectorSourceNAPI", "Failed to set VectorSource property");
        return nullptr;
    }
    
    Logger::info("VectorSourceNAPI", "VectorSource NAPI class initialized successfully");
    return exports;
}

napi_value VectorSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "VectorSource requires sourceId argument");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // VectorSource 需要 urlOrTileset 参数
        // 使用空字符串作为默认值，后续通过 setURL 设置
        mbgl::variant<std::string, mbgl::Tileset> urlOrTileset = std::string("");
        auto source = std::make_unique<mbgl::style::VectorSource>(
            sourceId,
            std::move(urlOrTileset)
        );
        
        VectorSourceNAPI* sourceNapi = new VectorSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap VectorSource object");
            return nullptr;
        }
        
        Logger::info("VectorSourceNAPI", "VectorSource created: %s", sourceId.c_str());
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "Failed to create VectorSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value VectorSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    VectorSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

napi_value VectorSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    VectorSourceNAPI* sourceNapi = nullptr;
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
        Logger::error("VectorSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

napi_value VectorSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    VectorSourceNAPI* sourceNapi = nullptr;
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
    
    // VectorSource 支持 setTiles 方法
    try {
        sourceNapi->source->setTiles({url});
        Logger::info("VectorSourceNAPI", "SetUrl: %s -> %s", sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value VectorSourceNAPI::SetTiles(napi_env env, napi_callback_info info) {
    // TODO: 实现 setTiles
    Logger::warn("VectorSourceNAPI", "SetTiles not implemented yet");
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

