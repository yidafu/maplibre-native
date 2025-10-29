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
    
    // 预加载的资源
    struct ImageData {
        std::string id;
        std::vector<uint8_t> data;
        uint32_t width;
        uint32_t height;
        float pixelRatio;
    };
    
    struct TransitionOptions {
        uint64_t duration = 300;  // milliseconds
        uint64_t delay = 0;
        bool enablePlacementTransitions = true;
    };
    
    // 预加载的资源（存储 JSON 字符串或对象序列化）
    std::vector<std::string> preloadedSourcesJson;
    std::vector<std::string> preloadedLayersJson;
    std::vector<ImageData> preloadedImages;
    TransitionOptions transitionOptions;
};

} // namespace harmony
} // namespace maplibre

