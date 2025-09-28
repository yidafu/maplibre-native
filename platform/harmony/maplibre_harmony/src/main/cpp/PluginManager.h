//
// Created on 2025/9/28.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MAPLIBREHARMONY_PLUGINMANAGER_H
#define MAPLIBREHARMONY_PLUGINMANAGER_H

#include "Render.h"
#include <js_native_api_types.h>
#include <unordered_map>
class PluginManager {

public:
    ~PluginManager();
    static Render* GetRender(int64_t& id);
    static napi_value ChangeColor(napi_env env, napi_callback_info info);
    static napi_value DrawPattern(napi_env env, napi_callback_info info);
    static napi_value SetSurfaceId(napi_env env, napi_callback_info info);
    static napi_value ChangeSurface(napi_env env, napi_callback_info info);
    static napi_value DestroySurface(napi_env env, napi_callback_info info);
    static napi_value GetXComponentStatus(napi_env env, napi_callback_info info);
public:
    static std::unordered_map<int64_t, Render*> pluginRenderMap_;
    static std::unordered_map<int64_t, OHNativeWindow*> windowMap_;
};

#endif //MAPLIBREHARMONY_PLUGINMANAGER_H
