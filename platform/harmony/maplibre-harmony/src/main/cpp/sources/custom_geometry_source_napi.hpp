#pragma once

#include <napi/native_api.h>
#include <mbgl/style/sources/custom_geometry_source.hpp>
#include <mbgl/renderer/query.hpp>
#include <functional>
#include <memory>
#include <string>
#include <vector>

namespace mbgl {
namespace harmony {
class ThreadSafeCallback;
} // namespace harmony
} // namespace mbgl

namespace mbgl {
namespace harmony {

/**
 * CustomGeometrySourceNAPI - NAPI wrapper for CustomGeometrySource
 *
 * Wraps mbgl::style::CustomGeometrySource (application-managed tile geometry).
 * Mirrors the Android CustomGeometrySource peer: the core source invokes
 * fetchTile/cancelTile from tile worker threads, and this wrapper forwards
 * them to the JS thread via ThreadSafeCallback. Tile data is pushed back with
 * setTileData(z, x, y, geojson).
 */
class CustomGeometrySourceNAPI {
public:
    CustomGeometrySourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::CustomGeometrySource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    explicit CustomGeometrySourceNAPI(mbgl::style::CustomGeometrySource* sourcePtr);

    ~CustomGeometrySourceNAPI();

    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::CustomGeometrySource* sourcePtr);

    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);

    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);

    // Tile data management
    static napi_value SetTileData(napi_env env, napi_callback_info info);
    static napi_value InvalidateTile(napi_env env, napi_callback_info info);
    static napi_value InvalidateRegion(napi_env env, napi_callback_info info);

    // Query
    static napi_value QuerySourceFeatures(napi_env env, napi_callback_info info);

    using QuerySourceFeaturesFn = std::function<std::vector<mbgl::Feature>(
        const std::string&, const mbgl::SourceQueryOptions&)>;
    // Registered per-owner (the HarmonyRenderer raw pointer) so multiple map
    // instances don't clobber each other; clearing is owner-checked so
    // destroying one map never disables another map's hooks.
    static void setQuerySourceFeaturesFn(QuerySourceFeaturesFn fn, void* owner);
    static void clearQuerySourceFeaturesFn(void* owner);
    // Resolve the current hook; empty when unset. Copy under the hook mutex.
    static QuerySourceFeaturesFn querySourceFeaturesFn();

    // Internal helpers
    std::string getId() const { return id; }
    mbgl::style::CustomGeometrySource* getSource() const {
        if (!source && weakSource) {
            return static_cast<mbgl::style::CustomGeometrySource*>(weakSource.get());
        }
        return source.get();
    }

    // Release ownership (for Style.addSource)
    std::unique_ptr<mbgl::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }

    // After addSource, keep a WeakPtr so the wrapper survives after the style
    // takes over ownership
    void attachToStyle(mbgl::style::CustomGeometrySource* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }

    static napi_ref constructor;
    static napi_env constructorEnv;

private:
    std::string id;
    std::unique_ptr<mbgl::style::CustomGeometrySource> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mbgl::style::Source> weakSource;

    // Shared with the TileFunction lambdas held by the core source so the
    // callbacks stay callable until the source itself is destroyed, even if
    // the JS wrapper is garbage collected first.
    std::shared_ptr<mbgl::harmony::ThreadSafeCallback> fetchTileCb;
    std::shared_ptr<mbgl::harmony::ThreadSafeCallback> cancelTileCb;
};

} // namespace harmony
} // namespace mbgl
