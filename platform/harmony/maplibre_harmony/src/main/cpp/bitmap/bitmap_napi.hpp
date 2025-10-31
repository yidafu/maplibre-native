#pragma once

#include <napi/native_api.h>
#include <mbgl/util/image.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * BitmapNAPI - NAPI wrapper for Bitmap/Image data
 * 
 * Wraps PremultipliedImage to provide bitmap functionality for HarmonyOS
 * Used for addImage, snapshot, etc.
 */
class BitmapNAPI {
public:
    BitmapNAPI(std::shared_ptr<mbgl::PremultipliedImage> image);
    ~BitmapNAPI();
    
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property getters
    static napi_value GetWidth(napi_env env, napi_callback_info info);
    static napi_value GetHeight(napi_env env, napi_callback_info info);
    static napi_value GetPixels(napi_env env, napi_callback_info info);
    
    // Utility methods
    static napi_value GetConfig(napi_env env, napi_callback_info info);
    static napi_value IsMutable(napi_env env, napi_callback_info info);
    
    // Create from PremultipliedImage
    static napi_value CreateFromImage(napi_env env, 
                                     const std::string& id,
                                     std::shared_ptr<mbgl::PremultipliedImage> image);
    
    // Internal methods
    std::shared_ptr<mbgl::PremultipliedImage> getImage() const { return image; }
    
    // Helper to check if a napi_value is a Bitmap object
    static bool IsBitmapObject(napi_env env, napi_value value);
    
    // Helper to unwrap BitmapNAPI from napi_value
    static BitmapNAPI* Unwrap(napi_env env, napi_value value);
    
    // Constructor reference
    static napi_ref constructor;
    
private:
    std::shared_ptr<mbgl::PremultipliedImage> image;
    std::string id;
};

} // namespace harmony
} // namespace mbgl

