#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/image_source.hpp>
#include <string>
#include <memory>

#include "source_napi_base.hpp"

namespace mbgl {
namespace harmony {

/**
 * ImageSourceNAPI - NAPI wrapper for Image Source
 *
 * Wraps mbgl::style::ImageSource to provide an object-oriented interface.
 * Ownership state and the shared accessors live in SourceNapiBase.
 */
class ImageSourceNAPI : public SourceNapiBase<ImageSourceNAPI, mbgl::style::ImageSource> {
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

    static napi_ref constructor;
    static napi_env constructorEnv;
};

} // namespace harmony
} // namespace mbgl
