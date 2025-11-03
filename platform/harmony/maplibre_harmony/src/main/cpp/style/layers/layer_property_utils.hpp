#pragma once

#include "../napi_value_wrapper.hpp"
#include "../conversion/harmony_conversion.hpp"
#include "../conversion/property_value.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

#include <mbgl/style/property_value.hpp>
#include <mbgl/style/conversion/property_value.hpp>
#include <napi/native_api.h>
#include <string>

namespace mbgl {
namespace harmony {

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

/**
 * Layer Property Utilities
 * 
 * Provides unified helper functions for setting and getting layer properties
 * with support for both constant values and expressions.
 */

/**
 * Set a layer property from a NAPI value
 * 
 * Converts the NAPI value to PropertyValue<T> using the MapLibre conversion system.
 * Supports both constant values and expression arrays.
 * 
 * @tparam T The property value type (e.g., float, Color, std::array<float, 2>)
 * @param env NAPI environment
 * @param value NAPI value (can be constant or expression array)
 * @param propertyName Property name for logging
 * @return PropertyValue<T> if conversion successful, nullopt otherwise
 */
template <typename T>
std::optional<mbgl::style::PropertyValue<T>> napiValueToPropertyValue(
    napi_env env,
    napi_value value,
    const char* propertyName
) {
    try {
        // Create NapiValue wrapper
        NapiValue napiValue(env, value);
        
        // Use MapLibre conversion system to convert to PropertyValue<T>
        mbgl::style::conversion::Error error;
        auto converted = mbgl::style::conversion::convert<mbgl::style::PropertyValue<T>>(
            std::move(napiValue),
            error,
            false,  // allowDataExpressions
            false   // convertTokens
        );
        
        if (!converted) {
            Logger::error("LayerPropertyUtils", 
                         "Failed to convert %s: %s", 
                         propertyName, 
                         error.message.c_str());
            return std::nullopt;
        }
        
        return *converted;
    } catch (const std::exception& e) {
        Logger::error("LayerPropertyUtils", 
                     "Exception converting %s: %s", 
                     propertyName, 
                     e.what());
        return std::nullopt;
    }
}

/**
 * Set a layer property from a NAPI value (data expressions allowed)
 * 
 * Same as above but allows data-driven expressions (expressions using feature data).
 */
template <typename T>
std::optional<mbgl::style::PropertyValue<T>> napiValueToPropertyValueWithData(
    napi_env env,
    napi_value value,
    const char* propertyName
) {
    try {
        NapiValue napiValue(env, value);
        
        mbgl::style::conversion::Error error;
        auto converted = mbgl::style::conversion::convert<mbgl::style::PropertyValue<T>>(
            std::move(napiValue),
            error,
            true,   // allowDataExpressions - allow feature data access
            false   // convertTokens
        );
        
        if (!converted) {
            Logger::error("LayerPropertyUtils", 
                         "Failed to convert %s: %s", 
                         propertyName, 
                         error.message.c_str());
            return std::nullopt;
        }
        
        return *converted;
    } catch (const std::exception& e) {
        Logger::error("LayerPropertyUtils", 
                     "Exception converting %s: %s", 
                     propertyName, 
                     e.what());
        return std::nullopt;
    }
}

/**
 * Convert PropertyValue<T> back to NAPI value
 * 
 * Handles constant values and expressions. Returns the appropriate
 * NAPI representation (primitive for constants, array for expressions).
 * 
 * @tparam T The property value type
 * @param env NAPI environment
 * @param value PropertyValue to convert
 * @return napi_value (constant or expression array)
 */
template <typename T>
napi_value propertyValueToNapiValue(
    napi_env env,
    const mbgl::style::PropertyValue<T>& value
) {
    using namespace mbgl::harmony::conversion;
    
    // Use propertyValueToNapi function to handle all cases
    auto result = propertyValueToNapi(env, value);
    
    if (result) {
        return *result;
    } else {
        // Return null on error
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
}

/**
 * Helper to set layout property with expression support
 * 
 * Extracts value from NAPI arguments and sets it on the layer.
 */
template <typename LayerT, typename T>
bool setLayoutProperty(
    napi_env env,
    LayerT* layer,
    napi_value value,
    const char* propertyName,
    void (LayerT::*setter)(const mbgl::style::PropertyValue<T>&)
) {
    auto propertyValue = napiValueToPropertyValue<T>(env, value, propertyName);
    if (propertyValue) {
        (layer->*setter)(*propertyValue);
        return true;
    }
    return false;
}

/**
 * Helper to set data-driven layout property (e.g., icon-image, icon-rotate)
 * 
 * Some layout properties support data expressions in MapLibre (property-type: data-driven).
 * This function explicitly enables data expressions for those properties.
 */
template <typename LayerT, typename T>
bool setDataDrivenLayoutProperty(
    napi_env env,
    LayerT* layer,
    napi_value value,
    const char* propertyName,
    void (LayerT::*setter)(const mbgl::style::PropertyValue<T>&)
) {
    auto propertyValue = napiValueToPropertyValueWithData<T>(env, value, propertyName);
    if (propertyValue) {
        (layer->*setter)(*propertyValue);
        Logger::info("LayerPropertyUtils", "✅ Data-driven property '%s' set successfully", propertyName);
        return true;
    } else {
        Logger::error("LayerPropertyUtils", "❌ Failed to set data-driven property '%s'", propertyName);
        return false;
    }
}

/**
 * Helper to set paint property with expression support (allows data expressions)
 */
template <typename LayerT, typename T>
bool setPaintProperty(
    napi_env env,
    LayerT* layer,
    napi_value value,
    const char* propertyName,
    void (LayerT::*setter)(const mbgl::style::PropertyValue<T>&)
) {
    auto propertyValue = napiValueToPropertyValueWithData<T>(env, value, propertyName);
    if (propertyValue) {
        (layer->*setter)(*propertyValue);
        return true;
    }
    return false;
}

/**
 * Helper to get property value with expression support
 */
template <typename LayerT, typename T>
napi_value getProperty(
    napi_env env,
    const LayerT* layer,
    const mbgl::style::PropertyValue<T>& (LayerT::*getter)() const
) {
    const auto& value = (layer->*getter)();
    return propertyValueToNapiValue(env, value);
}

} // namespace harmony
} // namespace mbgl

