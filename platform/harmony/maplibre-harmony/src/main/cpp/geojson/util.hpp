#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/util/geometry.hpp>
#include <vector>
#include <string>

// Shared mbgl::Value <-> napi_value conversion (single implementation for the
// style and geojson paths).
#include "../style/value_conversion.hpp"

namespace mbgl {
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

// Aliases over the shared Value conversion (style/value_conversion.hpp),
// keeping the historical geojson:: spellings used by geojson_converter.cpp.
inline napi_value PropertyMapToNapiObject(napi_env env, const mbgl::PropertyMap& properties) {
    return mbgl::harmony::valueMapToNapiObject(env, properties);
}

inline mbgl::PropertyMap NapiObjectToPropertyMap(napi_env env, napi_value obj) {
    return mbgl::harmony::napiObjectToValueMap(env, obj);
}

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
} // namespace mbgl

