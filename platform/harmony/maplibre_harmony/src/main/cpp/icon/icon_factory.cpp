#include "icon_factory.hpp"
#include <mbgl/util/logging.hpp>

// HarmonyOS Image Kit NDK APIs (no napi_env required, @since 12)
#include <multimedia/image_framework/image/image_source_native.h>
#include <multimedia/image_framework/image/pixelmap_native.h>
#include <multimedia/image_framework/image/image_common.h>
#include <rawfile/raw_file_manager.h>
#include <rawfile/raw_file.h>

#include <cmath>
#include <cstring>
#include <fstream>
#include <sstream>
#include <vector>

namespace mbgl {
namespace harmony {

namespace {

// RAII wrapper releasing an OH_ImageSourceNative
struct ImageSourceGuard {
    OH_ImageSourceNative* source = nullptr;

    explicit ImageSourceGuard(OH_ImageSourceNative* src = nullptr) : source(src) {}
    ~ImageSourceGuard() {
        if (source) {
            OH_ImageSourceNative_Release(source);
        }
    }
    ImageSourceGuard(const ImageSourceGuard&) = delete;
    ImageSourceGuard& operator=(const ImageSourceGuard&) = delete;
};

// RAII wrapper releasing an OH_DecodingOptions
struct DecodingOptionsGuard {
    OH_DecodingOptions* options = nullptr;

    DecodingOptionsGuard() {
        if (OH_DecodingOptions_Create(&options) != IMAGE_SUCCESS) {
            options = nullptr;
        }
    }
    ~DecodingOptionsGuard() {
        if (options) {
            OH_DecodingOptions_Release(options);
        }
    }
    DecodingOptionsGuard(const DecodingOptionsGuard&) = delete;
    DecodingOptionsGuard& operator=(const DecodingOptionsGuard&) = delete;
};

// RAII wrapper releasing an OH_PixelmapNative
struct PixelmapGuard {
    OH_PixelmapNative* pixelmap = nullptr;

    explicit PixelmapGuard(OH_PixelmapNative* pm = nullptr) : pixelmap(pm) {}
    ~PixelmapGuard() {
        if (pixelmap) {
            OH_PixelmapNative_Release(pixelmap);
        }
    }
    PixelmapGuard(const PixelmapGuard&) = delete;
    PixelmapGuard& operator=(const PixelmapGuard&) = delete;
};

// RAII wrapper releasing an OH_Pixelmap_ImageInfo
struct PixelmapInfoGuard {
    OH_Pixelmap_ImageInfo* info = nullptr;

    PixelmapInfoGuard() {
        if (OH_PixelmapImageInfo_Create(&info) != IMAGE_SUCCESS) {
            info = nullptr;
        }
    }
    ~PixelmapInfoGuard() {
        if (info) {
            OH_PixelmapImageInfo_Release(info);
        }
    }
    PixelmapInfoGuard(const PixelmapInfoGuard&) = delete;
    PixelmapInfoGuard& operator=(const PixelmapInfoGuard&) = delete;
};

// RAII wrapper releasing a NativeResourceManager obtained from
// OH_ResourceManager_InitNativeResourceManager
struct NativeResourceManagerGuard {
    NativeResourceManager* mgr = nullptr;

