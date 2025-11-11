/**
 * MapSnapshotter NAPI Bindings Header for HarmonyOS
 */

#pragma once

#include <napi/native_api.h>

namespace mbgl {
namespace harmony {

/**
 * MapSnapshotterNAPI - NAPI registration entry point.
 */
class MapSnapshotterNAPI {
public:
    /**
     * Initialize and register MapSnapshotter NAPI methods.
     */
    static void Init(napi_env env, napi_value exports);
};

} // namespace harmony
} // namespace mbgl

