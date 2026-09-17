//
// Created on 2025/10/16.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MAPLIBREHARMONY_NAPI_UTILS_H
#define MAPLIBREHARMONY_NAPI_UTILS_H
#include "stdint.h"
#include <napi/native_api.h>
#include <string>

// NAPI函数声明宏
#define DECLARE_NAPI_STATIC_FUNCTION(name, func) \
    { name, nullptr, func, nullptr, nullptr, nullptr, napi_default, nullptr }

namespace mbgl {
namespace harmony {
namespace napi {
    // Parses the surface id argument of an init/create callback.
    int64_t ParseSurfaceId(napi_env env, napi_callback_info info);

    // NAPI value-level converters. These complement NapiArgs (argument-stream
// parsing) for values obtained outside the argument list - named properties,
// array elements, callback payloads. They are not legacy code scheduled for
// removal.
    
    /**
     * 从NAPI值获取字符串
     */
    std::string GetStringFromValue(napi_env env, napi_value value);
    
    /**
     * 从NAPI值获取int64
     */
    int64_t GetInt64FromValue(napi_env env, napi_value value);
    
    /**
     * 从NAPI值获取double
     */
    double GetDoubleFromValue(napi_env env, napi_value value);
    
    /**
     * 从NAPI值获取bool
     */
    bool GetBoolFromValue(napi_env env, napi_value value);
    
    /**
     * 创建字符串NAPI值
     */
    napi_value CreateStringValue(napi_env env, const std::string& str);
    
    /**
     * 创建int64 NAPI值
     */
    napi_value CreateInt64Value(napi_env env, int64_t value);
    
    /**
     * 创建double NAPI值
     */
    napi_value CreateDoubleValue(napi_env env, double value);
    
    /**
     * 创建bool NAPI值
     */
    napi_value CreateBoolValue(napi_env env, bool value);
}
}
}
#endif //MAPLIBREHARMONY_NAPI_UTILS_H
