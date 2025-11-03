#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/image_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * ImageSourceNAPI - NAPI wrapper for Image Source
 * 
 * 封装 mbgl::style::ImageSource，提供面向对象的图像数据源接口
 */
class ImageSourceNAPI {
public:
    ImageSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::ImageSource> source);
    // 从现有 Source 创建（使用 WeakPtr，不拥有所有权）
    ImageSourceNAPI(mbgl::style::ImageSource* sourcePtr);
    
    ~ImageSourceNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
static napi_value New(napi_env env, napi_callback_info info);
    // 从现有 native 对象创建 NAPI 实例
    static napi_value CreateInstance(napi_env env, mbgl::style::ImageSource* sourcePtr);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetImage(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    
    // 内部方法
    std::string getId() const { return id; }
    mbgl::style::ImageSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::ImageSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // 释放所有权
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // 在 addSource 后调用，创建 WeakPtr
    void attachToStyle(mbgl::style::ImageSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::ImageSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace maplibre

