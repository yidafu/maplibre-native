#include "napi_value_wrapper.hpp"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

using Logger = mbgl::harmony::Logger;

// Thread-local storage for napi_env
thread_local napi_env NapiValue::tl_env = nullptr;

NapiValue::NapiValue(napi_env _env, napi_value _value)
    : value(_value) {
    // Store env in thread-local storage
    tl_env = _env;
}

void NapiValue::setThreadLocalEnv(napi_env env) {
    tl_env = env;
}

napi_env NapiValue::getEnv() const {
    return tl_env;
}

bool NapiValue::isNull() const {
    napi_env env = getEnv();
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok) {
        return true;
    }
    return type == napi_null;
}

bool NapiValue::isUndefined() const {
    napi_env env = getEnv();
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok) {
        return true;
    }
    return type == napi_undefined;
}

bool NapiValue::isArray() const {
    napi_env env = getEnv();
    bool result;
    napi_status status = napi_is_array(env, value, &result);
    if (status != napi_ok) {
        return false;
    }
    return result;
}

bool NapiValue::isObject() const {
    napi_env env = getEnv();
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok) {
        return false;
    }
    
    // Check if it's an object but not an array
    if (type == napi_object) {
        bool isArray;
        napi_is_array(env, value, &isArray);
        return !isArray;
    }
    return false;
}

bool NapiValue::isString() const {
    napi_env env = getEnv();
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok) {
        return false;
    }
    return type == napi_string;
}

bool NapiValue::isBool() const {
    napi_env env = getEnv();
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok) {
        return false;
    }
    return type == napi_boolean;
}

bool NapiValue::isNumber() const {
    napi_env env = getEnv();
    napi_valuetype type;
    napi_status status = napi_typeof(env, value, &type);
    if (status != napi_ok) {
        return false;
    }
    return type == napi_number;
}

std::string NapiValue::toString() const {
    napi_env env = getEnv();
    size_t length;
    napi_status status = napi_get_value_string_utf8(env, value, nullptr, 0, &length);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get string length");
        return "";
    }
    
    std::string result(length, '\0');
    status = napi_get_value_string_utf8(env, value, &result[0], length + 1, nullptr);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get string value");
        return "";
    }
    
    return result;
}

float NapiValue::toFloat() const {
    napi_env env = getEnv();
    double value_double;
    napi_status status = napi_get_value_double(env, value, &value_double);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get float value");
        return 0.0f;
    }
    return static_cast<float>(value_double);
}

double NapiValue::toDouble() const {
    napi_env env = getEnv();
    double result;
    napi_status status = napi_get_value_double(env, value, &result);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get double value");
        return 0.0;
    }
    return result;
}

int64_t NapiValue::toLong() const {
    napi_env env = getEnv();
    int64_t result;
    napi_status status = napi_get_value_int64(env, value, &result);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get int64 value");
        return 0;
    }
    return result;
}

bool NapiValue::toBool() const {
    napi_env env = getEnv();
    bool result;
    napi_status status = napi_get_value_bool(env, value, &result);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get bool value");
        return false;
    }
    return result;
}

NapiValue NapiValue::get(const char* key) const {
    napi_env env = getEnv();
    napi_value result;
    napi_status status = napi_get_named_property(env, value, key, &result);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get property: %s", key);
        napi_get_undefined(env, &result);
    }
    return NapiValue(env, result);
}

NapiValue NapiValue::get(size_t index) const {
    napi_env env = getEnv();
    napi_value result;
    napi_status status = napi_get_element(env, value, static_cast<uint32_t>(index), &result);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get element at index: %zu", index);
        napi_get_undefined(env, &result);
    }
    return NapiValue(env, result);
}

NapiValue NapiValue::keyArray() const {
    napi_env env = getEnv();
    napi_value propertyNames;
    napi_status status = napi_get_property_names(env, value, &propertyNames);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get property names");
        napi_value emptyArray;
        napi_create_array(env, &emptyArray);
        return NapiValue(env, emptyArray);
    }
    return NapiValue(env, propertyNames);
}

size_t NapiValue::getLength() const {
    napi_env env = getEnv();
    uint32_t length;
    napi_status status = napi_get_array_length(env, value, &length);
    if (status != napi_ok) {
        Logger::error("NapiValue", "Failed to get array length");
        return 0;
    }
    return static_cast<size_t>(length);
}

} // namespace harmony
} // namespace mbgl

