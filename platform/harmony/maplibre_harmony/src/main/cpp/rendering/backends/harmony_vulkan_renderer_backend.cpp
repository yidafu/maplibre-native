#include "harmony_vulkan_renderer_backend.hpp"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/vulkan/context.hpp>
#include <mbgl/vulkan/renderable_resource.hpp>
#include <mbgl/util/logging.hpp>

#include <cassert>
#include <string>
#include "utils/logger.h"

// VK_OHOS_surface definitions (VkSurfaceCreateInfoOHOS, vkCreateSurfaceOHOS,
// VK_OHOS_SURFACE_EXTENSION_NAME) come from the vendored Vulkan-Headers'
// <vulkan/vulkan_ohos.h>, pulled in via <vulkan/vulkan.hpp> in 1.4.352+.

namespace mbgl {
namespace harmony {

/**
 * @brief HarmonyOS-specific Vulkan renderable resource
 *
 * This class handles the creation and management of Vulkan surfaces
 * and swapchains for HarmonyOS native windows.
 */
class HarmonyVulkanRenderableResource final : public mbgl::vulkan::SurfaceRenderableResource {
public:
    explicit HarmonyVulkanRenderableResource(HarmonyVulkanRendererBackend& backend_)
        : SurfaceRenderableResource(backend_) {
        Logger::info("HarmonyVulkan", "Creating HarmonyVulkanRenderableResource");
    }

    ~HarmonyVulkanRenderableResource() override {
        Logger::info("HarmonyVulkan", "Destroying HarmonyVulkanRenderableResource");
    }

    /**
     * @brief Get device extensions required for HarmonyOS Vulkan rendering
     * @return Vector of required device extension names
     */
    std::vector<const char*> getDeviceExtensions() override {
        return {
            VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        };
    }

    /**
     * @brief Create the Vulkan surface for the HarmonyOS native window
     *
     * Uses the VK_OHOS_surface extension via vkCreateSurfaceOHOS, resolved
     * through the instance dispatcher. The VkSurfaceCreateInfoOHOS struct and
     * function pointer types come from the vendored <vulkan/vulkan_ohos.h>,
     * included by <vulkan/vulkan.h> when VK_USE_PLATFORM_OHOS is defined.
     */
    void createPlatformSurface() override {
        auto& backendImpl = static_cast<HarmonyVulkanRendererBackend&>(backend);
        OHNativeWindow* nativeWindow = backendImpl.getWindow();

        Logger::info("HarmonyVulkan", "Creating Vulkan surface for HarmonyOS window=%p", nativeWindow);

        if (!nativeWindow) {
            Logger::error("HarmonyVulkan", "Native window is null, cannot create surface");
            throw std::runtime_error("HarmonyOS native window is null");
        }

        VkInstance instance = backendImpl.getInstance()->operator VkInstance();
        const auto& dispatcher = backendImpl.getDispatcher();

        if (!dispatcher.vkCreateSurfaceOHOS) {
            Logger::error("HarmonyVulkan", "vkCreateSurfaceOHOS function not found");
            throw std::runtime_error("HarmonyOS Vulkan surface extension (VK_OHOS_surface) not available");
        }

        VkSurfaceCreateInfoOHOS createInfo{};
        createInfo.sType = VK_STRUCTURE_TYPE_SURFACE_CREATE_INFO_OHOS;
        createInfo.pNext = nullptr;
        createInfo.flags = 0;
        createInfo.window = nativeWindow;

        VkSurfaceKHR rawSurface = VK_NULL_HANDLE;
        VkResult result = dispatcher.vkCreateSurfaceOHOS(instance, &createInfo, nullptr, &rawSurface);

        if (result != VK_SUCCESS || rawSurface == VK_NULL_HANDLE) {
            Logger::error("HarmonyVulkan", "Failed to create Vulkan surface, error code: %d", result);
            throw std::runtime_error("Failed to create HarmonyOS Vulkan surface");
        }

        surface = vk::UniqueSurfaceKHR(
            vk::SurfaceKHR(rawSurface),
            mbgl::vulkan::ObjectDestroy<vk::Instance>(
                *backendImpl.getInstance(),
                nullptr,
                dispatcher)
        );

        Logger::info("HarmonyVulkan", "Successfully created Vulkan surface");
    }

    /**
     * @brief Bind the surface (no-op for Vulkan)
     */
    void bind() override {
        // No-op for Vulkan - binding is handled through command buffers
    }

