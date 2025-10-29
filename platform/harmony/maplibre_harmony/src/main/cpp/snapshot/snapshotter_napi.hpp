/**
 * MapSnapshotter NAPI Bindings Header for HarmonyOS
 */

#pragma once

#include <napi/native_api.h>

namespace mbgl {
namespace harmony {

/**
 * MapSnapshotterNAPI - NAPI 注册类
 */
class MapSnapshotterNAPI {
public:
    /**
     * 初始化并注册 MapSnapshotter NAPI 方法
     */
    static void Init(napi_env env, napi_value exports);
};

} // namespace harmony
} // namespace mbgl

