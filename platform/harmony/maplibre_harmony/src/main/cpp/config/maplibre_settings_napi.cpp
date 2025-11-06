#include "maplibre_settings_napi.hpp"
#include "maplibre_settings.hpp"
#include "napi/core/napi_utils.h"

#include <string>

namespace mbgl {
namespace harmony {

void MapLibreSettingsNAPI::Init(napi_env env, napi_value exports) {
    // 定义要导出的方法
    napi_property_descriptor descriptors[] = {
        {"setAccessToken", nullptr, SetAccessToken, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getAccessToken", nullptr, GetAccessToken, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"useMapboxConfiguration", nullptr, UseMapboxConfiguration, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"useMapTilerConfiguration", nullptr, UseMapTilerConfiguration, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"useMapLibreConfiguration", nullptr, UseMapLibreConfiguration, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setApiBaseURL", nullptr, SetApiBaseURL, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getApiBaseURL", nullptr, GetApiBaseURL, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    // 注册方法到 exports 对象
    napi_status status = napi_define_properties(env, exports, 
        sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to register MapLibreSettings NAPI functions");
    }
}

napi_value MapLibreSettingsNAPI::SetAccessToken(napi_env env, napi_callback_info info) {
    // 获取参数
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "setAccessToken requires 1 argument: token");
        return nullptr;
    }
    
    // 获取字符串参数
    size_t str_size;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &str_size);
    std::string token(str_size, '\0');
    napi_get_value_string_utf8(env, args[0], &token[0], str_size + 1, &str_size);
    
    // 设置 API Key
    MapLibreSettings::getInstance().setApiKey(token);
    
    return nullptr;
}

napi_value MapLibreSettingsNAPI::GetAccessToken(napi_env env, napi_callback_info info) {
    // 获取 API Key
    std::string token = MapLibreSettings::getInstance().getApiKey();
    
    // 转换为 NAPI 字符串
    napi_value result;
    napi_create_string_utf8(env, token.c_str(), token.length(), &result);
    
    return result;
}

napi_value MapLibreSettingsNAPI::UseMapboxConfiguration(napi_env env, napi_callback_info info) {
    MapLibreSettings::getInstance().useMapboxConfiguration();
    return nullptr;
}

napi_value MapLibreSettingsNAPI::UseMapTilerConfiguration(napi_env env, napi_callback_info info) {
    MapLibreSettings::getInstance().useMapTilerConfiguration();
    return nullptr;
}

napi_value MapLibreSettingsNAPI::UseMapLibreConfiguration(napi_env env, napi_callback_info info) {
    MapLibreSettings::getInstance().useMapLibreConfiguration();
    return nullptr;
}

napi_value MapLibreSettingsNAPI::SetApiBaseURL(napi_env env, napi_callback_info info) {
    // 获取参数
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "setApiBaseURL requires 1 argument: url");
        return nullptr;
    }
    
    // 获取字符串参数
    size_t str_size;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &str_size);
    std::string url(str_size, '\0');
    napi_get_value_string_utf8(env, args[0], &url[0], str_size + 1, &str_size);
    
    // 设置 Base URL
    MapLibreSettings::getInstance().setBaseURL(url);
    
    return nullptr;
}

napi_value MapLibreSettingsNAPI::GetApiBaseURL(napi_env env, napi_callback_info info) {
    // 获取 Base URL
    std::string url = MapLibreSettings::getInstance().getBaseURL();
    
    // 转换为 NAPI 字符串
    napi_value result;
    napi_create_string_utf8(env, url.c_str(), url.length(), &result);
    
    return result;
}

} // namespace harmony
} // namespace mbgl

