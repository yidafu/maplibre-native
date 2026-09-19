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
#include <mln/style/layers/background_layer.hpp>
#include <mln/style/layers/circle_layer.hpp>
#include <mln/style/layers/fill_layer.hpp>
#include <mln/style/layers/fill_extrusion_layer.hpp>
#include <mln/style/layers/heatmap_layer.hpp>
#include <mln/style/layers/hillshade_layer.hpp>
#include <mln/style/layers/line_layer.hpp>
#include <mln/style/layers/raster_layer.hpp>
#include <mln/style/layers/symbol_layer.hpp>
#include <mln/style/layers/color_relief_layer.hpp>
#include <mln/style/layers/location_indicator_layer.hpp>
#include <mln/style/layers/custom_drawable_layer.hpp>

#include <mln/style/sources/geojson_source.hpp>
#include <mln/style/sources/vector_source.hpp>
#include <mln/style/sources/raster_source.hpp>
#include <mln/style/sources/raster_dem_source.hpp>
#include <mln/style/sources/image_source.hpp>
#include <mln/style/sources/custom_geometry_source.hpp>

using mln::harmony::Logger;

namespace mln {
namespace harmony {

namespace {

// Fallback for layer types without a full NAPI wrapper (custom, unknown):
// a plain info object with id/type/visibility/zoom bounds.
napi_value createLayerInfoObject(napi_env env, mln::style::Layer* layer) {
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
    const char* visStr = (visibility == mln::style::VisibilityType::Visible) ? "visible" : "none";
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
napi_value createSourceInfoObject(napi_env env, mln::style::Source* source, const std::string& typeStr) {
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

} // namespace

std::string LayerSourceFactory::SourceTypeToString(mln::style::SourceType type) {
    switch (type) {
        case mln::style::SourceType::Vector:
            return "vector";
        case mln::style::SourceType::Raster:
            return "raster";
        case mln::style::SourceType::RasterDEM:
            return "raster-dem";
        case mln::style::SourceType::GeoJSON:
            return "geojson";
        case mln::style::SourceType::Image:
            return "image";
        case mln::style::SourceType::CustomVector:
            return "custom-vector";
        default:
            return "unknown";
    }
}

namespace {

// JS null handed back to callers that asked for WrapperFallback::Null.
napi_value createNullValue(napi_env env) {
    napi_value nullValue;
    napi_get_null(env, &nullValue);
    return nullValue;
}

} // namespace

napi_value LayerSourceFactory::createLayerWrapper(napi_env env, mln::style::Layer* layer,
                                                  WrapperFallback fallback) {
    if (!layer) {
        Logger::warn("LayerSourceFactory", "createLayerWrapper: null layer pointer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    const std::string layerType = layer->getTypeInfo()->type;

    // Full NAPI wrapper per layer type (consistent with StyleNAPI::GetLayer)
    if (layerType == "fill") {
        return mln::harmony::FillLayerNAPI::CreateInstance(env, static_cast<mln::style::FillLayer*>(layer));
    } else if (layerType == "line") {
        return mln::harmony::LineLayerNAPI::CreateInstance(env, static_cast<mln::style::LineLayer*>(layer));
    } else if (layerType == "circle") {
        return mln::harmony::CircleLayerNAPI::CreateInstance(env, static_cast<mln::style::CircleLayer*>(layer));
    } else if (layerType == "symbol") {
        return mln::harmony::SymbolLayerNAPI::CreateInstance(env, static_cast<mln::style::SymbolLayer*>(layer));
    } else if (layerType == "raster") {
        return mln::harmony::RasterLayerNAPI::CreateInstance(env, static_cast<mln::style::RasterLayer*>(layer));
    } else if (layerType == "background") {
        return mln::harmony::BackgroundLayerNAPI::CreateInstance(env,
                                                                  static_cast<mln::style::BackgroundLayer*>(layer));
    } else if (layerType == "heatmap") {
        return mln::harmony::HeatmapLayerNAPI::CreateInstance(env, static_cast<mln::style::HeatmapLayer*>(layer));
    } else if (layerType == "hillshade") {
        return mln::harmony::HillshadeLayerNAPI::CreateInstance(env,
                                                                 static_cast<mln::style::HillshadeLayer*>(layer));
    } else if (layerType == "fill-extrusion") {
        return mln::harmony::FillExtrusionLayerNAPI::CreateInstance(
            env, static_cast<mln::style::FillExtrusionLayer*>(layer));
    } else if (layerType == "color-relief") {
        return mln::harmony::ColorReliefLayerNAPI::CreateInstance(env,
                                                                   static_cast<mln::style::ColorReliefLayer*>(layer));
    } else if (layerType == "location-indicator") {
        return mln::harmony::LocationIndicatorLayerNAPI::CreateInstance(
            env, static_cast<mln::style::LocationIndicatorLayer*>(layer));
    } else if (layerType == "custom-drawable") {
        return mln::harmony::CustomDrawableLayerNAPI::CreateInstance(
            env, static_cast<mln::style::CustomDrawableLayer*>(layer));
    }

    if (fallback == WrapperFallback::Null) {
        return createNullValue(env);
    }

    Logger::info("LayerSourceFactory", "createLayerWrapper: info-only wrapper for type: %s, id: %s",
                layerType.c_str(), layer->getID().c_str());
    return createLayerInfoObject(env, layer);
}

napi_value LayerSourceFactory::createSourceWrapper(napi_env env, mln::style::Source* source,
                                                  WrapperFallback fallback) {
    if (!source) {
        Logger::warn("LayerSourceFactory", "createSourceWrapper: null source pointer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    const auto sourceType = source->getType();

    // Full NAPI wrapper per source type (consistent with StyleNAPI::GetSource)
    switch (sourceType) {
        case mln::style::SourceType::GeoJSON:
            return mln::harmony::GeoJsonSourceNAPI::CreateInstance(
                env, static_cast<mln::style::GeoJSONSource*>(source));
        case mln::style::SourceType::Vector:
            return mln::harmony::VectorSourceNAPI::CreateInstance(
                env, static_cast<mln::style::VectorSource*>(source));
        case mln::style::SourceType::Raster:
            return mln::harmony::RasterSourceNAPI::CreateInstance(
                env, static_cast<mln::style::RasterSource*>(source));
        case mln::style::SourceType::RasterDEM:
            return mln::harmony::RasterDemSourceNAPI::CreateInstance(
                env, static_cast<mln::style::RasterDEMSource*>(source));
        case mln::style::SourceType::Image:
            return mln::harmony::ImageSourceNAPI::CreateInstance(
                env, static_cast<mln::style::ImageSource*>(source));
        case mln::style::SourceType::CustomVector:
            return mln::harmony::CustomGeometrySourceNAPI::CreateInstance(
                env, static_cast<mln::style::CustomGeometrySource*>(source));
        default:
            break;
    }

    const std::string typeStr = SourceTypeToString(sourceType);
    if (fallback == WrapperFallback::Null) {
        return createNullValue(env);
    }
    Logger::info("LayerSourceFactory", "createSourceWrapper: info-only wrapper for type: %s, id: %s",
                typeStr.c_str(), source->getID().c_str());
    return createSourceInfoObject(env, source, typeStr);
}

} // namespace harmony
} // namespace mln
