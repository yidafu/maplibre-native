#include "style_napi.hpp"
#include "style/layers/color_relief_layer_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/style/style.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/layer.hpp>
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/layers/line_layer.hpp>
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/layers/symbol_layer.hpp>
#include <mbgl/style/layers/raster_layer.hpp>
#include <mbgl/style/layers/background_layer.hpp>
#include <mbgl/style/layers/heatmap_layer.hpp>
#include <mbgl/style/layers/hillshade_layer.hpp>
#include <mbgl/style/layers/fill_extrusion_layer.hpp>
#include <mbgl/style/layers/location_indicator_layer.hpp>
#include <vector>

// Helper function to convert SourceType enum to string
static const char *sourceTypeToString(mbgl::style::SourceType type) {
    switch (type) {
    case mbgl::style::SourceType::Vector:
        return "vector";
    case mbgl::style::SourceType::Raster:
        return "raster";
    case mbgl::style::SourceType::RasterDEM:
        return "raster-dem";
    case mbgl::style::SourceType::GeoJSON:
        return "geojson";
    case mbgl::style::SourceType::Image:
        return "image";
    default:
        return "unknown";
    }
}

// Reads the _TYPE_ marker set by every layer NAPI constructor. Returns ""
// when the value is missing — callers must treat that as "not a layer"
// because napi_unwrap alone cannot tell NAPI classes apart.
static std::string ReadLayerType(napi_env env, napi_value layerValue) {
    napi_value typeValue = nullptr;
    if (napi_get_named_property(env, layerValue, "_TYPE_", &typeValue) != napi_ok || !typeValue) {
        return "";
    }
    size_t typeLen = 0;
    if (napi_get_value_string_utf8(env, typeValue, nullptr, 0, &typeLen) != napi_ok || typeLen == 0) {
        return "";
    }
    std::string typeBuffer(typeLen, '\0');
    if (napi_get_value_string_utf8(env, typeValue, typeBuffer.data(), typeLen + 1, nullptr) != napi_ok) {
        return "";
    }
    return typeBuffer;
}

// Source NAPI classes
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"
// Layer NAPI classes
#include "style/layers/fill_layer_harmony.hpp"
#include "style/layers/line_layer_harmony.hpp"
#include "style/layers/circle_layer_harmony.hpp"
#include "style/layers/symbol_layer_harmony.hpp"
#include "style/layers/raster_layer_harmony.hpp"
#include "style/layers/background_layer_harmony.hpp"
#include "style/layers/heatmap_layer_harmony.hpp"
#include "style/layers/hillshade_layer_harmony.hpp"
#include "style/layers/fill_extrusion_layer_harmony.hpp"
#include "style/layers/location_indicator_layer_harmony.hpp"
#include "custom_layer_napi.hpp"
#include "custom_drawable_layer_napi.hpp"
#include <mbgl/style/layers/custom_drawable_layer.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

// Note: Constructor, Destructor, and static member are defined in style_napi_base.cpp
// Note: Source-related functions (AddSource, RemoveSource, GetSource, GetSources) are defined in style_napi_sources.cpp

// This file contains Layer-related functions for StyleNAPI

// Placeholder for AddSource - actual implementation is in style_napi_sources.cpp or style_napi_base.cpp
// ==================== Layer management ====================

