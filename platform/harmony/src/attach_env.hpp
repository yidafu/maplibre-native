#pragma once

#include <memory>

namespace mbgl {
namespace harmony {

// 在harmony平台上，我们简化JNI环境的处理
// 这里提供一个基本的框架，实际实现可能需要根据harmony平台特性调整

class EnvDeleter {
public:
    EnvDeleter() = default;
    void operator()(void* /*p*/) const {
        // harmony平台上不需要特殊的环境释放逻辑
    }
};

using UniqueEnv = std::unique_ptr<void, EnvDeleter>;

UniqueEnv AttachEnv();

} // namespace harmony
} // namespace mbgl