#include "offline_region_definition_napi.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "geojson/geojson_converter.hpp"
#include "utils/logger.h"

#include <variant>

namespace maplibre {
namespace harmony {

using Logger = mbgl::harmony::Logger;

// ========== 从 NAPI 对象转换为 C++ 定义 ==========

mbgl::OfflineRegionDefinition OfflineRegionDefinitionNAPI::FromNapiObject(napi_env env, napi_value obj) {
    // 检查对象类型
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

// ========== 从 C++ 定义转换为 NAPI 对象 ==========

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

// ========== TilePyramid 定义转换 ==========

mbgl::OfflineTilePyramidRegionDefinition OfflineRegionDefinitionNAPI::TilePyramidFromNapi(napi_env env, napi_value obj) {
    // 获取 styleURL
    napi_value styleURLValue;
    napi_get_named_property(env, obj, "styleURL", &styleURLValue);
    
    char styleURL[1024];
    size_t styleURLLen;
    napi_get_value_string_utf8(env, styleURLValue, styleURL, sizeof(styleURL), &styleURLLen);
    
    // 获取 bounds
    napi_value boundsValue;
    napi_get_named_property(env, obj, "bounds", &boundsValue);
    
    mbgl::LatLngBounds bounds;
    if (!mbgl::harmony::LatLngBoundsHarmony::ParseLatLngBounds(env, boundsValue, bounds)) {
        throw std::runtime_error("Failed to parse bounds");
    }
    
    // 获取 minZoom
    napi_value minZoomValue;
    napi_get_named_property(env, obj, "minZoom", &minZoomValue);
    double minZoom;
    napi_get_value_double(env, minZoomValue, &minZoom);
    
    // 获取 maxZoom
    napi_value maxZoomValue;
    napi_get_named_property(env, obj, "maxZoom", &maxZoomValue);
    double maxZoom;
    napi_get_value_double(env, maxZoomValue, &maxZoom);
    
    // 获取 pixelRatio
    napi_value pixelRatioValue;
    napi_get_named_property(env, obj, "pixelRatio", &pixelRatioValue);
    double pixelRatio;
    napi_get_value_double(env, pixelRatioValue, &pixelRatio);
    
    // 获取 includeIdeographs
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
    
    // 设置 type
    napi_value typeValue;
    napi_create_string_utf8(env, "tilePyramid", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, obj, "type", typeValue);
    
    // 设置 styleURL
    napi_value styleURLValue;
    napi_create_string_utf8(env, def.styleURL.c_str(), NAPI_AUTO_LENGTH, &styleURLValue);
    napi_set_named_property(env, obj, "styleURL", styleURLValue);
    
    // 设置 bounds
    napi_value boundsValue = mbgl::harmony::LatLngBoundsHarmony::CreateLatLngBoundsObject(env, def.bounds);
    napi_set_named_property(env, obj, "bounds", boundsValue);
    
    // 设置 minZoom
    napi_value minZoomValue;
    napi_create_double(env, def.minZoom, &minZoomValue);
    napi_set_named_property(env, obj, "minZoom", minZoomValue);
    
    // 设置 maxZoom
    napi_value maxZoomValue;
    napi_create_double(env, def.maxZoom, &maxZoomValue);
    napi_set_named_property(env, obj, "maxZoom", maxZoomValue);
    
    // 设置 pixelRatio
    napi_value pixelRatioValue;
    napi_create_double(env, def.pixelRatio, &pixelRatioValue);
    napi_set_named_property(env, obj, "pixelRatio", pixelRatioValue);
    
    // 设置 includeIdeographs
    napi_value includeIdeographsValue;
    napi_get_boolean(env, def.includeIdeographs, &includeIdeographsValue);
    napi_set_named_property(env, obj, "includeIdeographs", includeIdeographsValue);
    
    return obj;
}

// ========== Geometry 定义转换 ==========

mbgl::OfflineGeometryRegionDefinition OfflineRegionDefinitionNAPI::GeometryFromNapi(napi_env env, napi_value obj) {
    // 获取 styleURL
    napi_value styleURLValue;
    napi_get_named_property(env, obj, "styleURL", &styleURLValue);
    
    char styleURL[1024];
    size_t styleURLLen;
    napi_get_value_string_utf8(env, styleURLValue, styleURL, sizeof(styleURL), &styleURLLen);
    
    // 获取 geometry
    napi_value geometryValue;
    napi_get_named_property(env, obj, "geometry", &geometryValue);
    
    mbgl::Geometry<double> geometry = maplibre::harmony::geojson::GeoJsonConverter::JsObjectToGeometry(env, geometryValue);
    
    // 获取 minZoom
    napi_value minZoomValue;
    napi_get_named_property(env, obj, "minZoom", &minZoomValue);
    double minZoom;
    napi_get_value_double(env, minZoomValue, &minZoom);
    
    // 获取 maxZoom
    napi_value maxZoomValue;
    napi_get_named_property(env, obj, "maxZoom", &maxZoomValue);
    double maxZoom;
    napi_get_value_double(env, maxZoomValue, &maxZoom);
    
    // 获取 pixelRatio
    napi_value pixelRatioValue;
    napi_get_named_property(env, obj, "pixelRatio", &pixelRatioValue);
    double pixelRatio;
    napi_get_value_double(env, pixelRatioValue, &pixelRatio);
    
    // 获取 includeIdeographs
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
    
    // 设置 type
    napi_value typeValue;
    napi_create_string_utf8(env, "geometry", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, obj, "type", typeValue);
    
    // 设置 styleURL
    napi_value styleURLValue;
    napi_create_string_utf8(env, def.styleURL.c_str(), NAPI_AUTO_LENGTH, &styleURLValue);
    napi_set_named_property(env, obj, "styleURL", styleURLValue);
    
    // 设置 geometry
    napi_value geometryValue = maplibre::harmony::geojson::GeoJsonConverter::GeometryToJsObject(env, def.geometry);
    napi_set_named_property(env, obj, "geometry", geometryValue);
    
    // 设置 minZoom
    napi_value minZoomValue;
    napi_create_double(env, def.minZoom, &minZoomValue);
    napi_set_named_property(env, obj, "minZoom", minZoomValue);
    
    // 设置 maxZoom
    napi_value maxZoomValue;
    napi_create_double(env, def.maxZoom, &maxZoomValue);
    napi_set_named_property(env, obj, "maxZoom", maxZoomValue);
    
    // 设置 pixelRatio
    napi_value pixelRatioValue;
    napi_create_double(env, def.pixelRatio, &pixelRatioValue);
    napi_set_named_property(env, obj, "pixelRatio", pixelRatioValue);
    
    // 设置 includeIdeographs
    napi_value includeIdeographsValue;
    napi_get_boolean(env, def.includeIdeographs, &includeIdeographsValue);
    napi_set_named_property(env, obj, "includeIdeographs", includeIdeographsValue);
    
    return obj;
}

} // namespace harmony
} // namespace maplibre

