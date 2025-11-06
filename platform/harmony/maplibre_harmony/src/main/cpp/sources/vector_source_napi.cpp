#include "vector_source_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

// Static member initialization
napi_ref VectorSourceNAPI::constructor = nullptr;

VectorSourceNAPI::VectorSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::VectorSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("VectorSourceNAPI", "VectorSource instance created: %s", id.c_str());
}

VectorSourceNAPI::VectorSourceNAPI(mbgl::style::VectorSource* sourcePtr)
    : ownsSource(false) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        weakSource = sourcePtr->makeWeakPtr();
        Logger::info("VectorSourceNAPI", "VectorSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

VectorSourceNAPI::~VectorSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("VectorSourceNAPI", "VectorSource instance destroyed: %s", id.c_str());
}

void VectorSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
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
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) {
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
        
        napi_status status = napi_wrap(env, args.This(), sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap VectorSource object");
            return nullptr;
        }
        
        Logger::info("VectorSourceNAPI", "VectorSource created: %s", sourceId.c_str());
    
    // 添加 _TYPE_ 属性用于 ETS 层的类型判断
    napi_value typeValue;
    napi_create_string_utf8(env, "VectorSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, args.This(), "_TYPE_", typeValue);
        return args.This();
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "Failed to create VectorSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value VectorSourceNAPI::CreateInstance(napi_env env, mbgl::style::VectorSource* sourcePtr) {
    if (!sourcePtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("VectorSourceNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建空对象并设置原型（避免调用 JS 构造函数）
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数的原型
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 设置对象的原型
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建 NAPI wrapper（使用 WeakPtr 构造函数）
    VectorSourceNAPI* napiObj = new VectorSourceNAPI(sourcePtr);
    
    // 包装到 JS 对象
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("VectorSourceNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 添加 _TYPE_ 属性
    napi_value typeValue;
    napi_create_string_utf8(env, "VectorSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}

napi_value VectorSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    VectorSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

napi_value VectorSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    VectorSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
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
        Logger::error("VectorSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

napi_value VectorSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    VectorSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    std::string url = args.GetString(0, "url");
    if (args.HasError()) return nullptr;
    
    // VectorSource 支持 setTiles 方法
    try {
        source->setTiles({url});
        Logger::info("VectorSourceNAPI", "SetUrl: %s -> %s", sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value VectorSourceNAPI::SetTiles(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    VectorSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    // 解析 tiles 数组
    napi_value tilesArray = args.GetArray(0, "tiles");
    if (args.HasError()) return nullptr;
    
    uint32_t arrayLength = 0;
    napi_get_array_length(env, tilesArray, &arrayLength);
    
    std::vector<std::string> tiles;
    tiles.reserve(arrayLength);
    
    for (uint32_t i = 0; i < arrayLength; ++i) {
        napi_value element;
        napi_get_element(env, tilesArray, i, &element);
        
        size_t strSize;
        napi_get_value_string_utf8(env, element, nullptr, 0, &strSize);
        std::string tile(strSize + 1, '\0');
        napi_get_value_string_utf8(env, element, &tile[0], strSize + 1, &strSize);
        tile.resize(strSize);
        
        tiles.push_back(tile);
    }
    
    try {
        // 更新 tiles
        source->setTiles(tiles);
        Logger::info("VectorSourceNAPI", "SetTiles: %s (%zu tiles)", sourceNapi->id.c_str(), tiles.size());
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "SetTiles failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

