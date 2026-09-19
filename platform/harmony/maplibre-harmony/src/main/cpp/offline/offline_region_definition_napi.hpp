#pragma once

#include <napi/native_api.h>
#include <mln/storage/offline.hpp>

namespace mln {
namespace harmony {

/**
 * NAPI helpers for offline region definitions.
 */
class OfflineRegionDefinitionNAPI {
public:
    // Convert a NAPI object into the C++ definition
    static mln::OfflineRegionDefinition FromNapiObject(napi_env env, napi_value obj);
    
    // Convert the C++ definition into a NAPI object
    static napi_value ToNapiObject(napi_env env, const mln::OfflineRegionDefinition& definition);
    
private:
    // TilePyramid definition conversions
    static mln::OfflineTilePyramidRegionDefinition TilePyramidFromNapi(napi_env env, napi_value obj);
    static napi_value TilePyramidToNapi(napi_env env, const mln::OfflineTilePyramidRegionDefinition& def);
    
    // Geometry definition conversions
    static mln::OfflineGeometryRegionDefinition GeometryFromNapi(napi_env env, napi_value obj);
    static napi_value GeometryToNapi(napi_env env, const mln::OfflineGeometryRegionDefinition& def);
};

} // namespace harmony
} // namespace mln

