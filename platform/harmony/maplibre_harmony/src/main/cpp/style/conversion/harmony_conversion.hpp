#pragma once

#include "../napi_value_wrapper.hpp"

#include <mbgl/util/feature.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/geojson.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/style/conversion_impl.hpp>

#include <optional>
#include <string>

namespace mbgl {
namespace style {
namespace conversion {

/**
 * ConversionTraits specialization for Harmony NAPI values
 * 
 * This enables the MapLibre conversion system to work with NAPI values,
 * allowing seamless conversion from JavaScript/ArkTS values to C++ types.
 */
template <>
class ConversionTraits<mbgl::harmony::NapiValue> {
public:
    static bool isUndefined(const mbgl::harmony::NapiValue& value) { 
        return value.isNull() || value.isUndefined(); 
    }

    static bool isArray(const mbgl::harmony::NapiValue& value) { 
        return value.isArray(); 
    }

    static bool isObject(const mbgl::harmony::NapiValue& value) { 
        return value.isObject(); 
    }

    static std::size_t arrayLength(const mbgl::harmony::NapiValue& value) {
        return value.getLength();
    }

    static mbgl::harmony::NapiValue arrayMember(const mbgl::harmony::NapiValue& value, std::size_t i) { 
        return value.get(i); 
    }

    static std::optional<mbgl::harmony::NapiValue> objectMember(
        const mbgl::harmony::NapiValue& value, 
        const char* key
    ) {
        mbgl::harmony::NapiValue member = value.get(key);
        if (!member.isUndefined() && !member.isNull()) {
            return member;
        } else {
            return {};
        }
    }

    template <class Fn>
    static std::optional<Error> eachMember(
        const mbgl::harmony::NapiValue& value, 
        Fn&& fn
    ) {
        assert(value.isObject());
        mbgl::harmony::NapiValue keys = value.keyArray();
        std::size_t length = arrayLength(keys);
        for (std::size_t i = 0; i < length; ++i) {
            const auto k = keys.get(i).toString();
            auto v = value.get(k.c_str());
            std::optional<Error> result = fn(k, std::move(v));
            if (result) {
                return result;
            }
        }
        return {};
    }

    static std::optional<bool> toBool(const mbgl::harmony::NapiValue& value) {
        if (value.isBool()) {
            return value.toBool();
        } else {
            return {};
        }
    }

    static std::optional<float> toNumber(const mbgl::harmony::NapiValue& value) {
        if (value.isNumber()) {
            return value.toFloat();
        } else {
            return {};
        }
    }

    static std::optional<double> toDouble(const mbgl::harmony::NapiValue& value) {
        if (value.isNumber()) {
            return value.toDouble();
        } else {
            return {};
        }
    }

    static std::optional<std::string> toString(const mbgl::harmony::NapiValue& value) {
        if (value.isString()) {
            return value.toString();
        } else {
            return {};
        }
    }

    static std::optional<Value> toValue(const mbgl::harmony::NapiValue& value) {
        if (value.isNull() || value.isUndefined()) {
            return {};
        } else if (value.isBool()) {
            return {value.toBool()};
        } else if (value.isString()) {
            return {value.toString()};
        } else if (value.isNumber()) {
            // Try to detect if it's an integer
            double d = value.toDouble();
            int64_t i = value.toLong();
            if (static_cast<double>(i) == d) {
                return {static_cast<uint64_t>(i)};
            }
            return {d};
        } else {
            return {};
        }
    }

    static std::optional<GeoJSON> toGeoJSON(const mbgl::harmony::NapiValue& value, Error& error) {
        if (value.isNull() || value.isUndefined()) {
            error = {"no json data found"};
            return {};
        }

        if (value.isString()) {
            return parseGeoJSON(value.toString(), error);
        }

        if (value.isObject() || value.isArray()) {
            // JavaScript GeoJSON object: serialize with JSON.stringify and
            // reuse the string parser. Must run on the JS thread (napi_env).
            napi_env env = value.getEnv();
            napi_value global;
            if (napi_get_global(env, &global) != napi_ok) {
                error = {"failed to access JS global object"};
                return {};
            }
            napi_value json;
            if (napi_get_named_property(env, global, "JSON", &json) != napi_ok) {
                error = {"failed to access JSON object"};
                return {};
            }
            napi_value stringify;
            if (napi_get_named_property(env, json, "stringify", &stringify) != napi_ok) {
                error = {"failed to access JSON.stringify"};
                return {};
            }
            napi_value argv[] = {value.getValue()};
            napi_value result;
            if (napi_call_function(env, json, stringify, 1, argv, &result) != napi_ok) {
                error = {"JSON.stringify failed for GeoJSON object"};
                return {};
            }
            size_t length = 0;
            if (napi_get_value_string_utf8(env, result, nullptr, 0, &length) != napi_ok) {
                error = {"JSON.stringify did not return a string"};
                return {};
            }
            std::string jsonText(length, '\0');
            if (napi_get_value_string_utf8(env, result, jsonText.data(), length + 1, nullptr) != napi_ok) {
                error = {"failed to read serialized GeoJSON"};
                return {};
            }
            return parseGeoJSON(jsonText, error);
        }

        error = {"GeoJSON must be provided as a JSON string or object"};
        return {};
    }
};

/**
 * Helper function to convert from NapiValue with error handling
 */
template <class T, class... Args>
std::optional<T> convert(mbgl::harmony::NapiValue&& value, Error& error, Args&&... args) {
    return convert<T>(Convertible(std::move(value)), error, std::forward<Args>(args)...);
}

} // namespace conversion
} // namespace style
} // namespace mbgl

