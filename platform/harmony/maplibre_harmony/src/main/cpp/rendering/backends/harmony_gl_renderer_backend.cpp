#include "harmony_gl_renderer_backend.hpp"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gl/context.hpp>
#include <mbgl/gl/renderable_resource.hpp>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <native_window/external_window.h>
#include <window_manager/oh_display_manager.h>
#include "utils/logger.h"
#include "utils/anr_detector.hpp"
#include <cassert>
#include <thread>
#include <chrono>
#include <atomic>     // for std::atomic
#include <stdexcept>  // for std::runtime_error
#include <cmath>      // for std::abs

using mbgl::harmony::Logger;

namespace {

// 全局 EGL 操作互斥锁 - 保护所有关键 EGL 调用（创建、激活、切换等）
// 确保 EGL 操作串行化，避免多实例并发冲突
std::mutex g_eglMutex;

// Get device DPI using HarmonyOS Native API
// Reference: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-oh-display-manager-h#oh_nativedisplaymanager_getdefaultdisplaydensitydpi
float getDeviceDPI() {
    int32_t densityDPI = 160;  // Default MDPI
    int32_t ret = OH_NativeDisplayManager_GetDefaultDisplayDensityDpi(&densityDPI);
    
    if (ret != 0) {
        Logger::warn("HarmonyGL", "Failed to get DPI (error=%d), using default MDPI: %d", 
                    ret, densityDPI);
    }
    
    return static_cast<float>(densityDPI);
}

// Calculate pixelRatio based on MDPI baseline (160 DPI)
float calculatePixelRatio(float dpi) {
    return dpi / 160.0f;
}

const char* eglErrorString(int error) {
    switch (error) {
        case EGL_SUCCESS: return "EGL_SUCCESS";
        case EGL_NOT_INITIALIZED: return "EGL_NOT_INITIALIZED";
        case EGL_BAD_ACCESS: return "EGL_BAD_ACCESS";
        case EGL_BAD_ALLOC: return "EGL_BAD_ALLOC";
        case EGL_BAD_ATTRIBUTE: return "EGL_BAD_ATTRIBUTE";
        case EGL_BAD_CONFIG: return "EGL_BAD_CONFIG";
        case EGL_BAD_CONTEXT: return "EGL_BAD_CONTEXT";
        case EGL_BAD_CURRENT_SURFACE: return "EGL_BAD_CURRENT_SURFACE";
        case EGL_BAD_DISPLAY: return "EGL_BAD_DISPLAY";
        case EGL_BAD_MATCH: return "EGL_BAD_MATCH";
        case EGL_BAD_NATIVE_PIXMAP: return "EGL_BAD_NATIVE_PIXMAP";
        case EGL_BAD_NATIVE_WINDOW: return "EGL_BAD_NATIVE_WINDOW";
        case EGL_BAD_PARAMETER: return "EGL_BAD_PARAMETER";
        case EGL_BAD_SURFACE: return "EGL_BAD_SURFACE";
        case EGL_CONTEXT_LOST: return "EGL_CONTEXT_LOST";
        default: return "Unknown EGL error";
    }
}
} // anonymous namespace

namespace mbgl {
namespace harmony {

class HarmonyGLRenderableResource final : public mbgl::gl::RenderableResource {
public:
    HarmonyGLRenderableResource(HarmonyGLRendererBackend& backend_) 
        : backend(backend_) {}

    void bind() override {
        assert(gfx::BackendScope::exists());
        backend.setFramebufferBinding(0);
        backend.setViewport(0, 0, backend.getSize());
    }

