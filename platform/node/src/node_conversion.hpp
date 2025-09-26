#pragma once

#include <node_api.h>
#include <napi.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/style/conversion_impl.hpp>
#include "napi_utils.hpp"

namespace mbgl {
namespace style {
namespace conversion {

// 转发声明
struct NapiValueData;

// 包装器类，用于在Convertible和Napi::Value之间进行转换
// 只存储一个指针，确保大小不超过8字节
struct NapiValueWrapper {
    NapiValueData* data;
    
    NapiValueWrapper(const Napi::Value& v);
    
    // 获取存储的值
    const Napi::Value& getValue() const;
    
    // 获取环境变量
    napi_env getEnv() const;
};

// 实际存储数据的结构体
struct NapiValueData {
    const Napi::Value& value;
    const napi_env env;
    
    NapiValueData(const Napi::Value& v) : value(v), env(v.Env()) {}
};

// NapiValueWrapper的实现
inline NapiValueWrapper::NapiValueWrapper(const Napi::Value& v) : data(new NapiValueData(v)) {}

inline const Napi::Value& NapiValueWrapper::getValue() const {
    return data->value;
}

inline napi_env NapiValueWrapper::getEnv() const {
    return data->env;
};

// 为NapiValueWrapper特化ConversionTraits，而不是直接为Napi::Value特化
template <>
class ConversionTraits<NapiValueWrapper> {
public:
    static bool isUndefined(const NapiValueWrapper& wrapper) {
        return wrapper.getValue().IsUndefined() || wrapper.getValue().IsNull();
    }

    static bool isArray(const NapiValueWrapper& wrapper) {
        return wrapper.getValue().IsArray();
    }

    static std::size_t arrayLength(const NapiValueWrapper& wrapper) {
        if (!wrapper.getValue().IsArray()) {
            return 0;
        }
        return wrapper.getValue().As<Napi::Array>().Length();
    }

    static NapiValueWrapper arrayMember(const NapiValueWrapper& wrapper, std::size_t i) {
        if (!wrapper.getValue().IsArray()) {
            return NapiValueWrapper(Napi::Value::From(wrapper.getEnv(), nullptr));
        }
        return NapiValueWrapper(wrapper.getValue().As<Napi::Array>().Get(static_cast<uint32_t>(i)));
    }

    static bool isObject(const NapiValueWrapper& wrapper) {
        return wrapper.getValue().IsObject() && !wrapper.getValue().IsArray();
    }

    static std::optional<NapiValueWrapper> objectMember(const NapiValueWrapper& wrapper, const char* name) {
        if (!wrapper.getValue().IsObject() || wrapper.getValue().IsArray()) {
            return {};
        }
        Napi::Object obj = wrapper.getValue().As<Napi::Object>();
        if (!obj.Has(Napi::String::New(wrapper.getEnv(), name))) {
            return {};
        }
        Napi::Value result = obj.Get(name);
        return NapiValueWrapper(result);
    }

    template <class Fn>
    static std::optional<Error> eachMember(const NapiValueWrapper& wrapper, Fn&& fn) {
        if (!wrapper.getValue().IsObject() || wrapper.getValue().IsArray()) {
            return Error{"Not an object"};
        }
        
        Napi::Object obj = wrapper.getValue().As<Napi::Object>();
        Napi::Array keys = obj.GetPropertyNames();
        uint32_t length = keys.Length();
        
        for (uint32_t i = 0; i < length; ++i) {
            Napi::Value key = keys.Get(i);
            Napi::Value val = obj.Get(key);
            
            std::string keyStr;
            try {
                keyStr = key.As<Napi::String>().Utf8Value();
            } catch (...) {
                continue;
            }
            
            // 确保回调函数可以处理右值引用
            std::optional<Error> result = fn(keyStr, NapiValueWrapper(std::move(val)));
            if (result) {
                return result;
            }
        }
        
        return {};
    }

    static std::optional<bool> toBool(const NapiValueWrapper& wrapper) {
        if (!wrapper.getValue().IsBoolean()) {
            return {};
        }
        
        try {
            return wrapper.getValue().As<Napi::Boolean>();
        } catch (...) {
            return {};
        }
    }

    static std::optional<float> toNumber(const NapiValueWrapper& wrapper) {
        if (!wrapper.getValue().IsNumber()) {
            return {};
        }
        
        try {
            return static_cast<float>(wrapper.getValue().As<Napi::Number>().DoubleValue());
        } catch (...) {
            return {};
        }
    }

