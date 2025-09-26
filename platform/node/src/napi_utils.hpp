#pragma once

#include <node_api.h>
#include <string>
#include <vector>
#include <memory>
#include <functional>

namespace node_mbgl {
namespace napi_utils {

// 检查N-API调用的结果，如果失败则抛出异常
inline void check(napi_status status, const char* message = nullptr) {
    if (status != napi_ok) {
        throw std::runtime_error(message ? message : "N-API error");
    }
}

// 创建一个字符串
inline napi_value createString(napi_env env, const std::string& str) {
    napi_value result;
    check(napi_create_string_utf8(env, str.c_str(), str.length(), &result));
    return result;
}

// 创建一个数字
inline napi_value createNumber(napi_env env, double value) {
    napi_value result;
    check(napi_create_double(env, value, &result));
    return result;
}

// 创建一个整数
inline napi_value createInt32(napi_env env, int32_t value) {
    napi_value result;
    check(napi_create_int32(env, value, &result));
    return result;
}

// 创建一个布尔值
inline napi_value createBoolean(napi_env env, bool value) {
    napi_value result;
    check(napi_get_boolean(env, value, &result));
    return result;
}

// 创建一个数组
inline napi_value createArray(napi_env env, size_t length = 0) {
    napi_value result;
    check(napi_create_array_with_length(env, length, &result));
    return result;
}

// 创建一个对象
inline napi_value createObject(napi_env env) {
    napi_value result;
    check(napi_create_object(env, &result));
    return result;
}

// 创建一个空值
inline napi_value createNull(napi_env env) {
    napi_value result;
    check(napi_get_null(env, &result));
    return result;
}

// 创建一个undefined值
inline napi_value createUndefined(napi_env env) {
    napi_value result;
    check(napi_get_undefined(env, &result));
    return result;
}

// 设置对象的属性
inline void setProperty(napi_env env, napi_value obj, const std::string& name, napi_value value) {
    check(napi_set_named_property(env, obj, name.c_str(), value));
}

// 获取对象的属性
inline napi_value getProperty(napi_env env, napi_value obj, const std::string& name) {
    napi_value result;
    check(napi_get_named_property(env, obj, name.c_str(), &result));
    return result;
}

// 设置数组的元素
inline void setArrayElement(napi_env env, napi_value array, uint32_t index, napi_value value) {
    check(napi_set_element(env, array, index, value));
}

// 获取数组的元素
inline napi_value getArrayElement(napi_env env, napi_value array, uint32_t index) {
    napi_value result;
    check(napi_get_element(env, array, index, &result));
    return result;
}

// 获取数组的长度
inline uint32_t getArrayLength(napi_env env, napi_value array) {
    uint32_t length;
    check(napi_get_array_length(env, array, &length));
    return length;
}

// 调用函数
inline napi_value callFunction(napi_env env, napi_value func, napi_value thisArg, size_t argc, napi_value* argv) {
    napi_value result;
    check(napi_call_function(env, thisArg, func, argc, argv, &result));
    return result;
}

// 定义类构造函数和方法
struct ClassDef {
    const char* name;
    napi_callback constructor;
    void* data;
    std::vector<napi_property_descriptor> properties;
};

inline napi_value defineClass(napi_env env, const ClassDef& def, napi_value& constructor) {
    napi_callback_info info = nullptr;
    napi_property_attributes attributes = static_cast<napi_property_attributes>(napi_default | napi_external);
    
    napi_value result;
    check(napi_define_class(env, def.name, NAPI_AUTO_LENGTH, def.constructor, def.data, 
                            def.properties.size(), def.properties.data(), &constructor));
    return constructor;
}

// 创建一个外部数据对象
inline napi_value createExternal(napi_env env, void* data, napi_finalize finalize = nullptr, void* hint = nullptr) {
    napi_value result;
    check(napi_create_external(env, data, finalize, hint, &result));
    return result;
}

// 从外部数据对象获取数据
inline void* getExternalData(napi_env env, napi_value external) {
    void* data;
    check(napi_get_value_external(env, external, &data));
    return data;
}

// 创建一个引用
inline napi_ref createReference(napi_env env, napi_value value, uint32_t refCount = 1) {
    napi_ref ref;
    check(napi_create_reference(env, value, refCount, &ref));
    return ref;
}

// 从引用获取值
inline napi_value getReference(napi_env env, napi_ref ref) {
    napi_value result;
    check(napi_get_reference_value(env, ref, &result));
    return result;
}

// 删除引用
inline void deleteReference(napi_env env, napi_ref ref) {
    check(napi_delete_reference(env, ref));
}

// 检查值的类型
inline bool isObject(napi_env env, napi_value value) {
    napi_valuetype type;
    check(napi_typeof(env, value, &type));
    return type == napi_object;
}

inline bool isString(napi_env env, napi_value value) {
    napi_valuetype type;
    check(napi_typeof(env, value, &type));
    return type == napi_string;
}

inline bool isNumber(napi_env env, napi_value value) {
    napi_valuetype type;
    check(napi_typeof(env, value, &type));
    return type == napi_number;
}

inline bool isBoolean(napi_env env, napi_value value) {
    napi_valuetype type;
    check(napi_typeof(env, value, &type));
    return type == napi_boolean;
}

inline bool isArray(napi_env env, napi_value value) {
    bool isArray;
    check(napi_is_array(env, value, &isArray));
    return isArray;
}

inline bool isFunction(napi_env env, napi_value value) {
    napi_valuetype type;
    check(napi_typeof(env, value, &type));
    return type == napi_function;
}

// 转换值的类型
inline std::string toString(napi_env env, napi_value value) {
    size_t length;
    check(napi_get_value_string_utf8(env, value, nullptr, 0, &length));
    
    std::string result(length, '\0');
    check(napi_get_value_string_utf8(env, value, &result[0], length + 1, nullptr));
    return result;
}

inline double toNumber(napi_env env, napi_value value) {
    double result;
    check(napi_get_value_double(env, value, &result));
    return result;
}

inline int32_t toInt32(napi_env env, napi_value value) {
    int32_t result;
    check(napi_get_value_int32(env, value, &result));
    return result;
}

inline bool toBoolean(napi_env env, napi_value value) {
    bool result;
    check(napi_get_value_bool(env, value, &result));
    return result;
}

// 创建一个错误对象
inline napi_value createError(napi_env env, const std::string& message) {
    napi_value error;
    check(napi_create_error(env, nullptr, createString(env, message), &error));
    return error;
}

// 抛出错误
inline void throwError(napi_env env, const std::string& message) {
    check(napi_throw(env, createError(env, message)));
}

// 包装和展开对象
inline void wrapObject(napi_env env, napi_value jsObj, void* nativeObj) {
    check(napi_wrap(env, jsObj, nativeObj, nullptr, nullptr, nullptr));
}

inline void* unwrapObject(napi_env env, napi_value jsObj) {
    void* nativeObj;
    check(napi_unwrap(env, jsObj, &nativeObj));
    return nativeObj;
}

// 异步工作
struct AsyncWorker {
    napi_env env;
    napi_value async_resource;
    napi_value async_resource_name;
    napi_async_work work;
    std::function<void()> execute;
    std::function<void()> complete;
    std::exception_ptr error;
    
