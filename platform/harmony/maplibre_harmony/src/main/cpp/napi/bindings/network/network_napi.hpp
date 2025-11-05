#pragma once

#include "napi/native_api.h"

namespace mbgl {
namespace harmony {

/**
 * NetworkNAPI - 网络配置的NAPI绑定
 * 
 * 暴露HTTP请求头配置接口给ArkTS层
 */
class NetworkNAPI {
public:
    /**
     * 初始化网络配置NAPI模块
     * 导出静态方法到ArkTS
     */
    static napi_value Init(napi_env env, napi_value exports);

private:
    /**
     * 设置自定义HTTP请求头（替换所有现有请求头）
     * 
     * ArkTS调用: setCustomHttpHeaders(headers: Record<string, string>): void
     */
    static napi_value SetCustomHttpHeaders(napi_env env, napi_callback_info info);

    /**
     * 添加单个自定义HTTP请求头
     * 
     * ArkTS调用: addCustomHttpHeader(key: string, value: string): void
     */
    static napi_value AddCustomHttpHeader(napi_env env, napi_callback_info info);

    /**
     * 移除指定的自定义HTTP请求头
     * 
     * ArkTS调用: removeCustomHttpHeader(key: string): boolean
     */
    static napi_value RemoveCustomHttpHeader(napi_env env, napi_callback_info info);

    /**
     * 清除所有自定义HTTP请求头
     * 
     * ArkTS调用: clearCustomHttpHeaders(): void
     */
    static napi_value ClearCustomHttpHeaders(napi_env env, napi_callback_info info);

    /**
     * 获取所有自定义HTTP请求头
     * 
     * ArkTS调用: getCustomHttpHeaders(): Record<string, string>
     */
    static napi_value GetCustomHttpHeaders(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

