#include "icon_factory.hpp"
#include <mbgl/util/logging.hpp>

// HarmonyOS Image APIs - not used in C++ layer
// Image decoding requires napi_env, handled in ETS layer instead
// #include <rawfile/raw_file_manager.h>
// #include <rawfile/raw_file.h>
// #include <multimedia/image_framework/image_source_mdk.h>
// #include <multimedia/image_framework/image_pixel_map_mdk.h>

#include <cmath>
#include <cstring>
#include <sstream>

namespace mbgl {
namespace harmony {

namespace {
// RAII wrappers commented out - will be implemented when correct API is available
} // anonymous namespace

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::decodeImage(
    const uint8_t* data, size_t size) {
    
    if (!data || size == 0) {
        throw std::runtime_error("[IconFactory] Invalid image data: null or empty");
    }
    
    std::ostringstream oss;
    oss << "[IconFactory] Decoding image from raw data, size=" << size << " bytes";
    mbgl::Log::Info(mbgl::Event::General, oss.str());
    
    // TODO: Implement image decoding using correct HarmonyOS ImageSource API
    // The API requires NAPI environment and napi_value, not raw bytes
    // This needs to be called from NAPI layer with proper context
    
    throw std::runtime_error(
        "[IconFactory] decodeImage not yet implemented. "
        "HarmonyOS ImageSource API requires NAPI context. "
        "Use fromResourceData() from ETS layer instead."
    );
}

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::createFromRawData(
    const uint8_t* data, size_t size) {
    return decodeImage(data, size);
}

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::createFromRawfile(
    NativeResourceManager* /*resourceMgr*/, const std::string& fileName) {
    
    std::ostringstream oss;
    oss << "[IconFactory] Loading icon from rawfile: " << fileName;
    mbgl::Log::Info(mbgl::Event::General, oss.str());
    
    // NOTE: Image decoding in C++ requires napi_env which is not available in this context
    // HarmonyOS Image APIs (OH_ImageSource_CreateFromData, etc.) require napi_env parameter
    // Rawfile loading is better handled in ETS layer using IconFactory.fromRawfile()
    throw std::runtime_error(
        "[IconFactory] createFromRawfile not implemented. "
        "Use ETS IconFactory.fromRawfile() which handles ResourceManager and image decoding properly."
    );
}

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::createFromFilePath(
    const std::string& path) {
    
    std::ostringstream oss;
    oss << "[IconFactory] Loading icon from file: " << path;
    mbgl::Log::Info(mbgl::Event::General, oss.str());
    
    // TODO: Implement file path loading
    // Need to read file and decode using correct API
    throw std::runtime_error(
        "[IconFactory] createFromFilePath not yet implemented. "
        "Use fromResource() from ETS layer instead."
    );
}

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::createDefaultMarker(
    uint32_t size) {
    
    std::ostringstream oss;
    oss << "[IconFactory] Creating programmatic default marker (RED pin shape): " << size << "x" << size;
    mbgl::Log::Info(mbgl::Event::General, oss.str());
    
    // Create empty image
    auto image = std::make_shared<mbgl::PremultipliedImage>(
        mbgl::Size{size, size}
    );
    
    uint8_t* data = image->data.get();
    
    // Generate pin-shaped marker (similar to the Google Maps location pin)
    // Pin consists of a circular head plus a pointed tail
    const float centerX = size / 2.0f;
    const float headCenterY = size * 0.35f;  // Head center position (upper portion)
    const float headRadius = size * 0.25f;   // Head circular radius
    const float tipY = size * 0.9f;          // Tip Y coordinate (lower portion)
    
    // Color: RED (#FF0000) - standard map marker color
    const uint8_t red = 255;
    const uint8_t green = 0;
    const uint8_t blue = 0;
    const uint8_t alpha = 255;
    
    for (uint32_t y = 0; y < size; y++) {
        for (uint32_t x = 0; x < size; x++) {
            const float dx = x - centerX;
            const float dy = y - headCenterY;
            const float distance = std::sqrt(dx * dx + dy * dy);
            
            const size_t offset = (y * size + x) * 4;
            
            bool isInside = false;
            
            // 1. Circular head
            if (distance <= headRadius) {
                isInside = true;
            }
            // 2. Triangular tip (from head center downward to the point)
            else if (y > headCenterY) {
                // Compute triangle boundaries (isosceles triangle between head base and tip)
                const float triangleY = y - headCenterY;
                const float maxWidth = headRadius * (1.0f - (triangleY / (tipY - headCenterY)));
                if (std::abs(dx) <= maxWidth) {
                    isInside = true;
                }
            }
            
            if (isInside) {
                // Pin interior - red
                data[offset + 0] = red;
                data[offset + 1] = green;
                data[offset + 2] = blue;
                data[offset + 3] = alpha;
            } else {
                // Pin exterior - fully transparent
                data[offset + 0] = 0;
                data[offset + 1] = 0;
                data[offset + 2] = 0;
                data[offset + 3] = 0;
            }
        }
    }
    
    mbgl::Log::Info(mbgl::Event::General, "[IconFactory] Default RED pin-shaped marker created successfully");
    
    return image;
}

} // namespace harmony
} // namespace mbgl

