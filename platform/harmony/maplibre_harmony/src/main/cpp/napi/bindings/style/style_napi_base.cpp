#include "style/style_napi.hpp"
#include "../../napi/core/napi_args.hpp"
#include "../../napi/core/napi_utils.h"
#include "../../utils/logger.h"
#include <mbgl/style/style.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/layer.hpp>
// Source NAPI 类
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref StyleNAPI::constructor = nullptr;

StyleNAPI::StyleNAPI(mbgl::Map* map)
    : map(map), fullyLoaded(false) {
    Logger::info("StyleNAPI", "StyleNAPI instance created");
}

StyleNAPI::~StyleNAPI() {
    Logger::info("StyleNAPI", "StyleNAPI instance destroyed");
}

void StyleNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    Logger::debug("StyleNAPI", "Destructor called");
    StyleNAPI* style = static_cast<StyleNAPI*>(nativeObject);
    delete style;
}

napi_value StyleNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("StyleNAPI", "Initializing Style NAPI class");
    
    napi_property_descriptor properties[] = {
        // Getters
        { "getUri", nullptr, GetUri, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getJson", nullptr, GetJson, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isFullyLoaded", nullptr, IsFullyLoaded, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Source 管理
        { "addSource", nullptr, AddSource, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeSource", nullptr, RemoveSource, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSource", nullptr, GetSource, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSources", nullptr, GetSources, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer 管理
        { "addLayer", nullptr, AddLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addLayerBelow", nullptr, AddLayerBelow, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addLayerAbove", nullptr, AddLayerAbove, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addLayerAt", nullptr, AddLayerAt, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeLayer", nullptr, RemoveLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeLayerAt", nullptr, RemoveLayerAt, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLayer", nullptr, GetLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLayers", nullptr, GetLayers, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Image 管理
        { "addImage", nullptr, AddImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeImage", nullptr, RemoveImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getImage", nullptr, GetImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Light & Transition
        { "getLight", nullptr, GetLight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLight", nullptr, SetLight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTransition", nullptr, GetTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTransition", nullptr, SetTransition, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Style", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("StyleNAPI", "Failed to define Style class");
        return nullptr;
    }
    
    // 创建构造函数引用
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("StyleNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    // 将构造函数添加到 exports
    status = napi_set_named_property(env, exports, "Style", cons);
    if (status != napi_ok) {
        Logger::error("StyleNAPI", "Failed to set Style property");
        return nullptr;
    }
    
    Logger::info("StyleNAPI", "Style NAPI class initialized successfully");
    return exports;
}

napi_value StyleNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    // 检查参数
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Style constructor requires mapPtr argument");
        return nullptr;
    }
    
    // 获取 mapPtr
    int64_t mapPtr;
    napi_status status = napi_get_value_int64(env, args[0], &mapPtr);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to get mapPtr argument");
        return nullptr;
    }
    
    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);
    if (!map) {
        napi_throw_error(env, nullptr, "Invalid mapPtr");
        return nullptr;
    }
    
    // 创建 C++ 对象
    StyleNAPI* style = new StyleNAPI(map);
    
    // Wrap 到 JS 对象
    status = napi_wrap(env, jsThis, style, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete style;
        napi_throw_error(env, nullptr, "Failed to wrap StyleNAPI object");
        return nullptr;
    }
    
    Logger::debug("StyleNAPI", "Style instance created");
    return jsThis;
}

// ==================== Getters ====================

napi_value StyleNAPI::GetUri(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        return CreateStringValue(env, "");
    }
    
    try {
        std::string uri = style->map->getStyle().getURL();
        return CreateStringValue(env, uri);
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetUri failed: %s", e.what());
        return CreateStringValue(env, "");
    }
}

napi_value StyleNAPI::GetJson(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        return CreateStringValue(env, "");
    }
    
    try {
        std::string json = style->map->getStyle().getJSON();
        return CreateStringValue(env, json);
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetJson failed: %s", e.what());
        return CreateStringValue(env, "");
    }
}

napi_value StyleNAPI::IsFullyLoaded(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style) {
        return CreateBoolValue(env, false);
    }
    
    return CreateBoolValue(env, style->fullyLoaded);
}

// ==================== Source 管理 ====================

napi_value StyleNAPI::AddSource(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        Logger::error("StyleNAPI", "AddSource: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "AddSource requires source argument");
        return nullptr;
    }
    
    napi_value sourceValue = args[0];
    std::string sourceId;
    bool sourceAdded = false;
    
    // 尝试unwrap各种Source类型
    // 1. GeoJsonSource
    GeoJsonSourceNAPI* geoJsonSource = nullptr;
    napi_status status = napi_unwrap(env, sourceValue, reinterpret_cast<void**>(&geoJsonSource));
    if (status == napi_ok && geoJsonSource) {
        try {
            sourceId = geoJsonSource->getId();
            auto source = geoJsonSource->releaseSource();
            if (!source) {
                napi_throw_error(env, nullptr, "Source already added to style");
                return nullptr;
            }
            style->map->getStyle().addSource(std::move(source));
            style->sources[sourceId] = true;
            sourceAdded = true;
            Logger::info("StyleNAPI", "AddSource (GeoJsonSource): %s", sourceId.c_str());
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "AddSource (GeoJsonSource) failed: %s", e.what());
            napi_throw_error(env, nullptr, e.what());
            return nullptr;
        }
    }
    
    // 2. VectorSource
