#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/vector_source.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * VectorSource NAPI绑定类
 */
class VectorSourceHarmony {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value CreateWithUrl(napi_env env, napi_callback_info info);
    static napi_value CreateWithTileSet(napi_env env, napi_callback_info info);
    static napi_value QuerySourceFeatures(napi_env env, napi_callback_info info);
};

} // namespace harmony
} // namespace mbgl

