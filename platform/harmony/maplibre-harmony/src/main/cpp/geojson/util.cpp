#include "util.hpp"
#include "utils/logger.h"
#include <cstring>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {
namespace geojson {

std::vector<double> NapiArrayToDoubleVector(napi_env env, napi_value array) {
    std::vector<double> result;
    
    if (!IsArray(env, array)) {
        return result;
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, array, &length);
    result.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, array, i, &element);
        
        double value = 0.0;
        napi_get_value_double(env, element, &value);
        result.push_back(value);
    }
    
    return result;
}

std::vector<mbgl::Point<double>> NapiArrayToPointVector(napi_env env, napi_value array) {
    std::vector<mbgl::Point<double>> result;
    
    if (!IsArray(env, array)) {
        return result;
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, array, &length);
    result.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, array, i, &element);
        
        // Each element should be a [lng, lat] array
        auto coords = NapiArrayToDoubleVector(env, element);
        if (coords.size() >= 2) {
            result.push_back(mbgl::Point<double>{coords[0], coords[1]});
        }
    }
    
    return result;
}

std::vector<mbgl::LineString<double>> NapiArrayToLineStringVector(napi_env env, napi_value array) {
    std::vector<mbgl::LineString<double>> result;
    
    if (!IsArray(env, array)) {
        return result;
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, array, &length);
    result.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, array, i, &element);
        
        // Each element is a coordinate array
        result.push_back(NapiArrayToPointVector(env, element));
    }
    
    return result;
}

std::vector<mbgl::LinearRing<double>> NapiArrayToLinearRingVector(napi_env env, napi_value array) {
    std::vector<mbgl::LinearRing<double>> result;
    
    if (!IsArray(env, array)) {
        return result;
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, array, &length);
    result.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, array, i, &element);
        
        // Each element is a coordinate array (LinearRing is a vector<Point>)
        mbgl::LinearRing<double> ring = NapiArrayToPointVector(env, element);
        result.push_back(std::move(ring));
    }
    
    return result;
}

std::vector<mbgl::Polygon<double>> NapiArrayToPolygonVector(napi_env env, napi_value array) {
    std::vector<mbgl::Polygon<double>> result;
    
    if (!IsArray(env, array)) {
        return result;
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, array, &length);
    result.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, array, i, &element);
        
        // Each element is a LinearRing array (Polygon is a vector<LinearRing>)
        result.push_back(NapiArrayToLinearRingVector(env, element));
    }
    
    return result;
}

napi_value DoubleVectorToNapiArray(napi_env env, const std::vector<double>& vec) {
    napi_value array;
    napi_create_array_with_length(env, vec.size(), &array);
    
    for (size_t i = 0; i < vec.size(); i++) {
        napi_value element;
        napi_create_double(env, vec[i], &element);
        napi_set_element(env, array, i, element);
    }
    
    return array;
}

napi_value PointVectorToNapiArray(napi_env env, const std::vector<mbgl::Point<double>>& points) {
    napi_value array;
    napi_create_array_with_length(env, points.size(), &array);
    
    for (size_t i = 0; i < points.size(); i++) {
        napi_value coordArray;
        napi_create_array_with_length(env, 2, &coordArray);
        
        napi_value lng, lat;
        napi_create_double(env, points[i].x, &lng);
        napi_create_double(env, points[i].y, &lat);
        
        napi_set_element(env, coordArray, 0, lng);
        napi_set_element(env, coordArray, 1, lat);
        napi_set_element(env, array, i, coordArray);
    }
    
    return array;
}

napi_value LineStringVectorToNapiArray(napi_env env, const std::vector<mbgl::LineString<double>>& lineStrings) {
    napi_value array;
    napi_create_array_with_length(env, lineStrings.size(), &array);
    
    for (size_t i = 0; i < lineStrings.size(); i++) {
        napi_value lineArray = PointVectorToNapiArray(env, lineStrings[i]);
        napi_set_element(env, array, i, lineArray);
    }
    
    return array;
}

napi_value LinearRingVectorToNapiArray(napi_env env, const std::vector<mbgl::LinearRing<double>>& rings) {
    napi_value array;
    napi_create_array_with_length(env, rings.size(), &array);
    
    for (size_t i = 0; i < rings.size(); i++) {
        // LinearRing is essentially a vector<Point>, same as LineString
        napi_value ringArray = PointVectorToNapiArray(env, rings[i]);
        napi_set_element(env, array, i, ringArray);
    }
    
    return array;
}

napi_value PolygonVectorToNapiArray(napi_env env, const std::vector<mbgl::Polygon<double>>& polygons) {
    napi_value array;
    napi_create_array_with_length(env, polygons.size(), &array);
    
    for (size_t i = 0; i < polygons.size(); i++) {
        // Polygon is a vector<LinearRing>
        napi_value polyArray = LinearRingVectorToNapiArray(env, polygons[i]);
        napi_set_element(env, array, i, polyArray);
    }
    
    return array;
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

