#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/vector_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * VectorSourceNAPI - NAPI wrapper for Vector Source
 * 
 * 封装 mbgl::style::VectorSource，提供面向对象的矢量瓦片数据源接口
 */
class VectorSourceNAPI {
public:
    VectorSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::VectorSource> source);
    ~VectorSourceNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetTiles(napi_env env, napi_callback_info info);
    
    // 内部方法
    std::string getId() const { return id; }
    mbgl::style::VectorSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::VectorSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // 释放所有权
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // 在 addSource 后调用，创建 WeakPtr
    void attachToStyle(mbgl::style::VectorSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::VectorSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace maplibre

