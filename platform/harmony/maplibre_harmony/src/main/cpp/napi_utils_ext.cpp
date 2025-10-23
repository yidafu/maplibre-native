#include "napi_utils.h"
#include <cstring>

namespace mbgl {
namespace harmony {
namespace napi {

std::string GetStringFromValue(napi_env env, napi_value value) {
    size_t length = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &length);
    
    if (length == 0) {
        return "";
    }
    
    std::string result(length, '\0');
    napi_get_value_string_utf8(env, value, &result[0], length + 1, &length);
    return result;
}

int64_t GetInt64FromValue(napi_env env, napi_value value) {
    int64_t result = 0;
    napi_get_value_int64(env, value, &result);
    return result;
}

double GetDoubleFromValue(napi_env env, napi_value value) {
    double result = 0.0;
    napi_get_value_double(env, value, &result);
    return result;
}

bool GetBoolFromValue(napi_env env, napi_value value) {
    bool result = false;
    napi_get_value_bool(env, value, &result);
    return result;
}

napi_value CreateStringValue(napi_env env, const std::string& str) {
    napi_value result;
    napi_create_string_utf8(env, str.c_str(), str.length(), &result);
    return result;
}

napi_value CreateInt64Value(napi_env env, int64_t value) {
    napi_value result;
    napi_create_int64(env, value, &result);
    return result;
}

napi_value CreateDoubleValue(napi_env env, double value) {
    napi_value result;
    napi_create_double(env, value, &result);
    return result;
}

napi_value CreateBoolValue(napi_env env, bool value) {
    napi_value result;
    napi_get_boolean(env, value, &result);
    return result;
}

} // namespace napi
} // namespace harmony
} // namespace mbgl

