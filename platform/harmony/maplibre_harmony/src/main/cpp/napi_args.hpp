//
// Created for N-API parameter parsing utility
//

#ifndef MAPLIBREHARMONY_NAPI_ARGS_HPP
#define MAPLIBREHARMONY_NAPI_ARGS_HPP

#include <napi/native_api.h>
#include <string>
#include <vector>
#include <optional>

namespace mbgl {
namespace harmony {
namespace napi {

/**
 * NapiArgs - N-API 参数解析工具类
 * 
 * 简化 N-API 函数的参数解析过程，提供类型安全的参数访问和自动错误处理。
 * 
 * 使用示例:
 * ```cpp
 * napi_value MyFunction(napi_env env, napi_callback_info info) {
 *     NapiArgs args(env, info);
 *     args.RequireMinArgs(2);
 *     if (args.HasError()) return nullptr;
 *     
 *     std::string name = args.GetString(0, "name");
 *     int64_t value = args.GetInt64(1, "value");
 *     if (args.HasError()) return nullptr;
 *     
 *     // ... 使用参数
 * }
 * ```
 */
class NapiArgs {
public:
    /**
     * 构造函数 - 自动解析 N-API 回调信息
     * @param env N-API 环境
     * @param info N-API 回调信息
     * @param maxArgs 最大参数数量（默认16）
     */
    explicit NapiArgs(napi_env env, napi_callback_info info, size_t maxArgs = 16);
    
    // 禁用拷贝
    NapiArgs(const NapiArgs&) = delete;
    NapiArgs& operator=(const NapiArgs&) = delete;
    
    // ========== 参数数量和检查 ==========
    
    /**
     * 获取实际传入的参数数量
     */
    size_t Count() const { return argc_; }
    
    /**
     * 检查指定索引的参数是否存在
     */
    bool Has(size_t index) const { return index < argc_; }
    
    /**
     * 要求最少参数数量
     * 如果参数不足，设置错误并抛出 JS 异常
     */
    void RequireMinArgs(size_t min);
    
    /**
     * 检查参数类型
     */
    bool IsType(size_t index, napi_valuetype type);
    
    // ========== 错误处理 ==========
    
    /**
     * 检查是否有错误
     */
    bool HasError() const { return hasError_; }
    
    /**
     * 获取错误信息
     */
    std::string GetError() const { return errorMessage_; }
    
    /**
     * 获取 N-API 环境
     */
    napi_env Env() const { return env_; }
    
    // ========== 基础类型参数获取 ==========
    
    /**
     * 获取字符串参数
     * @param index 参数索引
     * @param name 参数名称（用于错误消息，可选）
     * @return 字符串值，失败时返回空字符串并设置错误
     */
    std::string GetString(size_t index, const char* name = nullptr);
    
    /**
     * 获取 int32 参数
     */
    int32_t GetInt32(size_t index, const char* name = nullptr);
    
    /**
     * 获取 int64 参数
     */
    int64_t GetInt64(size_t index, const char* name = nullptr);
    
    /**
     * 获取 uint32 参数
     */
    uint32_t GetUint32(size_t index, const char* name = nullptr);
    
    /**
     * 获取 double 参数
     */
    double GetDouble(size_t index, const char* name = nullptr);
    
    /**
     * 获取 bool 参数
     */
    bool GetBool(size_t index, const char* name = nullptr);
    
    /**
     * 获取 BigInt (int64) 参数
     * 主要用于 Surface ID 等需要 BigInt 的场景
     */
    int64_t GetBigInt(size_t index, const char* name = nullptr);
    
    // ========== 复杂类型参数获取 ==========
    
    /**
     * 获取对象参数
     * @param index 参数索引
     * @param name 参数名称（可选）
     * @return napi_value 对象，失败时返回 nullptr 并设置错误
     */
    napi_value GetObject(size_t index, const char* name = nullptr);
    
    /**
     * 获取数组参数
     */
    napi_value GetArray(size_t index, const char* name = nullptr);
    
    /**
     * 获取函数参数
     */
    napi_value GetFunction(size_t index, const char* name = nullptr);
    
    /**
     * 获取 Buffer 参数
     * @param index 参数索引
     * @param length 输出参数，Buffer 的长度
     * @param name 参数名称（可选）
     * @return Buffer 的数据指针，失败时返回 nullptr 并设置错误
     */
    void* GetBuffer(size_t index, size_t* length, const char* name = nullptr);
    
    /**
     * 获取原始 napi_value
     * 用于特殊情况下需要直接操作 napi_value 的场景
     */
    napi_value GetValue(size_t index);
    
    // ========== 可选参数（带默认值）==========
    
    /**
     * 获取可选字符串参数
     * 如果参数不存在或类型不匹配，返回默认值
     */
    std::string GetStringOr(size_t index, const std::string& defaultValue);
    
    /**
     * 获取可选 int32 参数
     */
    int32_t GetInt32Or(size_t index, int32_t defaultValue);
    
    /**
     * 获取可选 int64 参数
     */
    int64_t GetInt64Or(size_t index, int64_t defaultValue);
    
    /**
     * 获取可选 uint32 参数
     */
    uint32_t GetUint32Or(size_t index, uint32_t defaultValue);
    
    /**
     * 获取可选 double 参数
     */
    double GetDoubleOr(size_t index, double defaultValue);
    
    /**
     * 获取可选 bool 参数
     */
    bool GetBoolOr(size_t index, bool defaultValue);
    
    // ========== 对象属性访问辅助方法 ==========
    
    /**
     * 从对象中获取字符串属性
     * @param obj 对象
     * @param key 属性名
     * @param defaultValue 默认值
     */
    std::string GetStringProperty(napi_value obj, const char* key, const std::string& defaultValue = "");
    
    /**
     * 从对象中获取 int64 属性
     */
    int64_t GetInt64Property(napi_value obj, const char* key, int64_t defaultValue = 0);
    
    /**
     * 从对象中获取 double 属性
     */
    double GetDoubleProperty(napi_value obj, const char* key, double defaultValue = 0.0);
    
    /**
     * 从对象中获取 bool 属性
     */
    bool GetBoolProperty(napi_value obj, const char* key, bool defaultValue = false);

private:
    napi_env env_;
    size_t argc_;
    std::vector<napi_value> args_;
    bool hasError_;
    std::string errorMessage_;
    
    /**
     * 设置错误信息并抛出 JS 异常
     */
    void SetError(const std::string& message);
    
    /**
     * 检查参数索引是否有效
     */
    bool CheckIndex(size_t index, const char* name = nullptr);
    
    /**
     * 生成参数名称用于错误消息
     */
    std::string GetParamName(size_t index, const char* name) const;
};

} // namespace napi
} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_NAPI_ARGS_HPP

