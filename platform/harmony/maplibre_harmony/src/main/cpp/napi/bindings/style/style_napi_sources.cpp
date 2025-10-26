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
        if (status == napi_ok && backgroundLayer) {
            try {
                layerId = backgroundLayer->getId();
                auto layer = backgroundLayer->releaseLayer();
                if (!layer) {
                    napi_throw_error(env, nullptr, "Layer already added to style");
                    return nullptr;
                }
                style->map->getStyle().addLayer(std::move(layer));
                style->layers[layerId] = true;
                layerAdded = true;
                Logger::info("StyleNAPI", "AddLayer (BackgroundLayer): %s", layerId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddLayer (BackgroundLayer) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    // 5. RasterLayer
    if (!layerAdded) {
        RasterLayerNAPI* rasterLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&rasterLayer));
        if (status == napi_ok && rasterLayer) {
            try {
                layerId = rasterLayer->getId();
                auto layer = rasterLayer->releaseLayer();
                if (!layer) {
                    napi_throw_error(env, nullptr, "Layer already added to style");
                    return nullptr;
                }
                style->map->getStyle().addLayer(std::move(layer));
                style->layers[layerId] = true;
                layerAdded = true;
                Logger::info("StyleNAPI", "AddLayer (RasterLayer): %s", layerId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddLayer (RasterLayer) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    if (!layerAdded) {
        napi_throw_error(env, nullptr, "Invalid layer type or layer object");
        return nullptr;
    }
    
    return nullptr;
}

napi_value StyleNAPI::AddLayerBelow(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "AddLayerBelow requires 2 arguments: layer, belowLayerId");
        return nullptr;
    }
    
    napi_value layerValue = args[0];
    std::string belowLayerId = GetStringFromValue(env, args[1]);
    std::string layerId;
    std::unique_ptr<mbgl::style::Layer> layer;
    
    // Try to unwrap different layer types
    FillLayerNAPI* fillLayer = nullptr;
    napi_status status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&fillLayer));
    if (status == napi_ok && fillLayer) {
        layerId = fillLayer->getId();
        layer = fillLayer->releaseLayer();
    }
    
    if (!layer) {
        LineLayerNAPI* lineLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&lineLayer));
        if (status == napi_ok && lineLayer) {
            layerId = lineLayer->getId();
            layer = lineLayer->releaseLayer();
        }
    }
    
    if (!layer) {
        CircleLayerNAPI* circleLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&circleLayer));
        if (status == napi_ok && circleLayer) {
            layerId = circleLayer->getId();
            layer = circleLayer->releaseLayer();
        }
    }
    
    if (!layer) {
        BackgroundLayerNAPI* backgroundLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&backgroundLayer));
        if (status == napi_ok && backgroundLayer) {
            layerId = backgroundLayer->getId();
            layer = backgroundLayer->releaseLayer();
        }
    }
    
    if (!layer) {
        RasterLayerNAPI* rasterLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&rasterLayer));
        if (status == napi_ok && rasterLayer) {
            layerId = rasterLayer->getId();
            layer = rasterLayer->releaseLayer();
        }
    }
    
    if (!layer) {
        napi_throw_error(env, nullptr, "Invalid layer type or layer already added");
        return nullptr;
    }
    
    try {
        style->map->getStyle().addLayer(std::move(layer), belowLayerId);
        style->layers[layerId] = true;
        Logger::info("StyleNAPI", "AddLayerBelow: %s (below: %s)", layerId.c_str(), belowLayerId.c_str());
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddLayerBelow failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    return nullptr;
}

napi_value StyleNAPI::AddLayerAbove(napi_env env, napi_callback_info info) {
    // TODO: MapLibre Core doesn't have direct addLayerAbove
    // For now, treat as regular addLayer (adds to top)
    Logger::warn("StyleNAPI", "AddLayerAbove not fully implemented, adding to top");
    return AddLayer(env, info);
}

napi_value StyleNAPI::AddLayerAt(napi_env env, napi_callback_info info) {
    // TODO: Need to convert index to layer ID
    Logger::warn("StyleNAPI", "AddLayerAt not fully implemented, adding to top");
    return AddLayer(env, info);
}

napi_value StyleNAPI::RemoveLayer(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        return CreateBoolValue(env, false);
    }
    
    if (argc < 1) {
        return CreateBoolValue(env, false);
    }
    
    std::string layerId = GetStringFromValue(env, args[0]);
    
    try {
        style->map->getStyle().removeLayer(layerId);
        style->layers.erase(layerId);
        Logger::info("StyleNAPI", "RemoveLayer: %s", layerId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "RemoveLayer failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleNAPI::RemoveLayerAt(napi_env env, napi_callback_info info) {
    // TODO: 实现移除指定索引的图层
    return CreateBoolValue(env, false);
}

napi_value StyleNAPI::GetLayer(napi_env env, napi_callback_info info) {
    // TODO: 实现获取图层
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleNAPI::GetLayers(napi_env env, napi_callback_info info) {
    // TODO: 实现获取所有图层
    napi_value result;
    napi_create_array(env, &result);
    return result;
}

// ==================== Image 管理 ====================

napi_value StyleNAPI::AddImage(napi_env env, napi_callback_info info) {
    // TODO: 实现添加图片
    return nullptr;
}

napi_value StyleNAPI::RemoveImage(napi_env env, napi_callback_info info) {
    // TODO: 实现移除图片
    return CreateBoolValue(env, false);
}

napi_value StyleNAPI::GetImage(napi_env env, napi_callback_info info) {
    // TODO: 实现获取图片
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

// ==================== Light & Transition ====================

napi_value StyleNAPI::GetLight(napi_env env, napi_callback_info info) {
    // TODO: 实现获取光照
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleNAPI::SetLight(napi_env env, napi_callback_info info) {
    // TODO: 实现设置光照
    return nullptr;
}

napi_value StyleNAPI::GetTransition(napi_env env, napi_callback_info info) {
    // TODO: 实现获取过渡选项
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleNAPI::SetTransition(napi_env env, napi_callback_info info) {
    // TODO: 实现设置过渡选项
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

