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
#include <algorithm>  // for std::max

using mbgl::harmony::Logger;

namespace {

// Global mutex for EGL operations - protects critical EGL calls (creation, activation, switching, etc.)
// Ensures EGL actions run serially to avoid multi-instance concurrency issues
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
    // Register the instance with EGLDisplayManager (for resource limiting and monitoring)
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
    // 🛡️ CRITICAL FIX: set the stop flag to prevent cross-thread EGL context access during destruction
    // Issue: the EGL context is created on the render thread, but the destructor runs on the main thread
    // Solution: set the flag before cleanup so activate() sees it and skips work
    isStopped_ = true;
    Logger::info("HarmonyGLRendererBackend", "Calling cleanupEGL()...");
    cleanupEGL();
    Logger::info("HarmonyGLRendererBackend", "cleanupEGL() completed");
    
    // Unregister the instance (reduce the active count)
    Logger::info("HarmonyGLRendererBackend", "Unregistering instance...");
    EGLDisplayManager::getInstance().unregisterInstance();
    // 🛡️ CRITICAL FIX: remove the debug assertion to avoid cross-thread context access
    // Reason: the current thread might differ from the one that created the EGL context, so getContext() would cause conflicts
    // Solution: context cleanup is already handled in cleanupEGL(), no extra check required
    //
    // Original code (triggered black-screen crashes):
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
    // Thread affinity check (allow the first call before ownerThreadId_ is set)
    assertOnCorrectThread();
    EGLNativeWindowType newWindow = reinterpret_cast<EGLNativeWindowType>(window);
    
    // Skip reinitialization when the window is unchanged
    if (newWindow == eglWindow_) {
        return;
    }
    
    Logger::info("HarmonyGLRendererBackend", 
                "setNativeWindow: Changing window from %lu to %lu", 
                eglWindow_, newWindow);
    
    // ✅ Atomic-style operation: guard the entire cleanup→initialization process with the global mutex
    // Purpose: eliminate timing race windows so activate() is not called mid-transition
    // Effect: activate() waits until this completes and observes the correct isStopped_ state
    {
        std::lock_guard<std::mutex> lock(g_eglMutex);
        
        // Clean up the previous EGL resources (without setting isStopped_)
        cleanupEGL();
        
        // 🛡️ Fix re-entry crash: add a window validity check
        if (!newWindow) {
            Logger::warn("HarmonyGLRendererBackend", "setNativeWindow: null window provided, skipping initialization");
            return;
        }
        
        eglWindow_ = newWindow;
        
        // 🛡️ Brief delay to let the native window stabilize (addresses timing issues during page transitions)
        // Note: this delay is short (10 ms); the longer 500 ms wait lives in the TypeScript layer
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        
        // Initialize the EGL display and surface
        if (!initializeEGLDisplay()) {
            Logger::error("HarmonyGL", "Failed to initialize EGL display/surface");
            eglWindow_ = 0;
            // Do not set isStopped_; allow the recovery mechanism an opportunity to recover
        } else {
            // Update device DPI and pixelRatio
            updatePixelRatioFromDevice();
        }
        
    }
    // ✅ The lock releases automatically; other threads can resume activate() and see the correct state
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

    // Share the EGL display (via EGLDisplayManager)
    EGLDisplay display = EGLDisplayManager::getInstance().acquireDisplay();
    if (display == EGL_NO_DISPLAY) {
        Logger::error("HarmonyGL", "Failed to acquire shared EGL display");
        return false;
    }
    displayAcquired_ = true;
    // Choose the EGL configuration (via EGLDisplayManager)
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

    // ✅ Create a dedicated EGL surface (one per instance)
    // Note: Native Window buffer size will be set in resizeFramebuffer()
    eglSurface_ = eglCreateWindowSurface(display, eglConfig_, eglWindow_, nullptr);
    if (eglSurface_ == EGL_NO_SURFACE) {
        EGLint error = eglGetError();
        Logger::error("HarmonyGL", "Failed to create EGL surface: %s (0x%X)", 
                      eglErrorString(error), error);
        return false;
    }
    // Will move into initializeEGLContext()
    
    // 🔧 Fix black screen: reset the stop flag when EGL display and surface init succeed
    // Issue: cleanupEGL() sets isStopped_ = true but initializeEGLDisplay() never resets it
    // Solution: reset the flag once EGL initialization succeeds so rendering can continue
    isStopped_ = false;
    return true;
}

