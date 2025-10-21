//
// Created on 2025/9/28.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".


#include <ace/xcomponent/native_interface_xcomponent.h>
#include <cstdint>
#include <napi/native_api.h>
#include <string>
#include <native_window/external_window.h>
#include "logger.h"
#include "Render.h"
#include "PluginManager.h"

using mbgl::harmony::Logger;

namespace {
    int64_t ParseId(napi_env env, napi_callback_info info)
    {
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

std::unordered_map<int64_t, Render*> PluginManager::pluginRenderMap_;
std::unordered_map<int64_t, OHNativeWindow*> PluginManager::windowMap_;

PluginManager::~PluginManager()
{
    Logger::info("PluginManager", "~PluginManager");
    for (auto iter = pluginRenderMap_.begin(); iter != pluginRenderMap_.end(); ++iter) {
        if (iter->second != nullptr) {
            delete iter->second;
            iter->second = nullptr;
        }
    }
    pluginRenderMap_.clear();
    for (auto iter = windowMap_.begin(); iter != windowMap_.end(); ++iter) {
        if (iter->second != nullptr) {
            delete iter->second;
            iter->second = nullptr;
        }
    }
    windowMap_.clear();
}

Render* PluginManager::GetRender(int64_t& id)
{
    if (pluginRenderMap_.find(id) != pluginRenderMap_.end()) {
        return pluginRenderMap_[id];
    }
    return nullptr;
}

napi_value PluginManager::SetSurfaceId(napi_env env, napi_callback_info info)
{
    int64_t surfaceId = ParseId(env, info);
    OHNativeWindow *nativeWindow;
    Render *pluginRender;
    if (windowMap_.find(surfaceId) == windowMap_.end()) {
        OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &nativeWindow);
        windowMap_[surfaceId] = nativeWindow;
    } else {
        return nullptr;
    }
    if (pluginRenderMap_.find(surfaceId) == pluginRenderMap_.end()) {
        pluginRender = new Render(surfaceId);
        pluginRenderMap_[surfaceId] = pluginRender;
    }
    pluginRender->InitNativeWindow(nativeWindow);
    return nullptr;
}

napi_value PluginManager::DestroySurface(napi_env env, napi_callback_info info)
{
    int64_t surfaceId = ParseId(env, info);
    auto pluginRenderMapIter = pluginRenderMap_.find(surfaceId);
    if (pluginRenderMapIter != pluginRenderMap_.end()) {
        delete pluginRenderMapIter->second;
        pluginRenderMap_.erase(pluginRenderMapIter);
    }
    auto windowMapIter = windowMap_.find(surfaceId);
    if (windowMapIter != windowMap_.end()) {
        OH_NativeWindow_DestroyNativeWindow(windowMapIter->second);
        windowMap_.erase(windowMapIter);
    }
    return nullptr;
}

napi_value PluginManager::ChangeSurface(napi_env env, napi_callback_info info)
{
    if ((env == nullptr) || (info == nullptr)) {
        Logger::error("PluginManager", "ChangeSurface: OnLoad env or info is null");
        return nullptr;
    }
    int64_t surfaceId = 0;
    size_t argc = 3;
    napi_value args[3] = {nullptr};

    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        Logger::error("PluginManager", "ChangeSurface: GetContext napi_get_cb_info failed");
    }
    bool lossless = true;
    int index = 0;
    if (napi_ok != napi_get_value_bigint_int64(env, args[index++], &surfaceId, &lossless)) {
        Logger::error("PluginManager", "ChangeSurface: Get value failed");
    }
    double width;
    if (napi_ok != napi_get_value_double(env, args[index++], &width)) {
        Logger::error("PluginManager", "ChangeSurface: Get width failed");
    }
    double height;
    if (napi_ok != napi_get_value_double(env, args[index++], &height)) {
        Logger::error("PluginManager", "ChangeSurface: Get height failed");
    }
    auto pluginRender = GetRender(surfaceId);
    if (pluginRender == nullptr) {
        Logger::error("PluginManager", "ChangeSurface: Get pluginRender failed");
        return nullptr;
    }
    pluginRender->UpdateNativeWindowSize(width, height);
    return nullptr;
}

napi_value PluginManager::ChangeColor(napi_env env, napi_callback_info info)
{
    int64_t surfaceId = ParseId(env, info);
    auto pluginRender = GetRender(surfaceId);
    if (pluginRender == nullptr) {
        Logger::error("PluginManager", "ChangeColor: Get pluginRender failed");
        return nullptr;
    }
    pluginRender->ChangeColor();
    return nullptr;
}

napi_value PluginManager::DrawPattern(napi_env env, napi_callback_info info)
{
    int64_t surfaceId = ParseId(env, info);
    auto pluginRender = GetRender(surfaceId);
    if (pluginRender == nullptr) {
        Logger::error("PluginManager", "DrawPattern: Get pluginRender failed");
        return nullptr;
    }
    pluginRender->DrawPattern();
    return nullptr;
}

napi_value PluginManager::GetXComponentStatus(napi_env env, napi_callback_info info)
{
    int64_t surfaceId = ParseId(env, info);
    auto pluginRender = GetRender(surfaceId);
    if (pluginRender == nullptr) {
        Logger::error("PluginManager", "GetXComponentStatus: Get pluginRender failed");
        return nullptr;
    }
    napi_value hasDraw;
    napi_value hasChangeColor;
    napi_status ret = napi_create_int32(env, pluginRender->HasDraw(), &(hasDraw));
    if (ret != napi_ok) {
        Logger::error("PluginManager", "GetXComponentStatus: napi_create_int32 hasDraw_ error");
        return nullptr;
    }
    ret = napi_create_int32(env, pluginRender->HasChangedColor(), &(hasChangeColor));
    if (ret != napi_ok) {
        Logger::error("PluginManager", "GetXComponentStatus: napi_create_int32 hasChangeColor_ error");
        return nullptr;
    }
    napi_value obj;
    ret = napi_create_object(env, &obj);
    if (ret != napi_ok) {
        Logger::error("PluginManager", "GetXComponentStatus: napi_create_object error");
        return nullptr;
    }
    ret = napi_set_named_property(env, obj, "hasDraw", hasDraw);
    if (ret != napi_ok) {
        Logger::error("PluginManager", "GetXComponentStatus: napi_set_named_property hasDraw error");
        return nullptr;
    }
    ret = napi_set_named_property(env, obj, "hasChangeColor", hasChangeColor);
    if (ret != napi_ok) {
        Logger::error("PluginManager", "GetXComponentStatus: napi_set_named_property hasChangeColor error");
        return nullptr;
    }
    return obj;
}
