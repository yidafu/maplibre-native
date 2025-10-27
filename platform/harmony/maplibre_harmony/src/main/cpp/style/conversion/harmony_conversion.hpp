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
        // For now, we primarily support GeoJSON as string (JSON serialized)
        // TODO: Add support for parsing JavaScript GeoJSON objects directly
        if (value.isNull() || value.isUndefined()) {
            error = {"no json data found"};
            return {};
        }

        if (value.isString()) {
            return parseGeoJSON(value.toString(), error);
        }

        // Could add support for object format here in the future
        error = {"GeoJSON must be provided as a JSON string"};
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