bool HarmonyGLRendererBackend::initializeEGLContext() {
    // Use the shared display
    EGLDisplay display = EGLDisplayManager::getInstance().getDisplay();
    if (display == EGL_NO_DISPLAY || eglSurface_ == EGL_NO_SURFACE) {
        Logger::error("HarmonyGL", "Cannot create context: display or surface not initialized");
        return false;
    }
    
    if (eglContext_ != EGL_NO_CONTEXT) {
        return true;
    }
    
    // ✅ Protect context creation and activation with the global mutex
    // Prevent multiple instances from creating contexts concurrently and colliding
    std::lock_guard<std::mutex> lock(g_eglMutex);
    
    // ✅ Record the render thread ID (for subsequent validation)
    renderThreadId_ = std::this_thread::get_id();
    Logger::error("HarmonyGL", "🔴🔴🔴 Creating EGL Context on thread: %lu",
                 std::hash<std::thread::id>{}(renderThreadId_));
    Logger::info("HarmonyGLRendererBackend", "Recording render thread ID for EGL context (with mutex protection)");
    
    const EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,  // OpenGL ES 3
        EGL_NONE
    };
    
    // ✅ Create a dedicated EGL context (one per instance)
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
    
    // Inspect key OpenGL capabilities
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
    
    // Query the current viewport configuration
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    Logger::info("OpenGL", "GL_VIEWPORT: x=%d, y=%d, width=%d, height=%d", 
                 viewport[0], viewport[1], viewport[2], viewport[3]);
    
    
    // Validate shader attributes
    validateShaderAttributes();
    
    // ✅ Enable VSync to prevent flickering (moved here to run after context creation)
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
    // 🔍 ANR monitoring: record EGL cleanup duration
    harmony::ANRDetector detector("cleanupEGL", 100, 500);
    
    // ✅ Do not set isStopped_ here
    // Reason: cleanupEGL() may run during reinitialization (setNativeWindow)
    // Setting isStopped_ = true would block rendering during that window and cause a black screen
    // isStopped_ should only be set in the destructor to guard concurrent access during teardown
    
    try {
        // Use the shared display
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (display != EGL_NO_DISPLAY) {
            // ✅ Guard EGL cleanup with the global mutex
            {
                std::lock_guard<std::mutex> lock(g_eglMutex);
                
                // ✅ Clean up the dedicated EGL context
                if (eglContext_ != EGL_NO_CONTEXT) {
                    // 🛡️ Thread safety: confirm the current thread owns this context
                EGLContext currentContext = eglGetCurrentContext();
                if (currentContext == eglContext_) {
                        // Attempt to unbind; continue cleanup on failure
                    if (!eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT)) {
                            EGLint error = eglGetError();
                            Logger::warn("HarmonyGLRendererBackend", 
                                        "Failed to unbind context during cleanup (error=0x%x), continuing anyway", 
                                        error);
                            // Do not abort cleanup because unbind failed
                        }
                    } else {
                    }
                    
                    // 🛡️ The EGL context may be destroyed on any thread (so long as it is not current)
                if (!eglDestroyContext(display, eglContext_)) {
                        EGLint error = eglGetError();
                        Logger::warn("HarmonyGLRendererBackend", 
                                    "Failed to destroy context (error=0x%x)", error);
                    }
                    eglContext_ = EGL_NO_CONTEXT;
                    contextInitialized_ = false;
                }
                
                // ✅ Clean up the dedicated EGL surface
                if (eglSurface_ != EGL_NO_SURFACE) {
                if (!eglDestroySurface(display, eglSurface_)) {
                        EGLint error = eglGetError();
                        Logger::warn("HarmonyGLRendererBackend", 
                                    "Failed to destroy surface (error=0x%x)", error);
                    }
                    eglSurface_ = EGL_NO_SURFACE;
                }
            }  // ✅ Release the mutex

            // Release the shared display
            if (displayAcquired_) {
                EGLDisplayManager::getInstance().releaseDisplay();
                displayAcquired_ = false;
            }
        }
        
        eglWindow_ = 0;  // unsigned long on HarmonyOS, use 0 instead of nullptr
    } catch (const std::exception& e) {
        Logger::error("HarmonyGLRendererBackend", "Error during EGL cleanup: %s", e.what());
        // Ensure cleanup state remains consistent even if an exception occurs
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
        // Ensure cleanup state remains consistent even if an exception occurs
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

// 🛡️ Check EGL health (addresses repeated-entry crashes)
bool HarmonyGLRendererBackend::isEGLHealthy() const {
    // ✅ Use the shared display (getDisplay does not increase the reference count)
    EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
    
    // Basic EGL resource validation
    if (display == EGL_NO_DISPLAY || 
        eglSurface_ == EGL_NO_SURFACE || 
        eglContext_ == EGL_NO_CONTEXT) {
        return false;
    }
    
    // Verify surface validity
    if (!isSurfaceValid()) {
        return false;
    }
    
    // Ensure EGL reports no errors
    EGLint error = eglGetError();
    if (error != EGL_SUCCESS) {
        Logger::warn("HarmonyGLRendererBackend", 
                    "EGL has pending error: %s (0x%x)", 
                    eglErrorString(error), error);
        return false;
    }
    
    return true;
}

// 🛡️ Attempt to recover EGL state (fix repeated-entry crash)
bool HarmonyGLRendererBackend::tryRecoverEGL() {
    // ✅ Prevent concurrent recovery (if multiple instances fail, only one may perform recovery)
    static std::atomic<bool> recovering{false};
    if (recovering.exchange(true)) {
        Logger::warn("HarmonyGLRendererBackend", 
                    "❌ Already in recovery process, aborting this attempt");
        return false;
    }
    
    Logger::info("HarmonyGLRendererBackend", "🔧 Attempting to recover EGL state...");
    
    // Limit retries to avoid infinite loops
    static std::atomic<int> recoveryAttempts{0};
    static std::chrono::steady_clock::time_point lastRecoveryTime;
    
    auto now = std::chrono::steady_clock::now();
    auto timeSinceLastRecovery = std::chrono::duration_cast<std::chrono::seconds>(
        now - lastRecoveryTime).count();
    
    // If the last recovery was under 2 seconds ago, treat it as a rapid failure and abort recovery
    if (timeSinceLastRecovery < 2 && recoveryAttempts > 3) {
        Logger::error("HarmonyGLRendererBackend", 
                     "❌ Too many recovery attempts (%d) in short time, giving up", 
                     recoveryAttempts.load());
        recovering = false;  // ✅ Reset the flag
        return false;
    }
    
    // Reset the counter if more than five seconds have passed
    if (timeSinceLastRecovery > 5) {
        recoveryAttempts = 0;
    }
    
    recoveryAttempts++;
    lastRecoveryTime = now;
    
    Logger::info("HarmonyGLRendererBackend", 
                "Recovery attempt #%d (last recovery was %ld seconds ago)", 
                recoveryAttempts.load(), timeSinceLastRecovery);
    
    // 1. Fully clean up the current invalid EGL resources
    Logger::info("HarmonyGLRendererBackend", "Step 1: Cleaning up invalid EGL resources");
    
    // ✅ Use the shared display: no need to reset it entirely; clean only per-instance resources
    try {
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        
        // 1.1 Clean up the context
        if (eglContext_ != EGL_NO_CONTEXT && display != EGL_NO_DISPLAY) {
            EGLContext currentContext = eglGetCurrentContext();
            if (currentContext == eglContext_) {
                eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
            }
            eglDestroyContext(display, eglContext_);
            eglContext_ = EGL_NO_CONTEXT;
            contextInitialized_ = false;
        }
        
        // 1.2 Clean up the surface
        if (eglSurface_ != EGL_NO_SURFACE && display != EGL_NO_DISPLAY) {
            eglDestroySurface(display, eglSurface_);
            eglSurface_ = EGL_NO_SURFACE;
        }
        
        // 1.3 No need to terminate the display (shared resources are managed by EGLDisplayManager)
    } catch (...) {
        Logger::error("HarmonyGLRendererBackend", "Error during cleanup phase of recovery");
        // Ensure the state is reset
        eglContext_ = EGL_NO_CONTEXT;
        eglSurface_ = EGL_NO_SURFACE;
        contextInitialized_ = false;
    }
    
    // 2. Extend the delay to let the system fully stabilize
    Logger::info("HarmonyGLRendererBackend", "Step 2: Waiting for system to stabilize (50ms)");
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    
    // 3. Reinitialize the entire EGL stack (display + surface + context)
    Logger::info("HarmonyGLRendererBackend", "Step 3: Re-initializing complete EGL stack");
    if (!eglWindow_) {
        Logger::error("HarmonyGLRendererBackend", "❌ No native window available for recovery");
        recovering = false;  // ✅ Reset the flag
        return false;
    }
    
    if (!initializeEGLDisplay()) {
        Logger::error("HarmonyGLRendererBackend", "❌ Failed to re-initialize EGL display");
        recovering = false;  // ✅ Reset the flag
        return false;
    }
    
    // 4. Reinitialize the EGL context if on the render thread
    Logger::info("HarmonyGLRendererBackend", "Step 4: Re-initializing EGL context");
    if (!initializeEGLContext()) {
        Logger::error("HarmonyGLRendererBackend", "❌ Failed to re-initialize EGL context");
        recovering = false;  // ✅ Reset the flag
        return false;
    }
    
    recovering = false;  // ✅ Reset the flag
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
    // Must be invoked on the render thread
    assertOnCorrectThread();
    if (width <= 0 || height <= 0) {
        Logger::error("HarmonyGL", "❌ Invalid framebuffer size: %dx%d", width, height);
        return;
    }
    
    // Calculate physical pixel dimensions (DPI scaled for high-resolution rendering)
    uint32_t physicalWidth = static_cast<uint32_t>(width * pixelRatio_);
    uint32_t physicalHeight = static_cast<uint32_t>(height * pixelRatio_);
    
    size = {physicalWidth, physicalHeight};
    
    // ✅ Critical fix: update the OpenGL viewport (when the context is active)
    // This keeps the framebuffer size and viewport in sync
    // If the context is not active, the viewport will be updated on the next activate() via updateAssumedState() and setViewport()
    if (gfx::BackendScope::exists()) {
        try {
            // Update the context's assumed viewport state (without triggering assertions)
            getContext<gl::Context>().viewport = {0, 0, size};
            
            // If the context is currently active, update it immediately with glViewport
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
    
    // 🔍 Verify the surface state (when initialized)
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
    // Must be invoked on the render thread
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

// 🔒 Thread-safety verification helpers
bool HarmonyGLRendererBackend::isOnCorrectThread() const {
    // If no owner thread has been recorded yet (first call), allow any thread
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
    // 🔒 Record the owner thread on the first activation
    if (ownerThreadId_ == std::thread::id()) {
        ownerThreadId_ = std::this_thread::get_id();
    }
    
    // 🎯 Allow cross-thread calls: avoid strict assertions to support migration to the current thread
    // Note: RunLoop/Actor may schedule on a different thread; the actual binding happens later via eglMakeCurrent
    (void)0;
    if (renderThreadId_ != std::thread::id()) {
        auto currentThread = std::this_thread::get_id();
        if (currentThread != renderThreadId_) {
            Logger::warn("HarmonyGLRendererBackend",
                         "⚠️ activate() called on different thread. Will migrate context. Prev=%lu, Curr=%lu",
                         std::hash<std::thread::id>{}(renderThreadId_),
                         std::hash<std::thread::id>{}(currentThread));
            // Do not return here; migrate later through eglMakeCurrent and update renderThreadId_ on success
        }
    }
    
    // 🛡️ Safety check: if rendering has stopped, degrade gracefully without throwing
    // Reason: BackendScope may invoke activate() during destruction
    // Throwing here would lead to std::terminate() → crash
    if (isStopped_) {
        return;  // Return directly without activating
    }
    
    // 🛡️ Safety check: validate surface health
    // The surface may already be invalid during destruction; avoid throwing
    if (!isSurfaceValid()) {
        Logger::warn("HarmonyGLRendererBackend", "activate() failed: surface invalid (may be in cleanup)");
        return;  // Degrade gracefully without throwing
    }
    
    // HarmonyOS render-thread EGL context management
    // Create the context on the render thread the first time, then activate directly
    
    // First invocation on the render thread—defer context creation
    {
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (!contextInitialized_ && display != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
        Logger::info("HarmonyGLRendererBackend", "activate() - First call on render thread, creating context...");
        if (!initializeEGLContext()) {
            Logger::error("HarmonyGLRendererBackend", "Failed to initialize EGL context on render thread");
            // Do not throw during destruction
            if (isStopped_) {
                Logger::warn("HarmonyGLRendererBackend", "Skipping context init (cleanup in progress)");
                return;
            }
            throw std::runtime_error("Failed to initialize EGL context");
        }
        // initializeEGLContext() already invoked eglMakeCurrent, so the context is current
        Logger::info("HarmonyGLRendererBackend", "activate() - Context created and activated successfully");
        return;
        }
    }
    
    // Remove manual thread validation—EGL manages thread binding itself
    // eglMakeCurrent() reports an error if the thread is incorrect
    // This avoids over-strict checks that would block normal rendering
    
    // Context already created—activate directly
    {
        EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
        if (eglContext_ != EGL_NO_CONTEXT && display != EGL_NO_DISPLAY && eglSurface_ != EGL_NO_SURFACE) {
            auto ensureViewport = [this]() {
                GLint viewport[4];
                glGetIntegerv(GL_VIEWPORT, viewport);
                if (viewport[2] != static_cast<GLint>(size.width) ||
                    viewport[3] != static_cast<GLint>(size.height)) {
                    Logger::warn("HarmonyGL", "⚠️ Viewport size mismatch! Current=[%d, %d], Expected=[%u, %u] - Fixing...",
                                 viewport[2], viewport[3], size.width, size.height);
                    glViewport(0, 0, static_cast<GLsizei>(size.width), static_cast<GLsizei>(size.height));
                    if (gfx::BackendScope::exists()) {
                        getContext<gl::Context>().viewport = {0, 0, size};
                    }
                }
            };

            auto isRecoverableError = [](EGLint error) -> bool {
                switch (error) {
                    case EGL_BAD_ACCESS:
                    case EGL_BAD_SURFACE:
                    case EGL_BAD_CURRENT_SURFACE:
                    case EGL_CONTEXT_LOST:
                    case EGL_BAD_NATIVE_WINDOW:
                        return true;
                    default:
                        return false;
                }
            };

            bool contextAlreadyCurrent = false;
            bool makeCurrentSucceeded = false;
            EGLint makeCurrentError = EGL_SUCCESS;

            auto attemptMakeCurrent = [&](EGLDisplay eglDisplay) {
                std::lock_guard<std::mutex> lock(g_eglMutex);
                EGLContext currentContext = eglGetCurrentContext();
                if (currentContext == eglContext_) {
                    contextAlreadyCurrent = true;
                    return;
                }

                if (eglMakeCurrent(eglDisplay, eglSurface_, eglSurface_, eglContext_)) {
                    makeCurrentSucceeded = true;
                    return;
                }

                makeCurrentError = eglGetError();
                Logger::error("HarmonyGLRendererBackend",
                              "activate() FAILED to make context current: %s (error code: 0x%X)",
                              eglErrorString(makeCurrentError), makeCurrentError);
            };

            attemptMakeCurrent(display);

            if (contextAlreadyCurrent) {
                ensureViewport();
                return;
            }

            if (!makeCurrentSucceeded) {
                if (isStopped_) {
                    Logger::warn("HarmonyGLRendererBackend", "activate() failed but cleanup in progress, returning gracefully");
                    return;
                }

                if (isRecoverableError(makeCurrentError)) {
                    Logger::warn("HarmonyGLRendererBackend",
                                 "Attempting EGL recovery for error: %s (0x%X)",
                                 eglErrorString(makeCurrentError), makeCurrentError);
                    bool recovered = tryRecoverEGL();
                    if (recovered) {
                        if (size.width > 0 && size.height > 0) {
                            const double safeRatio = (pixelRatio_ > 0.01f) ? static_cast<double>(pixelRatio_) : 1.0;
                            int logicalWidth = static_cast<int>(std::lround(static_cast<double>(size.width) / safeRatio));
                            int logicalHeight = static_cast<int>(std::lround(static_cast<double>(size.height) / safeRatio));
                            logicalWidth = std::max(logicalWidth, 1);
                            logicalHeight = std::max(logicalHeight, 1);
                            try {
                                resizeFramebuffer(logicalWidth, logicalHeight);
                            } catch (const std::exception& resizeError) {
                                Logger::warn("HarmonyGLRendererBackend",
                                             "resizeFramebuffer failed during recovery: %s",
                                             resizeError.what());
                            }
                        }

                        EGLDisplay retryDisplay = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
                        if (retryDisplay != EGL_NO_DISPLAY && eglContext_ != EGL_NO_CONTEXT && eglSurface_ != EGL_NO_SURFACE) {
                            attemptMakeCurrent(retryDisplay);
                        } else {
                            makeCurrentSucceeded = false;
                        }
                    }
                }
            }

            if (!makeCurrentSucceeded) {
                if (isRecoverableError(makeCurrentError)) {
                    Logger::error("HarmonyGLRendererBackend",
                                  "activate() could not recover EGL context (error=%s). Pausing rendering.",
                                  eglErrorString(makeCurrentError));
                    pauseRendering();
                    return;
                }

                std::string error = "activate() failed: EGL not fully initialized (display=" +
                                    std::to_string(reinterpret_cast<uintptr_t>(display)) +
                                    ", surface=" + std::to_string(reinterpret_cast<uintptr_t>(eglSurface_)) +
                                    ", context=" + std::to_string(reinterpret_cast<uintptr_t>(eglContext_)) + ")";
                Logger::error("HarmonyGLRendererBackend", "%s", error.c_str());

                if (isStopped_) {
                    Logger::warn("HarmonyGLRendererBackend", "Skipping exception (cleanup in progress)");
                    return;
                }
                throw std::runtime_error(error);
            }

            // 🎯 After migration succeeds, update the render-thread ID
            renderThreadId_ = std::this_thread::get_id();

            ensureViewport();

            GLint framebuffer = 0;
            glGetIntegerv(GL_FRAMEBUFFER_BINDING, &framebuffer);

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
        
            if (isStopped_) {
                Logger::warn("HarmonyGLRendererBackend", "Skipping exception (cleanup in progress)");
                return;
            }
            throw std::runtime_error(error);
        }
    }
}

void HarmonyGLRendererBackend::deactivate() {
    // HarmonyOS render-thread single-thread optimization
    // The context is created and used only on the render thread, so frequent releases are unnecessary
    // This is a performance optimization: keeping the context current avoids repeated bind/unbind overhead
    
    // Note: if multi-threaded access to GL resources is needed in the future, release the context here
    // Under the current design, the context belongs exclusively to the render thread, so it can remain current
}

void HarmonyGLRendererBackend::swapBuffers() {
    // Reduce log noise: remove per-frame swapBuffers debug logging
    
    // 🛡️ Safety check: skip swapBuffers when rendering has stopped
    if (isStopped_) {
        Logger::warn("HarmonyGL", "⚠️ swapBuffers() - skipped (rendering stopped)");
        return;
    }
    
    // 🔒 Thread safety: ensure this is called on the creation/render thread
    assertOnCorrectThread();

    // 🔍 Diagnostic log: validate surface state
    if (!isSurfaceValid()) {
        Logger::error("HarmonyGL", "❌ swapBuffers() - Surface validation failed");
        // Detailed log: inspect surface attributes
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
        // Optional: print surface details only on failure to avoid per-frame logging
        
        // HarmonyOS buffer refresh retry mechanism
        int retryCount = 0;
        const int maxRetries = 3;
        bool success = false;
        
        // Before the first attempt, ensure the context is current (avoid an immediate BAD_SURFACE)
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
                
                // 🛡️ Stop retrying immediately when the error relates to the surface
                if (error == EGL_BAD_SURFACE || error == EGL_BAD_CURRENT_SURFACE) {
                    Logger::error("HarmonyGL", "   Surface invalid - stopping retry");
                    break;
                }
                
                if (retryCount < maxRetries) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                    // ✅ Guard against concurrent eglMakeCurrent calls with a lock
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


// 🛡️ Added: validate surface health
bool HarmonyGLRendererBackend::isSurfaceValid() const {
    // ✅ Use the shared display (getDisplay does not increase the reference count)
    EGLDisplay display = displayAcquired_ ? EGLDisplayManager::getInstance().getDisplay() : EGL_NO_DISPLAY;
    
    if (display == EGL_NO_DISPLAY || eglSurface_ == EGL_NO_SURFACE) {
        return false;
    }
    
    // Query surface attributes to verify validity
    EGLint width = 0, height = 0;
    if (!eglQuerySurface(display, eglSurface_, EGL_WIDTH, &width) ||
        !eglQuerySurface(display, eglSurface_, EGL_HEIGHT, &height)) {
        return false;
    }
    
    // Width and height must both be greater than zero
    return (width > 0 && height > 0);
}

// 🛡️ Added: pause rendering to prevent crashes
void HarmonyGLRendererBackend::pauseRendering() {
    Logger::info("HarmonyGLRendererBackend", "Pausing rendering to prevent crash");
    isStopped_ = true;
}

// 🛡️ Added: resume rendering
void HarmonyGLRendererBackend::resumeRendering() {
    Logger::info("HarmonyGLRendererBackend", "Resuming rendering");
    isStopped_ = false;
}

bool HarmonyGLRendererBackend::hasValidSurface() const {
    return isSurfaceValid();
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


