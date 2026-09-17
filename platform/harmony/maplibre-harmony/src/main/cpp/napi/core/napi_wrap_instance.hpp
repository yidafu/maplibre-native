#pragma once

#include <string>

#include "napi/native_api.h"
#include "utils/logger.h"

namespace mbgl {
namespace harmony {

/**
 * Build a JS object that shares the class prototype without running the JS
 * constructor, wraps an already-built native NAPI object into it, and tags it
 * with the class _TYPE_ marker used by the ETS side for type dispatch.
 *
 * This is the shared body of every NAPI class CreateInstance(...) method used
 * when the native object already exists (layers/sources re-wrapped from a
 * loaded style). Returns nullptr-valued napi_value if napiObj is null or any
 * NAPI step fails; on wrap failure the object is deleted to avoid leaks.
 */
template <typename NAPI>
inline napi_value WrapExistingInstance(napi_env env,
                                       napi_ref constructor,
                                       napi_finalize destructor,
                                       const char* typeName,
                                       NAPI* napiObj) {
    napi_value nullValue;
    napi_get_null(env, &nullValue);
    if (!napiObj) {
        return nullValue;
    }

    napi_value cons = nullptr;
    if (napi_get_reference_value(env, constructor, &cons) != napi_ok || !cons) {
        Logger::error(typeName, "Failed to get constructor reference");
        return nullValue;
    }

    napi_value instance = nullptr;
    if (napi_create_object(env, &instance) != napi_ok) {
        Logger::error(typeName, "CreateInstance: failed to create object");
        return nullValue;
    }

    napi_value prototype = nullptr;
    if (napi_get_named_property(env, cons, "prototype", &prototype) != napi_ok ||
        napi_set_named_property(env, instance, "__proto__", prototype) != napi_ok) {
        Logger::error(typeName, "CreateInstance: failed to set prototype");
        return nullValue;
    }

    if (napi_wrap(env, instance, napiObj, destructor, nullptr, nullptr) != napi_ok) {
        // NAPI classes keep their destructors private and free via the static
        // Destructor finalize callback; reuse it for the failed-wrap cleanup.
        NAPI::Destructor(nullptr, napiObj, nullptr);
        Logger::error(typeName, "CreateInstance: failed to wrap instance");
        return nullValue;
    }

    napi_value typeValue = nullptr;
    napi_create_string_utf8(env, typeName, NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);

    return instance;
}

} // namespace harmony
} // namespace mbgl
