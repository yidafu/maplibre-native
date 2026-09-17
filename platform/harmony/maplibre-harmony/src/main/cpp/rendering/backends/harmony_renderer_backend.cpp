#include "harmony_renderer_backend.hpp"
#include <cassert>

namespace mbgl {
namespace harmony {

void HarmonyRendererBackend::updateViewPort() {}

void HarmonyRendererBackend::resizeFramebuffer(int /*width*/, int /*height*/) {}

PremultipliedImage HarmonyRendererBackend::readFramebuffer() {
    return PremultipliedImage();
}

void HarmonyRendererBackend::markContextLost() {}

std::string HarmonyRendererBackend::getRendererInfo() {
    return backendTypeName();
}

void HarmonyRendererBackend::setSwapBehavior(gfx::Renderable::SwapBehaviour swapBehaviour_) {
    swapBehaviour = swapBehaviour_;
}

// Black-screen mitigation: default implementations of rendering control methods
void HarmonyRendererBackend::pauseRendering() {
    // Default implementation: subclasses should override
}

void HarmonyRendererBackend::resumeRendering() {
    // Default implementation: subclasses should override
}

} // namespace harmony
} // namespace mbgl
