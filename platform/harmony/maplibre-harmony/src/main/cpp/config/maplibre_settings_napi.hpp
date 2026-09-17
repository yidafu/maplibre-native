#ifndef MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_NAPI_HPP
#define MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_NAPI_HPP

#include <napi/native_api.h>

namespace mbgl {
namespace harmony {

/**
 * MapLibreSettingsNAPI - NAPI binding class
 *
 * Exposes MapLibreSettings functionality to the ArkTS layer.
 */
class MapLibreSettingsNAPI {
public:
    /**
     * Initialize and register NAPI methods.
     * @param env NAPI environment
     * @param exports Exports object
     */
    static void Init(napi_env env, napi_value exports);

private:
    // Set the access token
    static napi_value SetAccessToken(napi_env env, napi_callback_info info);
    
    // Get the access token
    static napi_value GetAccessToken(napi_env env, napi_callback_info info);
    
    // Apply Mapbox configuration
    static napi_value UseMapboxConfiguration(napi_env env, napi_callback_info info);
    
    // Apply MapTiler configuration
    static napi_value UseMapTilerConfiguration(napi_env env, napi_callback_info info);
    
    // Apply MapLibre configuration
    static napi_value UseMapLibreConfiguration(napi_env env, napi_callback_info info);
    
    // Set the base URL
    static napi_value SetApiBaseURL(napi_env env, napi_callback_info info);
    
    // Get the base URL
    static napi_value GetApiBaseURL(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_NAPI_HPP

