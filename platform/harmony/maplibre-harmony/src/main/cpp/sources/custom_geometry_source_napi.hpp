#pragma once

#include <napi/native_api.h>
#include <mln/style/sources/custom_geometry_source.hpp>
#include <mln/renderer/query.hpp>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "source_napi_base.hpp"

namespace mln {
namespace harmony {
class ThreadSafeCallback;
} // namespace harmony
} // namespace mln

namespace mln {
namespace harmony {

/**
 * CustomGeometrySourceNAPI - NAPI wrapper for CustomGeometrySource
 *
 * Wraps mln::style::CustomGeometrySource (application-managed tile geometry).
 * Mirrors the Android CustomGeometrySource peer: the core source invokes
 * fetchTile/cancelTile from tile worker threads, and this wrapper forwards
 * them to the JS thread via ThreadSafeCallback. Tile data is pushed back with
 * setTileData(z, x, y, geojson).
 *
 * Ownership state and the shared accessors live in SourceNapiBase.
 */
class CustomGeometrySourceNAPI
    : public SourceNapiBase<CustomGeometrySourceNAPI, mln::style::CustomGeometrySource> {
public:
    CustomGeometrySourceNAPI(const std::string& id, std::unique_ptr<mln::style::CustomGeometrySource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    explicit CustomGeometrySourceNAPI(mln::style::CustomGeometrySource* sourcePtr);

    ~CustomGeometrySourceNAPI();

    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mln::style::CustomGeometrySource* sourcePtr);

    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);

    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);

    // Tile data management
    static napi_value SetTileData(napi_env env, napi_callback_info info);
    static napi_value InvalidateTile(napi_env env, napi_callback_info info);
    static napi_value InvalidateRegion(napi_env env, napi_callback_info info);

    // Query
    static napi_value QuerySourceFeatures(napi_env env, napi_callback_info info);

    using QuerySourceFeaturesFn = std::function<std::vector<mln::Feature>(
        const std::string&, const mln::SourceQueryOptions&)>;
    // Registered per-owner (the HarmonyRenderer raw pointer) so multiple map
    // instances don't clobber each other; clearing is owner-checked so
    // destroying one map never disables another map's hooks.
    static void setQuerySourceFeaturesFn(QuerySourceFeaturesFn fn, void* owner);
    static void clearQuerySourceFeaturesFn(void* owner);
    // Resolve the current hook; empty when unset. Copy under the hook mutex.
    static QuerySourceFeaturesFn querySourceFeaturesFn();

    static napi_ref constructor;
    static napi_env constructorEnv;

private:
    // Shared with the TileFunction lambdas held by the core source so the
    // callbacks stay callable until the source itself is destroyed, even if
    // the JS wrapper is garbage collected first.
    std::shared_ptr<mln::harmony::ThreadSafeCallback> fetchTileCb;
    std::shared_ptr<mln::harmony::ThreadSafeCallback> cancelTileCb;
};

} // namespace harmony
} // namespace mln
