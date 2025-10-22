#include "harmony_vulkan_renderer_backend.hpp"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/vulkan/context.hpp>
#include <mbgl/vulkan/renderable_resource.hpp>
#include <mbgl/util/logging.hpp>

#include <cassert>
#include "logger.h"

// HarmonyOS Vulkan surface extension definitions
// These may need to be adjusted based on the actual HarmonyOS Vulkan SDK
#ifndef VK_OHOS_SURFACE_EXTENSION_NAME
#define VK_OHOS_SURFACE_EXTENSION_NAME "VK_OHOS_surface"
#endif

#ifndef VK_STRUCTURE_TYPE_OHOS_SURFACE_CREATE_INFO_KHR
#define VK_STRUCTURE_TYPE_OHOS_SURFACE_CREATE_INFO_KHR ((VkStructureType)1000000000)
#endif

// Forward declare HarmonyOS Vulkan surface structures if not available
#ifndef VK_OHOS_surface
struct VkOHOSSurfaceCreateInfoKHR {
    VkStructureType sType;
    const void* pNext;
    VkFlags flags;
    OHNativeWindow* window;
};

// Function pointer type for OHOS surface creation
// Use generic pointer for cross-platform compatibility
using PFN_vkCreateOHOSSurfaceKHR = VkResult (*)(VkInstance, const VkOHOSSurfaceCreateInfoKHR*, const VkAllocationCallbacks*, VkSurfaceKHR*);
#endif

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
        Logger::debug("HarmonyVulkan", "Getting device extensions");
        return {
            VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        };
    }

    /**
     * @brief Create the Vulkan surface for HarmonyOS native window
     * 
     * This method creates a platform-specific Vulkan surface using the
     * HarmonyOS native window handle. It uses the VK_OHOS_surface extension
     * to create the surface compatible with OHNativeWindow.
     */
    void createPlatformSurface() override {
        auto& backendImpl = static_cast<HarmonyVulkanRendererBackend&>(backend);
        OHNativeWindow* nativeWindow = backendImpl.getWindow();
        
        Logger::info("HarmonyVulkan", "Creating Vulkan surface for HarmonyOS window=%p", nativeWindow);
        
        if (!nativeWindow) {
            Logger::error("HarmonyVulkan", "Native window is null, cannot create surface");
            throw std::runtime_error("HarmonyOS native window is null");
        }

        try {
            // Get the Vulkan instance
            VkInstance instance = backendImpl.getInstance()->operator VkInstance();
            const auto& dispatcher = backendImpl.getDispatcher();
            
            // Create surface using HarmonyOS-specific Vulkan API
            VkOHOSSurfaceCreateInfoKHR createInfo{};
            createInfo.sType = VK_STRUCTURE_TYPE_OHOS_SURFACE_CREATE_INFO_KHR;
            createInfo.pNext = nullptr;
            createInfo.flags = 0;
            createInfo.window = nativeWindow;

            // Try to get the function pointer for vkCreateOHOSSurfaceKHR
            auto vkCreateOHOSSurfaceKHR = reinterpret_cast<PFN_vkCreateOHOSSurfaceKHR>(
                dispatcher.vkGetInstanceProcAddr(instance, "vkCreateOHOSSurfaceKHR")
            );
            
            if (!vkCreateOHOSSurfaceKHR) {
                Logger::error("HarmonyVulkan", "vkCreateOHOSSurfaceKHR function not found");
                throw std::runtime_error("HarmonyOS Vulkan surface extension not available");
            }
            
            VkSurfaceKHR rawSurface = VK_NULL_HANDLE;
            VkResult result = vkCreateOHOSSurfaceKHR(
                instance,
                &createInfo,
                nullptr,
                &rawSurface
            );
            
            if (result != VK_SUCCESS || rawSurface == VK_NULL_HANDLE) {
                Logger::error("HarmonyVulkan", "Failed to create Vulkan surface, error code: %d", result);
                throw std::runtime_error("Failed to create HarmonyOS Vulkan surface");
            }
            
            // Wrap in unique_ptr for automatic cleanup
            surface = vk::UniqueSurfaceKHR(
                vk::SurfaceKHR(rawSurface),
                vk::ObjectDestroy<vk::Instance, vk::DispatchLoaderDynamic>(
                    *backendImpl.getInstance(),
                    nullptr,
                    dispatcher
                )
            );
            
            Logger::info("HarmonyVulkan", "Successfully created Vulkan surface");
            
            // HarmonyOS may support surface pre-rotation similar to Android
            Logger::debug("HarmonyVulkan", "Surface transform support will be checked during swapchain creation");
            
        } catch (const std::exception& e) {
            Logger::error("HarmonyVulkan", "Exception during surface creation: %s", e.what());
            throw;
        }
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
        Logger::debug("HarmonyVulkan", "Swapping buffers");
        
        // Call base class swap implementation to handle presentation
        vulkan::SurfaceRenderableResource::swap();

        // Handle synchronization based on swap behavior
        const auto& swapBehaviour = static_cast<HarmonyVulkanRendererBackend&>(backend).getSwapBehavior();
        if (swapBehaviour == gfx::Renderable::SwapBehaviour::Flush) {
            // Wait for frame completion in flush mode
            static_cast<vulkan::Context&>(backend.getContext()).waitFrame();
            Logger::debug("HarmonyVulkan", "Frame flush completed");
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
        Logger::debug("HarmonyVulkan", "Window unchanged, skipping");
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
        // TODO: Implement surface recreation for window change
        // This requires recreating the surface and swapchain
        if (context) {
            static_cast<vulkan::Context&>(*context).requestSurfaceUpdate();
        }
    }
}

