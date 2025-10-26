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
    if (!sourceAdded) {
        VectorSourceNAPI* vectorSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void**>(&vectorSource));
        if (status == napi_ok && vectorSource) {
            try {
                sourceId = vectorSource->getId();
                auto source = vectorSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;
                Logger::info("StyleNAPI", "AddSource (VectorSource): %s", sourceId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddSource (VectorSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    // 3. RasterSource
    if (!sourceAdded) {
        RasterSourceNAPI* rasterSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void**>(&rasterSource));
        if (status == napi_ok && rasterSource) {
            try {
                sourceId = rasterSource->getId();
                auto source = rasterSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;
                Logger::info("StyleNAPI", "AddSource (RasterSource): %s", sourceId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddSource (RasterSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    // 4. RasterDemSource
    if (!sourceAdded) {
        RasterDemSourceNAPI* rasterDemSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void**>(&rasterDemSource));
        if (status == napi_ok && rasterDemSource) {
            try {
                sourceId = rasterDemSource->getId();
                auto source = rasterDemSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;
                Logger::info("StyleNAPI", "AddSource (RasterDemSource): %s", sourceId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddSource (RasterDemSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    // 5. ImageSource
    if (!sourceAdded) {
        ImageSourceNAPI* imageSource = nullptr;
        status = napi_unwrap(env, sourceValue, reinterpret_cast<void**>(&imageSource));
        if (status == napi_ok && imageSource) {
            try {
                sourceId = imageSource->getId();
                auto source = imageSource->releaseSource();
                if (!source) {
                    napi_throw_error(env, nullptr, "Source already added to style");
                    return nullptr;
                }
                style->map->getStyle().addSource(std::move(source));
                style->sources[sourceId] = true;
                sourceAdded = true;
                Logger::info("StyleNAPI", "AddSource (ImageSource): %s", sourceId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddSource (ImageSource) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    if (!sourceAdded) {
        napi_throw_error(env, nullptr, "Invalid source type or source object");
        return nullptr;
    }
    
    return nullptr;
}

napi_value StyleNAPI::RemoveSource(napi_env env, napi_callback_info info) {
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
    
    std::string sourceId = GetStringFromValue(env, args[0]);
    
    try {
        style->map->getStyle().removeSource(sourceId);
        style->sources.erase(sourceId);
        Logger::info("StyleNAPI", "RemoveSource: %s", sourceId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "RemoveSource failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleNAPI::GetSource(napi_env env, napi_callback_info info) {
    // TODO: 实现获取数据源
    // 需要将 mbgl::style::Source* 转换为 NAPI 对象
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleNAPI::GetSources(napi_env env, napi_callback_info info) {
    // TODO: 实现获取所有数据源
    // 返回空数组
    napi_value result;
    napi_create_array(env, &result);
    return result;
}

// ==================== Layer 管理 ====================

napi_value StyleNAPI::AddLayer(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        Logger::error("StyleNAPI", "AddLayer: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "AddLayer requires layer argument");
        return nullptr;
    }
    
    napi_value layerValue = args[0];
    std::string layerId;
    bool layerAdded = false;
    
    // 尝试unwrap各种Layer类型
    // 1. FillLayer
    FillLayerNAPI* fillLayer = nullptr;
    napi_status status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&fillLayer));
    if (status == napi_ok && fillLayer) {
        try {
            layerId = fillLayer->getId();
            auto layer = fillLayer->releaseLayer();
            if (!layer) {
                napi_throw_error(env, nullptr, "Layer already added to style");
                return nullptr;
            }
            style->map->getStyle().addLayer(std::move(layer));
            style->layers[layerId] = true;
            layerAdded = true;
            Logger::info("StyleNAPI", "AddLayer (FillLayer): %s", layerId.c_str());
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "AddLayer (FillLayer) failed: %s", e.what());
            napi_throw_error(env, nullptr, e.what());
            return nullptr;
        }
    }
    
    // 2. LineLayer
    if (!layerAdded) {
        LineLayerNAPI* lineLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&lineLayer));
        if (status == napi_ok && lineLayer) {
            try {
                layerId = lineLayer->getId();
                auto layer = lineLayer->releaseLayer();
                if (!layer) {
                    napi_throw_error(env, nullptr, "Layer already added to style");
                    return nullptr;
                }
                style->map->getStyle().addLayer(std::move(layer));
                style->layers[layerId] = true;
                layerAdded = true;
                Logger::info("StyleNAPI", "AddLayer (LineLayer): %s", layerId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddLayer (LineLayer) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    // 3. CircleLayer
    if (!layerAdded) {
        CircleLayerNAPI* circleLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&circleLayer));
        if (status == napi_ok && circleLayer) {
            try {
                layerId = circleLayer->getId();
                auto layer = circleLayer->releaseLayer();
                if (!layer) {
                    napi_throw_error(env, nullptr, "Layer already added to style");
                    return nullptr;
                }
                style->map->getStyle().addLayer(std::move(layer));
                style->layers[layerId] = true;
                layerAdded = true;
                Logger::info("StyleNAPI", "AddLayer (CircleLayer): %s", layerId.c_str());
            } catch (const std::exception& e) {
                Logger::error("StyleNAPI", "AddLayer (CircleLayer) failed: %s", e.what());
                napi_throw_error(env, nullptr, e.what());
                return nullptr;
            }
        }
    }
    
    // 4. BackgroundLayer
    if (!layerAdded) {
        BackgroundLayerNAPI* backgroundLayer = nullptr;
        status = napi_unwrap(env, layerValue, reinterpret_cast<void**>(&backgroundLayer));
