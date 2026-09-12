#include "layer_source_factory_harmony.hpp"
#include "utils/logger.h"

// Layer wrappers
#include "layers/background_layer_harmony.hpp"
#include "layers/circle_layer_harmony.hpp"
#include "layers/fill_layer_harmony.hpp"
#include "layers/fill_extrusion_layer_harmony.hpp"
#include "layers/heatmap_layer_harmony.hpp"
#include "layers/hillshade_layer_harmony.hpp"
#include "layers/line_layer_harmony.hpp"
#include "layers/raster_layer_harmony.hpp"
#include "layers/symbol_layer_harmony.hpp"
#include "layers/color_relief_layer_harmony.hpp"
#include "layers/location_indicator_layer_harmony.hpp"
#include "napi/bindings/style/custom_drawable_layer_napi.hpp"

// Source wrappers
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"
#include "sources/custom_geometry_source_napi.hpp"

// Core types
#include <mbgl/style/layers/background_layer.hpp>
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/layers/fill_extrusion_layer.hpp>
#include <mbgl/style/layers/heatmap_layer.hpp>
#include <mbgl/style/layers/hillshade_layer.hpp>
#include <mbgl/style/layers/line_layer.hpp>
#include <mbgl/style/layers/raster_layer.hpp>
#include <mbgl/style/layers/symbol_layer.hpp>
#include <mbgl/style/layers/color_relief_layer.hpp>
#include <mbgl/style/layers/location_indicator_layer.hpp>
#include <mbgl/style/layers/custom_drawable_layer.hpp>

#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/style/sources/vector_source.hpp>
#include <mbgl/style/sources/raster_source.hpp>
#include <mbgl/style/sources/raster_dem_source.hpp>
#include <mbgl/style/sources/image_source.hpp>
#include <mbgl/style/sources/custom_geometry_source.hpp>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

namespace {

// Fallback for layer types without a full NAPI wrapper (custom, unknown):
// a plain info object with id/type/visibility/zoom bounds.
napi_value createLayerInfoObject(napi_env env, mbgl::style::Layer* layer) {
    napi_value layerObj;
    napi_create_object(env, &layerObj);

    napi_value idValue;
    napi_create_string_utf8(env, layer->getID().c_str(), NAPI_AUTO_LENGTH, &idValue);
    napi_set_named_property(env, layerObj, "id", idValue);

    napi_value typeValue;
    napi_create_string_utf8(env, layer->getTypeInfo()->type, NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, layerObj, "type", typeValue);

    auto visibility = layer->getVisibility();
    napi_value visValue;
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &visValue);
    napi_set_named_property(env, layerObj, "visibility", visValue);

    napi_value minZoomValue, maxZoomValue;
    napi_create_double(env, layer->getMinZoom(), &minZoomValue);
    napi_create_double(env, layer->getMaxZoom(), &maxZoomValue);
    napi_set_named_property(env, layerObj, "minzoom", minZoomValue);
    napi_set_named_property(env, layerObj, "maxzoom", maxZoomValue);

    return layerObj;
}

// Fallback for source types without a full NAPI wrapper: a plain info object.
napi_value createSourceInfoObject(napi_env env, mbgl::style::Source* source, const std::string& typeStr) {
    napi_value sourceObj;
    napi_create_object(env, &sourceObj);

    napi_value idValue;
    napi_create_string_utf8(env, source->getID().c_str(), NAPI_AUTO_LENGTH, &idValue);
    napi_set_named_property(env, sourceObj, "id", idValue);

    napi_value typeValue;
    napi_create_string_utf8(env, typeStr.c_str(), NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, sourceObj, "type", typeValue);

    return sourceObj;
}

std::string sourceTypeToString(mbgl::style::SourceType type) {
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
        case mbgl::style::SourceType::CustomVector:
            return "custom-vector";
        default:
            return "unknown";
    }
}

} // namespace