// ⚠️ THREAD SAFETY NOTE — AddLayer & the onStyleLoaded crash
//
// This function is called from the main (UI/JS) thread but directly mutates the
// core mbgl::style::Style object via style->map->getStyle().addLayer().
// The render thread concurrently reads the same Style internal data (layers,
// sources collections) during frame rendering — this is a DATA RACE.
//
// Crash signature: SIGSEGV @0x8 inside Style::Impl::addLayer() (style_impl.cpp:212)
//   Address 0x8 = Layer::baseImpl at offset 8 from null Layer*
//   The Layer* becomes null when the style's internal collection is corrupted
//   by concurrent read/write from the render thread.
//
// Trigger path:
//   [Render Thread] onDidFinishLoadingStyle → notifyStyleLoaded() (async)
//   [Main Thread]   onStyleLoaded → MarkerManager → MarkerLayerManager.initialize()
//                   → Style.addLayer() → StyleNAPI::AddLayer() → core addLayer()
//   [Render Thread] simultaneously reading style layers to render a frame
//
// Additional risk: style->map is a RAW POINTER stored in StyleNAPI (see style_napi.hpp).
//   If NativeMapView reinitializes the renderer (map = nullptr; map = newMap),
//   style->map becomes a DANGLING POINTER that the !style->map guard cannot detect.
//
// === FIX GUIDANCE ===
// 1. Queue AddLayer operations to the render thread instead of calling addLayer
//    directly (use RendererFrontend or similar marshalling mechanism)
// 2. OR add a mutex around Style internal state (layers/sources collections)
// 3. OR ensure StyleNAPI::map is updated when the Map object is recreated
//    (e.g., via a callback from NativeMapView to all StyleNAPI instances)
// ========================================================================
// ============================================================================
// Layer dispatch tables
//
// napi_unwrap cannot tell NAPI classes apart, so every layer argument is
// type-gated through the _TYPE_ marker (ReadLayerType) and then dispatched
// through the tables below instead of a dozen hand-written branches per
// function. AddLayer/Below/Above/At share the same extract + commit path;
// commit always runs on the render thread and always reconnects the JS
// wrapper (attachToStyle), which the Below/Above/At paths used to skip.
// ============================================================================

// Result of trying to extract a pending layer from a JS wrapper.
enum class LayerExtract {
    NotThisType, // the JS object is not this NAPI class; try the next entry
    Ok,          // layer extracted and reattach callback prepared
    Failed,      // terminal failure (error already thrown to JS)
};

// Unwrap layerValue as NapiT, pull the native layer out for style insertion,
// and prepare the callback that reconnects the wrapper once the layer has
// been committed on the render thread.
template <typename NapiT, typename StyleLayerT>
LayerExtract TryExtractLayer(napi_env env, napi_value layerValue,
                             std::unique_ptr<mbgl::style::Layer> &pendingLayer,
                             std::function<void(mbgl::style::Layer *)> &pendingAttach,
                             std::string &layerId) {
    NapiT *napiLayer = nullptr;
    if (napi_unwrap(env, layerValue, reinterpret_cast<void **>(&napiLayer)) != napi_ok || !napiLayer) {
        return LayerExtract::NotThisType;
    }
    try {
        auto *layer = napiLayer->getLayer();
        if (!layer) {
            return LayerExtract::NotThisType;
        }
        layerId = layer->getID();
        auto released = napiLayer->releaseLayer();
        if (!released) {
            napi_throw_error(env, nullptr, "Layer already added to style");
            return LayerExtract::Failed;
        }
        pendingLayer = std::move(released);
        pendingAttach = [napiLayer](mbgl::style::Layer *styleLayer) {
            if (auto *typed = dynamic_cast<StyleLayerT *>(styleLayer)) {
                napiLayer->attachToStyle(typed);
            }
        };
        return LayerExtract::Ok;
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "AddLayer extract failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return LayerExtract::Failed;
    }
}

template <typename NapiT, typename StyleLayerT>
LayerExtract ExtractThunk(napi_env env, napi_value layerValue,
                          std::unique_ptr<mbgl::style::Layer> &pendingLayer,
                          std::function<void(mbgl::style::Layer *)> &pendingAttach,
                          std::string &layerId) {
    return TryExtractLayer<NapiT, StyleLayerT>(env, layerValue, pendingLayer, pendingAttach, layerId);
}

struct LayerExtractEntry {
    const char *jsType; // _TYPE_ marker set by the ETS wrapper
    LayerExtract (*extract)(napi_env, napi_value,
                            std::unique_ptr<mbgl::style::Layer> &,
                            std::function<void(mbgl::style::Layer *)> &,
                            std::string &);
};

