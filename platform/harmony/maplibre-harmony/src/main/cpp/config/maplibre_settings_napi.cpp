#include "maplibre_settings_napi.hpp"
#include "maplibre_settings.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"

#include <string>

namespace mbgl {
namespace harmony {

using mbgl::harmony::napi::NapiArgs;

void MapLibreSettingsNAPI::Init(napi_env env, napi_value exports) {
    // Define the methods to export
    napi_property_descriptor descriptors[] = {
        {"setAccessToken", nullptr, SetAccessToken, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getAccessToken", nullptr, GetAccessToken, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"useMapboxConfiguration", nullptr, UseMapboxConfiguration, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"useMapTilerConfiguration", nullptr, UseMapTilerConfiguration, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"useMapLibreConfiguration", nullptr, UseMapLibreConfiguration, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setApiBaseURL", nullptr, SetApiBaseURL, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getApiBaseURL", nullptr, GetApiBaseURL, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    // Register the methods on the exports object
    napi_status status = napi_define_properties(env, exports, 
        sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to register MapLibreSettings NAPI functions");
    }
}

napi_value MapLibreSettingsNAPI::SetAccessToken(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    std::string token = args.GetString(0, "token");
    if (args.HasError()) {
        return nullptr;
    }
    
    // Set the API key
    MapLibreSettings::getInstance().setApiKey(token);
    
    return args.Undefined();
}

napi_value MapLibreSettingsNAPI::GetAccessToken(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    // Get the API key
    std::string token = MapLibreSettings::getInstance().getApiKey();
    
    // Convert to a NAPI string
    napi_value result;
    napi_create_string_utf8(env, token.c_str(), token.length(), &result);
    
    return result;
}

napi_value MapLibreSettingsNAPI::UseMapboxConfiguration(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    MapLibreSettings::getInstance().useMapboxConfiguration();
    return args.Undefined();
}

napi_value MapLibreSettingsNAPI::UseMapTilerConfiguration(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    MapLibreSettings::getInstance().useMapTilerConfiguration();
    return args.Undefined();
}

napi_value MapLibreSettingsNAPI::UseMapLibreConfiguration(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    MapLibreSettings::getInstance().useMapLibreConfiguration();
    return args.Undefined();
}

napi_value MapLibreSettingsNAPI::SetApiBaseURL(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    std::string url = args.GetString(0, "url");
    if (args.HasError()) {
        return nullptr;
    }
    
    // Set the base URL
    MapLibreSettings::getInstance().setBaseURL(url);
    
    return args.Undefined();
}

napi_value MapLibreSettingsNAPI::GetApiBaseURL(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    if (args.HasError()) {
        return nullptr;
    }

    // Get the base URL
    std::string url = MapLibreSettings::getInstance().getBaseURL();
    
    // Convert to a NAPI string
    napi_value result;
    napi_create_string_utf8(env, url.c_str(), url.length(), &result);
    
    return result;
}

} // namespace harmony
} // namespace mbgl