    void swap() override {
        // Ensure BackendScope exists to avoid crashes
        if (!gfx::BackendScope::exists()) {
            Logger::error("HarmonyGL", "❌ BackendScope does not exist during swap operation");
            throw std::runtime_error("BackendScope does not exist during swap operation");
        }
        
        // Flush if needed
        const auto& swapBehaviour = static_cast<HarmonyRendererBackend&>(backend).getSwapBehavior();
        if (swapBehaviour == gfx::Renderable::SwapBehaviour::Flush) {
            static_cast<gl::Context&>(backend.getContext()).finish();
        }
        
        backend.swapBuffers();
    }

private:
    HarmonyGLRendererBackend& backend;
};

HarmonyGLRendererBackend::HarmonyGLRendererBackend()
    : mbgl::gl::RendererBackend(gfx::ContextMode::Unique),
      mbgl::gfx::Renderable({64, 64}, std::make_unique<HarmonyGLRenderableResource>(*this)) {
    // 注册实例到 EGLDisplayManager（用于资源限制和监控）
    if (!EGLDisplayManager::getInstance().registerInstance()) {
        Logger::error("HarmonyGLRendererBackend", 
                     "Failed to register instance: exceeded maximum concurrent map limit (%d)",
                     EGLDisplayManager::getMaxConcurrentInstances());
        throw std::runtime_error("Exceeded maximum concurrent map instances");
    }
    Logger::info("HarmonyGLRendererBackend", "Instance created (active: %d/%d)",
                EGLDisplayManager::getInstance().getActiveInstanceCount(),
                EGLDisplayManager::getMaxConcurrentInstances());
}

HarmonyGLRendererBackend::~HarmonyGLRendererBackend() {
    // 🛡️ CRITICAL FIX: 设置停止标志，防止析构期间的跨线程 EGL Context 访问
    // 问题：EGL Context 在渲染线程创建，但析构函数在主线程执行
    // 解决：在清理前设置标志，activate() 会检查此标志并跳过操作
    isStopped_ = true;
    Logger::info("HarmonyGLRendererBackend", "Calling cleanupEGL()...");
    cleanupEGL();
    Logger::info("HarmonyGLRendererBackend", "cleanupEGL() completed");
    
    // 注销实例（减少活跃计数）
    Logger::info("HarmonyGLRendererBackend", "Unregistering instance...");
    EGLDisplayManager::getInstance().unregisterInstance();
    // 🛡️ CRITICAL FIX: 移除 debug 断言，避免跨线程访问 Context
    // 原因：此时可能不在 EGL Context 创建的线程上，访问 getContext() 会导致线程冲突
    // 解决：Context 清理已在 cleanupEGL() 中完成，无需额外检查
    // 
    // 原代码（导致黑屏崩溃）：
    // #ifndef NDEBUG
    //     if (static_cast<gl::Context&>(getContext()).getCleanupOnDestruction()) {
    //         assert(eglGetCurrentContext() != EGL_NO_CONTEXT);
    //     }
    // #endif
}

void HarmonyGLRendererBackend::updatePixelRatioFromDevice() {
    float deviceDPI = getDeviceDPI();
    float newPixelRatio = calculatePixelRatio(deviceDPI);
    
    if (std::abs(pixelRatio_ - newPixelRatio) > 0.01f) {
        pixelRatio_ = newPixelRatio;
    }
}

void HarmonyGLRendererBackend::setNativeWindow(void* window) {
    // 线程亲和校验（首次 ownerThreadId_ 未设置时放行）
    assertOnCorrectThread();
    EGLNativeWindowType newWindow = reinterpret_cast<EGLNativeWindowType>(window);
    
    // 如果是同一个 window，不需要重新初始化
    if (newWindow == eglWindow_) {
        return;
    }
    
    Logger::info("HarmonyGLRendererBackend", 
                "setNativeWindow: Changing window from %lu to %lu", 
                eglWindow_, newWindow);
    
    // ✅ 原子操作：使用全局互斥锁保护整个清理→初始化流程
    // 目的：消除时序竞态窗口，防止 activate() 在中间状态执行
    // 效果：activate() 会等待此操作完成，看到正确的 isStopped_ 状态
    {
        std::lock_guard<std::mutex> lock(g_eglMutex);
        
        // 清理旧的 EGL 资源（不设置 isStopped_）
        cleanupEGL();
        
        // 🛡️ 修复第二次进入崩溃：添加 window 有效性检查
        if (!newWindow) {
            Logger::warn("HarmonyGLRendererBackend", "setNativeWindow: null window provided, skipping initialization");
            return;
        }
        
        eglWindow_ = newWindow;
        
        // 🛡️ 短暂延迟，让 Native Window 稳定（修复页面转换时的时序问题）
        // 注意：这里的延迟很短（10ms），主要延迟在 TypeScript 层（500ms）
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        
        // 初始化 EGL Display 和 Surface
        if (!initializeEGLDisplay()) {
            Logger::error("HarmonyGL", "Failed to initialize EGL display/surface");
            eglWindow_ = 0;
            // 不要设置 isStopped_，让恢复机制有机会修复
        } else {
            // Update device DPI and pixelRatio
            updatePixelRatioFromDevice();
        }
        
    }
    // ✅ lock 自动释放，其他线程的 activate() 可以继续，看到正确的状态
}

bool HarmonyGLRendererBackend::initializeEGLDisplay() {
    // HarmonyOS optimized EGL configuration with MSAA anti-aliasing
    const EGLint attribList[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 16,
        EGL_STENCIL_SIZE, 8,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        // MSAA anti-aliasing configuration
        EGL_SAMPLE_BUFFERS, 1,
        EGL_SAMPLES, 4,  // 4x MSAA
        // HarmonyOS specific configuration
        EGL_COLOR_BUFFER_TYPE, EGL_RGB_BUFFER,
        EGL_CONFIG_CAVEAT, EGL_NONE,  // Avoid EGL_SLOW_CONFIG
        EGL_CONFORMANT, EGL_OPENGL_ES3_BIT,
        EGL_NONE
    };

    // 共享 EGL Display（通过 EGLDisplayManager）
    EGLDisplay display = EGLDisplayManager::getInstance().acquireDisplay();
    if (display == EGL_NO_DISPLAY) {
        Logger::error("HarmonyGL", "Failed to acquire shared EGL display");
        return false;
    }
    displayAcquired_ = true;
    // 选择 EGL 配置（通过 EGLDisplayManager）
    if (!EGLDisplayManager::getInstance().chooseConfig(attribList, eglConfig_)) {
        Logger::error("HarmonyGL", "Failed to choose EGL config");
        return false;
    }
    // Verify MSAA configuration
    EGLint samples = 0, sampleBuffers = 0;
    eglGetConfigAttrib(display, eglConfig_, EGL_SAMPLES, &samples);
    eglGetConfigAttrib(display, eglConfig_, EGL_SAMPLE_BUFFERS, &sampleBuffers);
    Logger::info("HarmonyGL", "MSAA Config: sampleBuffers=%d, samples=%d", 
                 sampleBuffers, samples);
    if (samples > 1) {
        Logger::info("HarmonyGL", "MSAA enabled: %dx anti-aliasing", samples);
    } else {
        Logger::warn("HarmonyGL", "MSAA not enabled (device may not support)");
    }

    // ✅ 创建独立的 EGL Surface（每个实例独立）
    // Note: Native Window buffer size will be set in resizeFramebuffer()
    eglSurface_ = eglCreateWindowSurface(display, eglConfig_, eglWindow_, nullptr);
    if (eglSurface_ == EGL_NO_SURFACE) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to create EGL surface: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    // 将移到 initializeEGLContext() 中
    
    // 🔧 修复黑屏：EGL Display 和 Surface 初始化成功，重置停止标志
    // 问题：cleanupEGL() 设置 isStopped_ = true，但 initializeEGLDisplay() 成功后未重置
    // 解决：在 EGL 初始化成功后重置标志，允许渲染继续
    isStopped_ = false;
    return true;
}

bool HarmonyGLRendererBackend::initializeEGLContext() {
    // 使用共享 Display
    EGLDisplay display = EGLDisplayManager::getInstance().getDisplay();
    if (display == EGL_NO_DISPLAY || eglSurface_ == EGL_NO_SURFACE) {
        Logger::error("HarmonyGL", "Cannot create context: display or surface not initialized");
        return false;
    }
    
    if (eglContext_ != EGL_NO_CONTEXT) {
        return true;
    }
    
    // ✅ 使用全局互斥锁保护 Context 创建和激活
    // 防止多个实例并发创建 Context 导致冲突
    std::lock_guard<std::mutex> lock(g_eglMutex);
    
    // ✅ 记录渲染线程 ID（用于后续验证）
    renderThreadId_ = std::this_thread::get_id();
    Logger::error("HarmonyGL", "🔴🔴🔴 Creating EGL Context on thread: %lu",
                 std::hash<std::thread::id>{}(renderThreadId_));
    Logger::info("HarmonyGLRendererBackend", "Recording render thread ID for EGL context (with mutex protection)");
    
    const EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,  // OpenGL ES 3
        EGL_NONE
    };
    
