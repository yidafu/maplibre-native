#include "offline_region_definition_napi.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "geojson/geojson_converter.hpp"
#include "utils/logger.h"

#include <variant>

namespace maplibre {
namespace harmony {

using Logger = mbgl::harmony::Logger;

// ========== Convert from NAPI object to C++ definition ==========

mbgl::OfflineRegionDefinition OfflineRegionDefinitionNAPI::FromNapiObject(napi_env env, napi_value obj) {
    // Check object type
    napi_value typeValue;
    napi_get_named_property(env, obj, "type", &typeValue);
    
    char typeStr[256];
    size_t typeLen;
    napi_get_value_string_utf8(env, typeValue, typeStr, sizeof(typeStr), &typeLen);
    
    std::string type(typeStr, typeLen);
    
    if (type == "tilePyramid") {
        return TilePyramidFromNapi(env, obj);
    } else if (type == "geometry") {
        return GeometryFromNapi(env, obj);
    } else {
        Logger::error("OfflineRegionDefinitionNAPI", "Unknown definition type: %s", type.c_str());
        throw std::runtime_error("Unknown offline region definition type");
    }
}

// ========== Convert from C++ definition to NAPI object ==========

napi_value OfflineRegionDefinitionNAPI::ToNapiObject(napi_env env, const mbgl::OfflineRegionDefinition& definition) {
    return std::visit([env](const auto& def) {
        using T = std::decay_t<decltype(def)>;
        if constexpr (std::is_same_v<T, mbgl::OfflineTilePyramidRegionDefinition>) {
            return TilePyramidToNapi(env, def);
        } else if constexpr (std::is_same_v<T, mbgl::OfflineGeometryRegionDefinition>) {
            return GeometryToNapi(env, def);
        }
        return static_cast<napi_value>(nullptr);
    }, definition);
}

// ========== TilePyramid definition conversion ==========

mbgl::OfflineTilePyramidRegionDefinition OfflineRegionDefinitionNAPI::TilePyramidFromNapi(napi_env env, napi_value obj) {
    // Get styleURL
    napi_value styleURLValue;
    napi_get_named_property(env, obj, "styleURL", &styleURLValue);
    
    char styleURL[1024];
    size_t styleURLLen;
    napi_get_value_string_utf8(env, styleURLValue, styleURL, sizeof(styleURL), &styleURLLen);
    
    // Get bounds
    napi_value boundsValue;
    napi_get_named_property(env, obj, "bounds", &boundsValue);
    
    mbgl::LatLngBounds bounds;
    if (!mbgl::harmony::LatLngBoundsHarmony::ParseLatLngBounds(env, boundsValue, bounds)) {
        throw std::runtime_error("Failed to parse bounds");
    }
    
    // Get minZoom
    napi_value minZoomValue;
    napi_get_named_property(env, obj, "minZoom", &minZoomValue);
    double minZoom;
    napi_get_value_double(env, minZoomValue, &minZoom);
    
    // Get maxZoom
    napi_value maxZoomValue;
    napi_get_named_property(env, obj, "maxZoom", &maxZoomValue);
    double maxZoom;
    napi_get_value_double(env, maxZoomValue, &maxZoom);
    
    // Get pixelRatio
    napi_value pixelRatioValue;
    napi_get_named_property(env, obj, "pixelRatio", &pixelRatioValue);
    double pixelRatio;
    napi_get_value_double(env, pixelRatioValue, &pixelRatio);
    
    // Get includeIdeographs
    napi_value includeIdeographsValue;
    napi_get_named_property(env, obj, "includeIdeographs", &includeIdeographsValue);
    bool includeIdeographs;
    napi_get_value_bool(env, includeIdeographsValue, &includeIdeographs);
    
    return mbgl::OfflineTilePyramidRegionDefinition(
        std::string(styleURL, styleURLLen),
        bounds,
        minZoom,
        maxZoom,
        static_cast<float>(pixelRatio),
        includeIdeographs
    );
}

napi_value OfflineRegionDefinitionNAPI::TilePyramidToNapi(napi_env env, const mbgl::OfflineTilePyramidRegionDefinition& def) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // Set type
    napi_value typeValue;
    napi_create_string_utf8(env, "tilePyramid", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, obj, "type", typeValue);
    
    // Set styleURL
    napi_value styleURLValue;
    napi_create_string_utf8(env, def.styleURL.c_str(), NAPI_AUTO_LENGTH, &styleURLValue);
    napi_set_named_property(env, obj, "styleURL", styleURLValue);
    
    // Set bounds
    napi_value boundsValue = mbgl::harmony::LatLngBoundsHarmony::CreateLatLngBoundsObject(env, def.bounds);
    napi_set_named_property(env, obj, "bounds", boundsValue);
    
