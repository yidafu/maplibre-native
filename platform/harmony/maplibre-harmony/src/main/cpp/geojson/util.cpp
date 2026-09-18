#include "util.hpp"
#include "utils/logger.h"
#include <cstring>
#include <optional>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {
namespace geojson {

namespace {

// Walk a JS array and collect one converted value per element. Returns an empty
// vector when `array` is not a JS array. `convert` returns std::nullopt for
// elements that must be skipped (e.g. malformed coordinates).
template <typename T, typename Convert>
std::vector<T> MapNapiArray(napi_env env, napi_value array, Convert&& convert) {
    std::vector<T> result;
    if (!IsArray(env, array)) {
        return result;
    }

    uint32_t length = 0;
    napi_get_array_length(env, array, &length);
    result.reserve(length);

    for (uint32_t i = 0; i < length; i++) {
        napi_value element = nullptr;
        napi_get_element(env, array, i, &element);
        if (auto converted = convert(element)) {
            result.push_back(std::move(*converted));
        }
    }

    return result;
}

// Build a JS array holding `convert` applied to every element of `vec`.
template <typename T, typename Convert>
napi_value MapVectorToNapiArray(napi_env env, const std::vector<T>& vec, Convert&& convert) {
    napi_value array = nullptr;
    napi_create_array_with_length(env, vec.size(), &array);

    for (size_t i = 0; i < vec.size(); i++) {
        napi_set_element(env, array, i, convert(vec[i]));
    }

    return array;
}

} // namespace

std::vector<double> NapiArrayToDoubleVector(napi_env env, napi_value array) {
    return MapNapiArray<double>(env, array, [env](napi_value element) -> std::optional<double> {
        double value = 0.0;
        napi_get_value_double(env, element, &value);
        return value;
    });
}

std::vector<mbgl::Point<double>> NapiArrayToPointVector(napi_env env, napi_value array) {
    return MapNapiArray<mbgl::Point<double>>(
        env, array, [env](napi_value element) -> std::optional<mbgl::Point<double>> {
            // Each element should be a [lng, lat] array
            auto coords = NapiArrayToDoubleVector(env, element);
            if (coords.size() >= 2) {
                return mbgl::Point<double>{coords[0], coords[1]};
            }
            return std::nullopt;
        });
}

std::vector<mbgl::LineString<double>> NapiArrayToLineStringVector(napi_env env, napi_value array) {
    return MapNapiArray<mbgl::LineString<double>>(
        env, array, [env](napi_value element) -> std::optional<mbgl::LineString<double>> {
            // Each element is a coordinate array
            return NapiArrayToPointVector(env, element);
        });
}

std::vector<mbgl::LinearRing<double>> NapiArrayToLinearRingVector(napi_env env, napi_value array) {
    return MapNapiArray<mbgl::LinearRing<double>>(
        env, array, [env](napi_value element) -> std::optional<mbgl::LinearRing<double>> {
            // Each element is a coordinate array (LinearRing is a vector<Point>)
            return NapiArrayToPointVector(env, element);
        });
}

std::vector<mbgl::Polygon<double>> NapiArrayToPolygonVector(napi_env env, napi_value array) {
    return MapNapiArray<mbgl::Polygon<double>>(
        env, array, [env](napi_value element) -> std::optional<mbgl::Polygon<double>> {
            // Each element is a LinearRing array (Polygon is a vector<LinearRing>)
            return NapiArrayToLinearRingVector(env, element);
        });
}

napi_value DoubleVectorToNapiArray(napi_env env, const std::vector<double>& vec) {
    return MapVectorToNapiArray(env, vec, [env](double value) {
        napi_value element = nullptr;
        napi_create_double(env, value, &element);
        return element;
    });
}

napi_value PointVectorToNapiArray(napi_env env, const std::vector<mbgl::Point<double>>& points) {
    return MapVectorToNapiArray(env, points, [env](const mbgl::Point<double>& point) {
        napi_value coordArray = nullptr;
        napi_create_array_with_length(env, 2, &coordArray);

        napi_value lng = nullptr;
        napi_value lat = nullptr;
        napi_create_double(env, point.x, &lng);
        napi_create_double(env, point.y, &lat);

        napi_set_element(env, coordArray, 0, lng);
        napi_set_element(env, coordArray, 1, lat);
        return coordArray;
    });
}

napi_value LineStringVectorToNapiArray(napi_env env, const std::vector<mbgl::LineString<double>>& lineStrings) {
    return MapVectorToNapiArray(env, lineStrings, [env](const mbgl::LineString<double>& lineString) {
        return PointVectorToNapiArray(env, lineString);
    });
}

napi_value LinearRingVectorToNapiArray(napi_env env, const std::vector<mbgl::LinearRing<double>>& rings) {
    return MapVectorToNapiArray(env, rings, [env](const mbgl::LinearRing<double>& ring) {
        // LinearRing is essentially a vector<Point>, same as LineString
        return PointVectorToNapiArray(env, ring);
    });
}

napi_value PolygonVectorToNapiArray(napi_env env, const std::vector<mbgl::Polygon<double>>& polygons) {
    return MapVectorToNapiArray(env, polygons, [env](const mbgl::Polygon<double>& polygon) {
        // Polygon is a vector<LinearRing>
        return LinearRingVectorToNapiArray(env, polygon);
    });
}

// MbglValueToNapiValue / NapiValueToMbglValue / PropertyMapToNapiObject /
// NapiObjectToPropertyMap were unified into style/value_conversion.{hpp,cpp};
// geojson/util.hpp exposes thin aliases over the shared implementation.

std::string GetStringProperty(napi_env env, napi_value obj, const char* key) {
    napi_value value;
    if (napi_get_named_property(env, obj, key, &value) != napi_ok) {
        return {};
    }

    size_t length = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) {
        // Property missing or not a string — return empty instead of
        // allocating from an uninitialized length.
        return {};
    }
    std::string result(length, '\0');
    if (length > 0 &&
        napi_get_value_string_utf8(env, value, &result[0], length + 1, nullptr) != napi_ok) {
        return {};
    }
    
    return result;
}

double GetNumberProperty(napi_env env, napi_value obj, const char* key) {
    napi_value value;
    napi_get_named_property(env, obj, key, &value);
    
    double result = 0.0;
    napi_get_value_double(env, value, &result);
    
    return result;
}

napi_value GetObjectProperty(napi_env env, napi_value obj, const char* key) {
    napi_value value;
    napi_get_named_property(env, obj, key, &value);
    return value;
}

bool HasProperty(napi_env env, napi_value obj, const char* key) {
    bool hasProperty = false;
    napi_has_named_property(env, obj, key, &hasProperty);
    return hasProperty;
}

bool IsString(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    return type == napi_string;
}

bool IsNumber(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    return type == napi_number;
}

bool IsArray(napi_env env, napi_value value) {
    bool isArray = false;
    napi_is_array(env, value, &isArray);
    return isArray;
}

bool IsObject(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    return type == napi_object;
}

bool IsNull(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    return type == napi_null;
}

bool IsUndefined(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    return type == napi_undefined;
}

} // namespace geojson
} // namespace harmony
} // namespace mbgl

