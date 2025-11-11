#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/image_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * ImageSourceNAPI - NAPI wrapper for Image Source
 *
 * Wraps mbgl::style::ImageSource to provide an object-oriented interface.
 */
class ImageSourceNAPI {
public:
    ImageSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::ImageSource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    ImageSourceNAPI(mbgl::style::ImageSource* sourcePtr);
    
    ~ImageSourceNAPI();
    
    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::ImageSource* sourcePtr);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetImage(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    
    // Internal helpers
    std::string getId() const { return id; }
    mbgl::style::ImageSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::ImageSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // Release ownership
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // After addSource, create a WeakPtr
    void attachToStyle(mbgl::style::ImageSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::ImageSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace maplibre