    AsyncWorker(napi_env e, napi_value resource_name)
        : env(e), execute(nullptr), complete(nullptr), error(nullptr) {
        check(napi_create_string_utf8(env, "mbgl:async", NAPI_AUTO_LENGTH, &async_resource_name));
        check(napi_create_async_work(env, nullptr, async_resource_name, ExecuteWork, CompleteWork, this, &work));
    }
    
    ~AsyncWorker() {
        if (work) {
            napi_delete_async_work(env, work);
        }
    }
    
    void queue() {
        check(napi_queue_async_work(env, work));
    }
    
    static void ExecuteWork(napi_env env, void* data) {
        AsyncWorker* worker = static_cast<AsyncWorker*>(data);
        try {
            if (worker->execute) {
                worker->execute();
            }
        } catch (...) {
            worker->error = std::current_exception();
        }
    }
    
    static void CompleteWork(napi_env env, napi_status status, void* data) {
        AsyncWorker* worker = static_cast<AsyncWorker*>(data);
        try {
            if (worker->error) {
                std::rethrow_exception(worker->error);
            }
            if (worker->complete) {
                worker->complete();
            }
        } catch (const std::exception& e) {
            napi_throw_error(env, nullptr, e.what());
        } catch (...) {
            napi_throw_error(env, nullptr, "Unknown error");
        }
        delete worker;
    }
};

} // namespace napi_utils
} // namespace node_mbgl