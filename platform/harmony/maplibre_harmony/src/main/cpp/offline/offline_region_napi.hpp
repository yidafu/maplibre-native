#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/database_file_source.hpp>
#include <mbgl/storage/offline.hpp>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * OfflineRegionNAPI - Harmony offline map region wrapper.
 *
 * Represents an offline map region and exposes download control, status queries, and more.
 */
class OfflineRegionNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    
    // Create a NAPI object from a C++ OfflineRegion
    static napi_value New(napi_env env, 
                         std::shared_ptr<mbgl::DatabaseFileSource> fileSource,
                         mbgl::OfflineRegion&& region);
    
    // NAPI constructor
    static napi_value Constructor(napi_env env, napi_callback_info info);
    
    // Instance methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetDefinition(napi_env env, napi_callback_info info);
    static napi_value GetMetadata(napi_env env, napi_callback_info info);
    static napi_value SetDownloadState(napi_env env, napi_callback_info info);
    static napi_value SetObserver(napi_env env, napi_callback_info info);
    static napi_value GetStatus(napi_env env, napi_callback_info info);
    static napi_value Delete(napi_env env, napi_callback_info info);
    static napi_value Invalidate(napi_env env, napi_callback_info info);
    static napi_value UpdateMetadata(napi_env env, napi_callback_info info);
    
    // Destructor
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Helper utilities for metadata conversion
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
    napi_ref observerRef_; // Holds a reference to the observer
    
    // Static constructor reference
    static napi_ref constructor_;
};

} // namespace harmony
} // namespace maplibre

