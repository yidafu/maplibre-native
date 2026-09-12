#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/raster_source.hpp>
#include <string>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * RasterSourceNAPI - NAPI wrapper for Raster Source
 *
 * Wraps mbgl::style::RasterSource to provide an object-oriented raster tile interface.
 */
class RasterSourceNAPI {
public:
    RasterSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterSource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    RasterSourceNAPI(mbgl::style::RasterSource* sourcePtr);
    
    ~RasterSourceNAPI();
    
    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::RasterSource* sourcePtr);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetTileSize(napi_env env, napi_callback_info info);
    
    // Internal helpers
    std::string getId() const { return id; }
    mbgl::style::RasterSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::RasterSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // Release ownership
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // Create a WeakPtr after addSource
    void attachToStyle(mbgl::style::RasterSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    static napi_env constructorEnv;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::RasterSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace mbgl