const LayerExtractEntry kLayerExtractors[] = {
    {"FillLayer", &ExtractThunk<mbgl::harmony::FillLayerNAPI, mbgl::style::FillLayer>},
    {"LineLayer", &ExtractThunk<mbgl::harmony::LineLayerNAPI, mbgl::style::LineLayer>},
    {"CircleLayer", &ExtractThunk<mbgl::harmony::CircleLayerNAPI, mbgl::style::CircleLayer>},
    {"SymbolLayer", &ExtractThunk<mbgl::harmony::SymbolLayerNAPI, mbgl::style::SymbolLayer>},
    {"RasterLayer", &ExtractThunk<mbgl::harmony::RasterLayerNAPI, mbgl::style::RasterLayer>},
    {"BackgroundLayer", &ExtractThunk<mbgl::harmony::BackgroundLayerNAPI, mbgl::style::BackgroundLayer>},
    {"HeatmapLayer", &ExtractThunk<mbgl::harmony::HeatmapLayerNAPI, mbgl::style::HeatmapLayer>},
    {"HillshadeLayer", &ExtractThunk<mbgl::harmony::HillshadeLayerNAPI, mbgl::style::HillshadeLayer>},
    {"FillExtrusionLayer", &ExtractThunk<mbgl::harmony::FillExtrusionLayerNAPI, mbgl::style::FillExtrusionLayer>},
    {"LocationIndicatorLayer", &ExtractThunk<mbgl::harmony::LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer>},
    {"ColorReliefLayer", &ExtractThunk<mbgl::harmony::ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer>},
    {"CustomLayer", &ExtractThunk<mbgl::harmony::CustomLayerNAPI, mbgl::style::CustomLayer>},
    {"CustomDrawableLayer", &ExtractThunk<mbgl::harmony::CustomDrawableLayerNAPI, mbgl::style::CustomDrawableLayer>},
};

LayerExtract DispatchLayerExtract(napi_env env, napi_value layerValue, const std::string &layerType,
                                  std::unique_ptr<mbgl::style::Layer> &pendingLayer,
                                  std::function<void(mbgl::style::Layer *)> &pendingAttach,
                                  std::string &layerId) {
    for (const auto &entry : kLayerExtractors) {
        if (layerType == entry.jsType) {
            LayerExtract result = entry.extract(env, layerValue, pendingLayer, pendingAttach, layerId);
            if (result == LayerExtract::Ok) {
                Logger::info("StyleNAPI", "%s: %s", layerType.c_str(), layerId.c_str());
            }
            return result;
        }
    }
    return LayerExtract::NotThisType;
}

// Commit a pending layer on the render thread (the renderer reads the style's
// layer collection every frame; mutating it from the JS thread is a data race,
// documented SIGSEGV@0x8) and reconnect the JS wrapper to the committed layer.
bool CommitLayerAdd(napi_env env, StyleNAPI *style, const std::string &layerId,
                    std::unique_ptr<mbgl::style::Layer> pendingLayer,
                    std::function<void(mbgl::style::Layer *)> pendingAttach,
                    std::optional<std::string> beforeLayerId, const char *opName) {
    try {
        style->runOnMap([&](mbgl::Map &m) {
            m.getStyle().addLayer(std::move(pendingLayer), beforeLayerId);
            if (pendingAttach) {
                pendingAttach(m.getStyle().getLayer(layerId));
            }
        });
        Logger::info("StyleNAPI", "%s: %s", opName, layerId.c_str());
        return true;
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "%s failed: %s", opName, e.what());
        napi_throw_error(env, nullptr, e.what());
        return false;
    }
}

template <typename NapiT, typename StyleLayerT>
napi_value CreateLayerPeerThunk(napi_env env, mbgl::style::Layer *layer) {
    return NapiT::CreateInstance(env, static_cast<StyleLayerT *>(layer));
}

