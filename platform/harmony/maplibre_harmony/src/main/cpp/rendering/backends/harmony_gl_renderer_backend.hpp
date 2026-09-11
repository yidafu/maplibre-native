#pragma once

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <GLES2/gl2.h>

#include <mbgl/gfx/renderable.hpp>
#include <mbgl/gl/renderer_backend.hpp>
#include "harmony_renderer_backend.hpp"
#include "egl_display_manager.hpp"
#include <atomic>
#include <chrono>
#include <memory>
#include <thread>

namespace mbgl {
namespace harmony {

class HarmonyGLRendererBackend : public HarmonyRendererBackend,
                                 public mbgl::gl::RendererBackend,
                                 public mbgl::gfx::Renderable {
    friend class HarmonyGLRenderableResource;
public:
    HarmonyGLRendererBackend();
    ~HarmonyGLRendererBackend() override;

    mbgl::gfx::RendererBackend& getImpl() override { return *this; }

    void setNativeWindow(void* window) override;
    void updateViewPort() override;
    void markContextLost() override;
    void resizeFramebuffer(int width, int height) override;
    PremultipliedImage readFramebuffer() override;
    void cleanupBackend() override;
    std::string getRendererInfo() override;
    void swapBuffers();  // Call eglSwapBuffers to display frame
    
    // Added: retrieve and update pixelRatio
    float getPixelRatio() const { return pixelRatio_; }
    void updatePixelRatioFromDevice();

    // gfx::RendererBackend pure virtual methods
    mbgl::gfx::Renderable& getDefaultRenderable() override { return *this; }

    // gl::RendererBackend pure virtual methods
    void updateAssumedState() override;
    mbgl::gl::ProcAddress getExtensionFunctionPointer(const char*) override;

    // Added: pause/resume rendering (prevents crashes when switching pages)
    void pauseRendering() override;
    void resumeRendering() override;
    bool isRenderingStopped() const override { return isStopped_; }
    bool hasValidSurface() const override;
    
    // 🔒 Thread-safety checks
    bool isOnCorrectThread() const;
    std::thread::id getOwnerThreadId() const { return ownerThreadId_; }
    void assertOnCorrectThread() const;  // Debug assertion
    
    // 🎯 New architecture: expose EGL context initialization (invoked on render thread)
    bool initializeEGLContext();  // Render thread: create context
    
    // ✅ Expose EGL cleanup routine (must be called explicitly in cleanup())
    void cleanupEGL();

protected:
    void activate() override;
    void deactivate() override;
    std::unique_ptr<gfx::Context> createContext() override;

private:
    // Split EGL initialization into two phases (shared display, per-instance surface/context)
    bool initializeEGLDisplay();  // Acquire shared display and create surface
    
    // Added: check surface validity
    bool isSurfaceValid() const;
    
    // 🛡️ EGL diagnostics and auto-recovery (fixes crash on subsequent entry)
    bool isEGLHealthy() const;  // Check EGL health
    bool tryRecoverEGL();       // Attempt to recover EGL state
    
    // HarmonyOS OpenGL quirk handling
    void validateShaderAttributes();
    GLint bindAttributeWithFallback(GLuint program, GLuint index, const char* name);
    void logShaderInfo(GLuint program);

    // EGL references - shared display, per-instance context/surface
    EGLConfig eglConfig_ = EGL_NO_CONFIG_KHR;
    EGLSurface eglSurface_ = EGL_NO_SURFACE;
    EGLContext eglContext_ = EGL_NO_CONTEXT;
    EGLNativeWindowType eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
    bool contextInitialized_ = false;  // Tracks whether context was created on render thread
    bool displayAcquired_ = false;  // Tracks whether shared display is acquired
    float pixelRatio_ = 1.0f;  // Device pixel ratio
    bool isStopped_ = false;  // Tracks whether rendering is paused (prevents crashes)
    
    // 🔒 Thread ownership & safety
    std::thread::id ownerThreadId_;  // Thread owning the EGL context (for validation)
    std::thread::id renderThreadId_;  // Render thread ID (for eglMakeCurrent validation)

    // 🛡️ EGL recovery state. Per instance on purpose: process-wide statics
    // here would let one map instance's recovery suppress another's and race
    // on the non-atomic timestamp.
    std::atomic<bool> eglRecovering_{false};
    std::atomic<int> eglRecoveryAttempts_{0};
    std::chrono::steady_clock::time_point lastEglRecoveryTime_{};
};

} // namespace harmony
} // namespace mbgl


