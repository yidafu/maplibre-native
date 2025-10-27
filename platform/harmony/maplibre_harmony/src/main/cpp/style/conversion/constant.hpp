#pragma once

#include <napi/native_api.h>
#include <mbgl/util/color.hpp>
#include <mbgl/util/padding.hpp>
#include <mbgl/util/enum.hpp>
#include <mbgl/style/expression/formatted.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/variable_anchor_offset_collection.hpp>
#include <mbgl/style/rotation.hpp>

#include <string>
#include <array>
#include <vector>
#include <optional>

namespace mbgl {
namespace harmony {
namespace conversion {

/**
 * Result type for conversions - either a value or an error
 */
template <typename T>
using Result = std::optional<T>;

/**
 * Converters from C++ types to NAPI values
 * 
 * These converters are used to convert MapLibre C++ types back to
 * JavaScript/ArkTS values that can be returned to the caller.
 * 
 * These are NOT part of the MapLibre conversion system, they are
 * standalone converters for returning values to JavaScript.
 */

// Forward declaration
Result<napi_value> convertToNapi(napi_env env, bool value);
Result<napi_value> convertToNapi(napi_env env, float value);
Result<napi_value> convertToNapi(napi_env env, double value);
Result<napi_value> convertToNapi(napi_env env, const std::string& value);
Result<napi_value> convertToNapi(napi_env env, const Color& value);
Result<napi_value> convertToNapi(napi_env env, const Padding& value);
Result<napi_value> convertToNapi(napi_env env, const VariableAnchorOffsetCollection& value);
Result<napi_value> convertToNapi(napi_env env, const style::expression::Formatted& value);
Result<napi_value> convertToNapi(napi_env env, const style::expression::Image& value);
Result<napi_value> convertToNapi(napi_env env, const style::Rotation& value);
Result<napi_value> convertToNapi(napi_env env, const std::vector<std::string>& value);
Result<napi_value> convertToNapi(napi_env env, const std::vector<float>& value);
Result<napi_value> convertToNapi(napi_env env, const std::vector<double>& value);

template <typename T>
Result<napi_value> convertToNapi(napi_env env, T value, typename std::enable_if<std::is_integral<T>::value>::type* = nullptr);

template <typename T, size_t N>
Result<napi_value> convertToNapi(napi_env env, const std::array<T, N>& value);

template <typename T>
Result<napi_value> convertToNapi(napi_env env, T value, typename std::enable_if<std::is_enum<T>::value>::type* = nullptr);

} // namespace conversion
} // namespace harmony
} // namespace mbgl

