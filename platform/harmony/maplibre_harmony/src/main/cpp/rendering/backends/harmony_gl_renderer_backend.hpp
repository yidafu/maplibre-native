#pragma once

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <GLES2/gl2.h>

#include <mbgl/gfx/renderable.hpp>
#include <mbgl/gl/renderer_backend.hpp>
#include "harmony_renderer_backend.hpp"
#include <memory>

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

    void setNativeWindow(void* window);
    void updateViewPort();  // 移除了override - HarmonyRendererBackend的方法不是虚函数
    void markContextLost();
    void resizeFramebuffer(int width, int height);
    PremultipliedImage readFramebuffer();
    void swapBuffers();  // Call eglSwapBuffers to display frame
    
    // 新增：获取和更新 pixelRatio
    float getPixelRatio() const { return pixelRatio_; }
    void updatePixelRatioFromDevice();

    // gfx::RendererBackend pure virtual methods
    mbgl::gfx::Renderable& getDefaultRenderable() override { return *this; }

    // gl::RendererBackend pure virtual methods
    void updateAssumedState() override;
    mbgl::gl::ProcAddress getExtensionFunctionPointer(const char*) override;

    // 新增：停止和恢复渲染（防止页面切换时崩溃）
    void pauseRendering();
    void resumeRendering();
    bool isRenderingStopped() const { return isStopped_; }

protected:
    void activate() override;
    void deactivate() override;
    std::unique_ptr<gfx::Context> createContext() override;

private:
    // EGL初始化拆分为两阶段
    bool initializeEGLDisplay();  // 主线程：创建display和surface
    bool initializeEGLContext();  // 渲染线程：创建context
    void cleanupEGL();
    
    // 新增：检查Surface有效性
    bool isSurfaceValid() const;
    
    // HarmonyOS OpenGL quirk handling
    void validateShaderAttributes();
    GLint bindAttributeWithFallback(GLuint program, GLuint index, const char* name);
    void logShaderInfo(GLuint program);

    // EGL references - these should be managed by the platform layer
    EGLDisplay eglDisplay_ = EGL_NO_DISPLAY;
    EGLConfig eglConfig_ = EGL_NO_CONFIG_KHR;
    EGLSurface eglSurface_ = EGL_NO_SURFACE;
    EGLContext eglContext_ = EGL_NO_CONTEXT;
    EGLNativeWindowType eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
    bool contextInitialized_ = false;  // 标记context是否已在渲染线程创建
    float pixelRatio_ = 1.0f;  // 设备像素比
    bool isStopped_ = false;  // 标记渲染是否已停止（防止崩溃）
};

} // namespace harmony
} // namespace mbgl


