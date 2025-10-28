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

// 🛡️ 黑屏修复：渲染控制方法的默认实现
void HarmonyRendererBackend::pauseRendering() {
    // 默认实现：子类应该覆盖此方法
}

void HarmonyRendererBackend::resumeRendering() {
    // 默认实现：子类应该覆盖此方法
}

} // namespace harmony
} // namespace mbgl
