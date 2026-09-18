#ifndef MAPLIBREHARMONY_NAPI_CONSTRUCTOR_REF_HPP
#define MAPLIBREHARMONY_NAPI_CONSTRUCTOR_REF_HPP

#include "napi/native_api.h"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

// Re-registering a NAPI class constructor (multi-env / module reload) must
// release the previous persistent reference instead of silently leaking it —
// and napi_delete_reference has to run on the env the ref was created with,
// so the creating env is tracked alongside the ref.
//
// Usage pattern (class stores `static napi_ref constructor;` plus
// `static napi_env constructorEnv;`):
//
//   status = RefreshConstructorRef(env, cons, constructor, constructorEnv);
//
inline napi_status RefreshConstructorRef(napi_env env, napi_value cons, napi_ref& ref, napi_env& refEnv) {
    if (ref != nullptr && refEnv != nullptr) {
        napi_delete_reference(refEnv, ref);
        ref = nullptr;
        refEnv = nullptr;
    }
    napi_status status = napi_create_reference(env, cons, 1, &ref);
    if (status == napi_ok) {
        refEnv = env;
    }
    return status;
}

// One-shot NAPI class registration shared by every `XxxNAPI::Init(env, exports)`:
// define the class, refresh the persistent constructor reference, and publish
// the constructor on `exports` under `className`.
//
// The three failure logs keep the wording/level used by the Init() functions
// this replaces (className/logTag substituted). Every existing Init() failure
// branch returned nullptr, so this returns nullptr on failure and the created
// constructor on success; Init() wrappers turn that into
// `return cons ? exports : nullptr;`.
inline napi_value RegisterNapiClass(napi_env env, napi_value exports,
                                    const char* className,
                                    const napi_property_descriptor* props, size_t propCount,
                                    napi_callback ctor,
                                    napi_ref& outRef, napi_env& outRefEnv,
                                    const char* logTag) {
    napi_value cons = nullptr;
    napi_status status = napi_define_class(env, className, NAPI_AUTO_LENGTH, ctor, nullptr,
                                           propCount, props, &cons);
    if (status != napi_ok) {
        Logger::error(logTag, "Failed to define %s class", className);
        return nullptr;
    }

    status = RefreshConstructorRef(env, cons, outRef, outRefEnv);
    if (status != napi_ok) {
        Logger::error(logTag, "Failed to create reference to %s constructor", className);
        return nullptr;
    }

    status = napi_set_named_property(env, exports, className, cons);
    if (status != napi_ok) {
        Logger::error(logTag, "Failed to export %s class", className);
        return nullptr;
    }

    return cons;
}

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_NAPI_CONSTRUCTOR_REF_HPP
