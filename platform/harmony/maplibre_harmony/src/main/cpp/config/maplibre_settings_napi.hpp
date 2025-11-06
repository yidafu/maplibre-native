#ifndef MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_NAPI_HPP
#define MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_NAPI_HPP

#include <napi/native_api.h>

namespace mbgl {
namespace harmony {

/**
 * MapLibreSettingsNAPI - NAPI 绑定类
 * 
 * 将 MapLibreSettings 的功能暴露给 ArkTS 层
 */
class MapLibreSettingsNAPI {
public:
    /**
     * 初始化并注册 NAPI 方法
     * @param env NAPI 环境
     * @param exports 导出对象
     */
    static void Init(napi_env env, napi_value exports);

private:
    // 设置 Access Token
    static napi_value SetAccessToken(napi_env env, napi_callback_info info);
    
    // 获取 Access Token
    static napi_value GetAccessToken(napi_env env, napi_callback_info info);
    
    // 使用 Mapbox 配置
    static napi_value UseMapboxConfiguration(napi_env env, napi_callback_info info);
    
    // 使用 MapTiler 配置
    static napi_value UseMapTilerConfiguration(napi_env env, napi_callback_info info);
    
    // 使用 MapLibre 配置
    static napi_value UseMapLibreConfiguration(napi_env env, napi_callback_info info);
    
    // 设置 Base URL
    static napi_value SetApiBaseURL(napi_env env, napi_callback_info info);
    
    // 获取 Base URL
    static napi_value GetApiBaseURL(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_NAPI_HPP