    // ✅ 创建独立的 EGL Context（每个实例独立）
    eglContext_ = eglCreateContext(display, eglConfig_, EGL_NO_CONTEXT, contextAttribs);
    if (eglContext_ == EGL_NO_CONTEXT) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to create EGL context: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    // Activate context to get OpenGL information
    if (!eglMakeCurrent(display, eglSurface_, eglSurface_, eglContext_)) {
        EGLint error = eglGetError();
        Logger::error("OpenGL", "Failed to make context current: %s (error code: 0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    
    // Output OpenGL version and capabilities
    Logger::info("OpenGL", "OpenGL Info:");
    const GLubyte* version = glGetString(GL_VERSION);
    const GLubyte* glslVersion = glGetString(GL_SHADING_LANGUAGE_VERSION);
    const GLubyte* vendor = glGetString(GL_VENDOR);
    const GLubyte* renderer = glGetString(GL_RENDERER);
    
    Logger::info("OpenGL", "GL_VERSION: %s", version ? (const char*)version : "NULL");
    Logger::info("OpenGL", "GL_SHADING_LANGUAGE_VERSION: %s", glslVersion ? (const char*)glslVersion : "NULL");
    Logger::info("OpenGL", "GL_VENDOR: %s", vendor ? (const char*)vendor : "NULL");
    Logger::info("OpenGL", "GL_RENDERER: %s", renderer ? (const char*)renderer : "NULL");
    
    // 检查关键OpenGL能力
    GLint maxUBOBindings = 0;
    glGetIntegerv(GL_MAX_UNIFORM_BUFFER_BINDINGS, &maxUBOBindings);
    Logger::info("OpenGL", "GL_MAX_UNIFORM_BUFFER_BINDINGS: %d (UBO support: %s)", 
                 maxUBOBindings, maxUBOBindings > 0 ? "YES" : "NO");
    
    GLint maxUBOSize = 0;
    glGetIntegerv(GL_MAX_UNIFORM_BLOCK_SIZE, &maxUBOSize);
    Logger::info("OpenGL", "GL_MAX_UNIFORM_BLOCK_SIZE: %d bytes", maxUBOSize);
    
    GLint maxVertexAttribs = 0;
    glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &maxVertexAttribs);
    Logger::info("OpenGL", "GL_MAX_VERTEX_ATTRIBS: %d", maxVertexAttribs);
    
    GLint maxTextureSize = 0;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    Logger::info("OpenGL", "GL_MAX_TEXTURE_SIZE: %d", maxTextureSize);
    
    // 查询当前viewport设置
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    Logger::info("OpenGL", "GL_VIEWPORT: x=%d, y=%d, width=%d, height=%d", 
                 viewport[0], viewport[1], viewport[2], viewport[3]);
    
    
    // 验证shader属性
    validateShaderAttributes();
    
    // ✅ Enable VSync to prevent flickering（移到这里，在 Context 创建后调用）
    if (!eglSwapInterval(display, 1)) {
        EGLint error = eglGetError();
        Logger::warn("HarmonyGL", "Failed to set swap interval: %s", eglErrorString(error));
    } else {
    }
    
    contextInitialized_ = true;
    
    Logger::info("HarmonyGLRendererBackend", "EGL Context: %p (bound to render thread)", eglContext_);
    
    return true;
}

void HarmonyGLRendererBackend::cleanupEGL() {
    // 🔍 ANR监控：记录EGL清理耗时
    harmony::ANRDetector detector("cleanupEGL", 100, 500);
    
    // ✅ 不在这里设置 isStopped_
    // 原因：cleanupEGL() 可能在重新初始化时被调用（setNativeWindow）
    // 设置 isStopped_ = true 会在时序窗口期间阻止渲染，导致黑屏
    // isStopped_ 只应在析构函数中设置，保护析构期间的并发访问
    
    try {
        // 使用共享 Display
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (display != EGL_NO_DISPLAY) {
            // ✅ 使用全局互斥锁保护 EGL 清理操作
            {
                std::lock_guard<std::mutex> lock(g_eglMutex);
                
                // ✅ 清理独立的 EGL Context
                if (eglContext_ != EGL_NO_CONTEXT) {
                    // 🛡️ 线程安全：检查当前线程是否持有这个 Context
                EGLContext currentContext = eglGetCurrentContext();
                if (currentContext == eglContext_) {
                        // 尝试 unbind，如果失败也继续清理
                    if (!eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
                            EGLint error = eglGetError();
                            Logger::warn("HarmonyGLRendererBackend", 
                                        "Failed to unbind context during cleanup (error=0x%x), continuing anyway", 
                                        error);
                            // 不要因为 unbind 失败就停止清理
                        }
                    } else {
                    }
                    
                    // 🛡️ EGL Context 可以在任意线程销毁（只要不是 current）
                if (!eglDestroyContext(display, eglContext_)) {
                        EGLint error = eglGetError();
                        Logger::warn("HarmonyGLRendererBackend", 
                                    "Failed to destroy context (error=0x%x)", error);
                    }
                    eglContext_ = EGL_NO_CONTEXT;
                    contextInitialized_ = false;
                }
                
                // ✅ 清理独立的 EGL Surface
                if (eglSurface_ != EGL_NO_SURFACE) {
                if (!eglDestroySurface(display, eglSurface_)) {
                        EGLint error = eglGetError();
                        Logger::warn("HarmonyGLRendererBackend", 
                                    "Failed to destroy surface (error=0x%x)", error);
                    }
                    eglSurface_ = EGL_NO_SURFACE;
                }
            }  // ✅ 释放互斥锁
            
            // 释放共享 Display
            if (displayAcquired_) {
                EGLDisplayManager::getInstance().releaseDisplay();
                displayAcquired_ = false;
            }
        }
        
        eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
    } catch (const std::exception& e) {
        Logger::error("HarmonyGLRendererBackend", "Error during EGL cleanup: %s", e.what());
        // 确保清理状态即使发生异常
        eglContext_ = EGL_NO_CONTEXT;
        eglSurface_ = EGL_NO_SURFACE;
        eglWindow_ = 0;
        contextInitialized_ = false;
        if (displayAcquired_) {
            EGLDisplayManager::getInstance().releaseDisplay();
            displayAcquired_ = false;
        }
    } catch (...) {
        Logger::error("HarmonyGLRendererBackend", "Unknown error during EGL cleanup");
        // 确保清理状态即使发生异常
        eglContext_ = EGL_NO_CONTEXT;
        eglSurface_ = EGL_NO_SURFACE;
        eglWindow_ = 0;
        contextInitialized_ = false;
        if (displayAcquired_) {
            EGLDisplayManager::getInstance().releaseDisplay();
            displayAcquired_ = false;
        }
    }
    
}

// 🛡️ 检查 EGL 健康状态（修复第二次进入崩溃）
bool HarmonyGLRendererBackend::isEGLHealthy() const {
    // ✅ 使用共享 Display（getDisplay 不增加引用计数）
    EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
    
    // 基本 EGL 资源检查
    if (display == EGL_NO_DISPLAY || 
        eglSurface_ == EGL_NO_SURFACE || 
        eglContext_ == EGL_NO_CONTEXT) {
        return false;
    }
    
    // 检查 Surface 有效性
    if (!isSurfaceValid()) {
        return false;
    }
    
    // 检查 EGL 没有错误
    EGLint error = eglGetError();
    if (error != EGL_SUCCESS) {
        Logger::warn("HarmonyGLRendererBackend", 
                    "EGL has pending error: %s (0x%x)", 
                    eglErrorString(error), error);
        return false;
    }
    
    return true;
}

// 🛡️ 尝试恢复 EGL 状态（修复第二次进入崩溃）
bool HarmonyGLRendererBackend::tryRecoverEGL() {
    // ✅ 防止并发恢复（如果多个实例同时失败，只允许一个恢复）
    static std::atomic<bool> recovering{false};
    if (recovering.exchange(true)) {
        Logger::warn("HarmonyGLRendererBackend", 
                    "❌ Already in recovery process, aborting this attempt");
        return false;
    }
    
    Logger::info("HarmonyGLRendererBackend", "🔧 Attempting to recover EGL state...");
    
    // 限制重试次数，防止无限循环
    static std::atomic<int> recoveryAttempts{0};
    static std::chrono::steady_clock::time_point lastRecoveryTime;
    
    auto now = std::chrono::steady_clock::now();
    auto timeSinceLastRecovery = std::chrono::duration_cast<std::chrono::seconds>(
        now - lastRecoveryTime).count();
    
    // 如果距离上次恢复不到 2 秒，可能是快速失败，放弃恢复
    if (timeSinceLastRecovery < 2 && recoveryAttempts > 3) {
        Logger::error("HarmonyGLRendererBackend", 
                     "❌ Too many recovery attempts (%d) in short time, giving up", 
                     recoveryAttempts.load());
        recovering = false;  // ✅ 重置标志
        return false;
    }
    
    // 重置计数器（如果已经超过 5 秒）
    if (timeSinceLastRecovery > 5) {
        recoveryAttempts = 0;
    }
    
    recoveryAttempts++;
    lastRecoveryTime = now;
    
    Logger::info("HarmonyGLRendererBackend", 
                "Recovery attempt #%d (last recovery was %ld seconds ago)", 
                recoveryAttempts.load(), timeSinceLastRecovery);
    
    // 1. 完全清理当前无效的 EGL 资源
    Logger::info("HarmonyGLRendererBackend", "Step 1: Cleaning up invalid EGL resources");
    
    // ✅ 使用共享 Display：不需要完全重置 Display，只清理独立资源
    try {
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        
        // 1.1 清理 Context
        if (eglContext_ != EGL_NO_CONTEXT && display != EGL_NO_DISPLAY) {
            EGLContext currentContext = eglGetCurrentContext();
            if (currentContext == eglContext_) {
                eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
            }
            eglDestroyContext(display, eglContext_);
            eglContext_ = EGL_NO_CONTEXT;
            contextInitialized_ = false;
        }
        
        // 1.2 清理 Surface
        if (eglSurface_ != EGL_NO_SURFACE && display != EGL_NO_DISPLAY) {
            eglDestroySurface(display, eglSurface_);
            eglSurface_ = EGL_NO_SURFACE;
        }
        
        // 1.3 不需要 terminate Display（共享资源由 EGLDisplayManager 管理）
    } catch (...) {
        Logger::error("HarmonyGLRendererBackend", "Error during cleanup phase of recovery");
        // 确保状态清零
        eglContext_ = EGL_NO_CONTEXT;
        eglSurface_ = EGL_NO_SURFACE;
        contextInitialized_ = false;
    }
    
    // 2. 延长延迟时间，让系统完全稳定
    Logger::info("HarmonyGLRendererBackend", "Step 2: Waiting for system to stabilize (50ms)");
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    
    // 3. 重新初始化整个 EGL 栈（Display + Surface + Context）
    Logger::info("HarmonyGLRendererBackend", "Step 3: Re-initializing complete EGL stack");
    if (!eglWindow_) {
        Logger::error("HarmonyGLRendererBackend", "❌ No native window available for recovery");
        recovering = false;  // ✅ 重置标志
        return false;
    }
    
    if (!initializeEGLDisplay()) {
        Logger::error("HarmonyGLRendererBackend", "❌ Failed to re-initialize EGL display");
        recovering = false;  // ✅ 重置标志
        return false;
    }
    
    // 4. 重新初始化 EGL Context（如果在渲染线程）
    Logger::info("HarmonyGLRendererBackend", "Step 4: Re-initializing EGL context");
    if (!initializeEGLContext()) {
        Logger::error("HarmonyGLRendererBackend", "❌ Failed to re-initialize EGL context");
        recovering = false;  // ✅ 重置标志
        return false;
    }
    
    recovering = false;  // ✅ 重置标志
    return true;
}

// HarmonyOS OpenGL quirk handling methods
void HarmonyGLRendererBackend::validateShaderAttributes() {
    
    if (eglGetCurrentContext() == EGL_NO_CONTEXT) {
        Logger::warn("HarmonyGLRendererBackend", "No current EGL context for shader validation");
        return;
    }
    
    // Query OpenGL version and capabilities
    const char* glVersion = reinterpret_cast<const char*>(glGetString(GL_VERSION));
    const char* glRenderer = reinterpret_cast<const char*>(glGetString(GL_RENDERER));
    const char* glVendor = reinterpret_cast<const char*>(glGetString(GL_VENDOR));
    
    Logger::info("HarmonyGLRendererBackend", "OpenGL Version: %s", glVersion ? glVersion : "Unknown");
    Logger::info("HarmonyGLRendererBackend", "OpenGL Renderer: %s", glRenderer ? glRenderer : "Unknown");
    Logger::info("HarmonyGLRendererBackend", "OpenGL Vendor: %s", glVendor ? glVendor : "Unknown");
    
    // Check for HarmonyOS-specific OpenGL quirks
    if (glVendor && strstr(glVendor, "ARM")) {
        Logger::info("HarmonyGLRendererBackend", "Detected ARM GPU - enabling HarmonyOS attribute binding workarounds");
    }
    
}

GLint HarmonyGLRendererBackend::bindAttributeWithFallback(GLuint program, GLuint index, const char* name) {
    if (!program || !name) {
        Logger::error("HarmonyGLRendererBackend", "Invalid parameters for bindAttributeWithFallback");
        return -1;
    }
    
    // First, try to bind the attribute location before linking
    glBindAttribLocation(program, index, name);
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        Logger::warn("HarmonyGLRendererBackend", "glBindAttribLocation failed with error: 0x%x", error);
    }
    