// Build the NAPI peer for a live style layer, dispatching on the core
// type-info string (shared by GetLayer and GetLayers).
napi_value CreateLayerInstanceByType(napi_env env, const std::string &layerType, mbgl::style::Layer *layer) {
    struct LayerCreatorEntry {
        const char *typeInfo;
        napi_value (*create)(napi_env, mbgl::style::Layer *);
    };
    static const LayerCreatorEntry kCreators[] = {
        {"symbol", &CreateLayerPeerThunk<mbgl::harmony::SymbolLayerNAPI, mbgl::style::SymbolLayer>},
        {"fill", &CreateLayerPeerThunk<mbgl::harmony::FillLayerNAPI, mbgl::style::FillLayer>},
        {"line", &CreateLayerPeerThunk<mbgl::harmony::LineLayerNAPI, mbgl::style::LineLayer>},
        {"circle", &CreateLayerPeerThunk<mbgl::harmony::CircleLayerNAPI, mbgl::style::CircleLayer>},
        {"raster", &CreateLayerPeerThunk<mbgl::harmony::RasterLayerNAPI, mbgl::style::RasterLayer>},
        {"heatmap", &CreateLayerPeerThunk<mbgl::harmony::HeatmapLayerNAPI, mbgl::style::HeatmapLayer>},
        {"hillshade", &CreateLayerPeerThunk<mbgl::harmony::HillshadeLayerNAPI, mbgl::style::HillshadeLayer>},
        {"fill-extrusion", &CreateLayerPeerThunk<mbgl::harmony::FillExtrusionLayerNAPI, mbgl::style::FillExtrusionLayer>},
        {"background", &CreateLayerPeerThunk<mbgl::harmony::BackgroundLayerNAPI, mbgl::style::BackgroundLayer>},
        {"color-relief", &CreateLayerPeerThunk<mbgl::harmony::ColorReliefLayerNAPI, mbgl::style::ColorReliefLayer>},
        {"location-indicator", &CreateLayerPeerThunk<mbgl::harmony::LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer>},
        {"custom-drawable", &CreateLayerPeerThunk<mbgl::harmony::CustomDrawableLayerNAPI, mbgl::style::CustomDrawableLayer>},
    };
    for (const auto &entry : kCreators) {
        if (layerType == entry.typeInfo) {
            return entry.create(env, layer);
        }
    }
    Logger::warn("StyleNAPI", "Unknown layer type: %s", layerType.c_str());
    napi_value null_value;
    napi_get_null(env, &null_value);
    return null_value;
}

napi_value StyleNAPI::AddLayer(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value layerValue = napiArgs.GetValue(0);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "AddLayer: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    // napi_unwrap is type-agnostic: unwrapping an object of the wrong NAPI
    // class reinterprets its native pointer, so the _TYPE_ marker is mandatory.
    std::string layerType = ReadLayerType(env, layerValue);
    if (layerType.empty()) {
        napi_throw_error(env, nullptr, "AddLayer: value is not a layer instance created by this SDK (missing _TYPE_)");
        return nullptr;
    }

    std::string layerId;
    std::unique_ptr<mbgl::style::Layer> pendingLayer;
    std::function<void(mbgl::style::Layer *)> pendingAttach;
    LayerExtract result = DispatchLayerExtract(env, layerValue, layerType, pendingLayer, pendingAttach, layerId);
    if (result != LayerExtract::Ok) {
        if (result == LayerExtract::NotThisType) {
            napi_throw_error(env, nullptr, "Invalid layer type or layer object");
        }
        return nullptr;
    }

    if (CommitLayerAdd(env, style, layerId, std::move(pendingLayer), std::move(pendingAttach),
                       std::nullopt, "AddLayer")) {
        style->layers[layerId] = true;
    }
    return nullptr;
}

napi_value StyleNAPI::AddLayerBelow(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(2);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value layerValue = napiArgs.GetValue(0);
    napi_value belowValue = napiArgs.GetValue(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }
    std::string belowLayerId = GetStringFromValue(env, belowValue);

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "AddLayerBelow: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    std::string layerType = ReadLayerType(env, layerValue);
    if (layerType.empty()) {
        napi_throw_error(env, nullptr, "AddLayerBelow: value is not a layer instance created by this SDK (missing _TYPE_)");
        return nullptr;
    }

    std::string layerId;
    std::unique_ptr<mbgl::style::Layer> pendingLayer;
    std::function<void(mbgl::style::Layer *)> pendingAttach;
    LayerExtract result = DispatchLayerExtract(env, layerValue, layerType, pendingLayer, pendingAttach, layerId);
    if (result != LayerExtract::Ok) {
        if (result == LayerExtract::NotThisType) {
            napi_throw_error(env, nullptr, "Invalid layer type or layer object");
        }
        return nullptr;
    }

    if (CommitLayerAdd(env, style, layerId, std::move(pendingLayer), std::move(pendingAttach),
                       std::optional<std::string>(belowLayerId), "AddLayerBelow")) {
        style->layers[layerId] = true;
    }
    return nullptr;
}

