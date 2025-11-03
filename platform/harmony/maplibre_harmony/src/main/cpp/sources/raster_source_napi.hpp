#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/raster_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * RasterSourceNAPI - NAPI wrapper for Raster Source
 * 
 * 封装 mbgl::style::RasterSource，提供面向对象的栅格瓦片数据源接口
 */
class RasterSourceNAPI {
public:
    RasterSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterSource> source);
    // 从现有 Source 创建（使用 WeakPtr，不拥有所有权）
    RasterSourceNAPI(mbgl::style::RasterSource* sourcePtr);
    
    ~RasterSourceNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
static napi_value New(napi_env env, napi_callback_info info);
    // 从现有 native 对象创建 NAPI 实例
    static napi_value CreateInstance(napi_env env, mbgl::style::RasterSource* sourcePtr);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetTileSize(napi_env env, napi_callback_info info);
    
    // 内部方法
    std::string getId() const { return id; }
    mbgl::style::RasterSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::RasterSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // 释放所有权
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // 在 addSource 后调用，创建 WeakPtr
    void attachToStyle(mbgl::style::RasterSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::RasterSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace maplibre

