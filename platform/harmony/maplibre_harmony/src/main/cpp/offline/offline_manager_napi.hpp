#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/database_file_source.hpp>
#include <mbgl/storage/offline.hpp>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * OfflineManagerNAPI - Harmony offline map manager.
 *
 * Provides creation, listing, deletion, and other management utilities for offline regions.
 */
class OfflineManagerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    
    // NAPI constructor
    static napi_value Constructor(napi_env env, napi_callback_info info);
    
    // Instance methods
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
    
    // Destructor
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

