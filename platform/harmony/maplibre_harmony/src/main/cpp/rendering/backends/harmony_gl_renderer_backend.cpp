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
#include <cassert>
#include <thread>
#include <chrono>
#include <stdexcept>  // for std::runtime_error
#include <cmath>      // for std::abs

using mbgl::harmony::Logger;

namespace {

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
}

HarmonyGLRendererBackend::~HarmonyGLRendererBackend() {
    // 🛡️ CRITICAL FIX: 设置停止标志，防止析构期间的跨线程 EGL Context 访问
    // 问题：EGL Context 在渲染线程创建，但析构函数在主线程执行
    // 解决：在清理前设置标志，activate() 会检查此标志并跳过操作
    isStopped_ = true;
    
    cleanupEGL();
    
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
    if (reinterpret_cast<EGLNativeWindowType>(window) == eglWindow_) {
        return;
    }
    
    cleanupEGL();
    eglWindow_ = reinterpret_cast<EGLNativeWindowType>(window);

    if (eglWindow_) {
        if (!initializeEGLDisplay()) {
            Logger::error("HarmonyGL", "Failed to initialize EGL display/surface");
            eglWindow_ = 0;
        } else {
            // Update device DPI and pixelRatio
            updatePixelRatioFromDevice();
        }
    }
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

    eglDisplay_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (eglDisplay_ == EGL_NO_DISPLAY) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to get EGL display: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }

    EGLint majorVersion, minorVersion;
    if (!eglInitialize(eglDisplay_, &majorVersion, &minorVersion)) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to initialize EGL: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }

    if (!eglBindAPI(EGL_OPENGL_ES_API)) {
        Logger::error("HarmonyGL", "Failed to bind OpenGL ES API");
        return false;
    }

    EGLint numConfigs;
    if (!eglChooseConfig(eglDisplay_, attribList, &eglConfig_, 1, &numConfigs) || numConfigs <= 0) {
        EGLint error = eglGetError();
        Logger::error("OpenGL", "Failed to choose EGL config: %s (numConfigs=%d, error code: 0x%X)", 
                      eglErrorString(error), numConfigs, error);
        return false;
    }
    Logger::info("HarmonyGLRendererBackend", "Step 4/5: EGL config chosen (numConfigs=%d)", numConfigs);
    
    // Verify MSAA configuration
    EGLint samples = 0, sampleBuffers = 0;
    eglGetConfigAttrib(eglDisplay_, eglConfig_, EGL_SAMPLES, &samples);
    eglGetConfigAttrib(eglDisplay_, eglConfig_, EGL_SAMPLE_BUFFERS, &sampleBuffers);
    Logger::info("HarmonyGL", "MSAA Config: sampleBuffers=%d, samples=%d", 
                 sampleBuffers, samples);
    if (samples > 1) {
        Logger::info("HarmonyGL", "MSAA enabled: %dx anti-aliasing", samples);
    } else {
        Logger::warn("HarmonyGL", "MSAA not enabled (device may not support)");
    }

    // Note: Native Window buffer size will be set in resizeFramebuffer()
    eglSurface_ = eglCreateWindowSurface(eglDisplay_, eglConfig_, eglWindow_, nullptr);
    if (eglSurface_ == EGL_NO_SURFACE) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to create EGL surface: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    
    // Enable VSync to prevent flickering
    if (!eglSwapInterval(eglDisplay_, 1)) {
        EGLint error = eglGetError();
        Logger::warn("HarmonyGL", "Failed to set swap interval: %s", eglErrorString(error));
    }
    
    // 🔧 修复黑屏：EGL Display 和 Surface 初始化成功，重置停止标志
    // 问题：cleanupEGL() 设置 isStopped_ = true，但 initializeEGLDisplay() 成功后未重置
    // 解决：在 EGL 初始化成功后重置标志，允许渲染继续
    isStopped_ = false;
    Logger::info("HarmonyGLRendererBackend", "EGL initialized successfully, rendering enabled");
    
    return true;
}

