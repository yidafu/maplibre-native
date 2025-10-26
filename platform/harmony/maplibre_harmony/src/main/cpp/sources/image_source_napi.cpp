#include "image_source_napi.hpp"
#include "../napi_args.hpp"
#include "../napi_utils.h"
#include "../logger.h"
#include <mbgl/util/geo.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

napi_ref ImageSourceNAPI::constructor = nullptr;

ImageSourceNAPI::ImageSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::ImageSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("ImageSourceNAPI", "ImageSource instance created: %s", id.c_str());
}

ImageSourceNAPI::~ImageSourceNAPI() {
    Logger::info("ImageSourceNAPI", "ImageSource instance destroyed: %s", id.c_str());
}

void ImageSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    ImageSourceNAPI* sourceNapi = static_cast<ImageSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value ImageSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("ImageSourceNAPI", "Initializing ImageSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "ImageSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("ImageSourceNAPI", "Failed to define ImageSource class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("ImageSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "ImageSource", cons);
    if (status != napi_ok) {
        Logger::error("ImageSourceNAPI", "Failed to set ImageSource property");
        return nullptr;
    }
    
    Logger::info("ImageSourceNAPI", "ImageSource NAPI class initialized successfully");
    return exports;
}

napi_value ImageSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "ImageSource requires sourceId argument");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // TODO: 解析 coordinates 参数
        // 使用默认坐标创建
        std::array<mbgl::LatLng, 4> coords = {{
            mbgl::LatLng{0, 0}, mbgl::LatLng{0, 0},
            mbgl::LatLng{0, 0}, mbgl::LatLng{0, 0}
        }};
        
        auto source = std::make_unique<mbgl::style::ImageSource>(sourceId, coords);
        ImageSourceNAPI* sourceNapi = new ImageSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap ImageSource object");
            return nullptr;
        }
        
        Logger::info("ImageSourceNAPI", "ImageSource created: %s", sourceId.c_str());
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("ImageSourceNAPI", "Failed to create ImageSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value ImageSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

napi_value ImageSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageSourceNAPI* sourceNapi = nullptr;
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
    
    try {
        sourceNapi->source->setURL(url);
        Logger::info("ImageSourceNAPI", "SetUrl: %s -> %s", sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("ImageSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value ImageSourceNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    // TODO: 实现坐标设置
    Logger::warn("ImageSourceNAPI", "SetCoordinates not implemented yet");
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

