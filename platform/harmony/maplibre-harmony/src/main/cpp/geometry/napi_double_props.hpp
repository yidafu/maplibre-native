#ifndef MAPLIBREHARMONY_NAPI_DOUBLE_PROPS_HPP
#define MAPLIBREHARMONY_NAPI_DOUBLE_PROPS_HPP

#include <initializer_list>
#include <utility>

#include "napi/native_api.h"
#include "utils/logger.h"

namespace mln {
namespace harmony {

// Shared implementation for the geometry Create*/Parse* converters
// (LatLng, Point, ProjectedMeters, Rect, LatLngBounds). They all build or
// parse flat objects whose members are plain JS numbers.

// Creates `{key: value, ...}` from the given double properties.
// On napi_create_object failure logs and returns JS undefined (matching the
// historical Create* behavior).
inline napi_value CreateDoublePropsObject(napi_env env, const char* logTag,
                                          std::initializer_list<std::pair<const char*, double>> props) {
    napi_value obj;
    if (napi_create_object(env, &obj) != napi_ok) {
        Logger::error(logTag, "Failed to create object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    for (const auto& [key, value] : props) {
        napi_value doubleValue;
        napi_create_double(env, value, &doubleValue);
        napi_set_named_property(env, obj, key, doubleValue);
    }

    return obj;
}

// Parses `{key: value, ...}` double properties into the given out-params.
// Fails when the value is not an object or when any property is missing or
// not a number. Properties are processed in order; previously parsed
// out-params stay written when a later property fails (same as the
// historical per-property parsing).
inline bool ParseDoubleProps(napi_env env, napi_value value, const char* logTag,
                             std::initializer_list<std::pair<const char*, double*>> outProps) {
    napi_valuetype type;
    if (napi_typeof(env, value, &type) != napi_ok || type != napi_object) {
        Logger::error(logTag, "Value is not an object");
        return false;
    }

    for (const auto& [key, out] : outProps) {
        napi_value propValue;
        if (napi_get_named_property(env, value, key, &propValue) != napi_ok ||
            napi_get_value_double(env, propValue, out) != napi_ok) {
            Logger::error(logTag, "Failed to parse %s", key);
            return false;
        }
    }

    return true;
}

} // namespace harmony
} // namespace mln

#endif // MAPLIBREHARMONY_NAPI_DOUBLE_PROPS_HPP
