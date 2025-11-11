//
// Created for N-API parameter parsing utility
//

#include "napi_args.hpp"
#include "utils/logger.h"
#include <sstream>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {
namespace napi {

NapiArgs::NapiArgs(napi_env env, napi_callback_info info, size_t maxArgs)
    : env_(env), thisObj_(nullptr), argc_(maxArgs), hasError_(false) {
    
    args_.resize(maxArgs);
    
    // Retrieve this object and parameters
    napi_status status = napi_get_cb_info(env, info, &argc_, args_.data(), &thisObj_, nullptr);
    
    if (status != napi_ok) {
        SetError("Failed to get callback info");
        argc_ = 0;
        thisObj_ = nullptr;
        return;
    }
    
    // Resize vector to actual argument count
    args_.resize(argc_);
}

void NapiArgs::SetError(const std::string& message) {
    if (hasError_) {
        // An error already exists; keep the first one
        return;
    }
    
    hasError_ = true;
    errorMessage_ = message;
    
    // Throw JS exception
    napi_throw_type_error(env_, nullptr, message.c_str());
    
    Logger::error("NapiArgs", "Error: %s", message.c_str());
}

bool NapiArgs::CheckIndex(size_t index, const char* name) {
    if (index >= argc_) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) 
            << " is missing (index " << index << ", but only " << argc_ << " arguments provided)";
        SetError(oss.str());
        return false;
    }
    return true;
}

std::string NapiArgs::GetParamName(size_t index, const char* name) const {
    if (name && name[0] != '\0') {
        return std::string("'") + name + "'";
    }
    return std::string("[") + std::to_string(index) + "]";
}

void NapiArgs::RequireMinArgs(size_t min) {
    if (argc_ < min) {
        std::ostringstream oss;
        oss << "Insufficient arguments: expected at least " << min 
            << ", but got " << argc_;
        SetError(oss.str());
    }
}

bool NapiArgs::IsType(size_t index, napi_valuetype type) {
    if (!CheckIndex(index, nullptr)) {
        return false;
    }
    
    napi_valuetype actualType;
    napi_status status = napi_typeof(env_, args_[index], &actualType);
    
    if (status != napi_ok) {
        return false;
    }
    
    return actualType == type;
}

napi_value NapiArgs::GetValue(size_t index) {
    if (!CheckIndex(index, nullptr)) {
        return nullptr;
    }
    return args_[index];
}

// ========== Primitive Type Implementations ==========

std::string NapiArgs::GetString(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return "";
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_string) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a string";
        SetError(oss.str());
        return "";
    }
    
    size_t length = 0;
    status = napi_get_value_string_utf8(env_, args_[index], nullptr, 0, &length);
    
    if (status != napi_ok) {
        SetError("Failed to get string length");
        return "";
    }
    
    if (length == 0) {
        return "";
    }
    
    std::string result(length, '\0');
    status = napi_get_value_string_utf8(env_, args_[index], &result[0], length + 1, &length);
    
    if (status != napi_ok) {
        SetError("Failed to get string value");
        return "";
    }
    
    return result;
}

int32_t NapiArgs::GetInt32(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return 0;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_number) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a number";
        SetError(oss.str());
        return 0;
    }
    
    int32_t result = 0;
    status = napi_get_value_int32(env_, args_[index], &result);
    
    if (status != napi_ok) {
        SetError("Failed to get int32 value");
        return 0;
    }
    
    return result;
}

int64_t NapiArgs::GetInt64(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return 0;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_number) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a number";
        SetError(oss.str());
        return 0;
    }
    
    int64_t result = 0;
    status = napi_get_value_int64(env_, args_[index], &result);
    
    if (status != napi_ok) {
        SetError("Failed to get int64 value");
        return 0;
    }
    
    return result;
}

uint32_t NapiArgs::GetUint32(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return 0;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_number) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a number";
        SetError(oss.str());
        return 0;
    }
    
    uint32_t result = 0;
    status = napi_get_value_uint32(env_, args_[index], &result);
    
    if (status != napi_ok) {
        SetError("Failed to get uint32 value");
        return 0;
    }
    
    return result;
}

double NapiArgs::GetDouble(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return 0.0;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_number) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a number";
        SetError(oss.str());
        return 0.0;
    }
    
    double result = 0.0;
    status = napi_get_value_double(env_, args_[index], &result);
    
    if (status != napi_ok) {
        SetError("Failed to get double value");
        return 0.0;
    }
    
    return result;
}

bool NapiArgs::GetBool(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return false;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_boolean) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a boolean";
        SetError(oss.str());
        return false;
    }
    
    bool result = false;
    status = napi_get_value_bool(env_, args_[index], &result);
    
    if (status != napi_ok) {
        SetError("Failed to get bool value");
        return false;
    }
    
    return result;
}

