#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/util/geometry.hpp>
#include <mbgl/util/geojson.hpp>
#include <vector>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * GeoJSON converter bridging JavaScript objects and C++ GeoJSON types.
 *
 * Replaces the old NAPI class bindings by representing GeoJSON structures with plain JS objects.
 */
class GeoJsonConverter {
public:
    // ==================== JS Object -> C++ ====================
    
    /**
     * Convert a JS object into mbgl::Geometry.
     *
     * @param env NAPI environment
     * @param jsObj JS object with type and coordinates fields
     * @return mbgl::Geometry<double>
     * @throws std::runtime_error if the object format is invalid
     */
    static mbgl::Geometry<double> JsObjectToGeometry(napi_env env, napi_value jsObj);
    
    /**
     * Convert a JS object into mbgl::Feature.
     *
     * @param env NAPI environment
     * @param jsObj JS object with type, geometry, and properties fields
     * @return mbgl::Feature
     * @throws std::runtime_error if the object format is invalid
     */
    static mbgl::Feature JsObjectToFeature(napi_env env, napi_value jsObj);
    
    /**
     * Convert a JS object into mbgl::FeatureCollection.
     *
     * @param env NAPI environment
     * @param jsObj JS object with type and features fields
     * @return mbgl::FeatureCollection
     * @throws std::runtime_error if the object format is invalid
     */
    static mbgl::FeatureCollection JsObjectToFeatureCollection(napi_env env, napi_value jsObj);
    
    /**
     * Convert a JS object into mbgl::GeoJSON (generic conversion).
     *
     * @param env NAPI environment
     * @param jsObj JS object representing Geometry, Feature, or FeatureCollection
     * @return mbgl::GeoJSON
     * @throws std::runtime_error if the object format is invalid
     */
    static mbgl::GeoJSON JsObjectToGeoJSON(napi_env env, napi_value jsObj);
    
    // ==================== C++ -> JS Object ====================
    
    /**
     * Convert mbgl::Geometry to a JS object.
     *
     * @param env NAPI environment
     * @param geometry C++ Geometry instance
     * @return napi_value JS object
     */
    static napi_value GeometryToJsObject(napi_env env, const mbgl::Geometry<double>& geometry);
    
    /**
     * Convert mbgl::Feature to a JS object.
     *
     * @param env NAPI environment
     * @param feature C++ Feature instance
     * @return napi_value JS object
     */
    static napi_value FeatureToJsObject(napi_env env, const mbgl::Feature& feature);
    
    /**
     * Convert mbgl::FeatureCollection to a JS object.
     *
     * @param env NAPI environment
     * @param features C++ FeatureCollection
     * @return napi_value JS object
     */
    static napi_value FeatureCollectionToJsObject(napi_env env, const mbgl::FeatureCollection& features);
    
    /**
     * Convert a vector of Features to a JS array.
     *
     * @param env NAPI environment
     * @param features C++ Feature vector
     * @return napi_value JS array
     */
    static napi_value FeatureArrayToJsArray(napi_env env, const std::vector<mbgl::Feature>& features);

private:
    // Helper: parse Geometry based on the type field
    static mbgl::Geometry<double> ParseGeometryByType(napi_env env, napi_value jsObj, const std::string& type);
    
    // Helper: create a Geometry JS object
    static napi_value CreateGeometryJsObject(napi_env env, const std::string& type, napi_value coordinates);
    
    // Geometry parsing helpers
    static mbgl::Point<double> ParsePoint(napi_env env, napi_value coordinates);
    static mbgl::LineString<double> ParseLineString(napi_env env, napi_value coordinates);
    static mbgl::Polygon<double> ParsePolygon(napi_env env, napi_value coordinates);
    static mbgl::MultiPoint<double> ParseMultiPoint(napi_env env, napi_value coordinates);
    static mbgl::MultiLineString<double> ParseMultiLineString(napi_env env, napi_value coordinates);
    static mbgl::MultiPolygon<double> ParseMultiPolygon(napi_env env, napi_value coordinates);
    static mapbox::geometry::geometry_collection<double> ParseGeometryCollection(napi_env env, napi_value geometries);
    
    // Geometry to JS conversion helpers
    static napi_value PointToJsObject(napi_env env, const mbgl::Point<double>& point);
    static napi_value LineStringToJsObject(napi_env env, const mbgl::LineString<double>& lineString);
    static napi_value PolygonToJsObject(napi_env env, const mbgl::Polygon<double>& polygon);
    static napi_value MultiPointToJsObject(napi_env env, const mbgl::MultiPoint<double>& multiPoint);
    static napi_value MultiLineStringToJsObject(napi_env env, const mbgl::MultiLineString<double>& multiLineString);
    static napi_value MultiPolygonToJsObject(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon);
    static napi_value GeometryCollectionToJsObject(napi_env env, const mapbox::geometry::geometry_collection<double>& collection);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

