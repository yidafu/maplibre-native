#pragma once

#include <napi/native_api.h>
#include <mbgl/map/map.hpp>
#include <mbgl/style/style.hpp>
#include <string>
#include <unordered_map>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * StyleNAPI - NAPI wrapper for Style
 * 
 * 封装 mbgl::style::Style，提供面向对象的样式管理接口
 * 类似于 Android 的 Style 类
 */
class StyleNAPI {
public:
    StyleNAPI(mbgl::Map* map);
    ~StyleNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    
    // 构造函数回调
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 析构函数回调
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetUri(napi_env env, napi_callback_info info);
    static napi_value GetJson(napi_env env, napi_callback_info info);
    static napi_value IsFullyLoaded(napi_env env, napi_callback_info info);
    
    // Source 管理
    static napi_value AddSource(napi_env env, napi_callback_info info);
    static napi_value RemoveSource(napi_env env, napi_callback_info info);
    static napi_value GetSource(napi_env env, napi_callback_info info);
    static napi_value GetSources(napi_env env, napi_callback_info info);
    
    // Layer 管理
    static napi_value AddLayer(napi_env env, napi_callback_info info);
    static napi_value AddLayerBelow(napi_env env, napi_callback_info info);
    static napi_value AddLayerAbove(napi_env env, napi_callback_info info);
    static napi_value AddLayerAt(napi_env env, napi_callback_info info);
    static napi_value RemoveLayer(napi_env env, napi_callback_info info);
    static napi_value RemoveLayerAt(napi_env env, napi_callback_info info);
    static napi_value GetLayer(napi_env env, napi_callback_info info);
    static napi_value GetLayers(napi_env env, napi_callback_info info);
    
    // Image 管理
    static napi_value AddImage(napi_env env, napi_callback_info info);
    static napi_value AddImageAsync(napi_env env, napi_callback_info info);
    static napi_value AddImagesAsync(napi_env env, napi_callback_info info);
    static napi_value RemoveImage(napi_env env, napi_callback_info info);
    static napi_value GetImage(napi_env env, napi_callback_info info);
    
    // Light & Transition
    static napi_value GetLight(napi_env env, napi_callback_info info);
    static napi_value SetLight(napi_env env, napi_callback_info info);
    static napi_value GetTransition(napi_env env, napi_callback_info info);
    static napi_value SetTransition(napi_env env, napi_callback_info info);
    
    // 内部方法
    void setFullyLoaded(bool loaded) { fullyLoaded = loaded; }
    bool isFullyLoaded() const { return fullyLoaded; }
    mbgl::Map* getMap() const { return map; }
    
    // 构造函数引用（用于创建实例）
    static napi_ref constructor;
    
private:
    mbgl::Map* map;  // 持有 Map 指针（不负责释放）
    bool fullyLoaded;
    
    // 缓存（与 Android 一致）
    // 注意：这里只缓存 ID，实际对象由 mbgl::style::Style 管理
    std::unordered_map<std::string, bool> sources;  // sourceId -> exists
    std::unordered_map<std::string, bool> layers;   // layerId -> exists

public:
    std::unordered_map<std::string, bool> images;   // imageName -> exists
};

} // namespace harmony
} // namespace maplibre

