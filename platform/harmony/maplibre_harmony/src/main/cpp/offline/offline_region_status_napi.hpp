#pragma once

#include <napi/native_api.h>
#include <mbgl/storage/offline.hpp>

namespace maplibre {
namespace harmony {

/**
 * 离线区域状态相关的 NAPI 辅助函数
 */
class OfflineRegionStatusNAPI {
public:
    // 从 C++ 状态转换为 NAPI 对象
    static napi_value ToNapiObject(napi_env env, const mbgl::OfflineRegionStatus& status);
};

} // namespace harmony
} // namespace maplibre

