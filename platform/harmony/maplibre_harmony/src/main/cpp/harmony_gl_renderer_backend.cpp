#include "harmony_gl_renderer_backend.hpp"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gl/context.hpp>
#include <mbgl/gl/renderable_resource.hpp>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <native_window/external_window.h>
#include <window_manager/oh_display_manager.h>
#include "logger.h"
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
    cleanupEGL();
#ifndef NDEBUG
    if (static_cast<gl::Context&>(getContext()).getCleanupOnDestruction()) {
        assert(eglGetCurrentContext() != EGL_NO_CONTEXT);
    }
#endif
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
    
    try {
        if (eglDisplay_ != EGL_NO_DISPLAY) {
            Logger::debug("HarmonyGLRendererBackend", "Cleaning up EGL context and surface");
            
            if (eglContext_ != EGL_NO_CONTEXT) {
                // 确保当前没有EGL上下文
                EGLContext currentContext = eglGetCurrentContext();
                if (currentContext == eglContext_) {
                    Logger::debug("HarmonyGLRendererBackend", "Unbinding current EGL context");
                    eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
                }
                
                Logger::debug("HarmonyGLRendererBackend", "Destroying EGL context");
                eglDestroyContext(eglDisplay_, eglContext_);
                eglContext_ = EGL_NO_CONTEXT;
                contextInitialized_ = false;  // 重置标志
            }
            
            if (eglSurface_ != EGL_NO_SURFACE) {
                Logger::debug("HarmonyGLRendererBackend", "Destroying EGL surface");
                eglDestroySurface(eglDisplay_, eglSurface_);
                eglSurface_ = EGL_NO_SURFACE;
            }
            
            Logger::debug("HarmonyGLRendererBackend", "Terminating EGL display");
            eglTerminate(eglDisplay_);
            eglDisplay_ = EGL_NO_DISPLAY;
        }
        
        eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
        Logger::info("HarmonyGLRendererBackend", "EGL cleanup completed successfully");
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyGLRendererBackend", "Error during EGL cleanup: %s", e.what());
    } catch (...) {
        Logger::error("HarmonyGLRendererBackend", "Unknown error during EGL cleanup");
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
    
    Logger::debug("HarmonyGLRendererBackend", "updateAssumedState: viewport=(0, 0, %u, %u) logical pixels", 
                  size.width, size.height);
    
    // Set framebuffer binding directly (skip assumeFramebufferBinding which asserts)
    // Note: 0 != ImplicitFramebufferBinding, so assumeFramebufferBinding(0) would assert
    getContext<gl::Context>().bindFramebuffer.setCurrentValue(0);
    
    // Set viewport directly (skip setViewport which asserts)
    getContext<gl::Context>().viewport = {0, 0, size};
    
    Logger::debug("HarmonyGLRendererBackend", "updateAssumedState complete");
}

// initShaders is inherited from gl::RendererBackend

std::unique_ptr<gfx::Context> HarmonyGLRendererBackend::createContext() {
    // Create OpenGL context
    auto context = std::make_unique<gl::Context>(*this);
    context->enableDebugging();
    context->initializeExtensions(std::bind(&HarmonyGLRendererBackend::getExtensionFunctionPointer, this, std::placeholders::_1));
    return context;
}

void HarmonyGLRendererBackend::activate() {
    // HarmonyOS渲染线程EGL Context管理
    // 首次调用时在渲染线程创建context，之后直接激活
    
    // 首次调用且在渲染线程 - 延迟创建context
    if (!contextInitialized_ && eglDisplay_ != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        Logger::info("HarmonyGLRendererBackend", "activate() - First call on render thread, creating context...");
        if (!initializeEGLContext()) {
            Logger::error("HarmonyGLRendererBackend", "Failed to initialize EGL context on render thread");
            return;
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
            Logger::debug("HarmonyGLRendererBackend", "activate() - context already current");
            return;
        }
        
        Logger::debug("HarmonyGLRendererBackend", 
                     "activate() - making context current (display=%p, surface=%p, context=%p)",
                     eglDisplay_, eglSurface_, eglContext_);
        
        if (!eglMakeCurrent(eglDisplay_, eglSurface_, eglSurface_, eglContext_)) {
            EGLint error = eglGetError();
            Logger::error("HarmonyGLRendererBackend", 
                         "activate() FAILED to make context current: %s (error code: 0x%X)", 
                         eglErrorString(error), error);
        } else {
            Logger::debug("HarmonyGLRendererBackend", "activate() - GL context successfully activated");
        }
    } else {
        Logger::warn("HarmonyGLRendererBackend", 
                    "activate() called but EGL not fully initialized (display=%p, surface=%p, context=%p)",
                    eglDisplay_, eglSurface_, eglContext_);
    }
}

void HarmonyGLRendererBackend::deactivate() {
    // HarmonyOS渲染线程单线程优化
    // 由于context只在渲染线程创建和使用，不需要频繁释放
    // 这是一个性能优化：保持context current避免频繁的bind/unbind开销
    
    Logger::debug("HarmonyGLRendererBackend", "deactivate() - keeping context current for performance (single-thread mode)");
    
    // 注意：如果未来需要多线程访问GL资源，需要在这里真正释放context
    // 当前架构下，context只属于渲染线程，所以可以保持current
}

void HarmonyGLRendererBackend::swapBuffers() {
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
            
            // Stop rendering on swap failure to prevent crashes
            throw std::runtime_error("eglSwapBuffers failed: EGL buffer allocation failed");
        }
    } else {
        Logger::warn("HarmonyGLRendererBackend", 
                     "Cannot swap buffers: eglDisplay=%p, eglSurface=%p",
                     eglDisplay_, eglSurface_);
    }
}

// assumeFramebufferBinding, assumeViewport, assumeScissorTest are inherited from gl::RendererBackend


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


