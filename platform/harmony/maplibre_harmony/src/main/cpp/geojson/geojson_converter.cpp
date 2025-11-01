#include "geojson_converter.hpp"
#include "util.hpp"
#include "utils/logger.h"
#include <mapbox/geometry/geometry.hpp>
#include <stdexcept>

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

// ==================== JS 对象 -> C++ ====================

mbgl::Geometry<double> GeoJsonConverter::JsObjectToGeometry(napi_env env, napi_value jsObj) {
    if (!IsObject(env, jsObj)) {
        throw std::runtime_error("Geometry must be an object");
    }
    
    // 获取 type 字段
    if (!HasProperty(env, jsObj, "type")) {
        throw std::runtime_error("Geometry must have a 'type' property");
    }
    
    std::string type = GetStringProperty(env, jsObj, "type");
    return ParseGeometryByType(env, jsObj, type);
}

mbgl::Feature GeoJsonConverter::JsObjectToFeature(napi_env env, napi_value jsObj) {
    if (!IsObject(env, jsObj)) {
        throw std::runtime_error("Feature must be an object");
    }
    
    mbgl::Feature feature;
    
    // 解析 geometry
    if (HasProperty(env, jsObj, "geometry")) {
        napi_value geometryValue = GetObjectProperty(env, jsObj, "geometry");
        if (!IsNull(env, geometryValue) && !IsUndefined(env, geometryValue)) {
            feature.geometry = JsObjectToGeometry(env, geometryValue);
        }
    }
    
    // 解析 properties
    if (HasProperty(env, jsObj, "properties")) {
        napi_value propertiesValue = GetObjectProperty(env, jsObj, "properties");
        if (!IsNull(env, propertiesValue) && !IsUndefined(env, propertiesValue)) {
            feature.properties = NapiObjectToPropertyMap(env, propertiesValue);
        }
    }
    
    // 解析 id（可选）
    if (HasProperty(env, jsObj, "id")) {
        napi_value idValue = GetObjectProperty(env, jsObj, "id");
        if (!IsNull(env, idValue) && !IsUndefined(env, idValue)) {
            if (IsString(env, idValue)) {
                feature.id = GetStringProperty(env, jsObj, "id");
            } else if (IsNumber(env, idValue)) {
                double numValue = GetNumberProperty(env, jsObj, "id");
                if (numValue >= 0) {
                    feature.id = static_cast<uint64_t>(numValue);
                } else {
                    feature.id = static_cast<int64_t>(numValue);
                }
            }
        }
    }
    
    return feature;
}

mbgl::FeatureCollection GeoJsonConverter::JsObjectToFeatureCollection(napi_env env, napi_value jsObj) {
    if (!IsObject(env, jsObj)) {
        throw std::runtime_error("FeatureCollection must be an object");
    }
    
    mbgl::FeatureCollection collection;
    
    // 检查是否有 features 数组
    if (!HasProperty(env, jsObj, "features")) {
        throw std::runtime_error("FeatureCollection must have a 'features' property");
    }
    
    napi_value featuresValue = GetObjectProperty(env, jsObj, "features");
    if (!IsArray(env, featuresValue)) {
        throw std::runtime_error("FeatureCollection 'features' must be an array");
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, featuresValue, &length);
    collection.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, featuresValue, i, &element);
        
        try {
            mbgl::Feature feature = JsObjectToFeature(env, element);
            collection.push_back(std::move(feature));
        } catch (const std::exception& e) {
            Logger::warn("GeoJsonConverter", "Failed to parse feature at index %u: %s", i, e.what());
        }
    }
    
    return collection;
}

mbgl::GeoJSON GeoJsonConverter::JsObjectToGeoJSON(napi_env env, napi_value jsObj) {
    if (!IsObject(env, jsObj)) {
        throw std::runtime_error("GeoJSON must be an object");
    }
    
    // 获取 type 字段判断类型
    std::string type;
    if (HasProperty(env, jsObj, "type")) {
        type = GetStringProperty(env, jsObj, "type");
    } else {
        throw std::runtime_error("GeoJSON must have a 'type' property");
    }
    
    if (type == "FeatureCollection") {
        mbgl::FeatureCollection collection = JsObjectToFeatureCollection(env, jsObj);
        return mbgl::GeoJSON(std::move(collection));
    } else if (type == "Feature") {
        mbgl::Feature feature = JsObjectToFeature(env, jsObj);
        // 需要转换为 GeoJSONFeature (mapbox::feature::feature<double>)
        mbgl::GeoJSONFeature geoJsonFeature;
        geoJsonFeature.geometry = feature.geometry;
        geoJsonFeature.properties = feature.properties;
        geoJsonFeature.id = feature.id;
        return mbgl::GeoJSON(std::move(geoJsonFeature));
    } else {
        // Geometry 类型
        mbgl::Geometry<double> geometry = JsObjectToGeometry(env, jsObj);
        return mbgl::GeoJSON(std::move(geometry));
    }
}

// ==================== C++ -> JS 对象 ====================

