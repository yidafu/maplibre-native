#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/util/geojson.hpp>
#include <mbgl/renderer/query.hpp>
#include <string>
#include <memory>
#include <functional>
#include <map>
#include <optional>
#include <vector>

#include "source_napi_base.hpp"

namespace mbgl {
namespace harmony {

/**
 * GeoJsonSourceNAPI - NAPI wrapper for GeoJSON sources.
 *
 * Wraps mbgl::style::GeoJSONSource to provide an object-oriented interface,
 * similar to the Android GeoJsonSource class.
 *
 * Ownership state and the shared accessors live in SourceNapiBase; getSource()
 * and attachToStyle() are the one deliberate exception (see below).
 */
class GeoJsonSourceNAPI : public SourceNapiBase<GeoJsonSourceNAPI, mbgl::style::GeoJSONSource> {
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

    // Static callbacks for querying through the renderer. Set by NativeMapView
    // during initialization. Registered per-owner (the HarmonyRenderer raw
    // pointer): with multiple map instances a later instance replaces the
    // hooks, and clearing is owner-checked so destroying one map can never
    // disable (or leave dangling) another map's hooks.
    using QueryFeatureExtensionsFn = std::function<mbgl::FeatureExtensionValue(
        const std::string& sourceID,
        const mbgl::Feature& feature,
        const std::string& extension,
        const std::string& extensionField,
        const std::optional<std::map<std::string, mbgl::Value>>& args)>;

    using QuerySourceFeaturesFn = std::function<std::vector<mbgl::Feature>(
        const std::string& sourceID,
        const mbgl::SourceQueryOptions& options)>;

    static void setQueryFeatureExtensionsFn(QueryFeatureExtensionsFn fn, void* owner);
    static void setQuerySourceFeaturesFn(QuerySourceFeaturesFn fn, void* owner);
    // Clears both hooks only if they were registered by `owner`.
    static void clearRendererHooks(void* owner);

    // Resolve the current hook; empty when unset. Returns a copy under the
    // hook mutex so call sites invoke it without holding the lock.
    static QueryFeatureExtensionsFn queryFeatureExtensionsFn();
    static QuerySourceFeaturesFn querySourceFeaturesFn();
    
    // Internal helpers.
    //
    // These two deliberately shadow the SourceNapiBase versions (non-virtual,
    // never called through a base pointer): this wrapper reports *why* source
    // access was disabled when the WeakPtr initialisation failed, which the
    // shared implementation stays silent about. Their return semantics -
    // nullptr once the source is gone - are identical to the base's.
    mbgl::style::GeoJSONSource* getSource() const;

    // Create the WeakPtr after addSource (mirrors the iOS approach)
    void attachToStyle(mbgl::style::GeoJSONSource* sourcePtr);

    // Constructor reference
    static napi_ref constructor;
    static napi_env constructorEnv;
};

} // namespace harmony
} // namespace mbgl

