#pragma once

#include <napi/native_api.h>
#include <string>
#include <vector>

namespace mbgl {
namespace harmony {

/**
 * StyleBuilderNAPI - NAPI wrapper for the Style Builder.
 *
 * Provides a builder pattern for constructing and configuring map styles,
 * similar to Android's Style.Builder class.
 */
class StyleBuilderNAPI {
public:
    StyleBuilderNAPI();
    ~StyleBuilderNAPI();
    
    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Builder methods (chainable)
    static napi_value FromUri(napi_env env, napi_callback_info info);
    static napi_value FromJson(napi_env env, napi_callback_info info);
    static napi_value WithSource(napi_env env, napi_callback_info info);
    static napi_value WithLayer(napi_env env, napi_callback_info info);
    static napi_value WithImage(napi_env env, napi_callback_info info);
    static napi_value WithTransitionOptions(napi_env env, napi_callback_info info);
    
    // Getters (internal use)
    std::string getStyleUri() const { return styleUri; }
    std::string getStyleJson() const { return styleJson; }
    
    // Reference to the constructor
    static napi_ref constructor;
    static napi_env constructorEnv;
    
private:
    std::string styleUri;
    std::string styleJson;
    
    // Preloaded resources
    struct ImageData {
        std::string id;
        std::vector<uint8_t> data;
        uint32_t width;
        uint32_t height;
        float pixelRatio;
    };
    
    struct TransitionOptions {
        uint64_t duration = 300;  // milliseconds
        uint64_t delay = 0;
        bool enablePlacementTransitions = true;
    };
    
    // Preloaded resources (stored as JSON strings or serialized objects)
    std::vector<std::string> preloadedSourcesJson;
    std::vector<std::string> preloadedLayersJson;
    std::vector<ImageData> preloadedImages;
    TransitionOptions transitionOptions;
};

} // namespace harmony
} // namespace mbgl

