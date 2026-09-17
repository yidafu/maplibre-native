#pragma once

#include <napi/native_api.h>
#include <mbgl/style/image.hpp>
#include <mbgl/util/image.hpp>
#include <string>
#include <memory>
#include <vector>
#include <optional>

namespace mbgl {
namespace harmony {

/**
 * ImageNAPI - NAPI wrapper for Style Image
 * 
 * This class wraps an image's data and metadata, exposing it to ETS/TypeScript via NAPI.
 * It manages the image data in C++ layer and provides conversion to mbgl::style::Image.
 * 
 * Supports advanced features:
 * - SDF (Signed Distance Field) images for dynamic coloring
 * - Stretchable images (9-patch style) with stretchX and stretchY
 * - Content area definition for text placement
 */
class ImageNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetName(napi_env env, napi_callback_info info);
    static napi_value GetWidth(napi_env env, napi_callback_info info);
    static napi_value GetHeight(napi_env env, napi_callback_info info);
    static napi_value GetPixelRatio(napi_env env, napi_callback_info info);
    static napi_value GetSdf(napi_env env, napi_callback_info info);
    static napi_value GetData(napi_env env, napi_callback_info info);
    static napi_value GetStretchX(napi_env env, napi_callback_info info);
    static napi_value GetStretchY(napi_env env, napi_callback_info info);
    static napi_value GetContent(napi_env env, napi_callback_info info);
    
    // Conversion method - for internal C++ use
    std::unique_ptr<mbgl::style::Image> toStyleImage() const;
    
    // Internal access methods
    std::string getName() const { return name; }
    uint32_t getWidth() const { return width; }
    uint32_t getHeight() const { return height; }
    float getPixelRatio() const { return pixelRatio; }
    bool isSdf() const { return sdf; }
    
    // Helper to check if a napi_value is an Image object
    static bool IsImageObject(napi_env env, napi_value value);
    
    // Helper to unwrap ImageNAPI from napi_value
    static ImageNAPI* Unwrap(napi_env env, napi_value value);
    
private:
    static napi_ref constructor;
    static napi_env constructorEnv;
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    explicit ImageNAPI(
        std::string name,
        uint32_t width,
        uint32_t height,
        float pixelRatio,
        bool sdf,
        std::shared_ptr<std::vector<uint8_t>> data,
        std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchX = std::nullopt,
        std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchY = std::nullopt,
        std::optional<mbgl::style::ImageContent> content = std::nullopt
    );
    ~ImageNAPI();
    
    // Image metadata
    std::string name;
    uint32_t width;
    uint32_t height;
    float pixelRatio;
    bool sdf;
    
    // Image data (RGBA premultiplied)
    std::shared_ptr<std::vector<uint8_t>> data;
    
    // Stretchable image support
    std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchX;
    std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchY;
    
    // Content area for text placement
    std::optional<mbgl::style::ImageContent> content;
};

} // namespace harmony
} // namespace mbgl

