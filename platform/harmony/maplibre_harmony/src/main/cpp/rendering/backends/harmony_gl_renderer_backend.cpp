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
#include <sstream>    // for thread ID logging

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

    // 【多实例优化】类似 Android 的做法：EGL Display 是进程级别共享资源
    // 每次获取 EGL_DEFAULT_DISPLAY 都会返回相同的 Display 对象
    // 即使多个实例调用 eglGetDisplay 也不会有问题，因为它们共享同一个 Display
    eglDisplay_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (eglDisplay_ == EGL_NO_DISPLAY) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to get EGL display: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    Logger::debug("HarmonyGL", "Got EGL Display: %p (shared across all instances)", eglDisplay_);

    // 【多实例安全】eglInitialize 可以被多次调用，内部有引用计数
    // 如果 Display 已经初始化，这个调用会增加引用计数并立即返回成功
    EGLint majorVersion, minorVersion;
    if (!eglInitialize(eglDisplay_, &majorVersion, &minorVersion)) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to initialize EGL: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    Logger::info("HarmonyGL", "EGL Display initialized (or reused): version %d.%d", 
                 majorVersion, minorVersion);

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
    
    // 🔄 线程绑定（Android 风格）：记录创建 Context 的线程
    contextThreadId_ = std::this_thread::get_id();
    contextThreadBound_ = true;
    
    // 🔍 详细日志：记录 Context 绑定的线程
    std::ostringstream threadInfo;
    threadInfo << contextThreadId_;
    Logger::info("HarmonyGLRendererBackend", 
        "✅ EGL Context created and bound:\n"
        "   Context: %p\n"
        "   Bound to thread: %s\n"
        "   This Context can ONLY be used on this thread!", 
        eglContext_, threadInfo.str().c_str());
    
    return true;
}

