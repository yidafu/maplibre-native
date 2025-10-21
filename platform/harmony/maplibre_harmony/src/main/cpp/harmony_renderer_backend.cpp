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

void HarmonyRendererBackend::setSwapBehavior(gfx::Renderable::SwapBehaviour swapBehaviour_) {
    swapBehaviour = swapBehaviour_;
}

} // namespace harmony
} // namespace mbgl