    explicit NativeResourceManagerGuard(NativeResourceManager* m = nullptr) : mgr(m) {}
    ~NativeResourceManagerGuard() {
        if (mgr) {
            OH_ResourceManager_ReleaseNativeResourceManager(mgr);
        }
    }
    NativeResourceManagerGuard(const NativeResourceManagerGuard&) = delete;
    NativeResourceManagerGuard& operator=(const NativeResourceManagerGuard&) = delete;
};

[[noreturn]] void throwImageError(const std::string& context, Image_ErrorCode errorCode) {
    throw std::runtime_error(context + ": Image Kit error code " + std::to_string(errorCode));
}

// Convert one row of decoded pixels to straight-alpha RGBA_8888 in dstRow
// (width * 4 bytes). Mirrors BitmapHarmony's row conversion for the formats
// Image Kit can return.
size_t convertRowToRGBA(uint8_t* dstRow, const uint8_t* srcRow,
                        uint32_t width, int32_t srcFormat) {
    switch (srcFormat) {
    case PIXEL_FORMAT_RGBA_8888:
        std::memcpy(dstRow, srcRow, static_cast<size_t>(width) * 4);
        return static_cast<size_t>(width) * 4;
    case PIXEL_FORMAT_BGRA_8888:
        for (uint32_t x = 0; x < width; x++) {
            const uint8_t* pixel = srcRow + x * 4;
            dstRow[x * 4 + 0] = pixel[2];  // R
            dstRow[x * 4 + 1] = pixel[1];  // G
            dstRow[x * 4 + 2] = pixel[0];  // B
            dstRow[x * 4 + 3] = pixel[3];  // A
        }
        return static_cast<size_t>(width) * 4;
    case PIXEL_FORMAT_RGB_565:
        for (uint32_t x = 0; x < width; x++) {
            const uint16_t pixel = *reinterpret_cast<const uint16_t*>(srcRow + x * 2);
            dstRow[x * 4 + 0] = static_cast<uint8_t>(((pixel >> 11) & 0x1F) * 255 / 31);
            dstRow[x * 4 + 1] = static_cast<uint8_t>(((pixel >> 5) & 0x3F) * 255 / 63);
            dstRow[x * 4 + 2] = static_cast<uint8_t>((pixel & 0x1F) * 255 / 31);
            dstRow[x * 4 + 3] = 255;
        }
        return static_cast<size_t>(width) * 4;
    case PIXEL_FORMAT_RGB_888:
        for (uint32_t x = 0; x < width; x++) {
            dstRow[x * 4 + 0] = srcRow[x * 3 + 0];
            dstRow[x * 4 + 1] = srcRow[x * 3 + 1];
            dstRow[x * 4 + 2] = srcRow[x * 3 + 2];
            dstRow[x * 4 + 3] = 255;
        }
        return static_cast<size_t>(width) * 4;
    case PIXEL_FORMAT_ALPHA_8:
        for (uint32_t x = 0; x < width; x++) {
            const uint8_t alpha = srcRow[x];
            dstRow[x * 4 + 0] = alpha;
            dstRow[x * 4 + 1] = alpha;
            dstRow[x * 4 + 2] = alpha;
            dstRow[x * 4 + 3] = alpha;
        }
        return static_cast<size_t>(width) * 4;
    default:
        return 0;
    }
}

// Premultiply one RGBA row in place (HarmonyOS decodes straight alpha;
// PremultipliedImage requires premultiplied alpha).
void premultiplyRow(uint8_t* row, uint32_t width) {
    for (uint32_t x = 0; x < width; x++) {
        const uint8_t alpha = row[x * 4 + 3];
        if (alpha == 255) continue;
        if (alpha == 0) {
            row[x * 4 + 0] = 0;
            row[x * 4 + 1] = 0;
            row[x * 4 + 2] = 0;
            continue;
        }
        row[x * 4 + 0] = static_cast<uint8_t>(row[x * 4 + 0] * alpha / 255);
        row[x * 4 + 1] = static_cast<uint8_t>(row[x * 4 + 1] * alpha / 255);
        row[x * 4 + 2] = static_cast<uint8_t>(row[x * 4 + 2] * alpha / 255);
    }
}

// Convert a decoded OH_PixelmapNative into a PremultipliedImage.
std::shared_ptr<mbgl::PremultipliedImage> decodePixelmap(OH_PixelmapNative* pixelmap) {
    if (!pixelmap) {
        throw std::runtime_error("[IconFactory] Decoding produced no PixelMap");
    }
    PixelmapGuard pixelmapGuard(pixelmap);

    PixelmapInfoGuard infoGuard;
    if (!infoGuard.info) {
        throw std::runtime_error("[IconFactory] Failed to create PixelMap info object");
    }
    Image_ErrorCode err = OH_PixelmapNative_GetImageInfo(pixelmap, infoGuard.info);
    if (err != IMAGE_SUCCESS) {
        throwImageError("[IconFactory] Failed to get PixelMap info", err);
    }

    uint32_t width = 0;
    uint32_t height = 0;
    uint32_t rowStride = 0;
    int32_t pixelFormat = 0;
    OH_PixelmapImageInfo_GetWidth(infoGuard.info, &width);
    OH_PixelmapImageInfo_GetHeight(infoGuard.info, &height);
    OH_PixelmapImageInfo_GetRowStride(infoGuard.info, &rowStride);
    OH_PixelmapImageInfo_GetPixelFormat(infoGuard.info, &pixelFormat);

    if (width == 0 || height == 0) {
        throw std::runtime_error("[IconFactory] Decoded image has invalid dimensions");
    }

    const size_t dstRowBytes = static_cast<size_t>(width) * PremultipliedImage::channels;
    const size_t srcRowBytes = rowStride > 0 ? rowStride : dstRowBytes;
    const size_t bufferSize = srcRowBytes * height;

    std::vector<uint8_t> pixels(bufferSize);
    size_t inOutBufferSize = bufferSize;
    err = OH_PixelmapNative_ReadPixels(pixelmap, pixels.data(), &inOutBufferSize);
    if (err != IMAGE_SUCCESS) {
        throwImageError("[IconFactory] Failed to read PixelMap pixels", err);
    }

    auto image = std::make_shared<mbgl::PremultipliedImage>(mbgl::Size{width, height});
    for (uint32_t y = 0; y < height; y++) {
        const uint8_t* srcRow = pixels.data() + y * srcRowBytes;
        uint8_t* dstRow = image->data.get() + y * dstRowBytes;
        const size_t written = convertRowToRGBA(dstRow, srcRow, width, pixelFormat);
        if (written == 0) {
            throw std::runtime_error("[IconFactory] Unsupported decoded pixel format: " +
                                     std::to_string(pixelFormat));
        }
        premultiplyRow(dstRow, width);
    }

    return image;
}

} // anonymous namespace

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::decodeImage(
    const uint8_t* data, size_t size) {

    if (!data || size == 0) {
        throw std::runtime_error("[IconFactory] Invalid image data: null or empty");
    }

    // Create an ImageSource from the encoded file bytes (PNG/JPEG/WEBP/...)
    ImageSourceGuard sourceGuard;
    Image_ErrorCode err =
        OH_ImageSourceNative_CreateFromData(const_cast<uint8_t*>(data), size, &sourceGuard.source);
    if (err != IMAGE_SUCCESS || !sourceGuard.source) {
        throwImageError("[IconFactory] Failed to create ImageSource from data", err);
    }

    // Decode to RGBA_8888 regardless of the source format
    DecodingOptionsGuard optionsGuard;
    if (!optionsGuard.options) {
        throw std::runtime_error("[IconFactory] Failed to create decoding options");
    }
    err = OH_DecodingOptions_SetPixelFormat(optionsGuard.options, PIXEL_FORMAT_RGBA_8888);
    if (err != IMAGE_SUCCESS) {
        throwImageError("[IconFactory] Failed to set desired pixel format", err);
    }

    PixelmapGuard pixelmapGuard;
    err = OH_ImageSourceNative_CreatePixelmap(sourceGuard.source, optionsGuard.options,
                                              &pixelmapGuard.pixelmap);
    if (err != IMAGE_SUCCESS || !pixelmapGuard.pixelmap) {
        throwImageError("[IconFactory] Failed to decode image", err);
    }

    return decodePixelmap(pixelmapGuard.pixelmap);
}

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::createFromRawData(
    const uint8_t* data, size_t size) {
    return decodeImage(data, size);
}

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::createFromRawfile(
    NativeResourceManager* resourceMgr, const std::string& fileName) {

    if (!resourceMgr) {
        throw std::runtime_error("[IconFactory] NativeResourceManager is null");
    }

    RawFile* rawFile = OH_ResourceManager_OpenRawFile(resourceMgr, fileName.c_str());
    if (!rawFile) {
        throw std::runtime_error("[IconFactory] Cannot open rawfile: " + fileName);
    }

    const long rawFileSize = OH_ResourceManager_GetRawFileSize(rawFile);
    if (rawFileSize <= 0) {
        OH_ResourceManager_CloseRawFile(rawFile);
        throw std::runtime_error("[IconFactory] Empty rawfile: " + fileName);
    }

    std::vector<uint8_t> fileData(static_cast<size_t>(rawFileSize));
    const long bytesRead = OH_ResourceManager_ReadRawFile(rawFile, fileData.data(), rawFileSize);
    OH_ResourceManager_CloseRawFile(rawFile);

    if (bytesRead != rawFileSize) {
        throw std::runtime_error("[IconFactory] Failed to read rawfile: " + fileName);
    }

    return decodeImage(fileData.data(), fileData.size());
}

std::shared_ptr<mbgl::PremultipliedImage> IconFactory::createFromFilePath(
    const std::string& path) {

    std::ifstream file(path, std::ios::binary | std::ios::ate);
    if (!file.is_open()) {
        throw std::runtime_error("[IconFactory] Cannot open file: " + path);
    }

    const std::streamsize fileSize = file.tellg();
    if (fileSize <= 0) {
        throw std::runtime_error("[IconFactory] Empty or invalid file: " + path);
    }
    file.seekg(0, std::ios::beg);

    std::vector<uint8_t> fileData(static_cast<size_t>(fileSize));
    if (!file.read(reinterpret_cast<char*>(fileData.data()), fileSize)) {
        throw std::runtime_error("[IconFactory] Failed to read file: " + path);
    }

    return decodeImage(fileData.data(), fileData.size());
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
