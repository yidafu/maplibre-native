#pragma once

#include "thread_safe_callback.hpp"
#include "napi/native_api.h"
#include <string>
#include <unordered_map>
#include <memory>
#include <mutex>
#include <functional>

namespace mbgl {
namespace harmony {

/**
 * CallbackManager - 统一管理所有跨线程 JavaScript 回调
 * 
 * 负责管理 NativeMapView 中所有需要从 Map RunLoop 线程回调到 UI 线程的 JavaScript 函数。
 * 使用 ThreadSafeCallback 包装每个回调，确保线程安全。
 * 
 * 设计原则：
 * 1. 集中管理：所有 JS 回调通过统一接口注册和调用
 * 2. 线程安全：使用互斥锁保护回调容器
 * 3. 生命周期管理：提供清晰的注册、注销、清理接口
 * 4. 错误处理：处理回调不存在、重复注册等异常情况
 * 
 * 使用示例：
 * ```cpp
 * // 在 NativeMapView 构造函数中创建
 * callbackManager_ = std::make_unique<CallbackManager>(env);
 * 
 * // 注册回调（UI 线程）
 * callbackManager_->RegisterCallback("onMapLoaded", jsCallback);
 * 
 * // 调用回调（Map RunLoop 线程）
 * callbackManager_->InvokeCallback("onMapLoaded", [](napi_env env) {
 *     napi_value result;
 *     napi_create_string_utf8(env, "Map loaded!", NAPI_AUTO_LENGTH, &result);
 *     return result;
 * });
 * 
 * // 注销回调
 * callbackManager_->UnregisterCallback("onMapLoaded");
 * 
 * // 清理所有回调（析构时）
 * callbackManager_->Clear();
 * ```
 */
class CallbackManager {
public:
    /**
     * 构造函数
     * 
     * @param env N-API 环境（UI 线程）
     */
    explicit CallbackManager(napi_env env);
    
    ~CallbackManager();
    
    // 禁止拷贝和移动
    CallbackManager(const CallbackManager&) = delete;
    CallbackManager& operator=(const CallbackManager&) = delete;
    CallbackManager(CallbackManager&&) = delete;
    CallbackManager& operator=(CallbackManager&&) = delete;
    
    /**
     * 注册回调
     * 
     * @param name 回调名称（唯一标识）
     * @param callback JavaScript 回调函数
     * @return 是否成功注册
     * 
     * 注意：如果已存在同名回调，会先注销旧回调再注册新的
     */
    bool RegisterCallback(const std::string& name, napi_value callback);
    
    /**
     * 注销回调
     * 
     * @param name 回调名称
     * @return 是否成功注销
     */
    bool UnregisterCallback(const std::string& name);
    
    /**
     * 调用回调（从任意线程）
     * 
     * @param name 回调名称
     * @param builder 数据构造器（在 UI 线程执行）
     * @return 是否成功调度回调
     */
    bool InvokeCallback(
        const std::string& name,
        ThreadSafeCallback::DataBuilder builder
    );
    
    /**
     * 便捷方法：调用无参数回调
     */
    bool InvokeCallbackEmpty(const std::string& name);
    
    /**
     * 便捷方法：调用带字符串参数的回调
     */
    bool InvokeCallbackWithString(const std::string& name, const std::string& value);
    
    /**
     * 便捷方法：调用带对象参数的回调
     */
    bool InvokeCallbackWithObject(
        const std::string& name,
        const std::function<void(napi_env, napi_value)>& buildObject
    );
    
    /**
     * 检查回调是否存在
     */
    bool HasCallback(const std::string& name) const;
    
    /**
     * 获取已注册的回调数量
     */
    size_t GetCallbackCount() const;
    
    /**
     * 清理所有回调
     * 
     * 注意：会释放所有 ThreadSafeFunction，之后无法再调用任何回调
     */
    void Clear();
    
private:
    napi_env env_;
    
    // 回调容器（线程安全）
    std::unordered_map<std::string, std::unique_ptr<ThreadSafeCallback>> callbacks_;
    
    // 保护回调容器的互斥锁
    mutable std::mutex mutex_;
    
    // 标记是否已清理
    bool cleared_ = false;
};

} // namespace harmony
} // namespace mbgl

