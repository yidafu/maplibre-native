#include "attach_env.hpp"

namespace mbgl {
namespace harmony {

UniqueEnv AttachEnv() {
    // harmony平台上不需要特殊的环境附加逻辑
    // 返回一个空指针，EnvDeleter会处理释放
    return UniqueEnv(nullptr);
}

} // namespace harmony
} // namespace mbgl