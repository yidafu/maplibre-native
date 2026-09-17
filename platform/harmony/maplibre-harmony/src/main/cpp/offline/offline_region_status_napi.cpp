#include "offline_region_status_napi.hpp"

namespace mbgl {
namespace harmony {

napi_value OfflineRegionStatusNAPI::ToNapiObject(napi_env env, const mbgl::OfflineRegionStatus& status) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // downloadState
    napi_value downloadStateValue;
    int32_t downloadState = (status.downloadState == mbgl::OfflineRegionDownloadState::Active) ? 1 : 0;
    napi_create_int32(env, downloadState, &downloadStateValue);
    napi_set_named_property(env, obj, "downloadState", downloadStateValue);
    
    // completedResourceCount
    napi_value completedResourceCountValue;
    napi_create_int64(env, static_cast<int64_t>(status.completedResourceCount), &completedResourceCountValue);
    napi_set_named_property(env, obj, "completedResourceCount", completedResourceCountValue);
    
    // completedResourceSize
    napi_value completedResourceSizeValue;
    napi_create_int64(env, static_cast<int64_t>(status.completedResourceSize), &completedResourceSizeValue);
    napi_set_named_property(env, obj, "completedResourceSize", completedResourceSizeValue);
    
    // completedTileCount
    napi_value completedTileCountValue;
    napi_create_int64(env, static_cast<int64_t>(status.completedTileCount), &completedTileCountValue);
    napi_set_named_property(env, obj, "completedTileCount", completedTileCountValue);
    
    // completedTileSize
    napi_value completedTileSizeValue;
    napi_create_int64(env, static_cast<int64_t>(status.completedTileSize), &completedTileSizeValue);
    napi_set_named_property(env, obj, "completedTileSize", completedTileSizeValue);
    
    // requiredResourceCount
    napi_value requiredResourceCountValue;
    napi_create_int64(env, static_cast<int64_t>(status.requiredResourceCount), &requiredResourceCountValue);
    napi_set_named_property(env, obj, "requiredResourceCount", requiredResourceCountValue);
    
    // requiredTileCount
    napi_value requiredTileCountValue;
    napi_create_int64(env, static_cast<int64_t>(status.requiredTileCount), &requiredTileCountValue);
    napi_set_named_property(env, obj, "requiredTileCount", requiredTileCountValue);
    
    // requiredResourceCountIsPrecise
    napi_value requiredResourceCountIsPreciseValue;
    napi_get_boolean(env, status.requiredResourceCountIsPrecise, &requiredResourceCountIsPreciseValue);
    napi_set_named_property(env, obj, "requiredResourceCountIsPrecise", requiredResourceCountIsPreciseValue);
    
    // complete
    napi_value completeValue;
    napi_get_boolean(env, status.complete(), &completeValue);
    napi_set_named_property(env, obj, "complete", completeValue);
    
    return obj;
}

} // namespace harmony
} // namespace mbgl