    static std::optional<double> toDouble(const NapiValueWrapper& wrapper) {
        if (!wrapper.getValue().IsNumber()) {
            return {};
        }
        
        try {
            return wrapper.getValue().As<Napi::Number>().DoubleValue();
        } catch (...) {
            return {};
        }
    }

    static std::optional<std::string> toString(const NapiValueWrapper& wrapper) {
        if (!wrapper.getValue().IsString()) {
            return {};
        }
        
        try {
            return wrapper.getValue().As<Napi::String>().Utf8Value();
        } catch (...) {
            return {};
        }
    }

    static std::optional<Value> toValue(const NapiValueWrapper& wrapper) {
        if (wrapper.getValue().IsBoolean()) {
            try {
                return wrapper.getValue().As<Napi::Boolean>().Value();
            } catch (...) {
                return {};
            }
        } else if (wrapper.getValue().IsString()) {
            try {
                return wrapper.getValue().As<Napi::String>().Utf8Value();
            } catch (...) {
                return {};
            }
        } else if (wrapper.getValue().IsNumber()) {
            try {
                double num = wrapper.getValue().As<Napi::Number>().DoubleValue();
                // Check if it's an integer
                if (num == std::floor(num)) {
                    int64_t intVal = static_cast<int64_t>(num);
                    if (intVal >= INT32_MIN && intVal <= INT32_MAX) {
                        return static_cast<int32_t>(intVal);
                    } else {
                        return intVal;
                    }
                } else {
                    return num;
                }
            } catch (...) {
                return {};
            }
        } else {
            return {};
        }
    }

    static std::optional<GeoJSON> toGeoJSON(const NapiValueWrapper& wrapper, Error& error) {
        try {
            // Stringify the object
            Napi::Env env = Napi::Env(wrapper.getEnv());
            Napi::Object globalObject = env.Global();
            Napi::Object jsonObject = globalObject.Get("JSON").As<Napi::Object>();
            Napi::Function jsonStringify = jsonObject.Get("stringify").As<Napi::Function>();
            
            Napi::Value stringified = jsonStringify.Call({wrapper.getValue()});
            std::string string = stringified.As<Napi::String>().Utf8Value();
            return parseGeoJSON(string, error);
        } catch (const std::exception& ex) {
            error = {ex.what()};
            return {};
        } catch (...) {
            error = {"Unknown error"};
            return {};
        }
    }
};

// 辅助函数：将Napi::Value转换为NapiValueWrapper，用于创建Convertible
extern inline NapiValueWrapper wrapNapiValue(const Napi::Value& value) {
    return NapiValueWrapper(value);
}

template <>
class ConversionTraits<napi_value> {
public:
    static bool isUndefined(const napi_value& value) {
        return value == nullptr;
    }

    static bool isArray(const napi_value& value, const napi_env& env) {
        return node_mbgl::napi_utils::isArray(env, value);
    }

    static std::size_t arrayLength(const napi_value& value, const napi_env& env) {
        return node_mbgl::napi_utils::getArrayLength(env, value);
    }

    static napi_value arrayMember(const napi_value& value, std::size_t i, const napi_env& env) {
        return node_mbgl::napi_utils::getArrayElement(env, value, static_cast<uint32_t>(i));
    }

    static bool isObject(const napi_value& value, const napi_env& env) {
        return node_mbgl::napi_utils::isObject(env, value) && !node_mbgl::napi_utils::isArray(env, value);
    }

    static std::optional<napi_value> objectMember(const napi_value& value, const char* name, const napi_env& env) {
        bool hasProperty;
        napi_status status = napi_has_named_property(env, value, name, &hasProperty);
        if (status != napi_ok || !hasProperty) {
            return {};
        }
        
        napi_value result;
        status = napi_get_named_property(env, value, name, &result);
        if (status != napi_ok) {
            return {};
        }
        
        return result;
    }

