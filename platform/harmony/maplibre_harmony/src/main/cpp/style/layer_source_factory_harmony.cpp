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

// Source wrappers
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"

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

#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/style/sources/vector_source.hpp>
#include <mbgl/style/sources/raster_source.hpp>
#include <mbgl/style/sources/raster_dem_source.hpp>
#include <mbgl/style/sources/image_source.hpp>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

napi_value LayerSourceFactory::createLayerWrapper(napi_env env, mbgl::style::Layer* layer) {
    if (!layer) {
        Logger::warn("LayerSourceFactory", "createLayerWrapper: null layer pointer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& typeInfo = layer->getTypeInfo();
    std::string layerType = typeInfo->type;
    
    Logger::info("LayerSourceFactory", "Creating wrapper for layer type: %s, id: %s", 
                layerType.c_str(), layer->getID().c_str());
    
    // Note: We return a simple object with layer info for now
    // Full NAPI wrapper creation requires more complex setup
    // TODO: Implement full wrapper creation with proper lifecycle management
    
    napi_value layerObj;
    napi_create_object(env, &layerObj);
    
    // Set layer ID
    napi_value idValue;
    napi_create_string_utf8(env, layer->getID().c_str(), NAPI_AUTO_LENGTH, &idValue);
    napi_set_named_property(env, layerObj, "id", idValue);
    
    // Set layer type
    napi_value typeValue;
    napi_create_string_utf8(env, layerType.c_str(), NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, layerObj, "type", typeValue);
    
    // Set visibility
    auto visibility = layer->getVisibility();
    napi_value visValue;
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &visValue);
    napi_set_named_property(env, layerObj, "visibility", visValue);
    
    // Set minzoom/maxzoom
    napi_value minZoomValue, maxZoomValue;
    napi_create_double(env, layer->getMinZoom(), &minZoomValue);
    napi_create_double(env, layer->getMaxZoom(), &maxZoomValue);
    napi_set_named_property(env, layerObj, "minzoom", minZoomValue);
    napi_set_named_property(env, layerObj, "maxzoom", maxZoomValue);
    
    return layerObj;
}

napi_value LayerSourceFactory::createSourceWrapper(napi_env env, mbgl::style::Source* source) {
    if (!source) {
        Logger::warn("LayerSourceFactory", "createSourceWrapper: null source pointer");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    auto sourceType = source->getType();
    std::string sourceTypeStr;
    
    // Convert SourceType enum to string
    switch (sourceType) {
        case mbgl::style::SourceType::Vector:
            sourceTypeStr = "vector";
            break;
        case mbgl::style::SourceType::Raster:
            sourceTypeStr = "raster";
            break;
        case mbgl::style::SourceType::RasterDEM:
            sourceTypeStr = "raster-dem";
            break;
        case mbgl::style::SourceType::GeoJSON:
            sourceTypeStr = "geojson";
            break;
        case mbgl::style::SourceType::Image:
            sourceTypeStr = "image";
            break;
        default:
            sourceTypeStr = "unknown";
            break;
    }
    
    Logger::info("LayerSourceFactory", "Creating wrapper for source type: %s, id: %s", 
                sourceTypeStr.c_str(), source->getID().c_str());
    
    // Note: We return a simple object with source info for now
    // TODO: Implement full wrapper creation
    
    napi_value sourceObj;
    napi_create_object(env, &sourceObj);
    
    // Set source ID
    napi_value idValue;
    napi_create_string_utf8(env, source->getID().c_str(), NAPI_AUTO_LENGTH, &idValue);
    napi_set_named_property(env, sourceObj, "id", idValue);
    
    // Set source type
    napi_value typeValue;
    napi_create_string_utf8(env, sourceTypeStr.c_str(), NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, sourceObj, "type", typeValue);
    
    return sourceObj;
}

} // namespace harmony
} // namespace mbgl

