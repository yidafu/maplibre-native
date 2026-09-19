//
// Created for N-API parameter parsing utility
//

#include "napi_args.hpp"
#include "napi_scalar_traits.hpp"
#include "utils/logger.h"
#include <sstream>

using mln::harmony::Logger;

namespace mln {
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

void NapiArgs::SetTypeError(size_t index, const char* name, const char* expected) {
    std::ostringstream oss;
    oss << "Argument " << GetParamName(index, name) << " must be " << expected;
    SetError(oss.str());
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

// ========== Shared accessor skeletons ==========
//
// 下面四个模板承载 GetXxx / GetXxxOr / GetXxxProperty / GetArrayElementXxx
// 四组访问器完全相同的控制流，类型相关差异（jsType / 文案 / napi_get_value_*）
// 全部来自 NapiScalarTraits<T>。四组公开访问器因此退化为一行转发。
//
// 这些模板只在当前 TU 内实例化，故定义直接放在 .cpp 中。

template <typename T>
T NapiArgs::ReadArg(size_t index, const char* name, T fallback) {
    if (!CheckIndex(index, name)) {
        return fallback;
    }

    napi_valuetype type;
    // 短路求值：typeof 失败时不会读取未初始化的 type
    if (napi_typeof(env_, args_[index], &type) != napi_ok ||
        type != NapiScalarTraits<T>::jsType) {
        SetTypeError(index, name, NapiScalarTraits<T>::jsTypeName);
        return fallback;
    }

    T result = fallback;
    const char* failure = nullptr;
    if (NapiScalarTraits<T>::read(env_, args_[index], &result, &failure) != napi_ok) {
        SetError(failure != nullptr ? failure : "Failed to get value");
        return fallback;
    }

    return result;
}

template <typename T>
T NapiArgs::ReadArgOr(size_t index, T defaultValue) {
    if (!Has(index) || !IsType(index, NapiScalarTraits<T>::jsType)) {
        return defaultValue;
    }

    // 保留当前错误状态：一旦底层读取失败，按「可选参数」语义静默降级，
    // 不把错误传播给调用方，也不覆盖此前已有的错误。
    const bool hadError = hasError_;
    const std::string prevError = errorMessage_;

    const T result = ReadArg<T>(index, nullptr, defaultValue);

    if (hasError_ && !hadError) {
        hasError_ = hadError;
        errorMessage_ = prevError;
        return defaultValue;
    }

    return result;
}

template <typename T>
T NapiArgs::ReadProperty(napi_value obj, const char* key, T defaultValue) {
    if (!obj || !key) {
        return defaultValue;
    }

    napi_value value = nullptr;
    if (napi_get_named_property(env_, obj, key, &value) != napi_ok) {
        return defaultValue;
    }

    napi_valuetype type;
    if (napi_typeof(env_, value, &type) != napi_ok ||
        type != NapiScalarTraits<T>::jsType) {
        return defaultValue;
    }

    T result = defaultValue;
    const char* failure = nullptr;
    if (NapiScalarTraits<T>::read(env_, value, &result, &failure) != napi_ok) {
        return defaultValue;
    }

    return result;
}

template <typename T>
T NapiArgs::ReadArrayElement(napi_value array, uint32_t index, T defaultValue) {
    if (!array) {
        return defaultValue;
    }

    napi_value element = nullptr;
    if (napi_get_element(env_, array, index, &element) != napi_ok) {
        return defaultValue;
    }

    napi_valuetype type;
    if (napi_typeof(env_, element, &type) != napi_ok ||
        type != NapiScalarTraits<T>::jsType) {
        return defaultValue;
    }

    T result = defaultValue;
    const char* failure = nullptr;
    if (NapiScalarTraits<T>::read(env_, element, &result, &failure) != napi_ok) {
        return defaultValue;
    }

    return result;
}

// ========== Primitive Type Implementations ==========

std::string NapiArgs::GetString(size_t index, const char* name) {
    return ReadArg<std::string>(index, name, std::string());
}

int32_t NapiArgs::GetInt32(size_t index, const char* name) {
    return ReadArg<int32_t>(index, name, 0);
}

int64_t NapiArgs::GetInt64(size_t index, const char* name) {
    return ReadArg<int64_t>(index, name, 0);
}

uint32_t NapiArgs::GetUint32(size_t index, const char* name) {
    return ReadArg<uint32_t>(index, name, 0);
}

double NapiArgs::GetDouble(size_t index, const char* name) {
    return ReadArg<double>(index, name, 0.0);
}

bool NapiArgs::GetBool(size_t index, const char* name) {
    return ReadArg<bool>(index, name, false);
}

int64_t NapiArgs::GetBigInt(size_t index, const char* name) {
    if (!CheckIndex(index, name)) {
        return 0;
    }
    
    napi_valuetype type;
    napi_status status = napi_typeof(env_, args_[index], &type);
    
    if (status != napi_ok || type != napi_bigint) {
        SetTypeError(index, name, "a BigInt");
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
        SetTypeError(index, name, "an object");
        return nullptr;
    }
    
    // Ensure value is not an array
    bool isArray = false;
    status = napi_is_array(env_, args_[index], &isArray);
    
    if (status == napi_ok && isArray) {
        SetTypeError(index, name, "an object, not an array");
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
        SetTypeError(index, name, "an array");
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
        SetTypeError(index, name, "a function");
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
        SetTypeError(index, name, "a Buffer");
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
    return ReadArgOr<std::string>(index, defaultValue);
}

int32_t NapiArgs::GetInt32Or(size_t index, int32_t defaultValue) {
    return ReadArgOr<int32_t>(index, defaultValue);
}

int64_t NapiArgs::GetInt64Or(size_t index, int64_t defaultValue) {
    return ReadArgOr<int64_t>(index, defaultValue);
}

uint32_t NapiArgs::GetUint32Or(size_t index, uint32_t defaultValue) {
    return ReadArgOr<uint32_t>(index, defaultValue);
}

double NapiArgs::GetDoubleOr(size_t index, double defaultValue) {
    return ReadArgOr<double>(index, defaultValue);
}

bool NapiArgs::GetBoolOr(size_t index, bool defaultValue) {
    return ReadArgOr<bool>(index, defaultValue);
}

// ========== Object Property Helper Methods ==========

int32_t NapiArgs::GetInt32Property(napi_value obj, const char* key, int32_t defaultValue) {
    return ReadProperty<int32_t>(obj, key, defaultValue);
}

uint32_t NapiArgs::GetUint32Property(napi_value obj, const char* key, uint32_t defaultValue) {
    return ReadProperty<uint32_t>(obj, key, defaultValue);
}

std::string NapiArgs::GetStringProperty(napi_value obj, const char* key,
                                        const std::string& defaultValue) {
    return ReadProperty<std::string>(obj, key, defaultValue);
}

int64_t NapiArgs::GetInt64Property(napi_value obj, const char* key, int64_t defaultValue) {
    return ReadProperty<int64_t>(obj, key, defaultValue);
}

double NapiArgs::GetDoubleProperty(napi_value obj, const char* key, double defaultValue) {
    return ReadProperty<double>(obj, key, defaultValue);
}

bool NapiArgs::GetBoolProperty(napi_value obj, const char* key, bool defaultValue) {
    return ReadProperty<bool>(obj, key, defaultValue);
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

// ========== Array Helper Method Implementations ==========

uint32_t NapiArgs::GetArrayLength(napi_value array) {
    if (!array) {
        return 0;
    }

    uint32_t length = 0;
    napi_status status = napi_get_array_length(env_, array, &length);

    if (status != napi_ok) {
        return 0;
    }

    return length;
}

std::string NapiArgs::GetArrayElementString(napi_value array, uint32_t index,
                                            const std::string& defaultValue) {
    return ReadArrayElement<std::string>(array, index, defaultValue);
}

int32_t NapiArgs::GetArrayElementInt32(napi_value array, uint32_t index, int32_t defaultValue) {
    return ReadArrayElement<int32_t>(array, index, defaultValue);
}

double NapiArgs::GetArrayElementDouble(napi_value array, uint32_t index, double defaultValue) {
    return ReadArrayElement<double>(array, index, defaultValue);
}

bool NapiArgs::GetArrayElementBool(napi_value array, uint32_t index, bool defaultValue) {
    return ReadArrayElement<bool>(array, index, defaultValue);
}

} // namespace napi
} // namespace harmony
} // namespace mln
