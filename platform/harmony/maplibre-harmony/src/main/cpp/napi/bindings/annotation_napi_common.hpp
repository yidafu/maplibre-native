#ifndef MAPLIBREHARMONY_ANNOTATION_NAPI_COMMON_HPP
#define MAPLIBREHARMONY_ANNOTATION_NAPI_COMMON_HPP

#include <napi/native_api.h>
#include <mln/util/geo.hpp>
#include <mln/util/color.hpp>
#include <mln/util/geometry.hpp>
#include <cstdio>
#include <string>
#include <vector>

#include "geometry/lat_lng_harmony.hpp"

namespace mln {
namespace harmony {

// Shared helpers for the annotation NAPI classes (Marker / Polygon / Polyline).
// Header-only: each function preserves the exact behavior of the inline code it
// replaces (same parsing rules, same JS-visible output shapes).

// Parse a "#RRGGBB" string into mln::Color (alpha is 1.0f on success).
// Returns false when the string does not start with '#' or hex conversion fails;
// in that case `outColor` is left untouched.
inline bool ParseHexColor(const std::string& hex, mln::Color& outColor) {
    if (hex.empty() || hex[0] != '#') {
        return false;
    }
    try {
        unsigned int colorValue = std::stoul(hex.substr(1), nullptr, 16);
        float r = ((colorValue >> 16) & 0xFF) / 255.0f;
        float g = ((colorValue >> 8) & 0xFF) / 255.0f;
        float b = (colorValue & 0xFF) / 255.0f;
        outColor = mln::Color(r, g, b, 1.0f);
        return true;
    } catch (...) {
        return false;
    }
}

// Format an mln::Color as "#RRGGBB" (truncating channels like the previous
// snprintf("#%02X%02X%02X", ...) implementation).
inline std::string ColorToHex(const mln::Color& color) {
    char colorStr[8];
    snprintf(colorStr, sizeof(colorStr), "#%02X%02X%02X",
             static_cast<int>(color.r * 255),
             static_cast<int>(color.g * 255),
             static_cast<int>(color.b * 255));
    return std::string(colorStr);
}

// Parse a single {latitude, longitude} object into mln::Point<double>
// (Point stores x = longitude, y = latitude). Returns false when parsing fails.
inline bool ParseLatLngToPoint(napi_env env, napi_value value, mln::Point<double>& outPoint) {
    mln::LatLng latLng;
    if (!LatLngHarmony::ParseLatLng(env, value, latLng)) {
        return false;
    }
    outPoint = mln::Point<double>(latLng.longitude(), latLng.latitude());
    return true;
}

// Parse a JS array of {latitude, longitude} objects into points
// (x = longitude, y = latitude). Elements that fail to parse are skipped.
// Returns an empty vector when the value is not an array.
inline std::vector<mln::Point<double>> ParseLatLngArrayToPoints(napi_env env, napi_value arrayValue) {
    std::vector<mln::Point<double>> points;
    if (!env || !arrayValue) {
        return points;
    }
    bool isArray = false;
    napi_is_array(env, arrayValue, &isArray);
    if (!isArray) {
        return points;
    }
    uint32_t length = 0;
    napi_get_array_length(env, arrayValue, &length);
    points.reserve(length);
    for (uint32_t i = 0; i < length; i++) {
        napi_value pointValue;
        if (napi_get_element(env, arrayValue, i, &pointValue) != napi_ok) {
            continue;
        }
        mln::Point<double> point;
        if (ParseLatLngToPoint(env, pointValue, point)) {
            points.push_back(point);
        }
    }
    return points;
}

// Convert points (x = longitude, y = latitude) to a JS array of
// {latitude, longitude} objects.
inline napi_value PointArrayToJs(napi_env env, const std::vector<mln::Point<double>>& points) {
    napi_value result;
    napi_create_array_with_length(env, points.size(), &result);

    for (size_t i = 0; i < points.size(); i++) {
        napi_value point = LatLngHarmony::CreateLatLngObject(env, mln::LatLng(points[i].y, points[i].x));
        napi_set_element(env, result, static_cast<uint32_t>(i), point);
    }

    return result;
}

} // namespace harmony
} // namespace mln

#endif // MAPLIBREHARMONY_ANNOTATION_NAPI_COMMON_HPP
