#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/util/geometry.hpp>
#include <vector>
#include <string>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * Convert a NAPI array to a vector of doubles.
 */
std::vector<double> NapiArrayToDoubleVector(napi_env env, napi_value array);

/**
 * Convert a NAPI array to a vector of coordinate points.
 */
std::vector<mbgl::Point<double>> NapiArrayToPointVector(napi_env env, napi_value array);

/**
 * Convert a NAPI array to a vector of LineStrings.
 */
std::vector<mbgl::LineString<double>> NapiArrayToLineStringVector(napi_env env, napi_value array);

/**
 * Convert a NAPI array to a vector of LinearRings (for a single polygon).
 */
std::vector<mbgl::LinearRing<double>> NapiArrayToLinearRingVector(napi_env env, napi_value array);

/**
 * Convert a NAPI array to a vector of Polygons.
 */
std::vector<mbgl::Polygon<double>> NapiArrayToPolygonVector(napi_env env, napi_value array);

/**
 * Convert a vector of doubles to a NAPI array.
 */
napi_value DoubleVectorToNapiArray(napi_env env, const std::vector<double>& vec);

/**
 * Convert a vector of points to a NAPI array.
 */
napi_value PointVectorToNapiArray(napi_env env, const std::vector<mbgl::Point<double>>& points);

/**
 * Convert a vector of LineStrings to a NAPI array.
 */
napi_value LineStringVectorToNapiArray(napi_env env, const std::vector<mbgl::LineString<double>>& lineStrings);

/**
 * Convert a vector of LinearRings to a NAPI array (for polygon rings).
 */
napi_value LinearRingVectorToNapiArray(napi_env env, const std::vector<mbgl::LinearRing<double>>& rings);

/**
 * Convert a vector of Polygons to a NAPI array.
 */
napi_value PolygonVectorToNapiArray(napi_env env, const std::vector<mbgl::Polygon<double>>& polygons);

/**
 * Convert an mbgl::PropertyMap to a NAPI object.
 */
napi_value PropertyMapToNapiObject(napi_env env, const mbgl::PropertyMap& properties);

/**
 * Convert a NAPI object to an mbgl::PropertyMap.
 */
mbgl::PropertyMap NapiObjectToPropertyMap(napi_env env, napi_value obj);

/**
 * Convert an mbgl::Value to a NAPI value.
 */
napi_value MbglValueToNapiValue(napi_env env, const mbgl::Value& value);

/**
 * Convert a NAPI value to an mbgl::Value.
 */
mbgl::Value NapiValueToMbglValue(napi_env env, napi_value value);

/**
 * Get a string property from an object.
 */
std::string GetStringProperty(napi_env env, napi_value obj, const char* key);

/**
 * Get a numeric property from an object.
 */
double GetNumberProperty(napi_env env, napi_value obj, const char* key);

/**
 * Get an object property from an object.
 */
napi_value GetObjectProperty(napi_env env, napi_value obj, const char* key);

/**
 * Check whether an object has a given property.
 */
bool HasProperty(napi_env env, napi_value obj, const char* key);

/**
 * Type-check helpers.
 */
bool IsString(napi_env env, napi_value value);
bool IsNumber(napi_env env, napi_value value);
bool IsArray(napi_env env, napi_value value);
bool IsObject(napi_env env, napi_value value);
bool IsNull(napi_env env, napi_value value);
bool IsUndefined(napi_env env, napi_value value);

} // namespace geojson
} // namespace harmony
} // namespace maplibre

