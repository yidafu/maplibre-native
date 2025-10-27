#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/offline.hpp>

namespace maplibre {
namespace harmony {

/**
 * 离线区域定义相关的 NAPI 辅助函数
 */
class OfflineRegionDefinitionNAPI {
public:
    // 从 NAPI 对象转换为 C++ 定义
    static mbgl::OfflineRegionDefinition FromNapiObject(napi_env env, napi_value obj);
    
    // 从 C++ 定义转换为 NAPI 对象
    static napi_value ToNapiObject(napi_env env, const mbgl::OfflineRegionDefinition& definition);
    
private:
    // 转换 TilePyramid 定义
    static mbgl::OfflineTilePyramidRegionDefinition TilePyramidFromNapi(napi_env env, napi_value obj);
    static napi_value TilePyramidToNapi(napi_env env, const mbgl::OfflineTilePyramidRegionDefinition& def);
    
    // 转换 Geometry 定义
    static mbgl::OfflineGeometryRegionDefinition GeometryFromNapi(napi_env env, napi_value obj);
    static napi_value GeometryToNapi(napi_env env, const mbgl::OfflineGeometryRegionDefinition& def);
};

} // namespace harmony
} // namespace maplibre