    // After linking, query the actual location
    GLint actualLocation = glGetAttribLocation(program, name);
    error = glGetError();
    if (error != GL_NO_ERROR) {
        Logger::warn("HarmonyGLRendererBackend", "glGetAttribLocation failed with error: 0x%x", error);
    }
    
    if (actualLocation != static_cast<GLint>(index)) {
        Logger::warn("HarmonyGLRendererBackend", 
                     "Attribute binding mismatch for '%s': expected %d, got %d", 
                     name, index, actualLocation);
        
        if (actualLocation >= 0) {
            Logger::info("HarmonyGLRendererBackend", 
                         "Using actual location %d for attribute '%s'", 
                         actualLocation, name);
            return actualLocation;
        } else {
            Logger::error("HarmonyGLRendererBackend", 
                          "Attribute '%s' not found in program %u", 
                          name, program);
        }
    } else {
    }
    
    return actualLocation;
}

void HarmonyGLRendererBackend::logShaderInfo(GLuint program) {
    if (!program) {
        Logger::warn("HarmonyGLRendererBackend", "Cannot log info for null program");
        return;
    }
    
    Logger::info("HarmonyGL", "Shader Program Info:");
    Logger::info("HarmonyGLRendererBackend", "Program ID: %u", program);
    
    // Check if program is linked
    GLint linkStatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
    Logger::info("HarmonyGLRendererBackend", "Link Status: %s", linkStatus ? "SUCCESS" : "FAILED");
    
    if (!linkStatus) {
        GLint infoLogLength;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);
        if (infoLogLength > 0) {
            std::vector<char> infoLog(infoLogLength);
            glGetProgramInfoLog(program, infoLogLength, nullptr, infoLog.data());
            Logger::error("HarmonyGLRendererBackend", "Link Error: %s", infoLog.data());
        }
        return;
    }
    