napi_value StyleNAPI::RemoveLayer(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    size_t argc = napiArgs.Count();
    std::vector<napi_value> argsVec(argc);
    for (size_t i = 0; i < argc; ++i) {
        argsVec[i] = napiArgs.GetValue(i);
        if (napiArgs.HasError()) {
            return nullptr;
        }
    }
    napi_value* args = argsVec.data();

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->acquireMap()) {
        return CreateBoolValue(env, false);
    }

    if (argc < 1) {
        return CreateBoolValue(env, false);
    }

    std::string layerId = GetStringFromValue(env, args[0]);

    try {
        style->runOnMap([&](mbgl::Map &m) {
            m.getStyle().removeLayer(layerId);
        });
        style->layers.erase(layerId);
        Logger::info("StyleNAPI", "RemoveLayer: %s", layerId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "RemoveLayer failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleNAPI::GetLayer(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    size_t argc = napiArgs.Count();
    std::vector<napi_value> argsVec(argc);
    for (size_t i = 0; i < argc; ++i) {
        argsVec[i] = napiArgs.GetValue(i);
        if (napiArgs.HasError()) {
            return nullptr;
        }
    }
    napi_value* args = argsVec.data();

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->acquireMap()) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    if (argc < 1) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    std::string layerId = GetStringFromValue(env, args[0]);

    // Resolve the layer on the render thread (collection reads race the
    // renderer otherwise); the NAPI peer is then built on this thread.
    mbgl::style::Layer *layer = nullptr;
    std::string layerType;
    try {
        style->runOnMap([&](mbgl::Map &m) {
            layer = m.getStyle().getLayer(layerId);
            if (layer) {
                layerType = layer->getTypeInfo()->type;
            }
        });
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "GetLayer failed: %s", e.what());
        layer = nullptr;
    }

    if (!layer) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    Logger::info("StyleNAPI", "GetLayer: %s (type: %s)", layerId.c_str(), layerType.c_str());

    napi_value instance = CreateLayerInstanceByType(env, layerType, layer);
    if (!instance) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    return instance;
}


napi_value StyleNAPI::GetLayers(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    napi_value result;
    napi_create_array(env, &result);

    if (!style || !style->acquireMap()) {
        return result;
    }

    try {
        // Snapshot the layer list on the render thread; peers are built below
        // on this thread while the raw pointers are still guaranteed valid
        // (all style mutations are serialized through the same dispatch).
        std::vector<mbgl::style::Layer *> layerList;
        style->runOnMap([&](mbgl::Map &m) {
            const auto &layers = m.getStyle().getLayers();
            layerList.reserve(layers.size());
            for (const auto &layer : layers) {
                layerList.push_back(layer);
            }
        });

        uint32_t index = 0;

        for (auto *layer : layerList) {
            std::string layerType = layer->getTypeInfo()->type;
            napi_value layerInstance = CreateLayerInstanceByType(env, layerType, layer);

            if (layerInstance == nullptr) {
                continue; // Unknown layer types are skipped
            }

            napi_set_element(env, result, index++, layerInstance);
        }

        Logger::info("StyleNAPI", "GetLayers: returned %d layers", index);
        return result;
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "GetLayers failed: %s", e.what());
        return result;
    }
}

