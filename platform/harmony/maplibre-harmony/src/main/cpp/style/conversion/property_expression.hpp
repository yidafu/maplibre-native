#pragma once

#include "constant.hpp"
#include "../value_conversion.hpp"

#include <mbgl/style/property_expression.hpp>
#include <napi/native_api.h>

namespace mbgl {
namespace harmony {
namespace conversion {

/**
 * Convert PropertyExpression<T> to napi_value
 * 
 * Extracts and serializes the expression from PropertyExpression,
 * then converts it to a NAPI array.
 */
template <class T>
Result<napi_value> propertyExpressionToNapi(
    napi_env env, 
    const mbgl::style::PropertyExpression<T>& value
) {
    // Serialize the expression
    mbgl::Value serialized = value.getExpression().serialize();
    
    // Convert to NAPI value using existing value conversion
    return mbglValueToNapiValue(env, serialized);
}

} // namespace conversion
} // namespace harmony
} // namespace mbgl