    template <class Fn>
    static std::optional<Error> eachMember(const napi_value& value, Fn&& fn, const napi_env& env) {
        napi_value keys;
        napi_status status = napi_get_property_names(env, value, &keys);
        if (status != napi_ok) {
            return Error{"Failed to get property names"};
        }
        
        uint32_t length;
        status = napi_get_array_length(env, keys, &length);
        if (status != napi_ok) {
            return Error{"Failed to get array length"};
        }
        
        for (uint32_t i = 0; i < length; ++i) {
            napi_value key;
            status = napi_get_element(env, keys, i, &key);
            if (status != napi_ok) {
                continue;
            }
            
            napi_value val;
            status = napi_get_property(env, value, key, &val);
            if (status != napi_ok) {
                continue;
            }
            
            std::string keyStr;
            try {
                keyStr = node_mbgl::napi_utils::toString(env, key);
            } catch (...) {
                continue;
            }
            
            std::optional<Error> result = fn(keyStr, val);
            if (result) {
                return result;
            }
        }
        
        return {};
    }

    static std::optional<bool> toBool(const napi_value& value, const napi_env& env) {
        if (!node_mbgl::napi_utils::isBoolean(env, value)) {
            return {};
        }
        
        try {
            return node_mbgl::napi_utils::toBoolean(env, value);
        } catch (...) {
            return {};
        }
    }

    static std::optional<float> toNumber(const napi_value& value, const napi_env& env) {
        if (!node_mbgl::napi_utils::isNumber(env, value)) {
            return {};
        }
        
        try {
            return static_cast<float>(node_mbgl::napi_utils::toNumber(env, value));
        } catch (...) {
            return {};
        }
    }

    static std::optional<double> toDouble(const napi_value& value, const napi_env& env) {
        if (!node_mbgl::napi_utils::isNumber(env, value)) {
            return {};
        }
        
        try {
            return node_mbgl::napi_utils::toNumber(env, value);
        } catch (...) {
            return {};
        }
    }

    static std::optional<std::string> toString(const napi_value& value, const napi_env& env) {
        if (!node_mbgl::napi_utils::isString(env, value)) {
            return {};
        }
        
        try {
            return node_mbgl::napi_utils::toString(env, value);
        } catch (...) {
            return {};
        }
    }

    static std::optional<Value> toValue(const napi_value& value, const napi_env& env) {
        if (node_mbgl::napi_utils::isBoolean(env, value)) {
            try {
                return node_mbgl::napi_utils::toBoolean(env, value);
            } catch (...) {
                return {};
            }
        } else if (node_mbgl::napi_utils::isString(env, value)) {
            try {
                return node_mbgl::napi_utils::toString(env, value);
            } catch (...) {
                return {};
            }
        } else if (node_mbgl::napi_utils::isNumber(env, value)) {
            try {
                double num = node_mbgl::napi_utils::toNumber(env, value);
                // Check if it's an integer
                if (num == std::floor(num)) {
                    int64_t intVal = static_cast<int64_t>(num);
                    if (intVal >= INT32_MIN && intVal <= INT32_MAX) {
                        return static_cast<int32_t>(intVal);
                    } else {
                        return intVal;
                    }
                } else {
                    return num;
                }
            } catch (...) {
                return {};
            }
        } else {
            return {};
        }
    }

    static std::optional<GeoJSON> toGeoJSON(const napi_value& value, Error& error, const napi_env& env) {
        try {
            // Stringify the object
            napi_value globalObject;
            napi_status status = napi_get_global(env, &globalObject);
            if (status != napi_ok) {
                error = {"Failed to get global object"};
                return {};
            }

            napi_value jsonObject;
            status = napi_get_named_property(env, globalObject, "JSON", &jsonObject);
            if (status != napi_ok) {
                error = {"Failed to get JSON object"};
                return {};
            }

            napi_value jsonStringify;
            status = napi_get_named_property(env, jsonObject, "stringify", &jsonStringify);
            if (status != napi_ok) {
                error = {"Failed to get JSON.stringify"};
                return {};
            }
            
            napi_value stringified;
            status = napi_call_function(env, nullptr, jsonStringify, 1, &value, &stringified);
            if (status != napi_ok) {
                error = {"Failed to stringify object"};
                return {};
            }
            
            std::string string = node_mbgl::napi_utils::toString(env, stringified);
            return parseGeoJSON(string, error);
        } catch (const std::exception& ex) {
            error = {ex.what()};
            return {};
        } catch (...) {
            error = {"Unknown error"};
            return {};
        }
    }
};

// 用于转换 napi_value 到 Convertible 的辅助类
struct ConvertibleWithEnv {
    const napi_value& value;
    const napi_env& env;
    