int64_t NapiArgs::GetBigInt(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return 0;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_bigint) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a BigInt";
        SetError(oss.str());
        return 0;
    }
    
    int64_t result = 0;
    bool lossless = true;
    status = napi_get_value_bigint_int64(env_, args_[index], &result, &lossless);
    
    if (status != napi_ok) {
        SetError("Failed to get BigInt value");
        return 0;
    }
    
    if (!lossless) {
        Logger::warn("NapiArgs", "BigInt conversion was lossy for argument %s", 
                     GetParamName(index, name).c_str());
    }
    
    return result;
}

// ========== Complex Type Implementations ==========

napi_value NapiArgs::GetObject(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return nullptr;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_object) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be an object";
        SetError(oss.str());
        return nullptr;
    }
    
    // Ensure value is not an array
    bool isArray = false;
    status = napi_is_array(env_, args_[index], &isArray);
    
    if (status == napi_ok && isArray) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be an object, not an array";
        SetError(oss.str());
        return nullptr;
    }
    
    return args_[index];
}

napi_value NapiArgs::GetArray(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return nullptr;
    }
    
    bool isArray = false;
    napi_status status = napi_is_array(env_, args_[index], &isArray);
    
    if (status != napi_ok || !isArray) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be an array";
        SetError(oss.str());
        return nullptr;
    }
    
    return args_[index];
}

napi_value NapiArgs::GetFunction(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return nullptr;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_function) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a function";
        SetError(oss.str());
        return nullptr;
    }
    
    return args_[index];
}

void* NapiArgs::GetBuffer(size_t index, size_t* length, const char* name) {
    if (!CheckIndex(index, name)) {
        if (length) *length = 0;
        return nullptr;
    }
    
    bool isBuffer = false;
    napi_status status = napi_is_buffer(env_, args_[index], &isBuffer);
    
    if (status != napi_ok || !isBuffer) {
        std::ostringstream oss;
        oss << "Argument " << GetParamName(index, name) << " must be a Buffer";
        SetError(oss.str());
        if (length) *length = 0;
        return nullptr;
    }
    
    void* data = nullptr;
    size_t len = 0;
    status = napi_get_buffer_info(env_, args_[index], &data, &len);
    
    if (status != napi_ok) {
        SetError("Failed to get buffer info");
        if (length) *length = 0;
        return nullptr;
    }
    
    if (length) {
        *length = len;
    }
    
    return data;
}

// ========== Optional Parameter Implementations ==========

std::string NapiArgs::GetStringOr(size_t index, const std::string& defaultValue) {
    if (!Has(index)) {
        return defaultValue;
    }
    
    if (!IsType(index, napi_string)) {
        return defaultValue;
    }
    
    // Temporarily preserve current error state
    bool hadError = hasError_;
    std::string prevError = errorMessage_;
    
    std::string result = GetString(index, nullptr);
    
    // If retrieval fails, restore prior error state and return default value
    if (hasError_ && !hadError) {
        hasError_ = hadError;
        errorMessage_ = prevError;
        return defaultValue;
    }
    
    return result;
}

int32_t NapiArgs::GetInt32Or(size_t index, int32_t defaultValue) {
    if (!Has(index) || !IsType(index, napi_number)) {
        return defaultValue;
    }
    
    bool hadError = hasError_;
    std::string prevError = errorMessage_;
    
    int32_t result = GetInt32(index, nullptr);
    
    if (hasError_ && !hadError) {
        hasError_ = hadError;
        errorMessage_ = prevError;
        return defaultValue;
    }
    
    return result;
}

int64_t NapiArgs::GetInt64Or(size_t index, int64_t defaultValue) {
    if (!Has(index) || !IsType(index, napi_number)) {
        return defaultValue;
    }
    
    bool hadError = hasError_;
    std::string prevError = errorMessage_;
    
    int64_t result = GetInt64(index, nullptr);
    
    if (hasError_ && !hadError) {
        hasError_ = hadError;
        errorMessage_ = prevError;
        return defaultValue;
    }
    
    return result;
}

uint32_t NapiArgs::GetUint32Or(size_t index, uint32_t defaultValue) {
    if (!Has(index) || !IsType(index, napi_number)) {
        return defaultValue;
    }
    
    bool hadError = hasError_;
    std::string prevError = errorMessage_;
    
    uint32_t result = GetUint32(index, nullptr);
    
    if (hasError_ && !hadError) {
        hasError_ = hadError;
        errorMessage_ = prevError;
        return defaultValue;
    }
    
    return result;
}

double NapiArgs::GetDoubleOr(size_t index, double defaultValue) {
    if (!Has(index) || !IsType(index, napi_number)) {
        return defaultValue;
    }
    
    bool hadError = hasError_;
    std::string prevError = errorMessage_;
    
    double result = GetDouble(index, nullptr);
    
    if (hasError_ && !hadError) {
        hasError_ = hadError;
        errorMessage_ = prevError;
        return defaultValue;
    }
    
    return result;
}

