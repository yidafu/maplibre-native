#include "filter_conversion.hpp"
#include "conversion/harmony_conversion.hpp"
#include "value_conversion.hpp"
#include "utils/logger.h"
#include <mbgl/style/conversion/filter.hpp>

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

std::optional<mbgl::style::Filter> napiArrayToFilter(
    napi_env env, 
    napi_value filterArray
) {
    // Check if it's an array
    bool isArray;
    napi_status status = napi_is_array(env, filterArray, &isArray);
    
    if (status != napi_ok || !isArray) {
        Logger::error("FilterConversion", "Filter must be an array");
        return std::nullopt;
    }
    
    try {
        // Create NapiValue wrapper
        NapiValue napiValue(env, filterArray);
        
        // Use the conversion system to convert to Filter
        mbgl::style::conversion::Error error;
        auto converted = mbgl::style::conversion::convert<mbgl::style::Filter>(
            std::move(napiValue), 
            error
        );
        
        if (!converted) {
            Logger::error("FilterConversion", "Error converting filter: %s", error.message.c_str());
            return std::nullopt;
        }
        
        Logger::info("FilterConversion", "Filter converted successfully");
        return *converted;
    } catch (const std::exception& e) {
        Logger::error("FilterConversion", "Exception during filter conversion: %s", e.what());
        return std::nullopt;
    }
}

napi_value filterToNapiArray(
    napi_env env,
    const mbgl::style::Filter& filter
) {
    try {
        // Serialize the filter (Filter class has its own serialize method)
        mbgl::Value serialized = filter.serialize();
        
        // Convert mbgl::Value to NAPI array using existing conversion
        return mbglValueToNapiValue(env, serialized);
    } catch (const std::exception& e) {
        Logger::error("FilterConversion", "Exception during filter serialization: %s", e.what());
        
        // Return empty array on error
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

} // namespace harmony
} // namespace mbgl