    // Get number of active attributes
    GLint activeAttributes;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, &activeAttributes);
    Logger::info("HarmonyGLRendererBackend", "Active Attributes: %d", activeAttributes);
    
    // Get maximum attribute name length
    GLint maxAttributeNameLength;
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxAttributeNameLength);
    
    // Log each active attribute
    for (GLint i = 0; i < activeAttributes; ++i) {
        std::vector<char> name(maxAttributeNameLength);
        GLint size;
        GLenum type;
        glGetActiveAttrib(program, i, maxAttributeNameLength, nullptr, &size, &type, name.data());
        
        GLint location = glGetAttribLocation(program, name.data());
        Logger::info("HarmonyGLRendererBackend", 
                     "Attribute %d: '%s' (type=%d, size=%d, location=%d)", 
                     i, name.data(), type, size, location);
    }
    
}

// getExtensionFunctionPointer is now implemented in the wrapper

void HarmonyGLRendererBackend::updateViewPort() {
    assert(gfx::BackendScope::exists());
    assertOnCorrectThread();
    setViewport(0, 0, size);
}

void HarmonyGLRendererBackend::resizeFramebuffer(int width, int height) {
    // 必须在渲染线程调用
    assertOnCorrectThread();
    if (width <= 0 || height <= 0) {
        Logger::error("HarmonyGL", "❌ Invalid framebuffer size: %dx%d", width, height);
        return;
    }
    
    // Calculate physical pixel dimensions (DPI scaled for high-resolution rendering)
    uint32_t physicalWidth = static_cast<uint32_t>(width * pixelRatio_);
    uint32_t physicalHeight = static_cast<uint32_t>(height * pixelRatio_);
    
    size = {physicalWidth, physicalHeight};
    
    // ✅ 关键修复：更新 OpenGL viewport（如果 Context 已激活）
    // 这确保 framebuffer size 和 viewport 保持同步
    // 如果 Context 未激活，viewport 会在下次 activate() 时通过 updateAssumedState() 的和 setViewport() 自动更新
    if (gfx::BackendScope::exists()) {
        try {
            // 更新 Context 的 assumed viewport 状态（不触发断言）
            getContext<gl::Context>().viewport = {0, 0, size};
            
            // 如果 Context 当前已激活，立即调用 glViewport 更新
            EGLContext currentContext = eglGetCurrentContext();
            if (currentContext == eglContext_) {
                glViewport(0, 0, static_cast<GLsizei>(size.width), static_cast<GLsizei>(size.height));
            } else {
            }
        } catch (...) {
            Logger::warn("HarmonyGL", "⚠️ Failed to update viewport (Context may not be ready)");
        }
    } else {
    }
    
    // Set Native Window buffer geometry 
    // Note: Unlike Android's ANativeWindow which auto-syncs, HarmonyOS requires explicit call
    if (eglWindow_ != nullptr) {
        OHNativeWindow* nativeWindow = static_cast<OHNativeWindow*>(eglWindow_);
        
        if (nativeWindow != nullptr) {
            try {
                int32_t code = SET_BUFFER_GEOMETRY;
                int32_t ret = OH_NativeWindow_NativeWindowHandleOpt(
                    nativeWindow, 
                    code, 
                    static_cast<int32_t>(physicalWidth), 
                    static_cast<int32_t>(physicalHeight)
                );
                
                if (ret != 0) {
                    Logger::error("HarmonyGL", "❌ Failed to set buffer geometry: error=%d", ret);
                } else {
                }
            } catch (...) {
                Logger::error("HarmonyGL", "❌ Exception in OH_NativeWindow_NativeWindowHandleOpt");
            }
        } else {
            Logger::warn("HarmonyGL", "⚠️ Native window pointer is null");
        }
    } else {
        Logger::warn("HarmonyGL", "⚠️ eglWindow_ is null, cannot set buffer geometry");
    }
    
    // 🔍 验证 Surface 状态（如果已初始化）
    if (eglSurface_ != EGL_NO_SURFACE) {
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (display != EGL_NO_DISPLAY) {
            EGLint surfaceWidth = 0, surfaceHeight = 0;
            if (eglQuerySurface(display, eglSurface_, EGL_WIDTH, &surfaceWidth) &&
                eglQuerySurface(display, eglSurface_, EGL_HEIGHT, &surfaceHeight)) {
                if (static_cast<uint32_t>(surfaceWidth) != physicalWidth ||
                    static_cast<uint32_t>(surfaceHeight) != physicalHeight) {
                    Logger::warn("HarmonyGL", "⚠️ Surface size mismatch! Surface=%dx%d, Expected=%ux%u",
                                surfaceWidth, surfaceHeight, physicalWidth, physicalHeight);
                }
            } else {
                EGLint error = eglGetError();
                Logger::warn("HarmonyGL", "⚠️ Failed to query surface size: %s", eglErrorString(error));
            }
        }
    }
    
}

