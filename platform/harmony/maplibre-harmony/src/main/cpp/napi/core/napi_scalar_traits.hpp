//
// N-API 标量类型特征（供 NapiArgs 的取值模板复用）
//
// 背景：napi_args.cpp 里 GetXxx / GetXxxOr / GetXxxProperty /
// GetArrayElementXxx 四组函数各自重复了「校验索引 -> 校验 JS 类型 ->
// 抛错 -> 读值」的同一套骨架，唯一差异只是 napi_valuetype、napi_get_value_*
// 函数与错误文案。把这些差异收敛到一处 traits，骨架交给模板。
//
// 约束：错误文案必须与重构前逐字一致（外部测试与用户可见的异常信息依赖它）。
//

#ifndef MAPLIBREHARMONY_NAPI_SCALAR_TRAITS_HPP
#define MAPLIBREHARMONY_NAPI_SCALAR_TRAITS_HPP

#include <napi/native_api.h>
#include <string>

namespace mbgl {
namespace harmony {
namespace napi {

/**
 * 标量类型特征：把「JS 类型 / 类型名文案 / 取值函数 / 失败文案」绑定到一个 C++ 类型。
 *
 * 每个特化提供：
 *   static constexpr napi_valuetype jsType;   —— 期望的 JS 类型
 *   static constexpr const char* jsTypeName;  —— 类型不匹配时的文案片段（如 "a number"）
 *   static napi_status read(env, value, out, errorMessage)
 *                                            —— 读取值；失败时写入 errorMessage 并返回非 napi_ok
 *
 * 注意：read() 必须保证 out 在失败时处于「已定义」状态（不读取未初始化内存）。
 */
template <typename T>
struct NapiScalarTraits;

template <>
struct NapiScalarTraits<int32_t> {
    static constexpr napi_valuetype jsType = napi_number;
    static constexpr const char* jsTypeName = "a number";

    static napi_status read(napi_env env, napi_value value, int32_t* out,
                            const char** errorMessage) {
        const napi_status status = napi_get_value_int32(env, value, out);
        if (status != napi_ok) {
            *errorMessage = "Failed to get int32 value";
        }
        return status;
    }
};

template <>
struct NapiScalarTraits<int64_t> {
    static constexpr napi_valuetype jsType = napi_number;
    static constexpr const char* jsTypeName = "a number";

    static napi_status read(napi_env env, napi_value value, int64_t* out,
                            const char** errorMessage) {
        const napi_status status = napi_get_value_int64(env, value, out);
        if (status != napi_ok) {
            *errorMessage = "Failed to get int64 value";
        }
        return status;
    }
};

template <>
struct NapiScalarTraits<uint32_t> {
    static constexpr napi_valuetype jsType = napi_number;
    static constexpr const char* jsTypeName = "a number";

    static napi_status read(napi_env env, napi_value value, uint32_t* out,
                            const char** errorMessage) {
        const napi_status status = napi_get_value_uint32(env, value, out);
        if (status != napi_ok) {
            *errorMessage = "Failed to get uint32 value";
        }
        return status;
    }
};

template <>
struct NapiScalarTraits<double> {
    static constexpr napi_valuetype jsType = napi_number;
    static constexpr const char* jsTypeName = "a number";

    static napi_status read(napi_env env, napi_value value, double* out,
                            const char** errorMessage) {
        const napi_status status = napi_get_value_double(env, value, out);
        if (status != napi_ok) {
            *errorMessage = "Failed to get double value";
        }
        return status;
    }
};

template <>
struct NapiScalarTraits<bool> {
    static constexpr napi_valuetype jsType = napi_boolean;
    static constexpr const char* jsTypeName = "a boolean";

    static napi_status read(napi_env env, napi_value value, bool* out,
                            const char** errorMessage) {
        const napi_status status = napi_get_value_bool(env, value, out);
        if (status != napi_ok) {
            *errorMessage = "Failed to get bool value";
        }
        return status;
    }
};

/**
 * std::string 的取值是两步：先问长度，再拷贝内容。
 * 两步各有自己的失败文案，空串走短路返回，都与重构前一致。
 */
template <>
struct NapiScalarTraits<std::string> {
    static constexpr napi_valuetype jsType = napi_string;
    static constexpr const char* jsTypeName = "a string";

    static napi_status read(napi_env env, napi_value value, std::string* out,
                            const char** errorMessage) {
        size_t length = 0;
        napi_status status = napi_get_value_string_utf8(env, value, nullptr, 0, &length);
        if (status != napi_ok) {
            *errorMessage = "Failed to get string length";
            return status;
        }
        if (length == 0) {
            // 空串直接命中，不做第二次调用（与重构前一致）
            return napi_ok;
        }

        // 注意：std::string 保证 data()[size()] 处有可写的 '\0' 槽位，
        // 因此下面按 length + 1 写入（内容 + 终止符）是合法的；
        // 写完之后 size 仍为 length，与重构前完全一致（不做 resize）。
        std::string result(length, '\0');
        status = napi_get_value_string_utf8(env, value, &result[0], length + 1, &length);
        if (status != napi_ok) {
            *errorMessage = "Failed to get string value";
            return status;
        }
        *out = std::move(result);
        return napi_ok;
    }
};

} // namespace napi
} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_NAPI_SCALAR_TRAITS_HPP
