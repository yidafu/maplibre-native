#pragma once

#include <napi/native_api.h>
#include <mbgl/util/image.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * IconNAPI - NAPI wrapper for Icon
 * 
 * This class wraps an icon's bitmap data and exposes it to ETS/TypeScript via NAPI.
 * It manages the icon's image data in C++ layer, eliminating the need for repeated
 * PixelMap-to-bytes conversions.
 * 
 * Key optimization: PixelMap is converted to PremultipliedImage once during construction,
 * then the image data is directly used when adding to the map style.
 */
class IconNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetWidth(napi_env env, napi_callback_info info);
    static napi_value GetHeight(napi_env env, napi_callback_info info);
    static napi_value GetScale(napi_env env, napi_callback_info info);
    static napi_value IsReleased(napi_env env, napi_callback_info info);
    
    // Resource management
    static napi_value Release(napi_env env, napi_callback_info info);
    
    // Internal access methods (for C++ use)
    std::string getId() const { return id; }
    int getWidth() const { return width; }
    int getHeight() const { return height; }
    float getScale() const { return scale; }
    bool isReleasedInternal() const { return !image; }
    
    // Get the image data (returns nullptr if released)
    std::shared_ptr<mbgl::PremultipliedImage> getImage() const { return image; }
    
    // Helper to check if a napi_value is an Icon object
    static bool IsIconObject(napi_env env, napi_value value);
    
    /**
     * Create Icon NAPI object from PremultipliedImage (for C++ internal use)
     * 
     * This method is used by IconFactory NAPI to create Icon objects
     * without going through the PixelMap conversion.
     * 
     * @param env NAPI environment
     * @param id Icon identifier
     * @param image Shared pointer to PremultipliedImage
     * @param scale Pixel scale ratio
     * @return Icon NAPI object
     */
    static napi_value CreateFromImage(napi_env env, 
                                     const std::string& id,
                                     std::shared_ptr<mbgl::PremultipliedImage> image,
                                     float scale);
    
private:
    static napi_ref constructor;
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    explicit IconNAPI(std::string id, int width, int height, float scale, 
                      std::shared_ptr<mbgl::PremultipliedImage> image);
    ~IconNAPI();
    
    // Icon state
    std::string id;
    int width;
    int height;
    float scale;
    std::shared_ptr<mbgl::PremultipliedImage> image;  // nullptr when released
};

} // namespace harmony
} // namespace maplibre

