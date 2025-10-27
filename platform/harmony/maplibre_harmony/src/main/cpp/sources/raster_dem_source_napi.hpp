#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/raster_dem_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * RasterDemSourceNAPI - NAPI wrapper for Raster DEM Source
 * 
 * 封装 mbgl::style::RasterDEMSource，提供面向对象的数字高程模型数据源接口
 */
class RasterDemSourceNAPI {
public:
    RasterDemSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterDEMSource> source);
    ~RasterDemSourceNAPI();
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    
    // 内部方法
    std::string getId() const { return id; }
    mbgl::style::RasterDEMSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::RasterDEMSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // 释放所有权
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // 在 addSource 后调用，创建 WeakPtr
    void attachToStyle(mbgl::style::RasterDEMSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::RasterDEMSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace maplibre

