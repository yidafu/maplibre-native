#include "value_conversion.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using mbgl::harmony::Logger;

// 类型别名，简化代码
using Value = mapbox::feature::value;

Value napiValueToMbglValue(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    
    if (status != napi_ok) {
        Logger::error("ValueConversion", "Failed to get value type");
        return mapbox::feature::null_value_t{};
    }
    
    switch (type) {
        case napi_undefined:
        case napi_null: {
            return mapbox::feature::null_value_t{};
        }
        
        case napi_boolean: {
            bool boolValue;
            napi_get_value_bool(env, value, &boolValue);
            return boolValue;
        }
        
        case napi_number: {
            double numberValue;
            napi_get_value_double(env, value, &numberValue);
            
            // Check if it's an integer
            int64_t intValue;
            if (napi_get_value_int64(env, value, &intValue) == napi_ok) {
                // If the double and int64 are equal, it's an integer
                if (static_cast<double>(intValue) == numberValue) {
                    return static_cast<uint64_t>(intValue);
                }
            }
            
            return numberValue;
        }
        
        case napi_string: {
            size_t length;
            napi_get_value_string_utf8(env, value, nullptr, 0, &length);
            std::string str(length, '\0');
            napi_get_value_string_utf8(env, value, &str[0], length + 1, nullptr);
            return str;
        }
        
        case napi_object: {
            // Check if it's an array
            bool isArray;
            napi_is_array(env, value, &isArray);
            
            if (isArray) {
                return napiArrayToValueVector(env, value);
            } else {
                return napiObjectToValueMap(env, value);
            }
        }
        
        default: {
            Logger::warn("ValueConversion", "Unsupported value type: %d, treating as null", type);
            return mapbox::feature::null_value_t{};
        }
    }
}

napi_value mbglValueToNapiValue(napi_env env, const Value& value) {
    napi_value result;
    
    return value.match(
        [&](mapbox::feature::null_value_t) -> napi_value {
            napi_get_null(env, &result);
            return result;
        },
        [&](bool boolValue) -> napi_value {
            napi_get_boolean(env, boolValue, &result);
            return result;
        },
        [&](uint64_t intValue) -> napi_value {
            napi_create_int64(env, static_cast<int64_t>(intValue), &result);
            return result;
        },
        [&](int64_t intValue) -> napi_value {
            napi_create_int64(env, intValue, &result);
            return result;
        },
        [&](double doubleValue) -> napi_value {
            napi_create_double(env, doubleValue, &result);
            return result;
        },
        [&](const std::string& strValue) -> napi_value {
            napi_create_string_utf8(env, strValue.c_str(), NAPI_AUTO_LENGTH, &result);
            return result;
        },
        [&](const std::vector<Value>& vec) -> napi_value {
            return valueVectorToNapiArray(env, vec);
        },
        [&](const std::unordered_map<std::string, Value>& map) -> napi_value {
            return valueMapToNapiObject(env, map);
        }
    );
}

std::vector<Value> napiArrayToValueVector(napi_env env, napi_value array) {
    std::vector<Value> result;
    
    uint32_t length;
    napi_status status = napi_get_array_length(env, array, &length);
    
    if (status != napi_ok) {
        Logger::error("ValueConversion", "Failed to get array length");
        return result;
    }
    
    result.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value element;
        napi_get_element(env, array, i, &element);
        result.push_back(napiValueToMbglValue(env, element));
    }
    
    return result;
}

std::unordered_map<std::string, Value> napiObjectToValueMap(
    napi_env env, 
    napi_value object
) {
    std::unordered_map<std::string, Value> result;
    
    napi_value propertyNames;
    napi_status status = napi_get_property_names(env, object, &propertyNames);
    
    if (status != napi_ok) {
        Logger::error("ValueConversion", "Failed to get property names");
        return result;
    }
    
    uint32_t length;
    napi_get_array_length(env, propertyNames, &length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value keyValue;
        napi_get_element(env, propertyNames, i, &keyValue);
        
        size_t keyLength;
        napi_get_value_string_utf8(env, keyValue, nullptr, 0, &keyLength);
        std::string key(keyLength, '\0');
        napi_get_value_string_utf8(env, keyValue, &key[0], keyLength + 1, nullptr);
        
        napi_value propValue;
        napi_get_property(env, object, keyValue, &propValue);
        
        result[key] = napiValueToMbglValue(env, propValue);
    }
    
    return result;
}

napi_value valueVectorToNapiArray(
    napi_env env, 
    const std::vector<Value>& vec
) {
    napi_value result;
    napi_create_array_with_length(env, vec.size(), &result);
    
    for (size_t i = 0; i < vec.size(); i++) {
        napi_value element = mbglValueToNapiValue(env, vec[i]);
        napi_set_element(env, result, static_cast<uint32_t>(i), element);
    }
    
    return result;
}

napi_value valueMapToNapiObject(
    napi_env env,
    const std::unordered_map<std::string, Value>& map
) {
    napi_value result;
    napi_create_object(env, &result);
    
    for (const auto& pair : map) {
        napi_value value = mbglValueToNapiValue(env, pair.second);
        napi_set_named_property(env, result, pair.first.c_str(), value);
    }
    
    return result;
}

} // namespace harmony
} // namespace mbgl

