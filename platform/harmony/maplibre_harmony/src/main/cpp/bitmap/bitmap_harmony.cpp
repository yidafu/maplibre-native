#include "bitmap_harmony.hpp"
#include "utils/logger.h"
#include <cstring>
#include <algorithm>

using mbgl::harmony::Logger;
using namespace OHOS::Media;

namespace mbgl {
namespace harmony {

// ============================================================================
// PixelMapGuard Implementation
// ============================================================================

PixelMapGuard::PixelMapGuard(napi_env env, napi_value pixelMap)
    : env_(env), pixelMap_(pixelMap), address_(nullptr) {
    // Lock pixels for access using OH_AccessPixels
    int32_t result = OH_AccessPixels(env_, pixelMap_, &address_);
    if (result != OHOS_IMAGE_RESULT_SUCCESS || !address_) {
        Logger::error("PixelMapGuard", "Failed to lock pixels, error code: %d", result);
        throw std::runtime_error("PixelMapGuard: Failed to lock pixels");
    }
    
    Logger::debug("PixelMapGuard", "Successfully locked PixelMap pixels");
}

PixelMapGuard::~PixelMapGuard() {
    if (address_) {
        int32_t result = OH_UnAccessPixels(env_, pixelMap_);
        if (result != OHOS_IMAGE_RESULT_SUCCESS) {
            Logger::error("PixelMapGuard", "Failed to unlock pixels, error code: %d", result);
        } else {
            Logger::debug("PixelMapGuard", "Successfully unlocked PixelMap pixels");
        }
    }
}

PixelMapGuard::PixelMapGuard(PixelMapGuard&& other) noexcept
    : env_(other.env_), pixelMap_(other.pixelMap_), address_(other.address_) {
    other.address_ = nullptr;
}

PixelMapGuard& PixelMapGuard::operator=(PixelMapGuard&& other) noexcept {
    if (this != &other) {
        // Unlock current pixels if any
        if (address_) {
            OH_UnAccessPixels(env_, pixelMap_);
        }
        
        env_ = other.env_;
        pixelMap_ = other.pixelMap_;
        address_ = other.address_;
        
        other.address_ = nullptr;
    }
    return *this;
}

// ============================================================================
// BitmapHarmony Private Methods
// ============================================================================

bool BitmapHarmony::GetPixelMapInfo(napi_env env, napi_value pixelMap, PixelMapInfo& info) {
    // Get image info using OH_GetImageInfo
    OhosPixelMapInfo ohosInfo;
    int32_t result = OH_GetImageInfo(env, pixelMap, &ohosInfo);
    if (result != OHOS_IMAGE_RESULT_SUCCESS) {
        Logger::error("BitmapHarmony", "Failed to get PixelMap info, error code: %d", result);
        return false;
    }

    info.width = ohosInfo.width;
    info.height = ohosInfo.height;
    info.rowStride = ohosInfo.rowSize;
    info.pixelFormat = ohosInfo.pixelFormat;

    Logger::debug("BitmapHarmony", "PixelMap info: %dx%d, stride=%d, format=%d", 
                  info.width, info.height, info.rowStride, info.pixelFormat);

    return true;
}

bool BitmapHarmony::IsFormatSupported(int32_t format) {
    // We support RGBA_8888 format
    return format == OHOS_PIXEL_MAP_FORMAT_RGBA_8888;
}

napi_value BitmapHarmony::ConvertFormat(napi_env env, napi_value pixelMap) {
    // Format conversion is not implemented yet
    // For now, just log a warning and return the original
    Logger::warn("BitmapHarmony", "Format conversion requested but not implemented");
    return pixelMap;
}

// ============================================================================
// BitmapHarmony Public Methods
// ============================================================================

PremultipliedImage BitmapHarmony::GetImage(napi_env env, napi_value pixelMap) {
    Logger::debug("BitmapHarmony", "GetImage: Converting native PixelMap to PremultipliedImage");
    
    // Get PixelMap information
    PixelMapInfo info;
    if (!GetPixelMapInfo(env, pixelMap, info)) {
        throw std::runtime_error("Failed to get PixelMap information");
    }

    // Validate dimensions
    if (info.width == 0 || info.height == 0) {
        Logger::error("BitmapHarmony", "Invalid bitmap dimensions: %dx%d", info.width, info.height);
        throw std::runtime_error("Invalid bitmap dimensions");
    }

    // Check if format is supported
    if (!IsFormatSupported(info.pixelFormat)) {
        Logger::warn("BitmapHarmony", "Unsupported pixel format: %d, attempting conversion", info.pixelFormat);
        // Try to convert format (currently not implemented)
        pixelMap = ConvertFormat(env, pixelMap);
        // Re-get info after potential conversion
        if (!GetPixelMapInfo(env, pixelMap, info)) {
            throw std::runtime_error("Failed to get PixelMap information after conversion");
        }
        if (!IsFormatSupported(info.pixelFormat)) {
            throw std::runtime_error("Unsupported pixel format and conversion failed");
        }
    }

    // Lock pixels using RAII guard
    PixelMapGuard guard(env, pixelMap);

    // Allocate memory for PremultipliedImage
    const size_t expectedLength = info.width * info.height * PremultipliedImage::channels;
    auto pixels = std::make_unique<uint8_t[]>(expectedLength);

    // Copy pixel data row by row (accounting for stride)
    for (uint32_t y = 0; y < info.height; y++) {
        auto src = guard.get() + y * info.rowStride;
        auto dst = pixels.get() + y * info.width * PremultipliedImage::channels;
        std::copy(src, src + info.width * PremultipliedImage::channels, dst);
    }

    Logger::info("BitmapHarmony", "Successfully converted native PixelMap to PremultipliedImage (%dx%d)", 
                 info.width, info.height);

    return PremultipliedImage(Size{info.width, info.height}, std::move(pixels));
}

napi_value BitmapHarmony::CreateBitmap(napi_env env, const PremultipliedImage& image) {
    Logger::debug("BitmapHarmony", "CreateBitmap: Creating native PixelMap from PremultipliedImage (%dx%d)",
                  image.size.width, image.size.height);
    
    // Note: Creating a new PixelMap from raw data requires using the Image API from ArkTS side
    // The C API OH_GetImageInfo/OH_AccessPixels only provides read access to existing PixelMaps
    // For now, we'll create a simple object representation that can be handled on the JS side
    
    Logger::warn("BitmapHarmony", "CreateBitmap: C API doesn't support creating PixelMap, returning data object");
    
    napi_value result;
    napi_create_object(env, &result);
    
    // Set width
    napi_value widthValue;
    napi_create_uint32(env, image.size.width, &widthValue);
    napi_set_named_property(env, result, "width", widthValue);
    
    // Set height
    napi_value heightValue;
    napi_create_uint32(env, image.size.height, &heightValue);
    napi_set_named_property(env, result, "height", heightValue);
    
    // Create ArrayBuffer for pixel data
    size_t byteLength = image.size.width * image.size.height * PremultipliedImage::channels;
    void* data = nullptr;
    napi_value arrayBuffer;
    napi_status status = napi_create_arraybuffer(env, byteLength, &data, &arrayBuffer);
    
    if (status != napi_ok || data == nullptr) {
        Logger::error("BitmapHarmony", "Failed to create ArrayBuffer for pixel data");
        throw std::runtime_error("Failed to create ArrayBuffer for pixel data");
    }
    
    // Copy pixel data
    std::memcpy(data, image.data.get(), byteLength);
    
    // Create Uint8Array view
    napi_value uint8Array;
    napi_create_typedarray(env, napi_uint8_array, byteLength, arrayBuffer, 0, &uint8Array);
    
    // Set data property
    napi_set_named_property(env, result, "data", uint8Array);
    
    // Set format
    napi_value formatValue;
    napi_create_string_utf8(env, "RGBA_8888", NAPI_AUTO_LENGTH, &formatValue);
    napi_set_named_property(env, result, "format", formatValue);
    
    Logger::info("BitmapHarmony", "Created data object for conversion to PixelMap on JS side");
    
    return result;
}

napi_value BitmapHarmony::CreateBitmap(napi_env env, uint32_t width, uint32_t height, Config config) {
    Logger::debug("BitmapHarmony", "CreateBitmap: Creating empty bitmap data (%dx%d)", width, height);
    
    // Create empty image with transparent pixels
    size_t byteLength = width * height * PremultipliedImage::channels;
    auto pixels = std::make_unique<uint8_t[]>(byteLength);
    std::memset(pixels.get(), 0, byteLength);
    
    PremultipliedImage image(Size{width, height}, std::move(pixels));
    return CreateBitmap(env, image);
}

bool BitmapHarmony::GetBitmapInfo(napi_env env, napi_value bitmap, uint32_t& width, uint32_t& height) {
    Logger::debug("BitmapHarmony", "GetBitmapInfo: Getting dimensions from native PixelMap");
    
    // Get PixelMap information using native API
    PixelMapInfo info;
    if (!GetPixelMapInfo(env, bitmap, info)) {
        Logger::error("BitmapHarmony", "Failed to get PixelMap info");
        return false;
    }
    
    width = info.width;
    height = info.height;
    
    Logger::debug("BitmapHarmony", "PixelMap dimensions: %dx%d", width, height);
    return true;
}

} // namespace harmony
} // namespace mbgl