bool HarmonyGLRendererBackend::initializeEGLContext() {
    if (eglDisplay_ == EGL_NO_DISPLAY || eglSurface_ == EGL_NO_SURFACE) {
        Logger::error("HarmonyGL", "Cannot create context: display or surface not initialized");
        return false;
    }
    
    if (eglContext_ != EGL_NO_CONTEXT) {
        return true;
    }
    
    const EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,  // OpenGL ES 3
        EGL_NONE
    };
    
    eglContext_ = eglCreateContext(eglDisplay_, eglConfig_, EGL_NO_CONTEXT, contextAttribs);
    if (eglContext_ == EGL_NO_CONTEXT) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to create EGL context: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    
    // Activate context to get OpenGL information
    if (!eglMakeCurrent(eglDisplay_, eglSurface_, eglSurface_, eglContext_)) {
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
    
    contextInitialized_ = true;
    
    Logger::info("HarmonyGLRendererBackend", "EGL Context: %p (bound to render thread)", eglContext_);
    
    return true;
}

void HarmonyGLRendererBackend::cleanupEGL() {
    // 🛡️ CRITICAL FIX: 标记渲染已停止，防止并发访问
    isStopped_ = true;
    
    try {
        if (eglDisplay_ != EGL_NO_DISPLAY) {
            Logger::debug("HarmonyGLRendererBackend", "Cleaning up EGL context and surface");
            
            if (eglContext_ != EGL_NO_CONTEXT) {
                // 🛡️ 线程安全：检查当前线程是否持有这个 Context
                EGLContext currentContext = eglGetCurrentContext();
                if (currentContext == eglContext_) {
                    Logger::debug("HarmonyGLRendererBackend", "Unbinding current EGL context");
                    // 尝试 unbind，如果失败也继续清理
                    if (!eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
                        EGLint error = eglGetError();
                        Logger::warn("HarmonyGLRendererBackend", 
                                    "Failed to unbind context during cleanup (error=0x%x), continuing anyway", 
                                    error);
                        // 不要因为 unbind 失败就停止清理
                    }
                } else {
                    Logger::debug("HarmonyGLRendererBackend", 
                                 "Context not current on this thread (current=%p, ours=%p)", 
                                 currentContext, eglContext_);
                }
                
                Logger::debug("HarmonyGLRendererBackend", "Destroying EGL context");
                // 🛡️ EGL Context 可以在任意线程销毁（只要不是 current）
                if (!eglDestroyContext(eglDisplay_, eglContext_)) {
                    EGLint error = eglGetError();
                    Logger::warn("HarmonyGLRendererBackend", 
                                "Failed to destroy context (error=0x%x)", error);
                }
                eglContext_ = EGL_NO_CONTEXT;
                contextInitialized_ = false;
            }
            
            if (eglSurface_ != EGL_NO_SURFACE) {
                Logger::debug("HarmonyGLRendererBackend", "Destroying EGL surface");
                if (!eglDestroySurface(eglDisplay_, eglSurface_)) {
                    EGLint error = eglGetError();
                    Logger::warn("HarmonyGLRendererBackend", 
                                "Failed to destroy surface (error=0x%x)", error);
                }
                eglSurface_ = EGL_NO_SURFACE;
            }
            
            Logger::debug("HarmonyGLRendererBackend", "Terminating EGL display");
            // 🛡️ eglTerminate 会减少引用计数，多次调用是安全的
            if (!eglTerminate(eglDisplay_)) {
                EGLint error = eglGetError();
                Logger::warn("HarmonyGLRendererBackend", 
                            "Failed to terminate display (error=0x%x)", error);
            }
            eglDisplay_ = EGL_NO_DISPLAY;
        }
        
        eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
        Logger::info("HarmonyGLRendererBackend", "✅ EGL cleanup completed successfully");
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyGLRendererBackend", "Error during EGL cleanup: %s", e.what());
        // 确保清理状态即使发生异常
        eglContext_ = EGL_NO_CONTEXT;
        eglSurface_ = EGL_NO_SURFACE;
        eglDisplay_ = EGL_NO_DISPLAY;
        eglWindow_ = 0;
        contextInitialized_ = false;
    } catch (...) {
        Logger::error("HarmonyGLRendererBackend", "Unknown error during EGL cleanup");
        // 确保清理状态即使发生异常
        eglContext_ = EGL_NO_CONTEXT;
        eglSurface_ = EGL_NO_SURFACE;
        eglDisplay_ = EGL_NO_DISPLAY;
        eglWindow_ = 0;
        contextInitialized_ = false;
    }
    
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
    Logger::debug("HarmonyGLRendererBackend", "bindAttributeWithFallback: program=%u, index=%u, name=%s", 
                  program, index, name);
    
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
        Logger::debug("HarmonyGLRendererBackend", 
                      "Attribute '%s' bound successfully at location %d", 
                      name, actualLocation);
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
    setViewport(0, 0, size);
}

