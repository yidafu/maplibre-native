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
    ~ImageSourceNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    
    // 内部方法
    std::string getId() const { return id; }
    mbgl::style::ImageSource* getSource() const { return source.get(); }
    
    // 释放所有权
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        return std::move(source);
    }
    
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::ImageSource> source;
    bool ownsSource;
};

} // namespace harmony
} // namespace maplibre