napi_value GeoJsonConverter::GeometryToJsObject(napi_env env, const mbgl::Geometry<double>& geometry) {
    return geometry.match(
        [&](const mbgl::Point<double>& point) { return PointToJsObject(env, point); },
        [&](const mbgl::LineString<double>& lineString) { return LineStringToJsObject(env, lineString); },
        [&](const mbgl::Polygon<double>& polygon) { return PolygonToJsObject(env, polygon); },
        [&](const mbgl::MultiPoint<double>& multiPoint) { return MultiPointToJsObject(env, multiPoint); },
        [&](const mbgl::MultiLineString<double>& multiLineString) { return MultiLineStringToJsObject(env, multiLineString); },
        [&](const mbgl::MultiPolygon<double>& multiPolygon) { return MultiPolygonToJsObject(env, multiPolygon); },
        [&](const mapbox::geometry::geometry_collection<double>& collection) { return GeometryCollectionToJsObject(env, collection); },
        [&](const auto&) -> napi_value {
            napi_value null;
            napi_get_null(env, &null);
            return null;
        }
    );
}

napi_value GeoJsonConverter::FeatureToJsObject(napi_env env, const mbgl::Feature& feature) {
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "Feature"
    napi_value type;
    napi_create_string_utf8(env, "Feature", NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // id (optional)
    if (!feature.id.is<mbgl::NullValue>()) {
        napi_value id;
        if (feature.id.is<std::string>()) {
            const auto& idStr = feature.id.get<std::string>();
            napi_create_string_utf8(env, idStr.c_str(), NAPI_AUTO_LENGTH, &id);
        } else if (feature.id.is<uint64_t>()) {
            napi_create_double(env, static_cast<double>(feature.id.get<uint64_t>()), &id);
        } else if (feature.id.is<int64_t>()) {
            napi_create_double(env, static_cast<double>(feature.id.get<int64_t>()), &id);
        } else {
            napi_get_null(env, &id);
        }
        napi_set_named_property(env, result, "id", id);
    }
    
    // geometry
    napi_value geometry = GeometryToJsObject(env, feature.geometry);
    napi_set_named_property(env, result, "geometry", geometry);
    
    // properties
    napi_value properties = PropertyMapToNapiObject(env, feature.properties);
    napi_set_named_property(env, result, "properties", properties);
    
    return result;
}

napi_value GeoJsonConverter::FeatureCollectionToJsObject(napi_env env, const mbgl::FeatureCollection& featureCollection) {
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "FeatureCollection"
    napi_value type;
    napi_create_string_utf8(env, "FeatureCollection", NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // features array - FeatureCollection 继承自 vector<feature<double>>
    // 需要转换为 vector<mbgl::Feature>
    std::vector<mbgl::Feature> features;
    features.reserve(featureCollection.size());
    for (const auto& f : featureCollection) {
        mbgl::Feature feature;
        feature.geometry = f.geometry;
        feature.properties = f.properties;
        feature.id = f.id;
        features.push_back(std::move(feature));
    }
    napi_value featuresArray = FeatureArrayToJsArray(env, features);
    napi_set_named_property(env, result, "features", featuresArray);
    
    return result;
}

napi_value GeoJsonConverter::FeatureArrayToJsArray(napi_env env, const std::vector<mbgl::Feature>& features) {
    napi_value array;
    napi_create_array_with_length(env, features.size(), &array);
    
    for (size_t i = 0; i < features.size(); i++) {
        napi_value feature = FeatureToJsObject(env, features[i]);
        napi_set_element(env, array, i, feature);
    }
    
    return array;
}

// ==================== Private 辅助方法 ====================

mbgl::Geometry<double> GeoJsonConverter::ParseGeometryByType(napi_env env, napi_value jsObj, const std::string& type) {
    // 获取 coordinates 或 geometries 字段
    napi_value coordinatesOrGeometries;
    
    if (type == "GeometryCollection") {
        if (!HasProperty(env, jsObj, "geometries")) {
            throw std::runtime_error("GeometryCollection must have 'geometries' property");
        }
        coordinatesOrGeometries = GetObjectProperty(env, jsObj, "geometries");
        return ParseGeometryCollection(env, coordinatesOrGeometries);
    } else {
        if (!HasProperty(env, jsObj, "coordinates")) {
            throw std::runtime_error("Geometry must have 'coordinates' property");
        }
        coordinatesOrGeometries = GetObjectProperty(env, jsObj, "coordinates");
    }
    
    if (type == "Point") {
        return ParsePoint(env, coordinatesOrGeometries);
    } else if (type == "LineString") {
        return ParseLineString(env, coordinatesOrGeometries);
    } else if (type == "Polygon") {
        return ParsePolygon(env, coordinatesOrGeometries);
    } else if (type == "MultiPoint") {
        return ParseMultiPoint(env, coordinatesOrGeometries);
    } else if (type == "MultiLineString") {
        return ParseMultiLineString(env, coordinatesOrGeometries);
    } else if (type == "MultiPolygon") {
        return ParseMultiPolygon(env, coordinatesOrGeometries);
    } else {
        throw std::runtime_error("Unknown geometry type: " + type);
    }
}

// Geometry 解析实现

mbgl::Point<double> GeoJsonConverter::ParsePoint(napi_env env, napi_value coordinates) {
    auto coords = NapiArrayToDoubleVector(env, coordinates);
    if (coords.size() < 2) {
        throw std::runtime_error("Point coordinates must have at least 2 elements");
    }
    return mbgl::Point<double>{coords[0], coords[1]};
}

mbgl::LineString<double> GeoJsonConverter::ParseLineString(napi_env env, napi_value coordinates) {
    return NapiArrayToPointVector(env, coordinates);
}

mbgl::Polygon<double> GeoJsonConverter::ParsePolygon(napi_env env, napi_value coordinates) {
    return NapiArrayToLinearRingVector(env, coordinates);
}

mbgl::MultiPoint<double> GeoJsonConverter::ParseMultiPoint(napi_env env, napi_value coordinates) {
    return NapiArrayToPointVector(env, coordinates);
}

mbgl::MultiLineString<double> GeoJsonConverter::ParseMultiLineString(napi_env env, napi_value coordinates) {
    return NapiArrayToLineStringVector(env, coordinates);
}

mbgl::MultiPolygon<double> GeoJsonConverter::ParseMultiPolygon(napi_env env, napi_value coordinates) {
    return NapiArrayToPolygonVector(env, coordinates);
}

mapbox::geometry::geometry_collection<double> GeoJsonConverter::ParseGeometryCollection(napi_env env, napi_value geometries) {
    if (!IsArray(env, geometries)) {
        throw std::runtime_error("GeometryCollection 'geometries' must be an array");
    }
    
    mapbox::geometry::geometry_collection<double> collection;
    
    uint32_t length = 0;
    napi_get_array_length(env, geometries, &length);
    collection.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, geometries, i, &element);
        
        mbgl::Geometry<double> geom = JsObjectToGeometry(env, element);
        collection.push_back(std::move(geom));
    }
    
    return collection;
}

