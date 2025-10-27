#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/database_file_source.hpp>
#include <mbgl/storage/offline.hpp>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * OfflineManagerNAPI - 鸿蒙离线地图管理器
 * 
 * 提供离线地图区域的创建、列表、删除等管理功能
 */
class OfflineManagerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    
    // NAPI 构造函数
    static napi_value Constructor(napi_env env, napi_callback_info info);
    
    // 实例方法
    static napi_value ListOfflineRegions(napi_env env, napi_callback_info info);
    static napi_value CreateOfflineRegion(napi_env env, napi_callback_info info);
    static napi_value GetOfflineRegion(napi_env env, napi_callback_info info);
    static napi_value MergeOfflineRegions(napi_env env, napi_callback_info info);
    static napi_value ResetDatabase(napi_env env, napi_callback_info info);
    static napi_value PackDatabase(napi_env env, napi_callback_info info);
    static napi_value InvalidateAmbientCache(napi_env env, napi_callback_info info);
    static napi_value ClearAmbientCache(napi_env env, napi_callback_info info);
    static napi_value SetMaximumAmbientCacheSize(napi_env env, napi_callback_info info);
    static napi_value SetOfflineMapboxTileCountLimit(napi_env env, napi_callback_info info);
    static napi_value RunPackDatabaseAutomatically(napi_env env, napi_callback_info info);
    
    // 析构函数
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
private:
    explicit OfflineManagerNAPI(std::shared_ptr<mbgl::DatabaseFileSource> fileSource);
    ~OfflineManagerNAPI();
    
    std::shared_ptr<mbgl::DatabaseFileSource> fileSource_;
    napi_env env_;
    napi_ref wrapper_;
};

} // namespace harmony
} // namespace maplibre

