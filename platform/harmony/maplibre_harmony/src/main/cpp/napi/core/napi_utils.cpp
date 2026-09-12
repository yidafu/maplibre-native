//
// Created on 2025/10/16.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".
#include "stdint.h"
#include <js_native_api.h>
#include "napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {
namespace napi {
    // Legacy version kept for compatibility
    int64_t ParseSurfaceId(napi_env env, napi_callback_info info) {
        if ((env == nullptr) || (info == nullptr)) {
            Logger::error("ParseId", "env or info is null");
            return -1;
        }
        size_t argc = 1;
        napi_value args[1] = {nullptr};
        if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
            Logger::error("ParseId", "GetContext napi_get_cb_info failed");
            return -1;
        }
        int64_t value = 0;
        bool lossless = true;
        if (napi_ok != napi_get_value_bigint_int64(env, args[0], &value, &lossless)) {
            Logger::error("ParseId", "Get value failed");
            return -1;
        }
        return value;
    }
}
}
}