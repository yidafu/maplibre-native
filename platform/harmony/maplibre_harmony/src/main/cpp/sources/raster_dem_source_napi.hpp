#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/raster_dem_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * RasterDemSourceNAPI - NAPI wrapper for Raster DEM Source
 *
 * Wraps mbgl::style::RasterDEMSource to expose an object-oriented DEM interface.
 */
class RasterDemSourceNAPI {
public:
    RasterDemSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterDEMSource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    RasterDemSourceNAPI(mbgl::style::RasterDEMSource* sourcePtr);
    
    ~RasterDemSourceNAPI();
    
    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::RasterDEMSource* sourcePtr);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetTileSize(napi_env env, napi_callback_info info);
    
    // Internal helpers
    std::string getId() const { return id; }
    mbgl::style::RasterDEMSource* getSource() const { 
        if (!source && weakSource) {
            return static_cast<mbgl::style::RasterDEMSource*>(weakSource.get());
        }
        return source.get(); 
    }
    
    // Release ownership
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // After addSource, create a WeakPtr
    void attachToStyle(mbgl::style::RasterDEMSource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }
    
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::RasterDEMSource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;
};

} // namespace harmony
} // namespace maplibre

