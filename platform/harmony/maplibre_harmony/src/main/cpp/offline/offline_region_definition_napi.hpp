#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/offline.hpp>

namespace maplibre {
namespace harmony {

/**
 * NAPI helpers for offline region definitions.
 */
class OfflineRegionDefinitionNAPI {
public:
    // Convert a NAPI object into the C++ definition
    static mbgl::OfflineRegionDefinition FromNapiObject(napi_env env, napi_value obj);
    
    // Convert the C++ definition into a NAPI object
    static napi_value ToNapiObject(napi_env env, const mbgl::OfflineRegionDefinition& definition);
    
private:
    // TilePyramid definition conversions
    static mbgl::OfflineTilePyramidRegionDefinition TilePyramidFromNapi(napi_env env, napi_value obj);
    static napi_value TilePyramidToNapi(napi_env env, const mbgl::OfflineTilePyramidRegionDefinition& def);
    
    // Geometry definition conversions
    static mbgl::OfflineGeometryRegionDefinition GeometryFromNapi(napi_env env, napi_value obj);
    static napi_value GeometryToNapi(napi_env env, const mbgl::OfflineGeometryRegionDefinition& def);
};

} // namespace harmony
} // namespace maplibre