napi_value StyleNAPI::RemoveLayerAt(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    size_t argc = napiArgs.Count();
    std::vector<napi_value> argsVec(argc);
    for (size_t i = 0; i < argc; ++i) {
        argsVec[i] = napiArgs.GetValue(i);
        if (napiArgs.HasError()) {
            return nullptr;
        }
    }
    napi_value* args = argsVec.data();

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->acquireMap()) {
        return CreateBoolValue(env, false);
    }

    if (argc < 1) {
        return CreateBoolValue(env, false);
    }

    // Retrieve the index
    uint32_t index = 0;
    napi_get_value_uint32(env, args[0], &index);

    try {
        std::string layerId;
        bool removed = false;
        style->runOnMap([&](mbgl::Map &m) {
            const auto &layers = m.getStyle().getLayers();
            if (index < layers.size()) {
                layerId = layers[index]->getID();
                m.getStyle().removeLayer(layerId);
                removed = true;
            }
        });
        if (!removed) {
            Logger::warn("StyleNAPI", "RemoveLayerAt: index %d out of bounds", index);
            return CreateBoolValue(env, false);
        }
        style->layers.erase(layerId);
        Logger::info("StyleNAPI", "RemoveLayerAt: removed layer %s at index %d", layerId.c_str(), index);
        return CreateBoolValue(env, true);
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "RemoveLayerAt failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleNAPI::AddLayerAbove(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(2);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value layerValue = napiArgs.GetValue(0);
    napi_value aboveValue = napiArgs.GetValue(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }
    std::string aboveLayerId = GetStringFromValue(env, aboveValue);

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->acquireMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    // MapLibre core only exposes addLayer(layer, beforeLayerID); to insert
    // above `aboveLayerId`, resolve the ID of the layer right after it.
    // Collection reads are serialized with the render thread.
    bool foundAboveLayer = false;
    std::optional<std::string> beforeLayerId;
    try {
        style->runOnMap([&](mbgl::Map &m) {
            const auto &layers = m.getStyle().getLayers();
            for (size_t i = 0; i < layers.size(); ++i) {
                if (foundAboveLayer) {
                    beforeLayerId = layers[i]->getID();
                    break;
                }
                if (layers[i]->getID() == aboveLayerId) {
                    foundAboveLayer = true;
                }
            }
        });
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "AddLayerAbove lookup failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

    if (!foundAboveLayer) {
        Logger::warn("StyleNAPI", "AddLayerAbove: layer %s not found; adding to top", aboveLayerId.c_str());
        return AddLayer(env, info);
    }

    std::string layerType = ReadLayerType(env, layerValue);
    if (layerType.empty()) {
        napi_throw_error(env, nullptr, "AddLayerAbove: value is not a layer instance created by this SDK (missing _TYPE_)");
        return nullptr;
    }

    std::string layerId;
    std::unique_ptr<mbgl::style::Layer> pendingLayer;
    std::function<void(mbgl::style::Layer *)> pendingAttach;
    LayerExtract result = DispatchLayerExtract(env, layerValue, layerType, pendingLayer, pendingAttach, layerId);
    if (result != LayerExtract::Ok) {
        if (result == LayerExtract::NotThisType) {
            napi_throw_error(env, nullptr, "Invalid layer type or layer object");
        }
        return nullptr;
    }

    if (CommitLayerAdd(env, style, layerId, std::move(pendingLayer), std::move(pendingAttach),
                       beforeLayerId, "AddLayerAbove")) {
        style->layers[layerId] = true;
    }
    return nullptr;
}

napi_value StyleNAPI::AddLayerAt(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(2);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value layerValue = napiArgs.GetValue(0);
    napi_value indexValue = napiArgs.GetValue(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }
    uint32_t index = 0;
    napi_get_value_uint32(env, indexValue, &index);

    napi_value jsThis = napiArgs.This();
    StyleNAPI *style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void **>(&style));

    if (!style || !style->acquireMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    // Core has no index-based addLayer; translate the index into the ID of the
    // layer currently at that position (out of range -> insert at the top).
    std::optional<std::string> beforeLayerId;
    try {
        style->runOnMap([&](mbgl::Map &m) {
            const auto &layers = m.getStyle().getLayers();
            if (index < layers.size()) {
                beforeLayerId = layers[index]->getID();
            }
        });
    } catch (const std::exception &e) {
        Logger::error("StyleNAPI", "AddLayerAt lookup failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

    std::string layerType = ReadLayerType(env, layerValue);
    if (layerType.empty()) {
        napi_throw_error(env, nullptr, "AddLayerAt: value is not a layer instance created by this SDK (missing _TYPE_)");
        return nullptr;
    }

    std::string layerId;
    std::unique_ptr<mbgl::style::Layer> pendingLayer;
    std::function<void(mbgl::style::Layer *)> pendingAttach;
    LayerExtract result = DispatchLayerExtract(env, layerValue, layerType, pendingLayer, pendingAttach, layerId);
    if (result != LayerExtract::Ok) {
        if (result == LayerExtract::NotThisType) {
            napi_throw_error(env, nullptr, "Invalid layer type or layer object");
        }
        return nullptr;
    }

    if (CommitLayerAdd(env, style, layerId, std::move(pendingLayer), std::move(pendingAttach),
                       beforeLayerId, "AddLayerAt")) {
        style->layers[layerId] = true;
    }
    return nullptr;
}

} // namespace harmony
} // namespace mbgl
