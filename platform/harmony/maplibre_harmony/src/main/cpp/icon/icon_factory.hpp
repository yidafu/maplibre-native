#pragma once

#include <mbgl/util/image.hpp>
#include <memory>
#include <string>

// Forward declarations for HarmonyOS types
struct NativeResourceManager;

namespace mbgl {
namespace harmony {

/**
 * IconFactory - C++ layer icon creation utility
 * 
 * This factory creates icons directly in C++ using HarmonyOS native APIs,
 * avoiding expensive PixelMap-to-bytes conversions across the NAPI boundary.
 * 
 * Performance optimization:
 * - Old: ETS PixelMap → NAPI → memcpy → PremultipliedImage (2 allocations + copy)
 * - New: Raw bytes → HarmonyOS ImageSource → PremultipliedImage (1 allocation + 1 copy in C++)
 * 
 * Supported image formats: PNG, JPEG, WEBP (decoded by HarmonyOS ImageSource)
 */
class IconFactory {
public:
    /**
     * Decode image from raw bytes using HarmonyOS ImageSource API
     * 
     * @param data Raw image file data (PNG/JPEG/WEBP)
     * @param size Data size in bytes
     * @return Decoded PremultipliedImage
     * @throws std::runtime_error if decoding fails
     */
    static std::shared_ptr<mbgl::PremultipliedImage> decodeImage(
        const uint8_t* data, size_t size);
    
    /**
     * Create icon from raw image data
     * 
     * @param data Raw image file data
     * @param size Data size in bytes
     * @param iconId Icon identifier
     * @param scale Pixel scale ratio (default 1.0)
     * @return PremultipliedImage
     */
    static std::shared_ptr<mbgl::PremultipliedImage> createFromRawData(
        const uint8_t* data, size_t size);
    
    /**
     * Create icon from rawfile resource (resources/rawfile/)
     * 
     * Uses HarmonyOS OH_ResourceManager C API to directly read rawfile
     * without going through ETS layer.
     * 
     * @param resourceMgr Native ResourceManager handle
     * @param fileName Rawfile name (e.g., "marker.png")
     * @return PremultipliedImage
     * @throws std::runtime_error if file not found or read fails
     */
    static std::shared_ptr<mbgl::PremultipliedImage> createFromRawfile(
        NativeResourceManager* resourceMgr, const std::string& fileName);
    
    /**
     * Create icon from file path
     * 
     * @param path Absolute file path
     * @return PremultipliedImage
     * @throws std::runtime_error if file not found or read fails
     */
    static std::shared_ptr<mbgl::PremultipliedImage> createFromFilePath(
        const std::string& path);
    
    /**
     * Create programmatically generated default marker icon
     * 
     * Generates a simple red circle marker icon without requiring image files.
     * Used as fallback when no icon resources are available.
     * 
     * @param size Icon size (default 48x48)
     * @return PremultipliedImage of the generated icon
     */
    static std::shared_ptr<mbgl::PremultipliedImage> createDefaultMarker(
        uint32_t size = 48);

private:
    IconFactory() = delete;  // Static-only class
};

} // namespace harmony
} // namespace mbgl

