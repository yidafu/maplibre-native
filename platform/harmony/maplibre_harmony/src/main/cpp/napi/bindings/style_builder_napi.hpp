#pragma once

#include <napi/native_api.h>
#include <string>
#include <vector>

namespace maplibre {
namespace harmony {

/**
 * StyleBuilderNAPI - NAPI wrapper for Style Builder
 * 
 * 提供 Builder 模式来构建和配置地图样式
 * 类似于 Android 的 Style.Builder 类
 */
class StyleBuilderNAPI {
public:
    StyleBuilderNAPI();
    ~StyleBuilderNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    
    // 构造函数回调
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 析构函数回调
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Builder 方法（链式调用）
    static napi_value FromUri(napi_env env, napi_callback_info info);
    static napi_value FromJson(napi_env env, napi_callback_info info);
    static napi_value WithSource(napi_env env, napi_callback_info info);
    static napi_value WithLayer(napi_env env, napi_callback_info info);
    static napi_value WithImage(napi_env env, napi_callback_info info);
    static napi_value WithTransitionOptions(napi_env env, napi_callback_info info);
    
    // Getters (内部使用)
    std::string getStyleUri() const { return styleUri; }
    std::string getStyleJson() const { return styleJson; }
    
    // 构造函数引用
    static napi_ref constructor;
    
private:
    std::string styleUri;
    std::string styleJson;
    
    // 预加载的资源（存储为 NAPI 对象引用）
    // TODO: 实现预加载 sources/layers/images
    // std::vector<napi_ref> sources;
    // std::vector<napi_ref> layers;
    // std::vector<napi_ref> images;
};

} // namespace harmony
} // namespace maplibre