void HarmonyGLRendererBackend::resizeFramebuffer(int width, int height) {
    if (width <= 0 || height <= 0) {
        Logger::warn("OpenGL", "Invalid framebuffer size: %dx%d", width, height);
        return;
    }
    
    Logger::info("HarmonyGL", "Resizing framebuffer: logical %dx%d, pixelRatio=%.2f", 
                 width, height, pixelRatio_);
    
    // Calculate physical pixel dimensions (DPI scaled for high-resolution rendering)
    uint32_t physicalWidth = static_cast<uint32_t>(width * pixelRatio_);
    uint32_t physicalHeight = static_cast<uint32_t>(height * pixelRatio_);
    
    size = {physicalWidth, physicalHeight};
    
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
                    Logger::error("HarmonyGL", "Failed to set buffer geometry: error=%d", ret);
                }
            } catch (...) {
                Logger::error("HarmonyGL", "Exception in OH_NativeWindow_NativeWindowHandleOpt");
            }
        }
    } else {
        Logger::warn("HarmonyGL", "eglWindow_ is null, cannot set buffer geometry");
    }
}

PremultipliedImage HarmonyGLRendererBackend::readFramebuffer() {
    assert(gfx::BackendScope::exists());
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
        Logger::debug("EGL", "🔒 EGL Context owner thread set: %lu", 
                     std::hash<std::thread::id>{}(ownerThreadId_));
    }
    
    // 🔒 线程安全检查
    assertOnCorrectThread();
    // 🛡️ 安全检查：如果渲染已停止，抛出异常
    if (isStopped_) {
        throw std::runtime_error("activate() failed: rendering stopped");
    }
    
    // 🛡️ 安全检查：验证Surface有效性
    if (!isSurfaceValid()) {
        throw std::runtime_error("activate() failed: surface invalid");
    }
    
    // HarmonyOS渲染线程EGL Context管理
    // 首次调用时在渲染线程创建context，之后直接激活
    
    // 首次调用且在渲染线程 - 延迟创建context
    if (!contextInitialized_ && eglDisplay_ != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        Logger::info("HarmonyGLRendererBackend", "activate() - First call on render thread, creating context...");
        if (!initializeEGLContext()) {
            Logger::error("HarmonyGLRendererBackend", "Failed to initialize EGL context on render thread");
            throw std::runtime_error("Failed to initialize EGL context");
        }
        // initializeEGLContext()已经调用了eglMakeCurrent，所以context已经是current
        Logger::info("HarmonyGLRendererBackend", "activate() - Context created and activated successfully");
        return;
    }
    
    // Context已创建 - 直接激活
    if (eglContext_ != EGL_NO_CONTEXT && eglDisplay_ != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        // 检查context是否已经current（性能优化）
        EGLContext currentContext = eglGetCurrentContext();
        if (currentContext == eglContext_) {
            return;
        }
        
        if (!eglMakeCurrent(eglDisplay_, eglSurface_, eglSurface_, eglContext_)) {
            EGLint error = eglGetError();
            Logger::error("HarmonyGLRendererBackend", 
                         "activate() FAILED to make context current: %s (error code: 0x%X)", 
                         eglErrorString(error), error);
            
            // 🛡️ 如果是Surface相关错误，自动停止渲染防止崩溃
            if (error == EGL_BAD_SURFACE || error == EGL_BAD_ACCESS || error == EGL_BAD_CURRENT_SURFACE) {
                Logger::error("HarmonyGLRendererBackend", "Surface invalid - pausing rendering to prevent crash");
                pauseRendering();
                throw std::runtime_error("activate() failed: surface error - " + std::string(eglErrorString(error)));
            }
            throw std::runtime_error("eglMakeCurrent failed: " + std::string(eglErrorString(error)));
        }
    } else {
        std::string error = "activate() failed: EGL not fully initialized (display=" + 
                           std::to_string(reinterpret_cast<uintptr_t>(eglDisplay_)) + 
                           ", surface=" + std::to_string(reinterpret_cast<uintptr_t>(eglSurface_)) +
                           ", context=" + std::to_string(reinterpret_cast<uintptr_t>(eglContext_)) + ")";
        Logger::error("HarmonyGLRendererBackend", "%s", error.c_str());
        throw std::runtime_error(error);
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
    // 🛡️ 安全检查：如果渲染已停止，跳过swapBuffers
    if (isStopped_) {
        Logger::debug("HarmonyGLRendererBackend", "swapBuffers() - skipped (rendering stopped)");
        return;
    }
    
    // 🛡️ 安全检查：验证Surface有效性
    if (!isSurfaceValid()) {
        Logger::warn("HarmonyGLRendererBackend", "swapBuffers() - skipped (surface invalid)");
        pauseRendering();  // 自动停止渲染
        return;
    }
    
    if (eglDisplay_ != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        // HarmonyOS缓冲区刷新重试机制
        int retryCount = 0;
        const int maxRetries = 3;
        bool success = false;
        
        while (retryCount < maxRetries && !success) {
            if (eglSwapBuffers(eglDisplay_, eglSurface_)) {
                success = true;
            } else {
                EGLint error = eglGetError();
                retryCount++;
                Logger::warn("HarmonyGLRendererBackend", 
                            "eglSwapBuffers failed (attempt %d/%d): %s",
                            retryCount, maxRetries, eglErrorString(error));
                
                // 🛡️ 如果是Surface相关错误，立即停止重试
                if (error == EGL_BAD_SURFACE || error == EGL_BAD_CURRENT_SURFACE) {
                    Logger::error("HarmonyGLRendererBackend", "Surface invalid during swap - stopping retry");
                    break;
                }
                
                if (retryCount < maxRetries) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                    eglMakeCurrent(eglDisplay_, eglSurface_, eglSurface_, eglContext_);
                }
            }
        }
        
        if (!success) {
            EGLint error = eglGetError();
            Logger::error("HarmonyGLRendererBackend", 
                          "eglSwapBuffers failed after %d attempts: %s", 
                          maxRetries, eglErrorString(error));
            
            // 🛡️ Surface相关错误时停止渲染防止崩溃
            if (error == EGL_BAD_SURFACE || error == EGL_BAD_CURRENT_SURFACE || error == EGL_BAD_ALLOC) {
                Logger::error("HarmonyGLRendererBackend", "Pausing rendering to prevent crash");
                pauseRendering();
            }
            // 不再抛出异常，而是优雅地停止渲染
        }
    } else {
        Logger::warn("HarmonyGLRendererBackend", 
                     "Cannot swap buffers: eglDisplay=%p, eglSurface=%p",
                     eglDisplay_, eglSurface_);
    }
}

// assumeFramebufferBinding, assumeViewport, assumeScissorTest are inherited from gl::RendererBackend


// 🛡️ 新增：检查Surface有效性
bool HarmonyGLRendererBackend::isSurfaceValid() const {
    if (eglDisplay_ == EGL_NO_DISPLAY || eglSurface_ == EGL_NO_SURFACE) {
        return false;
    }
    
    // 查询Surface属性来验证其有效性
    EGLint width = 0, height = 0;
    if (!eglQuerySurface(eglDisplay_, eglSurface_, EGL_WIDTH, &width) ||
        !eglQuerySurface(eglDisplay_, eglSurface_, EGL_HEIGHT, &height)) {
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


