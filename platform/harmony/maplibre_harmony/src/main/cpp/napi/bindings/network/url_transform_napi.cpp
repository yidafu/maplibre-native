#include "url_transform_napi.hpp"
#include "napi/core/napi_utils.h"
#include "network/url_transform_manager.hpp"
#include "utils/logger.h"
#include <string>
#include <mutex>
#include <condition_variable>
#include <chrono>

using mbgl::harmony::Logger;
using mbgl::harmony::URLTransformManager;

namespace mbgl {
namespace harmony {

// 静态成员初始化
URLTransformNAPI::CallbackContext* URLTransformNAPI::callbackContext_ = nullptr;

// 线程安全函数调用的数据结构
struct TransformCallData {
    int kind;
    std::string url;
    std::string* result;  // 指向结果字符串的指针
    std::mutex* mutex;    // 用于同步的互斥锁
    std::condition_variable* cv;  // 用于同步的条件变量
    bool* done;           // 完成标志
};

// 线程安全函数的回调（在JS线程中执行）
static void CallJS(napi_env env, napi_value js_callback, void* context, void* data) {
    if (env == nullptr || js_callback == nullptr || data == nullptr) {
        return;
    }

    TransformCallData* callData = static_cast<TransformCallData*>(data);

    try {
        // 准备参数
        napi_value args[2];
        napi_create_int32(env, callData->kind, &args[0]);
        napi_create_string_utf8(env, callData->url.c_str(), NAPI_AUTO_LENGTH, &args[1]);

        // 调用JS回调
        napi_value result_value;
        napi_status status = napi_call_function(env, nullptr, js_callback, 2, args, &result_value);

        if (status == napi_ok) {
            // 获取返回值
            size_t result_length;
            napi_get_value_string_utf8(env, result_value, nullptr, 0, &result_length);
            
            if (result_length > 0) {
                std::string result_str(result_length, '\0');
                napi_get_value_string_utf8(env, result_value, &result_str[0], result_length + 1, nullptr);
                *callData->result = result_str;
            } else {
                // 回调返回空字符串或undefined，使用原URL
                *callData->result = callData->url;
            }
        } else {
            Logger::error("URLTransformNAPI", "Failed to call JS callback");
            *callData->result = callData->url;
        }

    } catch (const std::exception& e) {
        Logger::error("URLTransformNAPI", "Exception in CallJS: %s", e.what());
        *callData->result = callData->url;
    } catch (...) {
        Logger::error("URLTransformNAPI", "Unknown exception in CallJS");
        *callData->result = callData->url;
    }

    // 通知C++线程回调已完成
    {
        std::lock_guard<std::mutex> lock(*callData->mutex);
        *callData->done = true;
    }
    callData->cv->notify_one();
}

napi_value URLTransformNAPI::Init(napi_env env, napi_value exports) {
    napi_property_descriptor descriptors[] = {
        {"setResourceTransformCallback", nullptr, SetResourceTransformCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clearResourceTransformCallback", nullptr, ClearResourceTransformCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"hasResourceTransformCallback", nullptr, HasResourceTransformCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_status status = napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    if (status != napi_ok) {
        Logger::error("URLTransformNAPI", "Failed to define properties");
    }

    return exports;
}

napi_value URLTransformNAPI::SetResourceTransformCallback(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Missing argument: callback function required");
        return nullptr;
    }

    // 检查参数是否为函数
    napi_valuetype valuetype;
    napi_typeof(env, args[0], &valuetype);
    if (valuetype != napi_function) {
        napi_throw_type_error(env, nullptr, "Argument must be a function");
        return nullptr;
    }

    // 清理旧的回调上下文
    if (callbackContext_ != nullptr) {
        if (callbackContext_->tsfn != nullptr) {
            napi_release_threadsafe_function(callbackContext_->tsfn, napi_tsfn_abort);
        }
        if (callbackContext_->callbackRef != nullptr) {
            napi_delete_reference(callbackContext_->env, callbackContext_->callbackRef);
        }
        delete callbackContext_;
        callbackContext_ = nullptr;
    }

    // 创建新的回调上下文
    callbackContext_ = new CallbackContext();
    callbackContext_->env = env;

    // 创建持久引用
    napi_create_reference(env, args[0], 1, &callbackContext_->callbackRef);

    // 创建线程安全函数
    napi_value async_resource_name;
    napi_create_string_utf8(env, "URLTransformCallback", NAPI_AUTO_LENGTH, &async_resource_name);

    napi_status status = napi_create_threadsafe_function(
        env,
        args[0],
        nullptr,
        async_resource_name,
        0,  // 无限队列大小
        1,  // 初始线程计数
        nullptr,
        nullptr,
        nullptr,
        CallJS,
        &callbackContext_->tsfn);

    if (status != napi_ok) {
        Logger::error("URLTransformNAPI", "Failed to create threadsafe function");
        delete callbackContext_;
        callbackContext_ = nullptr;
        napi_throw_error(env, nullptr, "Failed to create threadsafe function");
        return nullptr;
    }

    // 设置C++层的转换回调
    URLTransformManager::getInstance().setTransformCallback(
        [](mbgl::Resource::Kind kind, const std::string& url) -> std::string {
            if (callbackContext_ == nullptr || callbackContext_->tsfn == nullptr) {
                return url;
            }

            try {
                // 准备调用数据
                std::string result;
                std::mutex mutex;
                std::condition_variable cv;
                bool done = false;

                TransformCallData callData{
                    static_cast<int>(kind),
                    url,
                    &result,
                    &mutex,
                    &cv,
                    &done
                };

                // 调用线程安全函数
                napi_status status = napi_call_threadsafe_function(
                    callbackContext_->tsfn,
                    &callData,
                    napi_tsfn_blocking);

                if (status != napi_ok) {
                    Logger::error("URLTransformNAPI", "Failed to call threadsafe function");
                    return url;
                }

                // 等待回调完成（超时保护）
                std::unique_lock<std::mutex> lock(mutex);
                if (!cv.wait_for(lock, std::chrono::seconds(5), [&done] { return done; })) {
                    Logger::error("URLTransformNAPI", "Timeout waiting for JS callback");
                    return url;
                }

                return result;

            } catch (const std::exception& e) {
                Logger::error("URLTransformNAPI", "Exception in transform callback: %s", e.what());
                return url;
            } catch (...) {
                Logger::error("URLTransformNAPI", "Unknown exception in transform callback");
                return url;
            }
        });

    Logger::info("URLTransformNAPI", "Resource transform callback set");

    return nullptr;
}

napi_value URLTransformNAPI::ClearResourceTransformCallback(napi_env env, napi_callback_info info) {
    // 清理回调上下文
    if (callbackContext_ != nullptr) {
        if (callbackContext_->tsfn != nullptr) {
            napi_release_threadsafe_function(callbackContext_->tsfn, napi_tsfn_abort);
            callbackContext_->tsfn = nullptr;
        }
        if (callbackContext_->callbackRef != nullptr) {
            napi_delete_reference(callbackContext_->env, callbackContext_->callbackRef);
            callbackContext_->callbackRef = nullptr;
        }
        delete callbackContext_;
        callbackContext_ = nullptr;
    }

    // 清除C++层的回调
    URLTransformManager::getInstance().clearTransformCallback();

    Logger::info("URLTransformNAPI", "Resource transform callback cleared");

    return nullptr;
}

napi_value URLTransformNAPI::HasResourceTransformCallback(napi_env env, napi_callback_info info) {
    bool hasCallback = URLTransformManager::getInstance().hasCallback();

    napi_value result;
    napi_get_boolean(env, hasCallback, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