PremultipliedImage HarmonyGLRendererBackend::readFramebuffer() {
    assert(gfx::BackendScope::exists());
    assertOnCorrectThread();
    return getContext<gl::Context>().readFramebuffer<PremultipliedImage>(size);
}

// updateAssumedState is now implemented in the wrapper

void HarmonyGLRendererBackend::markContextLost() {
    static_cast<gl::Context&>(getContext()).setCleanupOnDestruction(false);
}

// activate and deactivate are handled by the wrapper

// setFramebufferBinding, setViewport, setScissorTest are inherited from gl::RendererBackend

mbgl::gl::ProcAddress HarmonyGLRendererBackend::getExtensionFunctionPointer(const char* name) {
    return reinterpret_cast<gl::ProcAddress>(eglGetProcAddress(name));
}

void HarmonyGLRendererBackend::updateAssumedState() {
    // 必须在渲染线程调用
    assertOnCorrectThread();
    // Update assumed OpenGL state
    // Note: We directly set GL state here to avoid assertion failures in HarmonyOS/FFRT environment.
    // GL commands may be processed asynchronously, causing glGet* functions to return stale values
    // immediately after setting state. Base class methods call assert() which fails in this scenario.
    
    // Set framebuffer binding directly (skip assumeFramebufferBinding which asserts)
    // Note: 0 != ImplicitFramebufferBinding, so assumeFramebufferBinding(0) would assert
    getContext<gl::Context>().bindFramebuffer.setCurrentValue(0);
    
    // Set viewport directly (skip setViewport which asserts)
    getContext<gl::Context>().viewport = {0, 0, size};
}

// initShaders is inherited from gl::RendererBackend

std::unique_ptr<gfx::Context> HarmonyGLRendererBackend::createContext() {
    // Create OpenGL context
    auto context = std::make_unique<gl::Context>(*this);
    context->enableDebugging();
    context->initializeExtensions(std::bind(&HarmonyGLRendererBackend::getExtensionFunctionPointer, this, std::placeholders::_1));
    return context;
}

// 🔒 线程安全检查方法
bool HarmonyGLRendererBackend::isOnCorrectThread() const {
    // 如果还没有记录所有者线程（首次调用），任何线程都可以
    if (ownerThreadId_ == std::thread::id()) {
        return true;
    }
    return std::this_thread::get_id() == ownerThreadId_;
}

void HarmonyGLRendererBackend::assertOnCorrectThread() const {
#ifdef DEBUG
    if (!isOnCorrectThread()) {
        auto currentId = std::this_thread::get_id();
        Logger::error("EGL", "❌ Context accessed from wrong thread!");
        Logger::error("EGL", "  Expected: %lu, Current: %lu", 
                      std::hash<std::thread::id>{}(ownerThreadId_),
                      std::hash<std::thread::id>{}(currentId));
        assert(false && "EGL Context accessed from wrong thread");
    }
#endif
}

