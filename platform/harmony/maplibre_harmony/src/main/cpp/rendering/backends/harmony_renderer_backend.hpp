#pragma once

#include <ace/xcomponent/native_interface_xcomponent.h>
#include <mbgl/gfx/backend.hpp>
#include <mbgl/gfx/renderer_backend.hpp>
#include <mbgl/gfx/renderable.hpp>
#include <mbgl/util/image.hpp>
#include <native_window/external_window.h>


namespace mbgl {
namespace harmony {

class HarmonyRendererBackend : public gfx::Backend {
public:
    HarmonyRendererBackend() = default;
    HarmonyRendererBackend(const HarmonyRendererBackend&) = delete;
    HarmonyRendererBackend& operator=(const HarmonyRendererBackend&) = delete;
    virtual ~HarmonyRendererBackend() = default;

    static std::unique_ptr<HarmonyRendererBackend> Create(OHNativeWindow* window) {
        return mbgl::gfx::Backend::Create<HarmonyRendererBackend, OHNativeWindow*>(window);
    }
    virtual mbgl::gfx::RendererBackend& getImpl() = 0;

    virtual void updateViewPort();

    // Ensures the current context is not cleaned up when destroyed
    virtual void markContextLost();

    virtual void resizeFramebuffer(int width, int height);
    virtual PremultipliedImage readFramebuffer();

    gfx::Renderable::SwapBehaviour getSwapBehavior() const { return swapBehaviour; }
    virtual void setSwapBehavior(gfx::Renderable::SwapBehaviour swapBehaviour);
    
    // 🛡️ 黑屏修复：渲染控制方法
    virtual void pauseRendering();
    virtual void resumeRendering();
    virtual bool isRenderingStopped() const { return false; }

protected:
    gfx::Renderable::SwapBehaviour swapBehaviour = gfx::Renderable::SwapBehaviour::NoFlush;
};

} // namespace harmony
} // namespace mbgl
