#pragma once

#include <napi/native_api.h>
#include <mln/util/feature.hpp>
#include <mln/util/geometry.hpp>
#include <mln/util/geojson.hpp>
#include <vector>

namespace mln {
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
     * Convert a JS object into mln::Geometry.
     *
     * @param env NAPI environment
     * @param jsObj JS object with type and coordinates fields
     * @return mln::Geometry<double>
     * @throws std::runtime_error if the object format is invalid
     */
    static mln::Geometry<double> JsObjectToGeometry(napi_env env, napi_value jsObj);
    
    /**
     * Convert a JS object into mln::Feature.
     *
     * @param env NAPI environment
     * @param jsObj JS object with type, geometry, and properties fields
     * @return mln::Feature
     * @throws std::runtime_error if the object format is invalid
     */
    static mln::Feature JsObjectToFeature(napi_env env, napi_value jsObj);
    
    /**
     * Convert a JS object into mln::FeatureCollection.
     *
     * @param env NAPI environment
     * @param jsObj JS object with type and features fields
     * @return mln::FeatureCollection
     * @throws std::runtime_error if the object format is invalid
     */
    static mln::FeatureCollection JsObjectToFeatureCollection(napi_env env, napi_value jsObj);
    
    /**
     * Convert a JS object into mln::GeoJSON (generic conversion).
     *
     * @param env NAPI environment
     * @param jsObj JS object representing Geometry, Feature, or FeatureCollection
     * @return mln::GeoJSON
     * @throws std::runtime_error if the object format is invalid
     */
    static mln::GeoJSON JsObjectToGeoJSON(napi_env env, napi_value jsObj);
    
    // ==================== C++ -> JS Object ====================
    
    /**
     * Convert mln::Geometry to a JS object.
     *
     * @param env NAPI environment
     * @param geometry C++ Geometry instance
     * @return napi_value JS object
     */
    static napi_value GeometryToJsObject(napi_env env, const mln::Geometry<double>& geometry);
    
    /**
     * Convert mln::Feature to a JS object.
     *
     * @param env NAPI environment
     * @param feature C++ Feature instance
     * @return napi_value JS object
     */
    static napi_value FeatureToJsObject(napi_env env, const mln::Feature& feature);
    
    /**
     * Convert mln::FeatureCollection to a JS object.
     *
     * @param env NAPI environment
     * @param features C++ FeatureCollection
     * @return napi_value JS object
     */
    static napi_value FeatureCollectionToJsObject(napi_env env, const mln::FeatureCollection& features);
    
    /**
     * Convert a vector of Features to a JS array.
     *
     * @param env NAPI environment
     * @param features C++ Feature vector
     * @return napi_value JS array
     */
    static napi_value FeatureArrayToJsArray(napi_env env, const std::vector<mln::Feature>& features);

private:
    // Helper: parse Geometry based on the type field
    static mln::Geometry<double> ParseGeometryByType(napi_env env, napi_value jsObj, const std::string& type);
    
    // Helper: create a Geometry JS object
    static napi_value CreateGeometryJsObject(napi_env env, const std::string& type, napi_value coordinates);
    
    // Geometry parsing helpers
    static mln::Point<double> ParsePoint(napi_env env, napi_value coordinates);
    static mln::LineString<double> ParseLineString(napi_env env, napi_value coordinates);
    static mln::Polygon<double> ParsePolygon(napi_env env, napi_value coordinates);
    static mln::MultiPoint<double> ParseMultiPoint(napi_env env, napi_value coordinates);
    static mln::MultiLineString<double> ParseMultiLineString(napi_env env, napi_value coordinates);
    static mln::MultiPolygon<double> ParseMultiPolygon(napi_env env, napi_value coordinates);
    static mapbox::geometry::geometry_collection<double> ParseGeometryCollection(napi_env env, napi_value geometries);
    
    // Geometry to JS conversion helpers
    static napi_value PointToJsObject(napi_env env, const mln::Point<double>& point);
    static napi_value LineStringToJsObject(napi_env env, const mln::LineString<double>& lineString);
    static napi_value PolygonToJsObject(napi_env env, const mln::Polygon<double>& polygon);
    static napi_value MultiPointToJsObject(napi_env env, const mln::MultiPoint<double>& multiPoint);
    static napi_value MultiLineStringToJsObject(napi_env env, const mln::MultiLineString<double>& multiLineString);
    static napi_value MultiPolygonToJsObject(napi_env env, const mln::MultiPolygon<double>& multiPolygon);
    static napi_value GeometryCollectionToJsObject(napi_env env, const mapbox::geometry::geometry_collection<double>& collection);
};

} // namespace geojson
} // namespace harmony
} // namespace mln

