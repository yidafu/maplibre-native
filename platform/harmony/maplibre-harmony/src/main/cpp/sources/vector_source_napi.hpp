#pragma once

#include <napi/native_api.h>
#include <mln/style/sources/vector_source.hpp>
#include <string>
#include <memory>

#include "source_napi_base.hpp"

namespace mln {
namespace harmony {

/**
 * VectorSourceNAPI - NAPI wrapper for Vector Source
 *
 * Wraps mln::style::VectorSource to provide an object-oriented vector tile interface.
 * Ownership state and the shared accessors live in SourceNapiBase.
 */
class VectorSourceNAPI : public SourceNapiBase<VectorSourceNAPI, mln::style::VectorSource> {
public:
    VectorSourceNAPI(const std::string& id, std::unique_ptr<mln::style::VectorSource> source);
    // Construct from an existing Source (uses WeakPtr, does not take ownership)
    VectorSourceNAPI(mln::style::VectorSource* sourcePtr);

    ~VectorSourceNAPI();

    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mln::style::VectorSource* sourcePtr);

    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);

    // Getters
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetUrl(napi_env env, napi_callback_info info);

    // Setters
    static napi_value SetUrl(napi_env env, napi_callback_info info);
    static napi_value SetTiles(napi_env env, napi_callback_info info);

    static napi_ref constructor;
    static napi_env constructorEnv;
};

} // namespace harmony
} // namespace mln
