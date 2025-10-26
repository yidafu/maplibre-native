#pragma once

#include <mbgl/vulkan/renderable_resource.hpp>
#include <mbgl/vulkan/renderer_backend.hpp>
#include "harmony_renderer_backend.hpp"
#include <native_window/external_window.h>
#include <vector>

namespace mbgl {
namespace harmony {

/**
 * @brief Vulkan renderer backend implementation for HarmonyOS
 * 
 * This class provides the Vulkan rendering backend for MapLibre Native on HarmonyOS.
 * It inherits from both the generic HarmonyRendererBackend and the Vulkan-specific
 * RendererBackend and Renderable classes.
 */
class HarmonyVulkanRendererBackend : public HarmonyRendererBackend,
                                     public vulkan::RendererBackend,
                                     public vulkan::Renderable {
public:
    /**
     * @brief Construct with no window (for deferred initialization)
     */
    HarmonyVulkanRendererBackend();
    
    /**
     * @brief Construct a new HarmonyVulkanRendererBackend with window
     * @param window Pointer to the native HarmonyOS window (OHNativeWindow)
     */
    explicit HarmonyVulkanRendererBackend(OHNativeWindow* window);
    
    /**
     * @brief Destructor
     */
    ~HarmonyVulkanRendererBackend() override;

    /**
     * @brief Get the native window handle
     * @return Pointer to the OHNativeWindow
     */
    OHNativeWindow* getWindow() const { return window; }
    
    /**
     * @brief Set the native window and reinitialize surface
     * @param window Pointer to the native HarmonyOS window
     */
    void setNativeWindow(OHNativeWindow* window);
    
    /**
     * @brief Get the renderer backend implementation
     * @return Reference to the gfx::RendererBackend
     */
    mbgl::gfx::RendererBackend& getImpl() override { return *this; }

    /**
     * @brief Get the Vulkan instance extensions required for HarmonyOS
     * @return Vector of extension names
     */
    std::vector<const char*> getInstanceExtensions() override;

    /**
     * @brief Resize the framebuffer
     * @param width New width in pixels
     * @param height New height in pixels
     */
    void resizeFramebuffer(int width, int height) override;
    
    /**
     * @brief Read the framebuffer contents for screenshot functionality
     * @return PremultipliedImage containing the framebuffer data
     */
    PremultipliedImage readFramebuffer() override;

    // mbgl::gfx::RendererBackend implementation
public:
    /**
     * @brief Get the default renderable surface
     * @return Reference to the default Renderable
     */
    mbgl::gfx::Renderable& getDefaultRenderable() override { return *this; }

protected:
    /**
     * @brief Activate the rendering context (no-op for Vulkan)
     */
    void activate() override {
        // no-op for Vulkan
    }
    
    /**
     * @brief Deactivate the rendering context (no-op for Vulkan)
     */
    void deactivate() override {
        // no-op for Vulkan
    }

private:
    OHNativeWindow* window; ///< Native HarmonyOS window handle
};

} // namespace harmony
} // namespace mbgl
