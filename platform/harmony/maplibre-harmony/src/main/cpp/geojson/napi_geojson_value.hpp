#ifndef MAPLIBRE_HARMONY_NAPI_GEOJSON_VALUE_HPP
#define MAPLIBRE_HARMONY_NAPI_GEOJSON_VALUE_HPP

// Shared conversion of a JS GeoJSON payload (JSON string, or
// FeatureCollection / Feature / Geometry object) into mbgl::GeoJSON.
// GeoJsonSource::setGeoJson and CustomGeometrySource::setTileData used to
// hand-duplicate this dispatch.

#include "napi/core/napi_utils.h"
#include "geojson/util.hpp"
#include "geojson/geojson_converter.hpp"

#include <mbgl/style/conversion/json.hpp>
#include <mbgl/util/geojson.hpp>

#include <string>

namespace mbgl {
namespace harmony {
namespace geojson {

/** Converted value plus the payload kind, for per-branch caller logging:
 *  "string" for JSON text, otherwise the raw "type" property of the object. */
struct GeoJSONValueConversion {
    mbgl::GeoJSON value;
    std::string kind;
};

/**
 * Convert `value` into `out`. On failure a JS exception is left pending and
 * `false` is returned; the caller only has to bail out. `invalidTypeMessage`
 * preserves each caller's historical wording.
 */
inline bool NapiValueToGeoJSON(napi_env env, napi_value value,
                               GeoJSONValueConversion& out,
                               const char* invalidTypeMessage) {
    if (IsString(env, value)) {
        // String type: parse JSON
        std::string geoJsonString = napi::GetStringFromValue(env, value);

        mbgl::style::conversion::Error error;
        auto geoJson = mbgl::style::conversion::convertJSON<mbgl::GeoJSON>(geoJsonString, error);

        if (!geoJson) {
            napi_throw_error(env, nullptr, error.message.c_str());
            return false;
        }

        out.value = std::move(*geoJson);
        out.kind = "string";
        return true;
    }

    if (IsObject(env, value)) {
        // Object type: inspect the type property
        std::string type;
        if (HasProperty(env, value, "type")) {
            type = GetStringProperty(env, value, "type");
        }

        if (type == "FeatureCollection") {
            out.value = mbgl::GeoJSON(GeoJsonConverter::JsObjectToFeatureCollection(env, value));
        } else if (type == "Feature") {
            auto feature = GeoJsonConverter::JsObjectToFeature(env, value);
            // Convert to GeoJSONFeature
            mbgl::GeoJSONFeature geoJsonFeature;
            geoJsonFeature.geometry = feature.geometry;
            geoJsonFeature.properties = feature.properties;
            geoJsonFeature.id = feature.id;
            out.value = mbgl::GeoJSON(std::move(geoJsonFeature));
        } else {
            // Geometry object
            out.value = mbgl::GeoJSON(GeoJsonConverter::JsObjectToGeometry(env, value));
        }
        out.kind = type;
        return true;
    }

    napi_throw_error(env, nullptr, invalidTypeMessage);
    return false;
}

} // namespace geojson
} // namespace harmony
} // namespace mbgl

#endif // MAPLIBRE_HARMONY_NAPI_GEOJSON_VALUE_HPP
