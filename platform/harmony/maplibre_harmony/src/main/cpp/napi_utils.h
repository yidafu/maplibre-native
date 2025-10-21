//
// Created on 2025/10/16.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MAPLIBREHARMONY_NAPI_UTILS_H
#define MAPLIBREHARMONY_NAPI_UTILS_H
#include "stdint.h"
#include <js_native_api_types.h>

namespace mbgl {
namespace harmony {
namespace napi {
    int64_t ParseSurfaceId(napi_env env, napi_callback_info info) ;

}
}
}
#endif //MAPLIBREHARMONY_NAPI_UTILS_H
