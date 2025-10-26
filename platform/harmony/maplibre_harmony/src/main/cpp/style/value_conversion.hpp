#pragma once

#include <napi/native_api.h>
#include <mbgl/util/variant.hpp>
#include <mbgl/style/conversion.hpp>
#include <mapbox/feature.hpp>
#include <string>
#include <vector>
#include <unordered_map>

namespace mbgl {
namespace harmony {

// mbgl::Value 类型别名
using Value = mapbox::feature::value;

/**
 * Value 转换工具
 * 
 * 提供 NAPI Value 和 mbgl::Value 之间的双向转换
 * 支持所有 JavaScript 类型的递归转换
 */

/**
 * Convert NAPI value to mbgl::Value recursively
 * 
 * Supports:
 * - null -> NullValue
 * - boolean -> bool
 * - number -> double (int64 for integers, double for floats)
 * - string -> std::string
 * - array -> std::vector<mbgl::Value>
 * - object -> std::unordered_map<std::string, mbgl::Value>
 * 
 * @param env NAPI environment
 * @param value NAPI value to convert
 * @return mbgl::Value
 */
Value napiValueToMbglValue(napi_env env, napi_value value);

/**
 * Convert mbgl::Value to NAPI value recursively
 * 
 * @param env NAPI environment
 * @param value mbgl::Value to convert
 * @return NAPI value
 */
napi_value mbglValueToNapiValue(napi_env env, const Value& value);

/**
 * Convert NAPI array to std::vector<mbgl::Value>
 * 
 * @param env NAPI environment
 * @param array NAPI array
 * @return vector of mbgl::Value
 */
std::vector<Value> napiArrayToValueVector(napi_env env, napi_value array);

/**
 * Convert NAPI object to std::unordered_map<std::string, mbgl::Value>
 * 
 * @param env NAPI environment
 * @param object NAPI object
 * @return map of string to mbgl::Value
 */
std::unordered_map<std::string, Value> napiObjectToValueMap(
    napi_env env, 
    napi_value object
);

/**
 * Convert std::vector<mbgl::Value> to NAPI array
 * 
 * @param env NAPI environment
 * @param vec vector of mbgl::Value
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
 * @param map map of string to mbgl::Value
 * @return NAPI object
 */
napi_value valueMapToNapiObject(
    napi_env env,
    const std::unordered_map<std::string, Value>& map
);

} // namespace harmony
} // namespace mbgl

