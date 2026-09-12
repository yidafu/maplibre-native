#ifndef MAPLIBREHARMONY_NAPI_CONSTRUCTOR_REF_HPP
#define MAPLIBREHARMONY_NAPI_CONSTRUCTOR_REF_HPP

#include "napi/native_api.h"

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

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBREHARMONY_NAPI_CONSTRUCTOR_REF_HPP
