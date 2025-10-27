#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/database_file_source.hpp>
#include <mbgl/storage/offline.hpp>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * OfflineRegionNAPI - 鸿蒙离线地图区域
 * 
 * 表示一个离线地图区域，提供下载控制、状态查询等功能
 */
class OfflineRegionNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    
    // 从 C++ OfflineRegion 创建 NAPI 对象
    static napi_value New(napi_env env, 
                         std::shared_ptr<mbgl::DatabaseFileSource> fileSource,
                         mbgl::OfflineRegion&& region);
    
    // NAPI 构造函数
    static napi_value Constructor(napi_env env, napi_callback_info info);
    
    // 实例方法
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetDefinition(napi_env env, napi_callback_info info);
    static napi_value GetMetadata(napi_env env, napi_callback_info info);
    static napi_value SetDownloadState(napi_env env, napi_callback_info info);
    static napi_value SetObserver(napi_env env, napi_callback_info info);
    static napi_value GetStatus(napi_env env, napi_callback_info info);
    static napi_value Delete(napi_env env, napi_callback_info info);
    static napi_value Invalidate(napi_env env, napi_callback_info info);
    static napi_value UpdateMetadata(napi_env env, napi_callback_info info);
    
    // 析构函数
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 辅助函数：转换元数据
    static napi_value MetadataToArrayBuffer(napi_env env, const mbgl::OfflineRegionMetadata& metadata);
    static mbgl::OfflineRegionMetadata ArrayBufferToMetadata(napi_env env, napi_value arrayBuffer);
    
private:
    explicit OfflineRegionNAPI(std::shared_ptr<mbgl::DatabaseFileSource> fileSource,
                              std::unique_ptr<mbgl::OfflineRegion> region);
    ~OfflineRegionNAPI();
    
    std::shared_ptr<mbgl::DatabaseFileSource> fileSource_;
    std::unique_ptr<mbgl::OfflineRegion> region_;
    napi_env env_;
    napi_ref wrapper_;
    napi_ref observerRef_; // 保存观察者的引用
};

} // namespace harmony
} // namespace maplibre

