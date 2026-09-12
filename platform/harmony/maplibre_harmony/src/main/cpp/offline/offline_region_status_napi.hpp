#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/offline.hpp>

namespace mbgl {
namespace harmony {

/**
 * NAPI helpers for offline region status conversion.
 */
class OfflineRegionStatusNAPI {
public:
    // Convert a C++ status struct into a NAPI object
    static napi_value ToNapiObject(napi_env env, const mbgl::OfflineRegionStatus& status);
};

} // namespace harmony
} // namespace mbgl