void HarmonyGLRendererBackend::cleanupEGL() {
    // 实例标识（用于多实例调试）
    static int cleanupCounter = 0;
    int cleanupId = ++cleanupCounter;
    
    try {
        if (eglDisplay_ != EGL_NO_DISPLAY) {
            Logger::info("HarmonyGLRendererBackend", 
                        "🧹 [Cleanup #%d] Cleaning up EGL resources (Context=%p, Surface=%p, Display=%p)", 
                        cleanupId, eglContext_, eglSurface_, eglDisplay_);
            
            if (eglContext_ != EGL_NO_CONTEXT) {
                // 确保当前没有EGL上下文
                EGLContext currentContext = eglGetCurrentContext();
                if (currentContext == eglContext_) {
                    Logger::debug("HarmonyGLRendererBackend", "[Cleanup #%d] Unbinding current EGL context", cleanupId);
                    eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
                }
                
                Logger::debug("HarmonyGLRendererBackend", "[Cleanup #%d] Destroying EGL context: %p", cleanupId, eglContext_);
                eglDestroyContext(eglDisplay_, eglContext_);
                eglContext_ = EGL_NO_CONTEXT;
                contextInitialized_ = false;  // 重置标志
            }
            
            if (eglSurface_ != EGL_NO_SURFACE) {
                Logger::debug("HarmonyGLRendererBackend", "[Cleanup #%d] Destroying EGL surface: %p", cleanupId, eglSurface_);
                eglDestroySurface(eglDisplay_, eglSurface_);
                eglSurface_ = EGL_NO_SURFACE;
            }
            
            // ⚠️ 【多实例修复关键】不要调用 eglTerminate(eglDisplay_) ！
            // 
            // EGL Display 是进程级别的共享资源（类似 Android/iOS），如果在这里终止：
            // 1. 会破坏同一进程中其他地图实例的 EGL 上下文
            // 2. 导致后续创建的地图实例出现白屏/黑屏/渲染失败
            // 3. 系统会在进程退出时自动清理 EGL Display
            //
            // 修复效果：
            // - 修复前：第一个地图正常，第二个白屏，第三个黑屏
            // - 修复后：多个地图实例可以同时正常运行
            //
            // 参考：
            // - Android 的 AndroidGLRendererBackend 不调用 eglTerminate
            // - iOS 的 MLNMapViewOpenGLImpl 每个实例独立管理 EAGLContext
            Logger::info("HarmonyGLRendererBackend", 
                        "[Cleanup #%d] ✅ Keeping EGL Display alive for other instances (NOT calling eglTerminate)", 
                        cleanupId);
            
            // 只重置 display 引用，不销毁（Display 会由系统在进程结束时清理）
            eglDisplay_ = EGL_NO_DISPLAY;
        }
        
        eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
        Logger::info("HarmonyGLRendererBackend", 
                    "[Cleanup #%d] ✅ EGL cleanup completed successfully (Display preserved for other instances)", 
                    cleanupId);
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyGLRendererBackend", "[Cleanup #%d] ❌ Error during EGL cleanup: %s", cleanupId, e.what());
    } catch (...) {
        Logger::error("HarmonyGLRendererBackend", "[Cleanup #%d] ❌ Unknown error during EGL cleanup", cleanupId);
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

void HarmonyGLRendererBackend::activate() {
    // 🔍 日志：记录activate调用
    std::ostringstream callerThread;
    callerThread << std::this_thread::get_id();
    Logger::debug("HarmonyGLRendererBackend", "🔓 activate() called from thread=%s", callerThread.str().c_str());
    
    // 🛡️ 安全检查：如果渲染已停止，跳过激活
    if (isStopped_) {
        Logger::debug("HarmonyGLRendererBackend", "activate() - skipped (rendering stopped)");
        return;
    }
    
    // 🛡️ 安全检查：验证Surface有效性
    if (!isSurfaceValid()) {
        Logger::warn("HarmonyGLRendererBackend", "activate() - skipped (surface invalid)");
        return;
    }
    
    // 🛡️ 线程安全检查：Context 必须在创建线程使用（Android/iOS 模式）
    if (contextThreadBound_) {
        auto currentThreadId = std::this_thread::get_id();
        if (currentThreadId != contextThreadId_) {
            // 🔍 详细的线程信息
            std::ostringstream expected, actual;
            expected << contextThreadId_;
            actual << currentThreadId;
            
            Logger::error("HarmonyGLRendererBackend", 
                "❌ FATAL: EGL Context thread violation!\n"
                "  Context %p created on thread: %s\n"
                "  Called from thread:           %s\n"
                "  This will cause rendering corruption!\n"
                "  EGL Context MUST be used on the thread it was created on.",
                eglContext_, expected.str().c_str(), actual.str().c_str());
            
            // 抛出异常防止继续执行（避免 OpenGL 状态混乱）
            throw std::runtime_error(
                "EGL Context thread violation: Context must be used on the thread it was created on");
        } else {
            Logger::debug("HarmonyGLRendererBackend", "✅ Thread validation passed (thread=%s)", callerThread.str().c_str());
        }
    }
    
    // HarmonyOS渲染线程EGL Context管理
    // 首次调用时在渲染线程创建context，之后直接激活
    
    // 首次调用且在渲染线程 - 延迟创建context
    if (!contextInitialized_ && eglDisplay_ != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        Logger::info("HarmonyGLRendererBackend", "🆕 activate() - First call on render thread, creating context...");
        if (!initializeEGLContext()) {
            Logger::error("HarmonyGLRendererBackend", "❌ Failed to initialize EGL context on render thread");
            return;
        }
        // initializeEGLContext()已经调用了eglMakeCurrent，所以context已经是current
        Logger::info("HarmonyGLRendererBackend", "✅ activate() - Context created and activated successfully");
        return;
    }
    
    // Context已创建 - 直接激活
    if (eglContext_ != EGL_NO_CONTEXT && eglDisplay_ != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        // 检查context是否已经current（性能优化）
        EGLContext currentContext = eglGetCurrentContext();
        if (currentContext == eglContext_) {
            Logger::debug("HarmonyGLRendererBackend", "✅ Context already current, skipping eglMakeCurrent");
            return;
        }
        
        Logger::debug("HarmonyGLRendererBackend", "🔄 Calling eglMakeCurrent (context=%p, surface=%p)", eglContext_, eglSurface_);
        
        if (!eglMakeCurrent(eglDisplay_, eglSurface_, eglSurface_, eglContext_)) {
            EGLint error = eglGetError();
            Logger::error("HarmonyGLRendererBackend", 
                         "❌ activate() FAILED to make context current: %s (error code: 0x%X)", 
                         eglErrorString(error), error);
            
            // 🛡️ 如果是Surface相关错误，自动停止渲染防止崩溃
            if (error == EGL_BAD_SURFACE || error == EGL_BAD_ACCESS || error == EGL_BAD_CURRENT_SURFACE) {
                Logger::error("HarmonyGLRendererBackend", "Surface invalid - pausing rendering to prevent crash");
                pauseRendering();
            }
        } else {
            Logger::debug("HarmonyGLRendererBackend", "✅ eglMakeCurrent succeeded");
        }
    } else {
        Logger::warn("HarmonyGLRendererBackend", 
                    "⚠️ activate() called but EGL not fully initialized (display=%p, surface=%p, context=%p)",
                    eglDisplay_, eglSurface_, eglContext_);
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
    
    // 🔍 详细日志：记录 swapBuffers 调用
    Logger::debug("HarmonyGLRendererBackend", 
        "⏳ swapBuffers called (display=%p, surface=%p, context=%p)",
        eglDisplay_, eglSurface_, eglContext_);
    
    if (eglDisplay_ != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        // HarmonyOS缓冲区刷新重试机制
        int retryCount = 0;
        const int maxRetries = 3;
        bool success = false;
        
        while (retryCount < maxRetries && !success) {
            if (eglSwapBuffers(eglDisplay_, eglSurface_)) {
                success = true;
                Logger::debug("HarmonyGLRendererBackend", "✅ swapBuffers SUCCESS");
            } else {
                EGLint error = eglGetError();
                retryCount++;
                Logger::warn("HarmonyGLRendererBackend", 
                            "⚠️ eglSwapBuffers failed (attempt %d/%d): %s (0x%X)",
                            retryCount, maxRetries, eglErrorString(error), error);
                
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
                          "❌ swapBuffers FAILED after %d attempts: %s (0x%X)", 
                          maxRetries, eglErrorString(error), error);
            
            // 🛡️ Surface相关错误时停止渲染防止崩溃
            if (error == EGL_BAD_SURFACE || error == EGL_BAD_CURRENT_SURFACE || error == EGL_BAD_ALLOC) {
                Logger::error("HarmonyGLRendererBackend", "Pausing rendering to prevent crash");
                pauseRendering();
            }
            // 不再抛出异常，而是优雅地停止渲染
        }
    } else {
        Logger::warn("HarmonyGLRendererBackend", 
                     "⚠️ swapBuffers skipped: invalid display/surface (display=%p, surface=%p)",
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