std::vector<const char*> HarmonyVulkanRendererBackend::getInstanceExtensions() {
    Logger::debug("HarmonyVulkan", "Getting instance extensions");
    
    // Get base extensions from parent class
    auto extensions = mbgl::vulkan::RendererBackend::getInstanceExtensions();
    
    // Add Vulkan surface extension (standard WSI extension)
    extensions.push_back(VK_KHR_SURFACE_EXTENSION_NAME);
    
    // Add HarmonyOS-specific surface extension
    // VK_OHOS_surface is the HarmonyOS-specific extension for window surface support
    extensions.push_back(VK_OHOS_SURFACE_EXTENSION_NAME);
    
    Logger::info("HarmonyVulkan", "Requesting %zu Vulkan instance extensions", extensions.size());
    
    // Log all requested extensions for debugging
    for (size_t i = 0; i < extensions.size(); ++i) {
        Logger::debug("HarmonyVulkan", "  Extension[%zu]: %s", i, extensions[i]);
    }
    
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
        Logger::debug("HarmonyVulkan", "Requesting surface update for resize");
        static_cast<vulkan::Context&>(*context).requestSurfaceUpdate();
    } else {
        Logger::warn("HarmonyVulkan", "Context not available, resize will be applied on next render");
    }
}

PremultipliedImage HarmonyVulkanRendererBackend::readFramebuffer() {
    Logger::debug("HarmonyVulkan", "Reading framebuffer");
    
    try {
        // Get the current framebuffer size
        const auto& renderableSize = getDefaultRenderable().getSize();
        const uint32_t width = renderableSize.width;
        const uint32_t height = renderableSize.height;
        
        Logger::debug("HarmonyVulkan", "Framebuffer size: %ux%u", width, height);
        
        if (width == 0 || height == 0) {
            Logger::warn("HarmonyVulkan", "Invalid framebuffer size for readback");
            return PremultipliedImage(Size(2, 2));
        }
        
        // TODO: Implement actual framebuffer readback for HarmonyOS
        // This requires:
        // 1. Creating a staging buffer
        // 2. Copying the framebuffer image to the staging buffer
        // 3. Mapping the staging buffer memory
        // 4. Reading the pixel data
        // 5. Converting to PremultipliedImage format
        
        Logger::warn("HarmonyVulkan", "Framebuffer readback not fully implemented yet");
        
        // For now, return a minimal image
        // In production, this should copy the actual rendered content
        return PremultipliedImage(Size(width, height));
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyVulkan", "Error reading framebuffer: %s", e.what());
        return PremultipliedImage(Size(2, 2));
    }
}

} // namespace harmony
} // namespace mbgl

// ============================================================================
// Backend Factory Implementation
// ============================================================================

namespace mbgl {
namespace gfx {

/**
 * @brief Factory method specialization for creating HarmonyOS Vulkan backend
 * 
 * This template specialization is called when creating a Vulkan backend
 * with an OHNativeWindow parameter.
 */
template <>
std::unique_ptr<Backend> Backend::Create<Backend::Type::Vulkan>(OHNativeWindow* window) {
    mbgl::Log::Info(mbgl::Event::Render, "Creating HarmonyOS Vulkan backend");
    
    if (!window) {
        mbgl::Log::Error(mbgl::Event::Render, "Cannot create Vulkan backend with null window");
        throw std::runtime_error("OHNativeWindow is null");
    }
    
    auto backend = std::make_unique<mbgl::harmony::HarmonyVulkanRendererBackend>(window);
    return std::unique_ptr<Backend>(backend.release());
}

} // namespace gfx
} // namespace mbgl
