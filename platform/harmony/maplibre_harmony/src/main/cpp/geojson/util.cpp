#include "util.hpp"
#include "utils/logger.h"
#include <cstring>

using mbgl::harmony::Logger;

namespace maplibre {
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
        
        // 每个元素应该是 [lng, lat] 数组
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
        
        // 每个元素是坐标数组
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
        
        // 每个元素是坐标数组 (LinearRing is a vector<Point>)
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
        
        // 每个元素是 LinearRing 数组 (Polygon is a vector<LinearRing>)
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

napi_value MbglValueToNapiValue(napi_env env, const mbgl::Value& value) {
    napi_value result;
    
    if (value.is<mbgl::NullValue>()) {
        napi_get_null(env, &result);
    } else if (value.is<bool>()) {
        napi_get_boolean(env, value.get<bool>(), &result);
    } else if (value.is<uint64_t>()) {
        napi_create_double(env, static_cast<double>(value.get<uint64_t>()), &result);
    } else if (value.is<int64_t>()) {
        napi_create_double(env, static_cast<double>(value.get<int64_t>()), &result);
    } else if (value.is<double>()) {
        napi_create_double(env, value.get<double>(), &result);
    } else if (value.is<std::string>()) {
        napi_create_string_utf8(env, value.get<std::string>().c_str(), NAPI_AUTO_LENGTH, &result);
    } else if (value.is<std::vector<mbgl::Value>>()) {
        const auto& vec = value.get<std::vector<mbgl::Value>>();
        napi_create_array_with_length(env, vec.size(), &result);
        for (size_t i = 0; i < vec.size(); i++) {
            napi_value element = MbglValueToNapiValue(env, vec[i]);
            napi_set_element(env, result, i, element);
        }
    } else if (value.is<mbgl::PropertyMap>()) {
        result = PropertyMapToNapiObject(env, value.get<mbgl::PropertyMap>());
    } else {
        napi_get_null(env, &result);
    }
    
    return result;
}

mbgl::Value NapiValueToMbglValue(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    
    switch (type) {
        case napi_null:
        case napi_undefined:
            return mbgl::NullValue{};
            
        case napi_boolean: {
            bool boolValue;
            napi_get_value_bool(env, value, &boolValue);
            return boolValue;
        }
        
        case napi_number: {
            double numValue;
            napi_get_value_double(env, value, &numValue);
            return numValue;
        }
        
        case napi_string: {
            size_t length;
            napi_get_value_string_utf8(env, value, nullptr, 0, &length);
            std::string str(length, '\0');
            napi_get_value_string_utf8(env, value, &str[0], length + 1, &length);
            return str;
        }
        
        case napi_object: {
            bool isArray;
            napi_is_array(env, value, &isArray);
            
            if (isArray) {
                uint32_t arrayLength;
                napi_get_array_length(env, value, &arrayLength);
                std::vector<mbgl::Value> vec;
                vec.reserve(arrayLength);
                
                for (uint32_t i = 0; i < arrayLength; i++) {
                    napi_value element;
                    napi_get_element(env, value, i, &element);
                    vec.push_back(NapiValueToMbglValue(env, element));
                }
                return vec;
            } else {
                return NapiObjectToPropertyMap(env, value);
            }
        }
        
        default:
            return mbgl::NullValue{};
    }
}

napi_value PropertyMapToNapiObject(napi_env env, const mbgl::PropertyMap& properties) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    for (const auto& [key, value] : properties) {
        napi_value napiValue = MbglValueToNapiValue(env, value);
        napi_set_named_property(env, obj, key.c_str(), napiValue);
    }
    
    return obj;
}

mbgl::PropertyMap NapiObjectToPropertyMap(napi_env env, napi_value obj) {
    mbgl::PropertyMap result;
    
    if (!IsObject(env, obj)) {
        return result;
    }
    
    napi_value propertyNames;
    napi_get_property_names(env, obj, &propertyNames);
    
    uint32_t length;
    napi_get_array_length(env, propertyNames, &length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value keyValue;
        napi_get_element(env, propertyNames, i, &keyValue);
        
        size_t keyLength;
        napi_get_value_string_utf8(env, keyValue, nullptr, 0, &keyLength);
        std::string key(keyLength, '\0');
        napi_get_value_string_utf8(env, keyValue, &key[0], keyLength + 1, &keyLength);
        
        napi_value value;
        napi_get_named_property(env, obj, key.c_str(), &value);
        
        result[key] = NapiValueToMbglValue(env, value);
    }
    
    return result;
}

std::string GetStringProperty(napi_env env, napi_value obj, const char* key) {
    napi_value value;
    napi_get_named_property(env, obj, key, &value);
    
    size_t length;
    napi_get_value_string_utf8(env, value, nullptr, 0, &length);
    std::string result(length, '\0');
    napi_get_value_string_utf8(env, value, &result[0], length + 1, &length);
    
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
} // namespace maplibre