    // Set minZoom
    napi_value minZoomValue;
    napi_create_double(env, def.minZoom, &minZoomValue);
    napi_set_named_property(env, obj, "minZoom", minZoomValue);
    
    // Set maxZoom
    napi_value maxZoomValue;
    napi_create_double(env, def.maxZoom, &maxZoomValue);
    napi_set_named_property(env, obj, "maxZoom", maxZoomValue);
    
    // Set pixelRatio
    napi_value pixelRatioValue;
    napi_create_double(env, def.pixelRatio, &pixelRatioValue);
    napi_set_named_property(env, obj, "pixelRatio", pixelRatioValue);
    
    // Set includeIdeographs
    napi_value includeIdeographsValue;
    napi_get_boolean(env, def.includeIdeographs, &includeIdeographsValue);
    napi_set_named_property(env, obj, "includeIdeographs", includeIdeographsValue);
    
    return obj;
}

// ========== Geometry definition conversion ==========

mbgl::OfflineGeometryRegionDefinition OfflineRegionDefinitionNAPI::GeometryFromNapi(napi_env env, napi_value obj) {
    // Get styleURL
    napi_value styleURLValue;
    napi_get_named_property(env, obj, "styleURL", &styleURLValue);
    
    char styleURL[1024];
    size_t styleURLLen;
    napi_get_value_string_utf8(env, styleURLValue, styleURL, sizeof(styleURL), &styleURLLen);
    
    // Get geometry
    napi_value geometryValue;
    napi_get_named_property(env, obj, "geometry", &geometryValue);
    
    mbgl::Geometry<double> geometry = maplibre::harmony::geojson::GeoJsonConverter::JsObjectToGeometry(env, geometryValue);
    
    // Get minZoom
    napi_value minZoomValue;
    napi_get_named_property(env, obj, "minZoom", &minZoomValue);
    double minZoom;
    napi_get_value_double(env, minZoomValue, &minZoom);
    
    // Get maxZoom
    napi_value maxZoomValue;
    napi_get_named_property(env, obj, "maxZoom", &maxZoomValue);
    double maxZoom;
    napi_get_value_double(env, maxZoomValue, &maxZoom);
    
    // Get pixelRatio
    napi_value pixelRatioValue;
    napi_get_named_property(env, obj, "pixelRatio", &pixelRatioValue);
    double pixelRatio;
    napi_get_value_double(env, pixelRatioValue, &pixelRatio);
    
    // Get includeIdeographs
    napi_value includeIdeographsValue;
    napi_get_named_property(env, obj, "includeIdeographs", &includeIdeographsValue);
    bool includeIdeographs;
    napi_get_value_bool(env, includeIdeographsValue, &includeIdeographs);
    
    return mbgl::OfflineGeometryRegionDefinition(
        std::string(styleURL, styleURLLen),
        geometry,
        minZoom,
        maxZoom,
        static_cast<float>(pixelRatio),
        includeIdeographs
    );
}

napi_value OfflineRegionDefinitionNAPI::GeometryToNapi(napi_env env, const mbgl::OfflineGeometryRegionDefinition& def) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // Set type
    napi_value typeValue;
    napi_create_string_utf8(env, "geometry", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, obj, "type", typeValue);
    
    // Set styleURL
    napi_value styleURLValue;
    napi_create_string_utf8(env, def.styleURL.c_str(), NAPI_AUTO_LENGTH, &styleURLValue);
    napi_set_named_property(env, obj, "styleURL", styleURLValue);
    
    // Set geometry
    napi_value geometryValue = maplibre::harmony::geojson::GeoJsonConverter::GeometryToJsObject(env, def.geometry);
    napi_set_named_property(env, obj, "geometry", geometryValue);
    
    // Set minZoom
    napi_value minZoomValue;
    napi_create_double(env, def.minZoom, &minZoomValue);
    napi_set_named_property(env, obj, "minZoom", minZoomValue);
    
    // Set maxZoom
    napi_value maxZoomValue;
    napi_create_double(env, def.maxZoom, &maxZoomValue);
    napi_set_named_property(env, obj, "maxZoom", maxZoomValue);
    
    // Set pixelRatio
    napi_value pixelRatioValue;
    napi_create_double(env, def.pixelRatio, &pixelRatioValue);
    napi_set_named_property(env, obj, "pixelRatio", pixelRatioValue);
    
    // Set includeIdeographs
    napi_value includeIdeographsValue;
    napi_get_boolean(env, def.includeIdeographs, &includeIdeographsValue);
    napi_set_named_property(env, obj, "includeIdeographs", includeIdeographsValue);
    
    return obj;
}

} // namespace harmony
} // namespace maplibre

