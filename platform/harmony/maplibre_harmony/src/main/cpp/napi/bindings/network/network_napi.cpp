#include "network_napi.hpp"
#include "napi/core/napi_utils.h"
#include "network/http_request_config.hpp"
#include "utils/logger.h"
#include <string>
#include <map>

using mbgl::harmony::Logger;
using mbgl::harmony::HTTPRequestConfig;

namespace mbgl {
namespace harmony {

napi_value NetworkNAPI::Init(napi_env env, napi_value exports) {
    // 导出静态方法
    napi_property_descriptor descriptors[] = {
        {"setCustomHttpHeaders", nullptr, SetCustomHttpHeaders, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addCustomHttpHeader", nullptr, AddCustomHttpHeader, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"removeCustomHttpHeader", nullptr, RemoveCustomHttpHeader, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clearCustomHttpHeaders", nullptr, ClearCustomHttpHeaders, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getCustomHttpHeaders", nullptr, GetCustomHttpHeaders, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_status status = napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    if (status != napi_ok) {
        Logger::error("NetworkNAPI", "Failed to define properties");
    }

    return exports;
}

napi_value NetworkNAPI::SetCustomHttpHeaders(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Missing argument: headers object required");
        return nullptr;
    }

    // 检查参数是否为对象
    napi_valuetype valuetype;
    napi_typeof(env, args[0], &valuetype);
    if (valuetype != napi_object) {
        napi_throw_type_error(env, nullptr, "Argument must be an object");
        return nullptr;
    }

    // 获取对象的所有属性名
    napi_value property_names;
    napi_get_property_names(env, args[0], &property_names);

    uint32_t length;
    napi_get_array_length(env, property_names, &length);

    // 构建请求头映射
    std::map<std::string, std::string> headers;
    for (uint32_t i = 0; i < length; i++) {
        napi_value key_value;
        napi_get_element(env, property_names, i, &key_value);

        // 获取键名
        size_t key_length;
        napi_get_value_string_utf8(env, key_value, nullptr, 0, &key_length);
        std::string key(key_length, '\0');
        napi_get_value_string_utf8(env, key_value, &key[0], key_length + 1, nullptr);

        // 获取值
        napi_value value_value;
        napi_get_property(env, args[0], key_value, &value_value);

        size_t value_length;
        napi_get_value_string_utf8(env, value_value, nullptr, 0, &value_length);
        std::string value(value_length, '\0');
        napi_get_value_string_utf8(env, value_value, &value[0], value_length + 1, nullptr);

        headers[key] = value;
    }

    // 设置自定义请求头
    HTTPRequestConfig::getInstance().setCustomHeaders(headers);

    Logger::info("NetworkNAPI", "Set %zu custom HTTP headers", headers.size());

    return nullptr;
}

napi_value NetworkNAPI::AddCustomHttpHeader(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        napi_throw_error(env, nullptr, "Missing arguments: key and value required");
        return nullptr;
    }

    // 获取键
    size_t key_length;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &key_length);
    std::string key(key_length, '\0');
    napi_get_value_string_utf8(env, args[0], &key[0], key_length + 1, nullptr);

    // 获取值
    size_t value_length;
    napi_get_value_string_utf8(env, args[1], nullptr, 0, &value_length);
    std::string value(value_length, '\0');
    napi_get_value_string_utf8(env, args[1], &value[0], value_length + 1, nullptr);

    // 添加自定义请求头
    HTTPRequestConfig::getInstance().addCustomHeader(key, value);

    Logger::info("NetworkNAPI", "Added custom HTTP header: %s", key.c_str());

    return nullptr;
}

napi_value NetworkNAPI::RemoveCustomHttpHeader(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        napi_throw_error(env, nullptr, "Missing argument: key required");
        return nullptr;
    }

    // 获取键
    size_t key_length;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &key_length);
    std::string key(key_length, '\0');
    napi_get_value_string_utf8(env, args[0], &key[0], key_length + 1, nullptr);

    // 移除自定义请求头
    bool removed = HTTPRequestConfig::getInstance().removeCustomHeader(key);

    Logger::info("NetworkNAPI", "Removed custom HTTP header: %s (success: %d)", key.c_str(), removed);

    // 返回布尔值
    napi_value result;
    napi_get_boolean(env, removed, &result);
    return result;
}

napi_value NetworkNAPI::ClearCustomHttpHeaders(napi_env env, napi_callback_info info) {
    // 清除所有自定义请求头
    HTTPRequestConfig::getInstance().clearCustomHeaders();

    Logger::info("NetworkNAPI", "Cleared all custom HTTP headers");

    return nullptr;
}

napi_value NetworkNAPI::GetCustomHttpHeaders(napi_env env, napi_callback_info info) {
    // 获取所有自定义请求头
    auto headers = HTTPRequestConfig::getInstance().getCustomHeaders();

    // 创建返回对象
    napi_value result;
    napi_create_object(env, &result);

    // 将C++映射转换为NAPI对象
    for (const auto& [key, value] : headers) {
        napi_value key_value;
        napi_create_string_utf8(env, key.c_str(), NAPI_AUTO_LENGTH, &key_value);

        napi_value value_value;
        napi_create_string_utf8(env, value.c_str(), NAPI_AUTO_LENGTH, &value_value);

        napi_set_property(env, result, key_value, value_value);
    }

    Logger::debug("NetworkNAPI", "Retrieved %zu custom HTTP headers", headers.size());

    return result;
}

} // namespace harmony
} // namespace mbgl