    ConvertibleWithEnv(const napi_value& v, const napi_env& e) : value(v), env(e) {}
    
    // 转换运算符，允许 ConvertibleWithEnv 隐式转换为 Convertible
    operator Convertible() const {
        return Convertible(NapiValueWrapper(Napi::Value(env, value)));
    }
};

// Specialization for ConvertibleWithEnv
template <>
struct ConversionTraits<ConvertibleWithEnv> {
public:
    static bool isUndefined(const ConvertibleWithEnv& value) {
        return value.value == nullptr;
    }

    static bool isArray(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::isArray(value.value, value.env);
    }

    static std::size_t arrayLength(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::arrayLength(value.value, value.env);
    }

    static ConvertibleWithEnv arrayMember(const ConvertibleWithEnv& value, std::size_t i) {
        napi_value member = ConversionTraits<napi_value>::arrayMember(value.value, i, value.env);
        return ConvertibleWithEnv(member, value.env);
    }

    static bool isObject(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::isObject(value.value, value.env);
    }

    static std::optional<ConvertibleWithEnv> objectMember(const ConvertibleWithEnv& value, const char* name) {
        auto member = ConversionTraits<napi_value>::objectMember(value.value, name, value.env);
        if (member) {
            return ConvertibleWithEnv(*member, value.env);
        }
        return {};
    }

    template <class Fn>
    static std::optional<Error> eachMember(const ConvertibleWithEnv& value, Fn&& fn) {
        auto fnWrapper = [&fn, &env = value.env](const std::string& key, napi_value val) {
            return fn(key, ConvertibleWithEnv(val, env));
        };
        return ConversionTraits<napi_value>::eachMember(value.value, fnWrapper, value.env);
    }

    static std::optional<bool> toBool(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::toBool(value.value, value.env);
    }

    static std::optional<float> toNumber(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::toNumber(value.value, value.env);
    }

    static std::optional<double> toDouble(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::toDouble(value.value, value.env);
    }

    static std::optional<std::string> toString(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::toString(value.value, value.env);
    }

    static std::optional<Value> toValue(const ConvertibleWithEnv& value) {
        return ConversionTraits<napi_value>::toValue(value.value, value.env);
    }

    static std::optional<GeoJSON> toGeoJSON(const ConvertibleWithEnv& value, Error& error) {
        return ConversionTraits<napi_value>::toGeoJSON(value.value, error, value.env);
    }
};

// 辅助函数，用于检查参数中是否有 napi_env
template <typename... Args>
napi_env findEnvFromArgs(Args&&... args) {
    napi_env env = nullptr;
    bool found = false;
    
    (([&]() {
        if (!found && std::is_same<std::decay_t<Args>, napi_env>::value) {
            env = args;
            found = true;
        }
    }()), ...);
    
    return env;
}

template <class T, class... Args>
std::optional<T> nodeConvert(const napi_value& value, Error& error, Args&&... args) {
    try {
        // 首先尝试从参数中获取 env
        napi_env env = findEnvFromArgs(std::forward<Args>(args)...);
        
        if (env) {
            // 如果有 env 参数，使用我们的 ConvertibleWithEnv 结构体
            ConvertibleWithEnv convertible(value, env);
            return mbgl::style::conversion::Converter<T>()(convertible, error, std::forward<Args>(args)...);
        } else {
            // 回退到原始行为，直接使用 napi_value
            return mbgl::style::conversion::Converter<T>()(value, error, std::forward<Args>(args)...);
        }
    } catch (const std::exception& ex) {
        error = {ex.what()};
        return {};
    } catch (...) {
        error = {"Unknown conversion error"};
        return {};
    }
}

// 针对Napi::Value类型的重载
template <class T, class... Args>
std::optional<T> nodeConvert(const Napi::Value& value, Error& error, Args&&... args) {
    try {
        // 使用wrapNapiValue函数将Napi::Value转换为NapiValueWrapper
        NapiValueWrapper wrapper = wrapNapiValue(value);
        return mbgl::style::conversion::Converter<T>()(wrapper, error, value.Env(), std::forward<Args>(args)...);
    } catch (const std::exception& ex) {
        error = {ex.what()};
        return {};
    } catch (...) {
        error = {"Unknown conversion error"};
        return {};
    }
}

} // namespace conversion
} // namespace style
} // namespace mbgl
