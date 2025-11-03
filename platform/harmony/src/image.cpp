#include <mbgl/util/image.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/premultiply.hpp>

#include <multimedia/image_framework/image/image_source_native.h>
#include <multimedia/image_framework/image/pixelmap_native.h>
#include <multimedia/image_framework/image/image_common.h>

#include <memory>
#include <string>
#include <cstring>

namespace mbgl {

namespace {

// RAII wrapper for OH_ImageSourceNative
class ImageSourceGuard {
public:
    explicit ImageSourceGuard(OH_ImageSourceNative* src) : source(src) {}
    ~ImageSourceGuard() {
        if (source) {
            OH_ImageSourceNative_Release(source);
        }
    }
    ImageSourceGuard(const ImageSourceGuard&) = delete;
    ImageSourceGuard& operator=(const ImageSourceGuard&) = delete;
    OH_ImageSourceNative* get() const { return source; }
private:
    OH_ImageSourceNative* source;
};

// RAII wrapper for OH_PixelmapNative
class PixelMapGuard {
public:
    explicit PixelMapGuard(OH_PixelmapNative* pm) : pixelmap(pm) {}
    ~PixelMapGuard() {
        if (pixelmap) {
            OH_PixelmapNative_Release(pixelmap);
        }
    }
    PixelMapGuard(const PixelMapGuard&) = delete;
    PixelMapGuard& operator=(const PixelMapGuard&) = delete;
    OH_PixelmapNative* get() const { return pixelmap; }
private:
    OH_PixelmapNative* pixelmap;
};

// RAII wrapper for OH_DecodingOptions
class DecodingOptionsGuard {
public:
    explicit DecodingOptionsGuard(OH_DecodingOptions* opts) : options(opts) {}
    ~DecodingOptionsGuard() {
        if (options) {
            OH_DecodingOptions_Release(options);
        }
    }
    DecodingOptionsGuard(const DecodingOptionsGuard&) = delete;
    DecodingOptionsGuard& operator=(const DecodingOptionsGuard&) = delete;
    OH_DecodingOptions* get() const { return options; }
private:
    OH_DecodingOptions* options;
};

} // anonymous namespace

PremultipliedImage decodeImage(const std::string& string) {
    if (string.empty()) {
        Log::Warning(Event::General, "Attempting to decode empty image data");
        return PremultipliedImage({0, 0});
    }
    
    // 1. Create ImageSource from raw data
    OH_ImageSourceNative* imageSource = nullptr;
    Image_ErrorCode error = OH_ImageSourceNative_CreateFromData(
        reinterpret_cast<uint8_t*>(const_cast<char*>(string.data())),
        string.size(),
        &imageSource
    );
    
    if (error != IMAGE_SUCCESS || !imageSource) {
        throw std::runtime_error("Failed to create ImageSource");
    }
    
    ImageSourceGuard sourceGuard(imageSource);
    
    // 2. Create decoding options
    OH_DecodingOptions* decodingOptions = nullptr;
    error = OH_DecodingOptions_Create(&decodingOptions);
    if (error != IMAGE_SUCCESS || !decodingOptions) {
        throw std::runtime_error("Failed to create DecodingOptions");
    }
    
    DecodingOptionsGuard optionsGuard(decodingOptions);
    
    // 3. Set pixel format to RGBA_8888
    error = OH_DecodingOptions_SetPixelFormat(decodingOptions, PIXEL_FORMAT_RGBA_8888);
    if (error != IMAGE_SUCCESS) {
        throw std::runtime_error("Failed to set pixel format");
    }
    
    // 4. Decode image to PixelMap
    OH_PixelmapNative* pixelMap = nullptr;
    error = OH_ImageSourceNative_CreatePixelmap(imageSource, decodingOptions, &pixelMap);
    if (error != IMAGE_SUCCESS || !pixelMap) {
        throw std::runtime_error("Failed to decode image to PixelMap");
    }
    
    PixelMapGuard pixelMapGuard(pixelMap);
    
    // 5. Get image information
    OH_Pixelmap_ImageInfo* imageInfo = nullptr;
    error = OH_PixelmapImageInfo_Create(&imageInfo);
    if (error != IMAGE_SUCCESS || !imageInfo) {
        throw std::runtime_error("Failed to create PixelmapImageInfo");
    }
    
    error = OH_PixelmapNative_GetImageInfo(pixelMap, imageInfo);
    if (error != IMAGE_SUCCESS) {
        OH_PixelmapImageInfo_Release(imageInfo);
        throw std::runtime_error("Failed to get image info");
    }
    
    uint32_t width = 0, height = 0;
    int32_t alphaType = 0;
    
    OH_PixelmapImageInfo_GetWidth(imageInfo, &width);
    OH_PixelmapImageInfo_GetHeight(imageInfo, &height);
    OH_PixelmapImageInfo_GetAlphaType(imageInfo, &alphaType);
    
    OH_PixelmapImageInfo_Release(imageInfo);
    
    if (width == 0 || height == 0) {
        throw std::runtime_error("Invalid image dimensions");
    }
    
    // 6. Read pixel data
    size_t bufferSize = width * height * 4; // RGBA = 4 bytes per pixel
    auto pixels = std::make_unique<uint8_t[]>(bufferSize);
    
    size_t actualSize = bufferSize;
    error = OH_PixelmapNative_ReadPixels(pixelMap, pixels.get(), &actualSize);
    if (error != IMAGE_SUCCESS) {
        throw std::runtime_error("Failed to read pixel data");
    }
    
    // 7. Check if we need to premultiply alpha
    // HarmonyOS may return unpremultiplied alpha, but MapLibre needs premultiplied
    if (alphaType == PIXELMAP_ALPHA_TYPE_UNPREMULTIPLIED) {
        Log::Info(Event::General, 
                  "HarmonyOS decodeImage: Converting from unpremultiplied to premultiplied alpha");
        
        // Convert to premultiplied alpha
        for (size_t i = 0; i < bufferSize; i += 4) {
            uint8_t a = pixels[i + 3];
            if (a < 255) {
                pixels[i + 0] = (pixels[i + 0] * a) / 255; // R
                pixels[i + 1] = (pixels[i + 1] * a) / 255; // G
                pixels[i + 2] = (pixels[i + 2] * a) / 255; // B
            }
        }
    }
    
    Log::Info(Event::General, 
              "HarmonyOS decodeImage: Successfully decoded image using HarmonyOS Image API");
    
    return PremultipliedImage({width, height}, std::move(pixels));
}

} // namespace mbgl