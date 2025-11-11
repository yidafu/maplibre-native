#pragma once

#include "napi/native_api.h"

namespace mbgl {
namespace harmony {

/**
 * NetworkNAPI - NAPI bindings for network configuration.
 *
 * Exposes HTTP header configuration APIs to the ArkTS layer.
 */
class NetworkNAPI {
public:
    /**
     * Initialize the network configuration NAPI module and export static methods to ArkTS.
     */
    static napi_value Init(napi_env env, napi_value exports);

private:
    /**
     * Set custom HTTP headers (replaces existing headers).
     *
     * ArkTS call: setCustomHttpHeaders(headers: Record<string, string>): void
     */
    static napi_value SetCustomHttpHeaders(napi_env env, napi_callback_info info);

    /**
     * Add a single custom HTTP header.
     *
     * ArkTS call: addCustomHttpHeader(key: string, value: string): void
     */
    static napi_value AddCustomHttpHeader(napi_env env, napi_callback_info info);

    /**
     * Remove a specific custom HTTP header.
     *
     * ArkTS call: removeCustomHttpHeader(key: string): boolean
     */
    static napi_value RemoveCustomHttpHeader(napi_env env, napi_callback_info info);

    /**
     * Clear all custom HTTP headers.
     *
     * ArkTS call: clearCustomHttpHeaders(): void
     */
    static napi_value ClearCustomHttpHeaders(napi_env env, napi_callback_info info);

    /**
     * Retrieve all custom HTTP headers.
     *
     * ArkTS call: getCustomHttpHeaders(): Record<string, string>
     */
    static napi_value GetCustomHttpHeaders(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

