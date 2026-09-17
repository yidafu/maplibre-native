#pragma once

#include <napi/native_api.h>
#include <mbgl/style/filter.hpp>
#include <optional>

namespace mbgl {
namespace harmony {

/**
 * Filter conversion utilities.
 *
 * Provides bidirectional conversion between NAPI arrays and mbgl::style::Filter.
 */

/**
 * Convert NAPI array to mbgl::style::Filter
 * 
 * Converts a JavaScript array representing a MapLibre filter expression
 * to a native Filter object.
 * 
 * Example:
 *   ["==", ["get", "type"], "restaurant"]
 *   -> mbgl::style::Filter
 * 
 * @param env NAPI environment
 * @param filterArray NAPI array representing the filter expression
 * @return Optional Filter object, nullopt if conversion failed
 */
std::optional<mbgl::style::Filter> napiArrayToFilter(
    napi_env env, 
    napi_value filterArray
);

/**
 * Convert mbgl::style::Filter to NAPI array
 * 
 * Converts a native Filter object back to a JavaScript array.
 * 
 * @param env NAPI environment
 * @param filter Filter object to convert
 * @return NAPI array representing the filter expression
 */
napi_value filterToNapiArray(
    napi_env env,
    const mbgl::style::Filter& filter
);

} // namespace harmony
} // namespace mbgl

