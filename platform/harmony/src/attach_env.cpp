#include "attach_env.hpp"

namespace mbgl {
namespace harmony {

UniqueEnv AttachEnv() {
    // Harmony does not require special environment attachment logic.
    // Return a null pointer and let EnvDeleter manage the cleanup.
    return UniqueEnv(nullptr);
}

} // namespace harmony
} // namespace mbgl