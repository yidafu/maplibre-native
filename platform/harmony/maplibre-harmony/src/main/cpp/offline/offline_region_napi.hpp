#pragma once

#include <napi/native_api.h>
#include <mln/storage/database_file_source.hpp>
#include <mln/storage/offline.hpp>
#include <memory>

namespace mln {
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
                         std::shared_ptr<mln::DatabaseFileSource> fileSource,
                         mln::OfflineRegion&& region);
    
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
    static napi_value MetadataToArrayBuffer(napi_env env, const mln::OfflineRegionMetadata& metadata);
    static mln::OfflineRegionMetadata ArrayBufferToMetadata(napi_env env, napi_value arrayBuffer);
    
private:
    explicit OfflineRegionNAPI(std::shared_ptr<mln::DatabaseFileSource> fileSource,
                              std::unique_ptr<mln::OfflineRegion> region);
    ~OfflineRegionNAPI();

    // Shared body of delete()/invalidate(); `invalidate` selects the
    // invalidateOfflineRegion call and its thread-safe callback resource name.
    static napi_value DeleteOrInvalidate(napi_env env, napi_callback_info info, bool invalidate);

    // Resolve `this` into the wrapped instance and validate it, throwing
    // "Invalid OfflineRegion instance" (and returning nullptr) on failure.
    // `requireFileSource` adds the fileSource_ check used by DB-touching calls.
    static OfflineRegionNAPI* UnwrapThis(napi_env env, napi_callback_info info,
                                         bool requireFileSource);
    
    std::shared_ptr<mln::DatabaseFileSource> fileSource_;
    std::unique_ptr<mln::OfflineRegion> region_;
    napi_env env_;
    napi_ref wrapper_;
    napi_ref observerRef_; // Holds a reference to the observer
    
    // Static constructor reference
    static napi_ref constructor_;
    static napi_env constructor_Env;
};

} // namespace harmony
} // namespace mln

