#pragma once

#include <napi/native_api.h>
#include <mln/util/variant.hpp>
#include <mln/style/conversion.hpp>
#include <mapbox/feature.hpp>
#include <string>
#include <vector>
#include <unordered_map>

namespace mln {
namespace harmony {

// Alias for mln::Value
using Value = mapbox::feature::value;

/**
 * Value conversion utilities.
 *
 * Provides bidirectional conversion between NAPI values and mln::Value,
 * supporting recursive transformation of all JavaScript types.
 */

/**
 * Convert NAPI value to mln::Value recursively
 * 
 * Supports:
 * - null -> NullValue
 * - boolean -> bool
 * - number -> double (int64 for integers, double for floats)
 * - string -> std::string
 * - array -> std::vector<mln::Value>
 * - object -> std::unordered_map<std::string, mln::Value>
 * 
 * @param env NAPI environment
 * @param value NAPI value to convert
 * @return mln::Value
 */
Value napiValueToMbglValue(napi_env env, napi_value value);

/**
 * Convert mln::Value to NAPI value recursively
 * 
 * @param env NAPI environment
 * @param value mln::Value to convert
 * @return NAPI value
 */
napi_value mbglValueToNapiValue(napi_env env, const Value& value);

/**
 * Convert NAPI array to std::vector<mln::Value>
 * 
 * @param env NAPI environment
 * @param array NAPI array
 * @return vector of mln::Value
 */
std::vector<Value> napiArrayToValueVector(napi_env env, napi_value array);

/**
 * Convert NAPI object to std::unordered_map<std::string, mln::Value>
 * 
 * @param env NAPI environment
 * @param object NAPI object
 * @return map of string to mln::Value
 */
std::unordered_map<std::string, Value> napiObjectToValueMap(
    napi_env env, 
    napi_value object
);

/**
 * Convert std::vector<mln::Value> to NAPI array
 * 
 * @param env NAPI environment
 * @param vec vector of mln::Value
 * @return NAPI array
 */
napi_value valueVectorToNapiArray(
    napi_env env, 
    const std::vector<Value>& vec
);

/**
 * Convert std::unordered_map to NAPI object
 * 
 * @param env NAPI environment
 * @param map map of string to mln::Value
 * @return NAPI object
 */
napi_value valueMapToNapiObject(
    napi_env env,
    const std::unordered_map<std::string, Value>& map
);

} // namespace harmony
} // namespace mln

