#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/image_source.hpp>
#include <string>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * VideoSourceNAPI - NAPI wrapper for Video Source
 *
 * There is no video source in mbgl core; mirroring the historic iOS
 * MGLVideoSource, this is a platform-level composition over an
 * mbgl::style::ImageSource. The video player (AVPlayer) runs on the ArkTS
 * side; each sampled frame is pushed into the map with updateImage().
 */
class VideoSourceNAPI {
public:
    VideoSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::ImageSource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    explicit VideoSourceNAPI(mbgl::style::ImageSource* sourcePtr);

    ~VideoSourceNAPI();

    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::ImageSource* sourcePtr);

    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);

    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetCoordinates(napi_env env, napi_callback_info info);

    // Setters
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value UpdateImage(napi_env env, napi_callback_info info);

    // Internal helpers
    std::string getId() const { return id; }
    mbgl::style::ImageSource* getSource() const {
        if (!source && weakSource) {
            return static_cast<mbgl::style::ImageSource*>(weakSource.get());
        }
        return source.get();
    }

    // Release ownership (for Style.addSource)
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        // Hand the wrapped ImageSource to the style as a Source
        return std::unique_ptr<mbgl::style::Source>(source.release());
    }

    // After addSource, keep a WeakPtr so the wrapper survives after the style
    // takes over ownership
    void attachToStyle(mbgl::style::ImageSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }

    static napi_ref constructor;
    static napi_env constructorEnv;

private:
    std::string id;
    std::unique_ptr<mbgl::style::ImageSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace mbgl
