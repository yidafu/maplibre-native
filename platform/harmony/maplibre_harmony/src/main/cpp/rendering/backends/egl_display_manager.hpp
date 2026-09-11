#pragma once

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <mutex>
#include <atomic>

namespace mbgl {
namespace harmony {

/**
 * @brief Global EGL Display manager (singleton).
 *
 * Responsibilities:
 * - Manage a shared EGL Display (all map instances share one display)
 * - Provide thread-safe initialization and cleanup
 * - Maintain reference counting (cleanup occurs only when the last instance is destroyed)
 * - Enforce resource limits to prevent exhausting system resources
 *
 * Design principles:
 * - The EGL Display represents the connection to the display system and can be shared between contexts
 * - Each map instance owns its own EGLContext and EGLSurface while sharing a single EGLDisplay
 * - This preserves instance isolation while avoiding conflicts from repeated display initialization
 */
class EGLDisplayManager {
public:
    /**
     * @brief Retrieve the singleton instance.
     */
    static EGLDisplayManager& getInstance();

    /**
     * @brief Acquire the shared EGL Display (initializes if needed).
     * Increments the reference count; each instance should call this once during initialization.
     * @return Shared EGLDisplay, or EGL_NO_DISPLAY on failure.
     */
    EGLDisplay acquireDisplay();

    /**
     * @brief Access the shared EGL Display without incrementing the reference count.
     * Intended for internal use after acquire().
     * @return Shared EGLDisplay, or EGL_NO_DISPLAY if uninitialized.
     */
    EGLDisplay getDisplay() const;

    /**
     * @brief Choose an EGL configuration.
     * @param attribs Attribute array
     * @param config Output configuration
     * @return true on success, false otherwise
     */
    bool chooseConfig(const EGLint* attribs, EGLConfig& config);

    /**
     * @brief Release the display reference (decrements the reference count).
     * Automatically cleans up the EGL Display when the count reaches zero.
     */
    void releaseDisplay();

    /**
     * @brief Get the number of active instances.
     */
    int getActiveInstanceCount() const { return activeInstanceCount_.load(); }

    /**
     * @brief Register a new instance (increments active count).
     * @return true on success, false if the maximum instance limit is exceeded.
     */
    bool registerInstance();

    /**
     * @brief Unregister an instance (decrements active count).
     */
    void unregisterInstance();

    /**
     * @brief Return the maximum supported concurrent instances.
     */
    static constexpr int getMaxConcurrentInstances() { return MAX_CONCURRENT_INSTANCES; }

    // Delete copy and assignment operations (singleton)
    EGLDisplayManager(const EGLDisplayManager&) = delete;
    EGLDisplayManager& operator=(const EGLDisplayManager&) = delete;

private:
    EGLDisplayManager() = default;
    ~EGLDisplayManager();

    /**
     * @brief Initialize the EGL Display (internal, requires lock).
     * @return true on success, false otherwise.
     */
    bool initializeDisplay();

    /**
     * @brief Clean up the EGL Display (internal, requires lock).
     */
    void cleanupDisplay();

    // Maximum concurrent map instances (based on HarmonyOS system limits)
    static constexpr int MAX_CONCURRENT_INSTANCES = 4;

    // Thread-safety guard (mutable: getDisplay() is const and hot)
    mutable std::mutex mutex_;

    // Shared EGL Display
    EGLDisplay sharedDisplay_ = EGL_NO_DISPLAY;

    // Display initialization state
    bool displayInitialized_ = false;

    // Display reference count (number of backend instances using it)
    int displayRefCount_ = 0;

    // Active instance count (for resource limiting)
    std::atomic<int> activeInstanceCount_{0};

    // EGL version information
    EGLint majorVersion_ = 0;
    EGLint minorVersion_ = 0;
};

} // namespace harmony
} // namespace mbgl