    /**
     * @brief Swap buffers and present the rendered frame
     *
     * This method submits the frame and presents it to the screen.
     * It also handles synchronization based on the swap behavior setting.
     */
    void swap() override {
        // Call base class swap implementation to handle presentation
        vulkan::SurfaceRenderableResource::swap();

        // Handle synchronization based on swap behavior
        const auto& swapBehaviour = static_cast<HarmonyVulkanRendererBackend&>(backend).getSwapBehavior();
        if (swapBehaviour == gfx::Renderable::SwapBehaviour::Flush) {
            // Wait for frame completion in flush mode
            static_cast<vulkan::Context&>(backend.getContext()).waitFrame();
        }
    }
};

// ============================================================================
// HarmonyVulkanRendererBackend Implementation
// ============================================================================

HarmonyVulkanRendererBackend::HarmonyVulkanRendererBackend()
    : vulkan::RendererBackend(gfx::ContextMode::Unique),
      vulkan::Renderable({64, 64}, std::make_unique<HarmonyVulkanRenderableResource>(*this)),
      window(nullptr) {

    Logger::info("HarmonyVulkan", "Creating HarmonyVulkanRendererBackend (deferred initialization)");
    // Note: init() will be called later when window is set via setNativeWindow()
}

HarmonyVulkanRendererBackend::HarmonyVulkanRendererBackend(OHNativeWindow* window_)
    : vulkan::RendererBackend(gfx::ContextMode::Unique),
      vulkan::Renderable({64, 64}, std::make_unique<HarmonyVulkanRenderableResource>(*this)),
      window(window_) {

    Logger::info("HarmonyVulkan", "Initializing HarmonyVulkanRendererBackend with window=%p", window);

    if (!window) {
        Logger::error("HarmonyVulkan", "Cannot initialize with null window");
        throw std::runtime_error("HarmonyOS native window is null");
    }

    try {
        // Initialize the Vulkan backend
        // This will call initInstance, initSurface, initDevice, etc.
        init();
        Logger::info("HarmonyVulkan", "HarmonyVulkanRendererBackend initialization completed successfully");
    } catch (const std::exception& e) {
        Logger::error("HarmonyVulkan", "Failed to initialize Vulkan backend: %s", e.what());
        throw;
    }
}

HarmonyVulkanRendererBackend::~HarmonyVulkanRendererBackend() {
    Logger::info("HarmonyVulkan", "Destroying HarmonyVulkanRendererBackend");
}

void HarmonyVulkanRendererBackend::setNativeWindow(OHNativeWindow* window_) {
    Logger::info("HarmonyVulkan", "Setting native window: %p", window_);

    if (window == window_) {
        return;
    }

    window = window_;

    if (!window) {
        Logger::warn("HarmonyVulkan", "Setting null window");
        return;
    }

    // If not initialized yet, initialize now
    if (!context) {
        Logger::info("HarmonyVulkan", "Initializing Vulkan backend with window");
        try {
            init();
            Logger::info("HarmonyVulkan", "Vulkan backend initialized successfully");
        } catch (const std::exception& e) {
            Logger::error("HarmonyVulkan", "Failed to initialize: %s", e.what());
            throw;
        }
    } else {
        Logger::info("HarmonyVulkan", "Reinitializing surface for new window");
        if (context) {
            static_cast<vulkan::Context&>(*context).requestSurfaceUpdate();
        }
    }
}

std::vector<const char*> HarmonyVulkanRendererBackend::getInstanceExtensions() {
    // Get base extensions from parent class
    auto extensions = mbgl::vulkan::RendererBackend::getInstanceExtensions();

    // Add Vulkan surface extension (standard WSI extension)
    extensions.push_back(VK_KHR_SURFACE_EXTENSION_NAME);

    // Add HarmonyOS-specific surface extension
    extensions.push_back(VK_OHOS_SURFACE_EXTENSION_NAME);

    Logger::info("HarmonyVulkan", "Requesting %zu Vulkan instance extensions", extensions.size());

    return extensions;
}

void HarmonyVulkanRendererBackend::resizeFramebuffer(int width, int height) {
    Logger::info("HarmonyVulkan", "Resizing framebuffer to %dx%d", width, height);

    if (width <= 0 || height <= 0) {
        Logger::warn("HarmonyVulkan", "Invalid framebuffer size: %dx%d, ignoring resize", width, height);
        return;
    }

    // Update the renderable size
    size = {static_cast<uint32_t>(width), static_cast<uint32_t>(height)};

    // Request surface update if context is available
    if (context) {
        static_cast<vulkan::Context&>(*context).requestSurfaceUpdate();
    } else {
        Logger::warn("HarmonyVulkan", "Context not available, resize will be applied on next render");
    }
}

void HarmonyVulkanRendererBackend::enableFramebufferRead(bool value) {
    if (!value) {
        return;
    }

    // The core SurfaceRenderableResource copies the acquired swapchain image
    // into a readback texture during the next swap.
    if (hasResource()) {
        getResource<HarmonyVulkanRenderableResource>().queueSurfaceRead();
    }
}

PremultipliedImage HarmonyVulkanRendererBackend::readFramebuffer() {
    if (!hasResource()) {
        Logger::warn("HarmonyVulkan", "readFramebuffer called without a renderable resource");
        return {};
    }

    auto image = getResource<HarmonyVulkanRenderableResource>().readImage();
    if (!image) {
        Logger::warn("HarmonyVulkan", "Framebuffer readback not queued for this frame");
        return {};
    }
    return std::move(*image);
}

void HarmonyVulkanRendererBackend::cleanupBackend() {
    Logger::info("HarmonyVulkan", "Cleaning up Vulkan backend resources");

    // Drain pending frames before the surface/swapchain go away
    if (context) {
        try {
            static_cast<vulkan::Context&>(*context).waitFrame();
        } catch (const std::exception& e) {
            Logger::warn("HarmonyVulkan", "waitFrame during cleanup failed: %s", e.what());
        }
    }
    // Instance/device/swapchain teardown happens in the vulkan::RendererBackend
    // and RenderableResource destructors.
}

std::string HarmonyVulkanRendererBackend::getRendererInfo() {
    std::string info = "vulkan";
    try {
        const auto& props = getDeviceProperties();
        info += " | ";
        info += std::string(props.deviceName.data());
    } catch (const std::exception& e) {
        Logger::warn("HarmonyVulkan", "getRendererInfo failed: %s", e.what());
    }
    return info;
}

} // namespace harmony
} // namespace mbgl
