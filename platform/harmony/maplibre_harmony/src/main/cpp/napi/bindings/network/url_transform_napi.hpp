#pragma once

#include "napi/native_api.h"
#include <mbgl/storage/resource.hpp>

namespace mbgl {
namespace harmony {

/**
 * URLTransformNAPI - URL转换功能的NAPI绑定
 * 
 * 暴露URL转换配置接口给ArkTS层，处理跨线程回调
 */
class URLTransformNAPI {
public:
    /**
     * 初始化URL转换NAPI模块
     */
    static napi_value Init(napi_env env, napi_value exports);

private:
    /**
     * 设置URL转换回调
     * 
     * ArkTS调用: setResourceTransformCallback(callback: (kind: number, url: string) => string): void
     */
    static napi_value SetResourceTransformCallback(napi_env env, napi_callback_info info);

    /**
     * 清除URL转换回调
     * 
     * ArkTS调用: clearResourceTransformCallback(): void
     */
    static napi_value ClearResourceTransformCallback(napi_env env, napi_callback_info info);

    /**
     * 检查是否设置了转换回调
     * 
     * ArkTS调用: hasResourceTransformCallback(): boolean
     */
    static napi_value HasResourceTransformCallback(napi_env env, napi_callback_info info);

    // 用于存储跨线程回调的静态变量
    struct CallbackContext {
        napi_env env;
        napi_ref callbackRef;
        napi_threadsafe_function tsfn;
    };

    static CallbackContext* callbackContext_;
};

} // namespace harmony
} // namespace mbgl