napi_value LayerSourceFactory::createLayerWrapper(napi_env env, mbgl::style::Layer* layer) {
    if (!layer) {
        Logger::warn("LayerSourceFactory", "createLayerWrapper: null layer pointer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    const std::string layerType = layer->getTypeInfo()->type;

    // Full NAPI wrapper per layer type (consistent with StyleNAPI::GetLayer)
    if (layerType == "fill") {
        return mbgl::harmony::FillLayerNAPI::CreateInstance(env, static_cast<mbgl::style::FillLayer*>(layer));
    } else if (layerType == "line") {
        return mbgl::harmony::LineLayerNAPI::CreateInstance(env, static_cast<mbgl::style::LineLayer*>(layer));
    } else if (layerType == "circle") {
        return mbgl::harmony::CircleLayerNAPI::CreateInstance(env, static_cast<mbgl::style::CircleLayer*>(layer));
    } else if (layerType == "symbol") {
        return mbgl::harmony::SymbolLayerNAPI::CreateInstance(env, static_cast<mbgl::style::SymbolLayer*>(layer));
    } else if (layerType == "raster") {
        return mbgl::harmony::RasterLayerNAPI::CreateInstance(env, static_cast<mbgl::style::RasterLayer*>(layer));
    } else if (layerType == "background") {
        return mbgl::harmony::BackgroundLayerNAPI::CreateInstance(env,
                                                                  static_cast<mbgl::style::BackgroundLayer*>(layer));
    } else if (layerType == "heatmap") {
        return mbgl::harmony::HeatmapLayerNAPI::CreateInstance(env, static_cast<mbgl::style::HeatmapLayer*>(layer));
    } else if (layerType == "hillshade") {
        return mbgl::harmony::HillshadeLayerNAPI::CreateInstance(env,
                                                                 static_cast<mbgl::style::HillshadeLayer*>(layer));
    } else if (layerType == "fill-extrusion") {
        return mbgl::harmony::FillExtrusionLayerNAPI::CreateInstance(
            env, static_cast<mbgl::style::FillExtrusionLayer*>(layer));
    } else if (layerType == "color-relief") {
        return mbgl::harmony::ColorReliefLayerNAPI::CreateInstance(env,
                                                                   static_cast<mbgl::style::ColorReliefLayer*>(layer));
    } else if (layerType == "location-indicator") {
        return mbgl::harmony::LocationIndicatorLayerNAPI::CreateInstance(
            env, static_cast<mbgl::style::LocationIndicatorLayer*>(layer));
    } else if (layerType == "custom-drawable") {
        return mbgl::harmony::CustomDrawableLayerNAPI::CreateInstance(
            env, static_cast<mbgl::style::CustomDrawableLayer*>(layer));
    }

    Logger::info("LayerSourceFactory", "createLayerWrapper: info-only wrapper for type: %s, id: %s",
                layerType.c_str(), layer->getID().c_str());
    return createLayerInfoObject(env, layer);
}

napi_value LayerSourceFactory::createSourceWrapper(napi_env env, mbgl::style::Source* source) {
    if (!source) {
        Logger::warn("LayerSourceFactory", "createSourceWrapper: null source pointer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    const auto sourceType = source->getType();

    // Full NAPI wrapper per source type (consistent with StyleNAPI::GetSource)
    switch (sourceType) {
        case mbgl::style::SourceType::GeoJSON:
            return mbgl::harmony::GeoJsonSourceNAPI::CreateInstance(
                env, static_cast<mbgl::style::GeoJSONSource*>(source));
        case mbgl::style::SourceType::Vector:
            return mbgl::harmony::VectorSourceNAPI::CreateInstance(
                env, static_cast<mbgl::style::VectorSource*>(source));
        case mbgl::style::SourceType::Raster:
            return mbgl::harmony::RasterSourceNAPI::CreateInstance(
                env, static_cast<mbgl::style::RasterSource*>(source));
        case mbgl::style::SourceType::RasterDEM:
            return mbgl::harmony::RasterDemSourceNAPI::CreateInstance(
                env, static_cast<mbgl::style::RasterDEMSource*>(source));
        case mbgl::style::SourceType::Image:
            return mbgl::harmony::ImageSourceNAPI::CreateInstance(
                env, static_cast<mbgl::style::ImageSource*>(source));
        case mbgl::style::SourceType::CustomVector:
            return mbgl::harmony::CustomGeometrySourceNAPI::CreateInstance(
                env, static_cast<mbgl::style::CustomGeometrySource*>(source));
        default:
            break;
    }

    const std::string typeStr = sourceTypeToString(sourceType);
    Logger::info("LayerSourceFactory", "createSourceWrapper: info-only wrapper for type: %s, id: %s",
                typeStr.c_str(), source->getID().c_str());
    return createSourceInfoObject(env, source, typeStr);
}

} // namespace harmony
} // namespace mbgl
