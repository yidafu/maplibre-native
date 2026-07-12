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

}

PixelMapGuard::~PixelMapGuard() {
    if (address_) {
        int32_t result = OH_UnAccessPixels(env_, pixelMap_);
        if (result != OHOS_IMAGE_RESULT_SUCCESS) {
            Logger::error("PixelMapGuard", "Failed to unlock pixels, error code: %d", result);
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

    return true;
}

bool BitmapHarmony::IsFormatSupported(int32_t format) {
    // We support RGBA_8888 directly; other formats require conversion
    return format == OHOS_PIXEL_MAP_FORMAT_RGBA_8888;
}

// Convert a single row of pixel data to RGBA premultiplied format
// Returns the number of bytes written to dstRow
// dstRow must have capacity of width * 4 bytes
size_t BitmapHarmony::ConvertRowToRGBA(uint8_t* dstRow, const uint8_t* srcRow,
                                        uint32_t width, int32_t srcFormat, uint32_t srcRowStride) {
    // PixelMap format constants (numeric values from image_pixel_map_napi.h)
    // OHOS_PIXEL_MAP_FORMAT_NONE      = 0
    // OHOS_PIXEL_MAP_FORMAT_RGB_565   = 2
    // OHOS_PIXEL_MAP_FORMAT_RGBA_8888 = 3
    // Additional common formats not defined in current SDK:
    constexpr int32_t FMT_BGRA_8888 = 4;
    constexpr int32_t FMT_RGB_888   = 5;
    constexpr int32_t FMT_ALPHA_8    = 6;

    switch (srcFormat) {
    case OHOS_PIXEL_MAP_FORMAT_RGBA_8888: {
        // Direct copy (PremultipliedImage stores RGBA)
        std::copy(srcRow, srcRow + width * 4, dstRow);
        return width * 4;
    }
    case FMT_BGRA_8888: {
        // BGRA -> RGBA: swap R and B
        for (uint32_t x = 0; x < width; x++) {
            const uint8_t* pixel = srcRow + x * 4;
            dstRow[x * 4 + 0] = pixel[2];  // R
            dstRow[x * 4 + 1] = pixel[1];  // G
            dstRow[x * 4 + 2] = pixel[0];  // B
            dstRow[x * 4 + 3] = pixel[3];  // A
        }
        return width * 4;
    }
    case OHOS_PIXEL_MAP_FORMAT_RGB_565: {
        // Each pixel is 2 bytes (16-bit): RRRRR GGGGGG BBBBB
        for (uint32_t x = 0; x < width; x++) {
            const uint16_t pixel = *reinterpret_cast<const uint16_t*>(srcRow + x * 2);
            uint8_t r = ((pixel >> 11) & 0x1F) * 255 / 31;
            uint8_t g = ((pixel >> 5)  & 0x3F) * 255 / 63;
            uint8_t b = (pixel        & 0x1F) * 255 / 31;
            dstRow[x * 4 + 0] = r;
            dstRow[x * 4 + 1] = g;
            dstRow[x * 4 + 2] = b;
            dstRow[x * 4 + 3] = 255;
        }
        return width * 4;
    }
    case FMT_RGB_888: {
        // Each pixel is 3 bytes: R, G, B
        for (uint32_t x = 0; x < width; x++) {
            dstRow[x * 4 + 0] = srcRow[x * 3 + 0];  // R
            dstRow[x * 4 + 1] = srcRow[x * 3 + 1];  // G
            dstRow[x * 4 + 2] = srcRow[x * 3 + 2];  // B
            dstRow[x * 4 + 3] = 255;                  // A (fully opaque)
        }
        return width * 4;
    }
    case FMT_ALPHA_8: {
        // Single channel: alpha only -> RGBA with white as color
        for (uint32_t x = 0; x < width; x++) {
            uint8_t a = srcRow[x];
            dstRow[x * 4 + 0] = a;
            dstRow[x * 4 + 1] = a;
            dstRow[x * 4 + 2] = a;
            dstRow[x * 4 + 3] = a;
        }
        return width * 4;
    }
    default:
        Logger::error("BitmapHarmony", "Unsupported pixel format: %d", srcFormat);
        return 0;
    }
}

// Premultiply an RGBA row in-place
void BitmapHarmony::PremultiplyRow(uint8_t* row, uint32_t width) {
    for (uint32_t x = 0; x < width; x++) {
        uint8_t a = row[x * 4 + 3];
        if (a == 255) continue;  // Already fully opaque, skip
        if (a == 0) {
            // Fully transparent
            row[x * 4 + 0] = 0;
            row[x * 4 + 1] = 0;
            row[x * 4 + 2] = 0;
            continue;
        }
        row[x * 4 + 0] = row[x * 4 + 0] * a / 255;
        row[x * 4 + 1] = row[x * 4 + 1] * a / 255;
        row[x * 4 + 2] = row[x * 4 + 2] * a / 255;
    }
}

napi_value BitmapHarmony::ConvertFormat(napi_env env, napi_value pixelMap) {
    // ConvertFormat now returns the same PixelMap but logging is done
    // The actual format conversion happens in GetImage() during row copy
    Logger::info("BitmapHarmony", "Format conversion will be handled during GetImage()");
    return pixelMap;
}

// ============================================================================
// BitmapHarmony Public Methods
// ============================================================================

PremultipliedImage BitmapHarmony::GetImage(napi_env env, napi_value pixelMap) {
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

    // Lock pixels using RAII guard
    PixelMapGuard guard(env, pixelMap);

    // Allocate memory for PremultipliedImage (always RGBA)
    const size_t channels = PremultipliedImage::channels;  // 4
    const size_t dstRowBytes = info.width * channels;
    const size_t expectedLength = info.height * dstRowBytes;
    auto pixels = std::make_unique<uint8_t[]>(expectedLength);

    if (IsFormatSupported(info.pixelFormat)) {
        // RGBA_8888: direct copy row by row, then premultiply
        for (uint32_t y = 0; y < info.height; y++) {
            auto src = guard.get() + y * info.rowStride;
            auto dst = pixels.get() + y * dstRowBytes;
            std::copy(src, src + dstRowBytes, dst);
        }
        // Premultiply: RGBA_8888 from HarmonyOS is straight alpha, but
        // PremultipliedImage expects premultiplied alpha
        for (uint32_t y = 0; y < info.height; y++) {
            PremultiplyRow(pixels.get() + y * dstRowBytes, info.width);
        }
    } else {
        // Convert from other pixel formats row by row
        Logger::info("BitmapHarmony", "Converting pixel format %d to RGBA (premultiplied)", info.pixelFormat);

        for (uint32_t y = 0; y < info.height; y++) {
            auto src = guard.get() + y * info.rowStride;
            auto dst = pixels.get() + y * dstRowBytes;
            size_t written = ConvertRowToRGBA(dst, src, info.width, info.pixelFormat, info.rowStride);
            if (written == 0) {
                throw std::runtime_error("Failed to convert pixel row: unsupported format");
            }
        }
    }

    Logger::info("BitmapHarmony", "Successfully converted native PixelMap to PremultipliedImage (%dx%d, format=%d)",
                 info.width, info.height, info.pixelFormat);

    return PremultipliedImage(Size{info.width, info.height}, std::move(pixels));
}

napi_value BitmapHarmony::CreateBitmap(napi_env env, const PremultipliedImage& image) {
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
    // Create empty image with transparent pixels
    size_t byteLength = width * height * PremultipliedImage::channels;
    auto pixels = std::make_unique<uint8_t[]>(byteLength);
    std::memset(pixels.get(), 0, byteLength);
    
    PremultipliedImage image(Size{width, height}, std::move(pixels));
    return CreateBitmap(env, image);
}

bool BitmapHarmony::GetBitmapInfo(napi_env env, napi_value bitmap, uint32_t& width, uint32_t& height) {
    // Get PixelMap information using native API
    PixelMapInfo info;
    if (!GetPixelMapInfo(env, bitmap, info)) {
        Logger::error("BitmapHarmony", "Failed to get PixelMap info");
        return false;
    }
    
    width = info.width;
    height = info.height;
    
    return true;
}

} // namespace harmony
} // namespace mbgl
