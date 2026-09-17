#include "network_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "network/http_request_config.hpp"
#include "utils/logger.h"
#include <string>
#include <map>

using mbgl::harmony::Logger;
using mbgl::harmony::HTTPRequestConfig;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

napi_value NetworkNAPI::Init(napi_env env, napi_value exports) {
    // Export static methods
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
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    napi_value headersObj = args.GetObject(0, "headers");
    if (args.HasError()) {
        return nullptr;
    }

    // Retrieve all property names from the object
    napi_value property_names;
    if (napi_get_property_names(env, headersObj, &property_names) != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to read header property names");
        return nullptr;
    }

    uint32_t length = 0;
    napi_get_array_length(env, property_names, &length);

    // Build the header map
    std::map<std::string, std::string> headers;
    for (uint32_t i = 0; i < length; i++) {
        napi_value key_value;
        if (napi_get_element(env, property_names, i, &key_value) != napi_ok) {
            continue;
        }

        // Get the key name: property names are always strings, but check the
        // status anyway — an unchecked/uninitialized length would drive a huge
        // allocation or, worse, a std::string exception escaping a raw NAPI
        // callback (std::terminate).
        size_t key_length = 0;
        if (napi_get_value_string_utf8(env, key_value, nullptr, 0, &key_length) != napi_ok) {
            napi_throw_error(env, nullptr, "Header names must be strings");
            return nullptr;
        }
        std::string key(key_length, '\0');
        if (key_length > 0 &&
            napi_get_value_string_utf8(env, key_value, &key[0], key_length + 1, nullptr) != napi_ok) {
            napi_throw_error(env, nullptr, "Failed to read header name");
            return nullptr;
        }

        // Get the value: must be a string (a number would previously leave the
        // length uninitialized and allocate from garbage).
        napi_value value_value;
        if (napi_get_property(env, headersObj, key_value, &value_value) != napi_ok) {
            napi_throw_error(env, nullptr, "Failed to read header value");
            return nullptr;
        }

        size_t value_length = 0;
        if (napi_get_value_string_utf8(env, value_value, nullptr, 0, &value_length) != napi_ok) {
            napi_throw_error(env, nullptr, "Header values must be strings");
            return nullptr;
        }
        std::string value(value_length, '\0');
        if (value_length > 0 &&
            napi_get_value_string_utf8(env, value_value, &value[0], value_length + 1, nullptr) != napi_ok) {
            napi_throw_error(env, nullptr, "Failed to read header value");
            return nullptr;
        }

        headers[std::move(key)] = std::move(value);
    }

    // Apply the custom headers
    HTTPRequestConfig::getInstance().setCustomHeaders(headers);

    Logger::info("NetworkNAPI", "Set %zu custom HTTP headers", headers.size());

    return args.Undefined();
}

napi_value NetworkNAPI::AddCustomHttpHeader(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }

    std::string key = args.GetString(0, "key");
    std::string value = args.GetString(1, "value");
    if (args.HasError()) {
        return nullptr;
    }

    // Add a custom header
    HTTPRequestConfig::getInstance().addCustomHeader(key, value);

    Logger::info("NetworkNAPI", "Added custom HTTP header: %s", key.c_str());

    return args.Undefined();
}

napi_value NetworkNAPI::RemoveCustomHttpHeader(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    std::string key = args.GetString(0, "key");
    if (args.HasError()) {
        return nullptr;
    }

    // Remove a custom header
    bool removed = HTTPRequestConfig::getInstance().removeCustomHeader(key);

    Logger::info("NetworkNAPI", "Removed custom HTTP header: %s (success: %d)", key.c_str(), removed);

    // Return a boolean
    napi_value result;
    napi_get_boolean(env, removed, &result);
    return result;
}

napi_value NetworkNAPI::ClearCustomHttpHeaders(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    // Clear all custom headers
    HTTPRequestConfig::getInstance().clearCustomHeaders();

    Logger::info("NetworkNAPI", "Cleared all custom HTTP headers");

    return args.Undefined();
}

napi_value NetworkNAPI::GetCustomHttpHeaders(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    // Fetch all custom headers
    auto headers = HTTPRequestConfig::getInstance().getCustomHeaders();

    // Create the return object
    napi_value result;
    napi_create_object(env, &result);

    // Convert the C++ map into a NAPI object
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

