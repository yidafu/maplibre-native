#pragma once

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <GLES2/gl2.h>

#include <mbgl/gfx/renderable.hpp>
#include <mbgl/gl/renderer_backend.hpp>
#include "harmony_renderer_backend.hpp"
#include "egl_display_manager.hpp"
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

    void setNativeWindow(void* window);
    void updateViewPort() override;
    void markContextLost() override;
    void resizeFramebuffer(int width, int height) override;
    PremultipliedImage readFramebuffer() override;
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
    void pauseRendering() override;
    void resumeRendering() override;
    bool isRenderingStopped() const override { return isStopped_; }
    
    // 🔒 线程安全检查
    bool isOnCorrectThread() const;
    std::thread::id getOwnerThreadId() const { return ownerThreadId_; }
    void assertOnCorrectThread() const;  // 调试断言
    
    // 🎯 新架构：公开 EGL Context 初始化（在渲染线程调用）
    bool initializeEGLContext();  // 渲染线程：创建context

protected:
    void activate() override;
    void deactivate() override;
    std::unique_ptr<gfx::Context> createContext() override;

private:
    // EGL初始化拆分为两阶段（共享 Display，实例独立 Surface/Context）
    bool initializeEGLDisplay();  // 获取共享 display 并创建 surface
    void cleanupEGL();
    
    // 新增：检查Surface有效性
    bool isSurfaceValid() const;
    
    // 🛡️ EGL 状态诊断和自动恢复（修复第二次进入崩溃）
    bool isEGLHealthy() const;  // 检查 EGL 健康状态
    bool tryRecoverEGL();       // 尝试恢复 EGL 状态
    
    // HarmonyOS OpenGL quirk handling
    void validateShaderAttributes();
    GLint bindAttributeWithFallback(GLuint program, GLuint index, const char* name);
    void logShaderInfo(GLuint program);

    // EGL references - 共享 Display，实例独立 Context/Surface
    EGLConfig eglConfig_ = EGL_NO_CONFIG_KHR;
    EGLSurface eglSurface_ = EGL_NO_SURFACE;
    EGLContext eglContext_ = EGL_NO_CONTEXT;
    EGLNativeWindowType eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
    bool contextInitialized_ = false;  // 标记context是否已在渲染线程创建
    bool displayAcquired_ = false;  // 标记是否已获取共享 Display
    float pixelRatio_ = 1.0f;  // 设备像素比
    bool isStopped_ = false;  // 标记渲染是否已停止（防止崩溃）
    
    // 🔒 线程所有权和安全
    std::thread::id ownerThreadId_;  // EGL Context 所属线程（用于验证）
    std::thread::id renderThreadId_;  // 渲染线程 ID（用于 eglMakeCurrent 验证）
};

} // namespace harmony
} // namespace mbgl