void HarmonyGLRendererBackend::activate() {
    // 🔒 首次激活时记录所有者线程
    if (ownerThreadId_ == std::thread::id()) {
        ownerThreadId_ = std::this_thread::get_id();
    }
    
    // 🎯 允许跨线程调用：不强制断言，支持迁移到当前线程
    // 注意：RunLoop/Actor 可能调度到不同线程，这里只在后续 eglMakeCurrent 绑定
    (void)0;
    if (renderThreadId_ != std::thread::id()) {
        auto currentThread = std::this_thread::get_id();
        if (currentThread != renderThreadId_) {
            Logger::warn("HarmonyGLRendererBackend",
                         "⚠️ activate() called on different thread. Will migrate context. Prev=%lu, Curr=%lu",
                         std::hash<std::thread::id>{}(renderThreadId_),
                         std::hash<std::thread::id>{}(currentThread));
            // 不在此处返回，后续通过 eglMakeCurrent 迁移，并在成功后更新 renderThreadId_
        }
    }
    
    // 🛡️ 安全检查：如果渲染已停止，优雅降级（不抛出异常）
    // 原因：析构时 BackendScope 可能调用 activate()
    // 如果抛出异常会导致 std::terminate() → 崩溃
    if (isStopped_) {
        return;  // 直接返回，不激活
    }
    
    // 🛡️ 安全检查：验证Surface有效性
    // 析构时 Surface 可能已无效，不应抛出异常
    if (!isSurfaceValid()) {
        Logger::warn("HarmonyGLRendererBackend", "activate() failed: surface invalid (may be in cleanup)");
        return;  // 优雅降级，不抛出异常
    }
    
    // HarmonyOS渲染线程EGL Context管理
    // 首次调用时在渲染线程创建context，之后直接激活
    
    // 首次调用且在渲染线程 - 延迟创建context
    {
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (!contextInitialized_ && display != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        Logger::info("HarmonyGLRendererBackend", "activate() - First call on render thread, creating context...");
        if (!initializeEGLContext()) {
            Logger::error("HarmonyGLRendererBackend", "Failed to initialize EGL context on render thread");
            // 在析构时不要抛出异常
            if (isStopped_) {
                Logger::warn("HarmonyGLRendererBackend", "Skipping context init (cleanup in progress)");
                return;
            }
            throw std::runtime_error("Failed to initialize EGL context");
        }
        // initializeEGLContext()已经调用了eglMakeCurrent，所以context已经是current
        Logger::info("HarmonyGLRendererBackend", "activate() - Context created and activated successfully");
        return;
        }
    }
    
    // 移除手动线程验证 - EGL 自己会处理线程绑定
    // eglMakeCurrent() 会返回错误如果线程不正确
    // 这样避免了过于严格的验证导致正常渲染被阻止
    
    // Context已创建 - 直接激活
    {
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (eglContext_ != EGL_NO_CONTEXT && display != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        // ✅ 关键修复：将 eglGetCurrentContext() 也放到锁内
        // 确保 检查-激活 是原子操作，完全消除竞态条件
        std::lock_guard<std::mutex> lock(g_eglMutex);
        
        // 在锁内检查context是否已经current（性能优化）
        EGLContext currentContext = eglGetCurrentContext();
        if (currentContext == eglContext_) {
            // 已经是当前 Context，无需切换
            // 🔍 诊断日志：验证 viewport（即使 Context 已经是 current）
            GLint viewport[4];
            glGetIntegerv(GL_VIEWPORT, viewport);
            if (viewport[2] != static_cast<GLint>(size.width) || 
                viewport[3] != static_cast<GLint>(size.height)) {
                Logger::warn("HarmonyGL", "⚠️ Viewport size mismatch! Current=[%d, %d], Expected=[%u, %u] - Fixing...",
                            viewport[2], viewport[3], size.width, size.height);
                // ✅ 关键修复：主动修复 viewport 不匹配
                glViewport(0, 0, static_cast<GLsizei>(size.width), static_cast<GLsizei>(size.height));
                // 更新 Context 的 assumed viewport 状态
                if (gfx::BackendScope::exists()) {
                    getContext<gl::Context>().viewport = {0, 0, size};
                }
            }
            return;
        }
        
        // ✅ 在锁内切换 Context，不停止渲染，让错误自然恢复
        if (!eglMakeCurrent(display, eglSurface_, eglSurface_, eglContext_)) {
            EGLint error = eglGetError();
            Logger::error("HarmonyGLRendererBackend", 
                         "activate() FAILED to make context current: %s (error code: 0x%X)", 
                         eglErrorString(error), error);
            
            // ✅ 析构时不抛出异常，优雅返回
            if (isStopped_) {
                Logger::warn("HarmonyGLRendererBackend", "activate() failed but cleanup in progress, returning gracefully");
                return;
            }
            
            // ✅ 不停止渲染！让上层抛出异常或重试
            // 移除 pauseRendering() 调用，避免在未激活 Context 下执行 OpenGL 命令
            throw std::runtime_error("eglMakeCurrent failed: " + std::string(eglErrorString(error)));
        }
        
        // 🎯 迁移成功后，更新渲染线程 ID
        renderThreadId_ = std::this_thread::get_id();

        // 🔍 诊断日志：激活后验证 viewport 和 framebuffer 状态
        GLint viewport[4];
        glGetIntegerv(GL_VIEWPORT, viewport);
        GLint framebuffer = 0;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &framebuffer);
        
        if (viewport[2] != static_cast<GLint>(size.width) || 
            viewport[3] != static_cast<GLint>(size.height)) {
            Logger::warn("HarmonyGL", "⚠️ Viewport size mismatch after activate! Current=[%d, %d], Expected=[%u, %u] - Fixing...",
                        viewport[2], viewport[3], size.width, size.height);
            // ✅ 关键修复：主动修复 viewport 不匹配
            glViewport(0, 0, static_cast<GLsizei>(size.width), static_cast<GLsizei>(size.height));
            // 更新 Context 的 assumed viewport 状态
            if (gfx::BackendScope::exists()) {
                getContext<gl::Context>().viewport = {0, 0, size};
            }
        }
        
        GLenum glError = glGetError();
        if (glError != GL_NO_ERROR) {
            Logger::warn("HarmonyGL", "⚠️ OpenGL error after activate: 0x%X", glError);
        }
        } else {
        std::string error = "activate() failed: EGL not fully initialized (display=" + 
                           std::to_string(reinterpret_cast<uintptr_t>(display)) + 
                           ", surface=" + std::to_string(reinterpret_cast<uintptr_t>(eglSurface_)) +
                           ", context=" + std::to_string(reinterpret_cast<uintptr_t>(eglContext_)) + ")";
        Logger::error("HarmonyGLRendererBackend", "%s", error.c_str());
        
        // 析构时不抛出异常
        if (isStopped_) {
            Logger::warn("HarmonyGLRendererBackend", "Skipping exception (cleanup in progress)");
            return;
        }
        throw std::runtime_error(error);
        }
    }
}

