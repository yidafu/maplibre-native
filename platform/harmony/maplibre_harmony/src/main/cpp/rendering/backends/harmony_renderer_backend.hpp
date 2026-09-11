#pragma once

#include <ace/xcomponent/native_interface_xcomponent.h>
#include <mbgl/gfx/backend.hpp>
#include <mbgl/gfx/renderer_backend.hpp>
#include <mbgl/gfx/renderable.hpp>
#include <mbgl/util/image.hpp>
#include <native_window/external_window.h>
#include <string>


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

    /// Queue a readback of the next presented frame (Vulkan swapchain copy;
    /// no-op for GL, which reads the EGL surface directly). Call before
    /// rendering the frame that should be captured by readFramebuffer().
    virtual void enableFramebufferRead(bool /*value*/) {}

    /// Bind the platform native window (OHNativeWindow* passed as void*).
    /// Called on the render thread; implementations rebuild their surface
    /// state as needed and must tolerate repeated calls.
    virtual void setNativeWindow(void* /*window*/) {}

    /// Whether the backend has a window bound and is ready to present frames
    virtual bool hasValidSurface() const { return false; }

    /// Release backend-specific rendering resources (EGL context/surface or
    /// Vulkan device work). Called from the render thread during teardown.
    virtual void cleanupBackend() {}

    /// Human-readable description of the active backend and GPU, for
    /// diagnostics and the renderer-info test page.
    virtual std::string getRendererInfo();

    /// Static name of the compiled-in backend ("opengl" / "vulkan" / ...)
    static std::string backendTypeName() { return gfx::Backend::GetTypeName(gfx::Backend::GetType()); }

    gfx::Renderable::SwapBehaviour getSwapBehavior() const { return swapBehaviour; }
    virtual void setSwapBehavior(gfx::Renderable::SwapBehaviour swapBehaviour);
    
    // 🛡️ Black screen mitigation: rendering control hooks
    virtual void pauseRendering();
    virtual void resumeRendering();
    virtual bool isRenderingStopped() const { return false; }

protected:
    gfx::Renderable::SwapBehaviour swapBehaviour = gfx::Renderable::SwapBehaviour::NoFlush;
};

} // namespace harmony
} // namespace mbgl
