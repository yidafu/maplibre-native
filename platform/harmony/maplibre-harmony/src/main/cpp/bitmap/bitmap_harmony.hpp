#pragma once

#include <napi/native_api.h>
#include <mbgl/util/image.hpp>
#include <multimedia/image_framework/image_pixel_map_napi.h>
#include <cstdint>

namespace mbgl {
namespace harmony {

// Forward declaration
class PixelMapGuard;

/**
 * PixelMapInfo - Information about a PixelMap
 */
struct PixelMapInfo {
    uint32_t width;
    uint32_t height;
    uint32_t rowStride;  // Row stride in bytes (rowSize in OhosPixelMapInfo)
    int32_t pixelFormat;
};

/**
 * BitmapHarmony - Native PixelMap wrapper for bitmap/image data
 * 
 * This class handles conversion between HarmonyOS native PixelMap and MapLibre's
 * PremultipliedImage format using OH_PixelMap C API.
 * 
 * Design follows Android/iOS patterns with RAII resource management.
 */
class BitmapHarmony {
public:
    /**
     * Config enum for bitmap pixel format
     */
    enum class Config {
        ALPHA_8,
        RGB_565,
        ARGB_8888,
        RGBA_8888
    };

    /**
     * Extract image data from native PixelMap object
     * 
     * @param env NAPI environment
     * @param pixelMap NAPI PixelMap object (native HarmonyOS PixelMap)
     * @return PremultipliedImage containing the pixel data
     * @throws std::runtime_error if conversion fails
     */
    static PremultipliedImage GetImage(napi_env env, napi_value pixelMap);

    /**
     * Create native PixelMap from PremultipliedImage
     * 
     * @param env NAPI environment
     * @param image Source image
     * @return NAPI PixelMap object
     * @throws std::runtime_error if creation fails
     */
    static napi_value CreateBitmap(napi_env env, const PremultipliedImage& image);

    /**
     * Create empty native PixelMap with given dimensions
     * 
     * @param env NAPI environment
     * @param width Width in pixels
     * @param height Height in pixels
     * @param config Pixel format (default: RGBA_8888)
     * @return NAPI PixelMap object
     * @throws std::runtime_error if creation fails
     */
    static napi_value CreateBitmap(napi_env env, uint32_t width, uint32_t height, Config config = Config::RGBA_8888);

    /**
     * Get bitmap dimensions from native PixelMap
     * 
     * @param env NAPI environment
     * @param bitmap NAPI native PixelMap object
     * @param width Output width
     * @param height Output height
     * @return true if successful
     */
    static bool GetBitmapInfo(napi_env env, napi_value bitmap, uint32_t& width, uint32_t& height);

private:
    /**
     * Get complete PixelMap information including stride
     * 
     * @param env NAPI environment
     * @param pixelMap NAPI PixelMap object
     * @param info Output PixelMapInfo structure
     * @return true if successful
     */
    static bool GetPixelMapInfo(napi_env env, napi_value pixelMap, PixelMapInfo& info);

    /**
     * Check if pixel format is supported (RGBA_8888)
     * 
     * @param format OH_PixelMap format
     * @return true if supported
     */
    static bool IsFormatSupported(int32_t format);
    
    /**
     * Convert PixelMap to RGBA_8888 format if needed
     * The actual row-level conversion is handled in ConvertRowToRGBA during GetImage().
     *
     * @param env NAPI environment
     * @param pixelMap Source PixelMap
     * @return Original PixelMap (conversion happens during extraction)
     */
    static napi_value ConvertFormat(napi_env env, napi_value pixelMap);

    /**
     * Convert a single row of pixel data to RGBA 8-bit format.
     * Handles BGRA_8888, RGB_565, RGB_888, ALPHA_8, and similar formats.
     *
     * @param dstRow Destination buffer (must have width * 4 bytes capacity)
     * @param srcRow Source pixel row
     * @param width Number of pixels in the row
     * @param srcFormat Source pixel format (OHOS_PIXEL_MAP_FORMAT_*)
     * @param srcRowStride Source row stride in bytes
     * @return Number of bytes written to dstRow, or 0 on failure
     */
    static size_t ConvertRowToRGBA(uint8_t* dstRow, const uint8_t* srcRow,
                                    uint32_t width, int32_t srcFormat, uint32_t srcRowStride);

    /**
     * Premultiply alpha in an RGBA row in-place.
     * HarmonyOS provides straight alpha; MapLibre needs premultiplied.
     *
     * @param row RGBA pixel row
     * @param width Number of pixels
     */
    static void PremultiplyRow(uint8_t* row, uint32_t width);
};

/**
 * PixelMapGuard - RAII wrapper for PixelMap pixel access
 * 
 * Automatically locks pixels on construction and unlocks on destruction.
 * Follows the same pattern as Android's PixelGuard.
 */
class PixelMapGuard {
public:
    /**
     * Constructor - locks PixelMap pixels
     * 
     * @param env NAPI environment
     * @param pixelMap NAPI PixelMap object
     * @throws std::runtime_error if pixel locking fails
     */
    PixelMapGuard(napi_env env, napi_value pixelMap);

    /**
     * Destructor - automatically unlocks PixelMap pixels
     */
    ~PixelMapGuard();

    /**
     * Get pointer to locked pixel data
     * 
     * @return Pointer to pixel data
     */
    uint8_t* get() { return static_cast<uint8_t*>(address_); }

    // Disable copy
    PixelMapGuard(const PixelMapGuard&) = delete;
    PixelMapGuard& operator=(const PixelMapGuard&) = delete;

    // Enable move
    PixelMapGuard(PixelMapGuard&& other) noexcept;
    PixelMapGuard& operator=(PixelMapGuard&& other) noexcept;

private:
    napi_env env_;
    napi_value pixelMap_;
    void* address_;
};

} // namespace harmony
} // namespace mbgl

