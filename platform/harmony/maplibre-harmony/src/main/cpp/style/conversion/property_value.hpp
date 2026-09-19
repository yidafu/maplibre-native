#pragma once

#include "constant.hpp"
#include "property_expression.hpp"
#include "../value_conversion.hpp"
#include "utils/logger.h"

#include <mln/style/property_value.hpp>
#include <mln/style/color_ramp_property_value.hpp>
#include <napi/native_api.h>

namespace mln {
namespace harmony {
namespace conversion {

using Logger = mln::harmony::Logger;

/**
 * PropertyValueEvaluator - Converts PropertyValue<T> to napi_value
 * 
 * Handles three cases:
 * 1. Undefined - returns null
 * 2. Constant value - converts T to napi_value
 * 3. PropertyExpression - serializes expression to array
 */
template <typename T>
class PropertyValueEvaluator {
public:
    PropertyValueEvaluator(napi_env _env) : env(_env) {}

    napi_value operator()(const mln::style::Undefined&) const {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value operator()(const T& value) const {
        // Convert constant value to NAPI
        auto result = convertToNapi(env, value);
        if (result) {
            return *result;
        } else {
            Logger::error("PropertyValueEvaluator", "Failed to convert constant value");
            napi_value null_value;
            napi_get_null(env, &null_value);
            return null_value;
        }
    }

    napi_value operator()(const mln::style::PropertyExpression<T>& expression) const {
        // Convert expression to NAPI array
        auto result = propertyExpressionToNapi(env, expression);
        if (result) {
            return *result;
        } else {
            Logger::error("PropertyValueEvaluator", "Failed to convert property expression");
            napi_value null_value;
            napi_get_null(env, &null_value);
            return null_value;
        }
    }

private:
    napi_env env;
};

/**
 * Convert PropertyValue<T> to napi_value
 * 
 * Uses PropertyValueEvaluator to handle all possible PropertyValue states.
 */
template <class T>
Result<napi_value> propertyValueToNapi(
    napi_env env, 
    const mln::style::PropertyValue<T>& value
) {
    PropertyValueEvaluator<T> evaluator(env);
    return value.evaluate(evaluator);
}

/**
 * Special function for ColorRampPropertyValue (used in heatmap-color)
 */
inline Result<napi_value> colorRampPropertyValueToNapi(
    napi_env env,
    const mln::style::ColorRampPropertyValue& value
) {
    if (value.isUndefined()) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Serialize the expression
    mln::Value serialized = value.getExpression().serialize();
    
    // Convert to NAPI value
    return mbglValueToNapiValue(env, serialized);
}

} // namespace conversion
} // namespace harmony
} // namespace mln

