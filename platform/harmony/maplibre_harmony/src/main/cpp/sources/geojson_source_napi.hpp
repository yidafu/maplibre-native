#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/geojson_source.hpp>
#include <string>
#include <memory>

namespace maplibre {
namespace harmony {

/**
 * GeoJsonSourceNAPI - NAPI wrapper for GeoJSON sources.
 *
 * Wraps mbgl::style::GeoJSONSource to provide an object-oriented interface,
 * similar to the Android GeoJsonSource class.
 */
class GeoJsonSourceNAPI {
public:
    GeoJsonSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::GeoJSONSource> source);
    // Construct from an existing source (uses WeakPtr, does not take ownership)
    GeoJsonSourceNAPI(mbgl::style::GeoJSONSource* sourcePtr);
    
    ~GeoJsonSourceNAPI();
    
    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::GeoJSONSource* sourcePtr);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    
    // Data management
    static napi_value SetGeoJson(napi_env env, napi_callback_info info);
    static napi_value SetGeoJsonSync(napi_env env, napi_callback_info info);
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);
    
    // Query helpers
    static napi_value QuerySourceFeatures(napi_env env, napi_callback_info info);
    
    // Clustering helpers
    static napi_value GetClusterChildren(napi_env env, napi_callback_info info);
    static napi_value GetClusterLeaves(napi_env env, napi_callback_info info);
    static napi_value GetClusterExpansionZoom(napi_env env, napi_callback_info info);
    
    // Internal helpers
    std::string getId() const { return id; }
    mbgl::style::GeoJSONSource* getSource() const;
    
    // Release ownership (used when Style.addSource takes over)
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }
    
    // Create the WeakPtr after addSource (mirrors the iOS approach)
    void attachToStyle(mbgl::style::GeoJSONSource* sourcePtr);
    
    // Constructor reference
    static napi_ref constructor;
    
private:
    std::string id;
    std::unique_ptr<mbgl::style::GeoJSONSource> source;
    bool ownsSource;  // Indicates whether this wrapper owns the source
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;  // WeakPtr used after ownership transfer
    mbgl::style::GeoJSONSource* rawSourceFallback = nullptr; // Temporary raw pointer when WeakPtr creation fails
};

} // namespace harmony
} // namespace maplibre

