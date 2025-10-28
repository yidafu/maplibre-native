#pragma once

#include "napi/native_api.h"
#include <functional>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * ThreadSafeCallback - 线程安全的跨线程回调包装器
 * 
 * 封装 N-API ThreadSafeFunction，支持从任意线程安全地调用 JavaScript 回调。
 * 参考 Android 的 MapRendererRunnable 设计，但使用 N-API 的 ThreadSafeFunction。
 * 
 * 使用示例：
 * ```cpp
 * // 在 UI 线程创建
 * auto callback = ThreadSafeCallback::Create(env, jsCallback, "onMapLoaded");
 * 
 * // 从渲染线程调用
 * callback->Call([](napi_env env) {
 *     napi_value result;
 *     napi_create_string_utf8(env, "Map loaded", NAPI_AUTO_LENGTH, &result);
 *     return result;
 * });
 * 
 * // 销毁（自动在析构时调用）
 * callback->Release();
 * ```
 */
class ThreadSafeCallback {
public:
    /**
     * 数据构造器 - 用于在回调中构造参数
     * 
     * @param env N-API 环境（已在 UI 线程）
     * @return 回调参数（napi_value）
     */
    using DataBuilder = std::function<napi_value(napi_env env)>;
    
    /**
     * 创建线程安全的回调
     * 
     * @param env N-API 环境
     * @param callback JavaScript 回调函数
     * @param resourceName 资源名称（用于调试）
     * @return ThreadSafeCallback 实例，失败返回 nullptr
     */
    static std::unique_ptr<ThreadSafeCallback> Create(
        napi_env env,
        napi_value callback,
        const char* resourceName
    );
    
    ~ThreadSafeCallback();
    
    // 禁止拷贝
    ThreadSafeCallback(const ThreadSafeCallback&) = delete;
    ThreadSafeCallback& operator=(const ThreadSafeCallback&) = delete;
    
    /**
     * 从任意线程调用回调
     * 
     * @param builder 数据构造器（在 UI 线程执行）
     * @return 是否成功调度回调
     */
    bool Call(DataBuilder builder);
    
    /**
     * 带单个参数的便捷调用
     */
    bool CallWithString(const std::string& value);
    
    /**
     * 带对象参数的便捷调用
     */
    bool CallWithObject(const std::function<void(napi_env, napi_value)>& buildObject);
    
    /**
     * 无参数调用
     */
    bool CallEmpty();
    
    /**
     * 释放资源（可提前调用，析构时自动调用）
     */
    void Release();
    
    /**
     * 检查是否有效
     */
    bool IsValid() const { return tsfn_ != nullptr; }
    
private:
    ThreadSafeCallback() = default;
    
    /**
     * 初始化 ThreadSafeFunction
     */
    bool Initialize(
        napi_env env,
        napi_value callback,
        const char* resourceName
    );
    
    /**
     * 回调数据包装
     */
    struct CallbackData {
        DataBuilder builder;
        
        explicit CallbackData(DataBuilder b) : builder(std::move(b)) {}
    };
    
    /**
     * N-API 回调：在 UI 线程执行
     */
    static void CallJS(
        napi_env env,
        napi_value js_callback,
        void* context,
        void* data
    );
    
    /**
     * ThreadSafeFunction 终结器
     */
    static void Finalize(
        napi_env env,
        void* finalize_data,
        void* finalize_hint
    );
    
    napi_threadsafe_function tsfn_ = nullptr;
    std::string resourceName_;
};

} // namespace harmony
} // namespace mbgl

