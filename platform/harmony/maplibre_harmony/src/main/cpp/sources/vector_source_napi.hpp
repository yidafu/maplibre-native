#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/vector_source.hpp>
#include <string>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * VectorSourceNAPI - NAPI wrapper for Vector Source
 *
 * Wraps mbgl::style::VectorSource to provide an object-oriented vector tile interface.
 */
class VectorSourceNAPI {
public:
    VectorSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::VectorSource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    VectorSourceNAPI(mbgl::style::VectorSource* sourcePtr);
    
    ~VectorSourceNAPI();
    
    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::VectorSource* sourcePtr);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetTiles(napi_env env, napi_callback_info info);
    
    // Internal helpers
    std::string getId() const { return id; }
    mbgl::style::VectorSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::VectorSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // Release ownership
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // After addSource, create a WeakPtr
    void attachToStyle(mbgl::style::VectorSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    static napi_env constructorEnv;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::VectorSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace mbgl

