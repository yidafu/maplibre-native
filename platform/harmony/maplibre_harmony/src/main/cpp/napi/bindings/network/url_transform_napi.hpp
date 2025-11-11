#pragma once

#include "napi/native_api.h"
#include <mbgl/storage/resource.hpp>

namespace mbgl {
namespace harmony {

/**
 * URLTransformNAPI - NAPI bindings for URL transformation.
 *
 * Exposes URL transformation configuration to the ArkTS layer and manages cross-thread callbacks.
 */
class URLTransformNAPI {
public:
    /**
     * Initialize the URL transformation NAPI module.
     */
    static napi_value Init(napi_env env, napi_value exports);

private:
    /**
     * Set the URL transformation callback.
     *
     * ArkTS call: setResourceTransformCallback(callback: (kind: number, url: string) => string): void
     */
    static napi_value SetResourceTransformCallback(napi_env env, napi_callback_info info);

    /**
     * Clear the URL transformation callback.
     *
     * ArkTS call: clearResourceTransformCallback(): void
     */
    static napi_value ClearResourceTransformCallback(napi_env env, napi_callback_info info);

    /**
     * Check whether a transformation callback is set.
     *
     * ArkTS call: hasResourceTransformCallback(): boolean
     */
    static napi_value HasResourceTransformCallback(napi_env env, napi_callback_info info);

    // Static context used to store the cross-thread callback
    struct CallbackContext {
        napi_env env;
        napi_ref callbackRef;
        napi_threadsafe_function tsfn;
    };

    static CallbackContext* callbackContext_;
};

} // namespace harmony
} // namespace mbgl

