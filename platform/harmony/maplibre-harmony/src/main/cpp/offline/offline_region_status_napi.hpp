#pragma once

#include <napi/native_api.h>
#include <mln/storage/offline.hpp>

namespace mln {
namespace harmony {

/**
 * NAPI helpers for offline region status conversion.
 */
class OfflineRegionStatusNAPI {
public:
    // Convert a C++ status struct into a NAPI object
    static napi_value ToNapiObject(napi_env env, const mln::OfflineRegionStatus& status);
};

} // namespace harmony
} // namespace mln

