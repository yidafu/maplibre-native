#pragma once

#include <memory>

namespace mbgl {
namespace harmony {

// Provide a simplified JNI environment wrapper for Harmony.
// Extend this skeleton as needed for platform-specific behavior.

class EnvDeleter {
public:
    EnvDeleter() = default;
    void operator()(void* /*p*/) const {
        // Harmony does not require custom environment release logic.
    }
};

using UniqueEnv = std::unique_ptr<void, EnvDeleter>;

UniqueEnv AttachEnv();

} // namespace harmony
} // namespace mbgl