void HarmonyGLRendererBackend::deactivate() {
    // HarmonyOS渲染线程单线程优化
    // 由于context只在渲染线程创建和使用，不需要频繁释放
    // 这是一个性能优化：保持context current避免频繁的bind/unbind开销
    
    // 注意：如果未来需要多线程访问GL资源，需要在这里真正释放context
    // 当前架构下，context只属于渲染线程，所以可以保持current
}

void HarmonyGLRendererBackend::swapBuffers() {
    // 降低日志噪音：移除每帧 swapBuffers 调试日志
    
    // 🛡️ 安全检查：如果渲染已停止，跳过swapBuffers
    if (isStopped_) {
        Logger::warn("HarmonyGL", "⚠️ swapBuffers() - skipped (rendering stopped)");
        return;
    }
    
    // 🔒 线程安全：确保在创建/渲染线程调用
    assertOnCorrectThread();

    // 🔍 诊断日志：验证 Surface 状态
    if (!isSurfaceValid()) {
        Logger::error("HarmonyGL", "❌ swapBuffers() - Surface validation failed");
        // 详细日志：检查 Surface 属性
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (display != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
            EGLint width = 0, height = 0;
            if (eglQuerySurface(display, eglSurface_, EGL_WIDTH, &width) &&
                eglQuerySurface(display, eglSurface_, EGL_HEIGHT, &height)) {
                Logger::error("HarmonyGL", "   Surface size: %dx%d (invalid if <= 0)", width, height);
            } else {
                EGLint error = eglGetError();
                Logger::error("HarmonyGL", "   Failed to query surface: %s", eglErrorString(error));
            }
        }
        return;
    }
    
    EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
    if (display != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        // 可选：仅在失败时打印 Surface 信息，避免每帧日志
        
        // HarmonyOS缓冲区刷新重试机制
        int retryCount = 0;
        const int maxRetries = 3;
        bool success = false;
        
        // 在首次尝试之前，确保 context 已经 current（避免首次即 BAD_SURFACE）
        {
            std::lock_guard<std::mutex> lock(g_eglMutex);
            EGLContext currentContext = eglGetCurrentContext();
            if (currentContext != eglContext_) {
                if (!eglMakeCurrent(display, eglSurface_, eglSurface_, eglContext_)) {
                    EGLint makeCurrentError = eglGetError();
                    Logger::error("HarmonyGL", "   Failed to make context current before swap: %s", eglErrorString(makeCurrentError));
                }
            }
        }

        while (retryCount < maxRetries && !success) {
            
            EGLBoolean swapResult = eglSwapBuffers(display, eglSurface_);
            if (swapResult) {
                success = true;
                
            } else {
                EGLint error = eglGetError();
                retryCount++;
                Logger::error("HarmonyGL", "❌ eglSwapBuffers FAILED (attempt %d/%d): %s (0x%X)",
                            retryCount, maxRetries, eglErrorString(error), error);
                
                // 🛡️ 如果是Surface相关错误，立即停止重试
                if (error == EGL_BAD_SURFACE || error == EGL_BAD_CURRENT_SURFACE) {
                    Logger::error("HarmonyGL", "   Surface invalid - stopping retry");
                    break;
                }
                
                if (retryCount < maxRetries) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                    // ✅ 添加锁保护，防止并发 eglMakeCurrent 调用
                    std::lock_guard<std::mutex> lock(g_eglMutex);
                    if (!eglMakeCurrent(display, eglSurface_, eglSurface_, eglContext_)) {
                        EGLint makeCurrentError = eglGetError();
                        Logger::error("HarmonyGL", "   Failed to restore context: %s", eglErrorString(makeCurrentError));
                    }
                }
            }
        }
        
        if (!success) {
            EGLint error = eglGetError();
            Logger::error("HarmonyGL", "❌ swapBuffers() FAILED after %d attempts: %s (0x%X)",
                         maxRetries, eglErrorString(error), error);
            Logger::warn("HarmonyGL", "   Skipping this frame, will retry next frame");
        }
    } else {
        Logger::error("HarmonyGL", "❌ Cannot swap buffers: display=%p, eglSurface=%p",
                     display, eglSurface_);
        Logger::error("HarmonyGL", "   displayAcquired_=%d, displayAcquired check=%s",
                     displayAcquired_ ? 1 : 0,
                     (display != EGL_NO_DISPLAY) ? "OK" : "FAILED");
    }
}

// assumeFramebufferBinding, assumeViewport, assumeScissorTest are inherited from gl::RendererBackend


// 🛡️ 新增：检查Surface有效性
bool HarmonyGLRendererBackend::isSurfaceValid() const {
    // ✅ 使用共享 Display（getDisplay 不增加引用计数）
    EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
    
    if (display == EGL_NO_DISPLAY || eglSurface_ == EGL_NO_SURFACE) {
        return false;
    }
    
    // 查询Surface属性来验证其有效性
    EGLint width = 0, height = 0;
    if (!eglQuerySurface(display, eglSurface_, EGL_WIDTH, &width) ||
        !eglQuerySurface(display, eglSurface_, EGL_HEIGHT, &height)) {
        return false;
    }
    
    // 宽度和高度必须大于0
    return (width > 0 && height > 0);
}

// 🛡️ 新增：暂停渲染（防止崩溃）
void HarmonyGLRendererBackend::pauseRendering() {
    Logger::info("HarmonyGLRendererBackend", "Pausing rendering to prevent crash");
    isStopped_ = true;
}

// 🛡️ 新增：恢复渲染
void HarmonyGLRendererBackend::resumeRendering() {
    Logger::info("HarmonyGLRendererBackend", "Resuming rendering");
    isStopped_ = false;
}

} // namespace harmony
} // namespace mbgl

namespace mbgl {
namespace gfx {

template <>
std::unique_ptr<Backend> Backend::Create<Backend::Type::OpenGL>(OHNativeWindow* window) {
    auto backend = std::make_unique<mbgl::harmony::HarmonyGLRendererBackend>();
    backend->setNativeWindow(window);
    return std::unique_ptr<Backend>(backend.release());
}

} // namespace gfx
} // namespace mbgl