// Geometry 转换为 JS 对象实现

napi_value GeoJsonConverter::PointToJsObject(napi_env env, const mbgl::Point<double>& point) {
    napi_value coordinates;
    napi_create_array_with_length(env, 2, &coordinates);
    
    napi_value x, y;
    napi_create_double(env, point.x, &x);
    napi_create_double(env, point.y, &y);
    napi_set_element(env, coordinates, 0, x);
    napi_set_element(env, coordinates, 1, y);
    
    return CreateGeometryJsObject(env, "Point", coordinates);
}

napi_value GeoJsonConverter::LineStringToJsObject(napi_env env, const mbgl::LineString<double>& lineString) {
    napi_value coordinates = PointVectorToNapiArray(env, lineString);
    return CreateGeometryJsObject(env, "LineString", coordinates);
}

napi_value GeoJsonConverter::PolygonToJsObject(napi_env env, const mbgl::Polygon<double>& polygon) {
    napi_value coordinates = LinearRingVectorToNapiArray(env, polygon);
    return CreateGeometryJsObject(env, "Polygon", coordinates);
}

napi_value GeoJsonConverter::MultiPointToJsObject(napi_env env, const mbgl::MultiPoint<double>& multiPoint) {
    napi_value coordinates = PointVectorToNapiArray(env, multiPoint);
    return CreateGeometryJsObject(env, "MultiPoint", coordinates);
}

napi_value GeoJsonConverter::MultiLineStringToJsObject(napi_env env, const mbgl::MultiLineString<double>& multiLineString) {
    napi_value coordinates = LineStringVectorToNapiArray(env, multiLineString);
    return CreateGeometryJsObject(env, "MultiLineString", coordinates);
}

napi_value GeoJsonConverter::MultiPolygonToJsObject(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon) {
    napi_value coordinates = PolygonVectorToNapiArray(env, multiPolygon);
    return CreateGeometryJsObject(env, "MultiPolygon", coordinates);
}

napi_value GeoJsonConverter::GeometryCollectionToJsObject(napi_env env, const mapbox::geometry::geometry_collection<double>& collection) {
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "GeometryCollection"
    napi_value type;
    napi_create_string_utf8(env, "GeometryCollection", NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // geometries array
    napi_value geometries;
    napi_create_array_with_length(env, collection.size(), &geometries);
    
    for (size_t i = 0; i < collection.size(); i++) {
        napi_value geom = GeometryToJsObject(env, collection[i]);
        napi_set_element(env, geometries, i, geom);
    }
    
    napi_set_named_property(env, result, "geometries", geometries);
    
    return result;
}

napi_value GeoJsonConverter::CreateGeometryJsObject(napi_env env, const std::string& type, napi_value coordinates) {
    napi_value result;
    napi_create_object(env, &result);
    
    // type
    napi_value typeValue;
    napi_create_string_utf8(env, type.c_str(), NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, result, "type", typeValue);
    
    // coordinates
    napi_set_named_property(env, result, "coordinates", coordinates);
    
    return result;
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