bool NapiArgs::GetBoolOr(size_t index, bool defaultValue) {
    if (!Has(index) || !IsType(index, napi_boolean)) {
        return defaultValue;
    }
    
    bool hadError = hasError_;
    std::string prevError = errorMessage_;
    
    bool result = GetBool(index, nullptr);
    
    if (hasError_ && !hadError) {
        hasError_ = hadError;
        errorMessage_ = prevError;
        return defaultValue;
    }
    
    return result;
}

// ========== Object Property Helper Methods ==========

int32_t NapiArgs::GetInt32Property(napi_value obj, const char* key, int32_t defaultValue) {
    if (!obj || !key) {
        return defaultValue;
    }
    
    napi_value value;
    napi_status status = napi_get_named_property(env_, obj, key, &value);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    napi_valuetype type;
    status = napi_typeof(env_, value, &type);
    
    if (status != napi_ok || type != napi_number) {
        return defaultValue;
    }
    
    int32_t result = 0;
    status = napi_get_value_int32(env_, value, &result);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    return result;
}

uint32_t NapiArgs::GetUint32Property(napi_value obj, const char* key, uint32_t defaultValue) {
    if (!obj || !key) {
        return defaultValue;
    }
    
    napi_value value;
    napi_status status = napi_get_named_property(env_, obj, key, &value);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    napi_valuetype type;
    status = napi_typeof(env_, value, &type);
    
    if (status != napi_ok || type != napi_number) {
        return defaultValue;
    }
    
    uint32_t result = 0;
    status = napi_get_value_uint32(env_, value, &result);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    return result;
}

std::string NapiArgs::GetStringProperty(napi_value obj, const char* key, const std::string& defaultValue) {
    if (!obj || !key) {
        return defaultValue;
    }
    
    napi_value value;
    napi_status status = napi_get_named_property(env_, obj, key, &value);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    napi_valuetype type;
    status = napi_typeof(env_, value, &type);
    
    if (status != napi_ok || type != napi_string) {
        return defaultValue;
    }
    
    size_t length = 0;
    status = napi_get_value_string_utf8(env_, value, nullptr, 0, &length);
    
    if (status != napi_ok || length == 0) {
        return defaultValue;
    }
    
    std::string result(length, '\0');
    status = napi_get_value_string_utf8(env_, value, &result[0], length + 1, &length);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    return result;
}

int64_t NapiArgs::GetInt64Property(napi_value obj, const char* key, int64_t defaultValue) {
    if (!obj || !key) {
        return defaultValue;
    }
    
    napi_value value;
    napi_status status = napi_get_named_property(env_, obj, key, &value);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    napi_valuetype type;
    status = napi_typeof(env_, value, &type);
    
    if (status != napi_ok || type != napi_number) {
        return defaultValue;
    }
    
    int64_t result = 0;
    status = napi_get_value_int64(env_, value, &result);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    return result;
}

double NapiArgs::GetDoubleProperty(napi_value obj, const char* key, double defaultValue) {
    if (!obj || !key) {
        return defaultValue;
    }
    
    napi_value value;
    napi_status status = napi_get_named_property(env_, obj, key, &value);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    napi_valuetype type;
    status = napi_typeof(env_, value, &type);
    
    if (status != napi_ok || type != napi_number) {
        return defaultValue;
    }
    
    double result = 0.0;
    status = napi_get_value_double(env_, value, &result);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    return result;
}

bool NapiArgs::GetBoolProperty(napi_value obj, const char* key, bool defaultValue) {
    if (!obj || !key) {
        return defaultValue;
    }
    
    napi_value value;
    napi_status status = napi_get_named_property(env_, obj, key, &value);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    napi_valuetype type;
    status = napi_typeof(env_, value, &type);
    
    if (status != napi_ok || type != napi_boolean) {
        return defaultValue;
    }
    
    bool result = false;
    status = napi_get_value_bool(env_, value, &result);
    
    if (status != napi_ok) {
        return defaultValue;
    }
    
    return result;
}

// ========== Convenience Method Implementations ==========

napi_value NapiArgs::Undefined() const {
    napi_value undefined;
    napi_get_undefined(env_, &undefined);
    return undefined;
}

napi_value NapiArgs::Null() const {
    napi_value null;
    napi_get_null(env_, &null);
    return null;
}

napi_value NapiArgs::This() const {
    return thisObj_;
}

bool NapiArgs::IsNullOrUndefined(size_t index) {
    if (!CheckIndex(index, nullptr)) {
        return false;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok) {
        return false;
    }
    
    return (type == napi_null || type == napi_undefined);
}

} // namespace napi
} // namespace harmony
} // namespace mbgl

