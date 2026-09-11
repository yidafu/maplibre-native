#include "egl_display_manager.hpp"
#include "utils/logger.h"
#include <stdexcept>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

namespace {
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

EGLDisplayManager& EGLDisplayManager::getInstance() {
    static EGLDisplayManager instance;
    return instance;
}

EGLDisplayManager::~EGLDisplayManager() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (displayInitialized_) {
        Logger::warn("EGLDisplayManager", 
                    "Display still initialized in destructor (refCount=%d), force cleaning up",
                    displayRefCount_);
        cleanupDisplay();
    }
}

bool EGLDisplayManager::registerInstance() {
    int current = activeInstanceCount_.load();
    if (current >= MAX_CONCURRENT_INSTANCES) {
        Logger::error("EGLDisplayManager", 
                     "Cannot create map instance: exceeded maximum limit (%d/%d)",
                     current, MAX_CONCURRENT_INSTANCES);
        return false;
    }
    
    activeInstanceCount_++;
    Logger::info("EGLDisplayManager", 
                "Map instance registered (active: %d/%d)",
                activeInstanceCount_.load(), MAX_CONCURRENT_INSTANCES);
    return true;
}

void EGLDisplayManager::unregisterInstance() {
    if (activeInstanceCount_ > 0) {
        activeInstanceCount_--;
        Logger::info("EGLDisplayManager", 
                    "Map instance unregistered (active: %d/%d)",
                    activeInstanceCount_.load(), MAX_CONCURRENT_INSTANCES);
    }
}

EGLDisplay EGLDisplayManager::acquireDisplay() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // If already initialized, increment reference count and return
    if (displayInitialized_ && sharedDisplay_ != EGL_NO_DISPLAY) {
        displayRefCount_++;
        Logger::info("EGLDisplayManager", 
                    "acquireDisplay() called (refCount: %d→%d) - Reusing shared display: %p",
                    displayRefCount_ - 1, displayRefCount_, sharedDisplay_);
        return sharedDisplay_;
    }
    
    // First-time initialization
    if (!initializeDisplay()) {
        Logger::error("EGLDisplayManager", "Failed to initialize EGL Display");
        return EGL_NO_DISPLAY;
    }
    
    displayRefCount_ = 1;
    Logger::info("EGLDisplayManager", 
                "acquireDisplay() called (refCount: 0→1) - Created shared display: %p",
                sharedDisplay_);
    
    return sharedDisplay_;
}

EGLDisplay EGLDisplayManager::getDisplay() const {
    // Lock: sharedDisplay_ is written under the mutex by initialize/cleanup,
    // and cleanup can run concurrently with a still-live render thread's
    // health checks.
    std::lock_guard<std::mutex> lock(mutex_);
    return sharedDisplay_;
}

bool EGLDisplayManager::chooseConfig(const EGLint* attribs, EGLConfig& config) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (!displayInitialized_ || sharedDisplay_ == EGL_NO_DISPLAY) {
        Logger::error("EGLDisplayManager", "Display not initialized, cannot choose config");
        return false;
    }
    
    EGLint numConfigs = 0;
    if (!eglChooseConfig(sharedDisplay_, attribs, &config, 1, &numConfigs) || numConfigs <= 0) {
        EGLint error = eglGetError();
        Logger::error("EGLDisplayManager", 
                     "Failed to choose EGL config: %s (numConfigs=%d, error=0x%X)",
                     eglErrorString(error), numConfigs, error);
        return false;
    }
    
    return true;
}

void EGLDisplayManager::releaseDisplay() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (displayRefCount_ <= 0) {
        Logger::warn("EGLDisplayManager", "releaseDisplay() called but refCount already 0");
        return;
    }
    
    Logger::info("EGLDisplayManager", 
                "releaseDisplay() called (refCount: %d→%d)",
                displayRefCount_, displayRefCount_ - 1);
    
    displayRefCount_--;
    
    // Clean up the display when reference count drops to 0
    if (displayRefCount_ == 0) {
        Logger::info("EGLDisplayManager", "No more references, cleaning up EGL Display");
        cleanupDisplay();
    }
}

bool EGLDisplayManager::initializeDisplay() {
    // Note: function is invoked with lock already held
    
    // Acquire default Display
    sharedDisplay_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (sharedDisplay_ == EGL_NO_DISPLAY) {
        EGLint error = eglGetError();
        Logger::error("EGLDisplayManager", 
                     "Failed to get EGL display: %s (0x%X)",
                     eglErrorString(error), error);
        return false;
    }
    
    // Initialize EGL
    if (!eglInitialize(sharedDisplay_, &majorVersion_, &minorVersion_)) {
        EGLint error = eglGetError();
        Logger::error("EGLDisplayManager", 
                     "Failed to initialize EGL: %s (0x%X)",
                     eglErrorString(error), error);
        sharedDisplay_ = EGL_NO_DISPLAY;
        return false;
    }
    
    Logger::info("EGLDisplayManager", 
                "EGL initialized successfully: version %d.%d",
                majorVersion_, minorVersion_);
    
    // Bind OpenGL ES API
    if (!eglBindAPI(EGL_OPENGL_ES_API)) {
        EGLint error = eglGetError();
        Logger::error("EGLDisplayManager", 
                     "Failed to bind OpenGL ES API: %s",
                     eglErrorString(error));
        eglTerminate(sharedDisplay_);
        sharedDisplay_ = EGL_NO_DISPLAY;
        return false;
    }
    
    displayInitialized_ = true;
    
    // Output EGL information
    const char* vendor = eglQueryString(sharedDisplay_, EGL_VENDOR);
    const char* version = eglQueryString(sharedDisplay_, EGL_VERSION);
    const char* extensions = eglQueryString(sharedDisplay_, EGL_EXTENSIONS);
    
    Logger::info("EGLDisplayManager", "EGL Vendor: %s", vendor ? vendor : "NULL");
    Logger::info("EGLDisplayManager", "EGL Version: %s", version ? version : "NULL");
    return true;
}

void EGLDisplayManager::cleanupDisplay() {
    // Note: function is invoked with lock already held
    
    if (!displayInitialized_) {
        return;
    }
    
    if (sharedDisplay_ != EGL_NO_DISPLAY) {
        Logger::info("EGLDisplayManager", "Terminating EGL Display: %p", sharedDisplay_);
        
        // Ensure there is no current context
        EGLContext currentContext = eglGetCurrentContext();
        if (currentContext != EGL_NO_CONTEXT) {
            Logger::warn("EGLDisplayManager", 
                        "Current context still active during cleanup, unbinding");
            eglMakeCurrent(sharedDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        }
        
        if (!eglTerminate(sharedDisplay_)) {
            EGLint error = eglGetError();
            Logger::warn("EGLDisplayManager", 
                        "Failed to terminate EGL display: %s (0x%X)",
                        eglErrorString(error), error);
        } else {
            Logger::info("EGLDisplayManager", "EGL Display terminated successfully");
        }
        
        sharedDisplay_ = EGL_NO_DISPLAY;
    }
    
    displayInitialized_ = false;
    displayRefCount_ = 0;
    majorVersion_ = 0;
    minorVersion_ = 0;
}

} // namespace harmony
} // namespace mbgl

