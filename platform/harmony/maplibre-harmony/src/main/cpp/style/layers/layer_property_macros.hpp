#ifndef MAPLIBRE_HARMONY_LAYER_PROPERTY_MACROS_HPP
#define MAPLIBRE_HARMONY_LAYER_PROPERTY_MACROS_HPP

// ============================================================================
// Shared per-property NAPI accessor generators for the layer wrapper classes.
//
// Every Set*/Get* on a layer NAPI class is a thin shell around the shared
// setLayoutProperty / setPaintProperty / setDataDrivenLayoutProperty /
// getProperty helpers (see layer_property_utils.hpp); the bodies used to be
// hand-duplicated per property across the layer files (~2500 lines). The
// macros take the NAPI class, the native layer type, the wrapper method name,
// the helper, the property key and the native member functions, with the
// value type as a variadic tail so comma-bearing types like
// std::array<float, 2> survive.
//
// Getter failure semantics are unified on null (matching the symbol layer,
// heatmap, hillshade, location-indicator and background layers).
//
// This header also carries the two shells that are identical for *every*
// layer: the constructor (DEFINE_LAYER_NEW) and the base-layer chunk of the
// Init() descriptor table (LAYER_BASE_PROPERTY_DESCRIPTORS).
// ============================================================================

#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"

#include <napi/native_api.h>

namespace mln {
namespace harmony {

/**
 * Attach a freshly built layer wrapper to its JS object and tag it with
 * `_TYPE_` so the ETS side can discriminate the subclasses.
 *
 * Returns false when napi_wrap failed; in that case the wrapper has NOT been
 * adopted by the JS object and the caller must delete it. The deletion is left
 * to the caller on purpose: the layer wrappers keep their destructors private,
 * so only a member of the class (where DEFINE_LAYER_NEW expands) can do it.
 */
template <typename NapiCls>
bool AttachLayerInstance(napi_env env, napi_value thisVar, NapiCls* layerObj,
                         const char* typeName, const char* logTag) {
    if (napi_wrap(env, thisVar, layerObj, NapiCls::Destructor, nullptr, nullptr) != napi_ok) {
        Logger::error(logTag, "Failed to wrap %s object", typeName);
        return false;
    }

    // Initialised up front: napi_create_string_utf8() leaves the out-param
    // untouched on failure, and setting an indeterminate napi_value is UB.
    napi_value typeValue = nullptr;
    napi_create_string_utf8(env, typeName, NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return true;
}

} // namespace harmony
} // namespace mln

/**
 * The base-layer chunk every layer's Init() table ends with, in the canonical
 * order. Expand directly inside the `napi_property_descriptor properties[]`
 * initialiser; no trailing comma, so it must close the list.
 *
 * Background and LocationIndicator omit the four source-related entries
 * (getSourceId / set|getSourceLayer / set|getFilter) because they have no
 * source; the symbol layer lists the same names in its own order. Those keep
 * hand-written tables.
 */
#define LAYER_BASE_PROPERTY_DESCRIPTORS                                          \
    /* Layer base methods */                                                     \
    { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },        \
    { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },    \
    { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "setSourceLayer", nullptr, SetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "getSourceLayer", nullptr, GetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "setFilter", nullptr, SetFilter, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "getFilter", nullptr, GetFilter, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    /* Generic property methods (Android-compatible API) */                      \
    { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr }, \
    { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr }

/**
 * The JS constructor every layer wrapper shares: read `layerId` (and usually
 * `sourceId`), build the wrapper, then wrap + tag it.
 *
 *   NapiCls   - the layer NAPI class
 *   TypeName  - the `_TYPE_` tag / log label (e.g. "LineLayer")
 *   MinArgs   - how many arguments are required
 *   CtorExpr  - the `new XxxLayerNAPI(...)` expression; commas are safe because
 *               they sit inside the call parentheses
 *   ...       - the argument-extraction statements (they declare the locals
 *               CtorExpr consumes); the `if (args.HasError()) return nullptr;`
 *               guard after them is emitted by the macro
 */
#define DEFINE_LAYER_NEW(NapiCls, TypeName, MinArgs, CtorExpr, ...)              \
    napi_value NapiCls::New(napi_env env, napi_callback_info info) {             \
        NapiArgs args(env, info);                                                \
        napi_value thisVar = nullptr;                                            \
        napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);        \
        args.RequireMinArgs(MinArgs);                                            \
        if (args.HasError()) {                                                   \
            return nullptr;                                                      \
        }                                                                        \
        __VA_ARGS__                                                              \
        if (args.HasError()) {                                                   \
            return nullptr;                                                      \
        }                                                                        \
        NapiCls* layerObj = (CtorExpr);                                          \
        if (!mln::harmony::AttachLayerInstance(env, thisVar, layerObj,          \
                                                TypeName, #NapiCls)) {           \
            /* Expanded inside a member function, so the wrapper's private */    \
            /* destructor is reachable; napi_wrap did not adopt the object.  */  \
            delete layerObj;                                                     \
            return nullptr;                                                      \
        }                                                                        \
        return thisVar;                                                          \
    }

#define DEFINE_LAYER_SETTER(NapiCls, MbglLayer, Fn, Helper, PropName, SetFn, ...) \
    napi_value NapiCls::Fn(napi_env env, napi_callback_info info) {               \
        napi_value thisVar;                                                       \
        size_t argc = 1;                                                          \
        napi_value argv[1];                                                       \
        napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);              \
        auto* layerObj = NapiArgs::Unwrap<NapiCls>(env, thisVar);                 \
        if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;       \
        mln::harmony::Helper<MbglLayer, __VA_ARGS__>(                            \
            env, layerObj->getLayer(), argv[0], PropName,                         \
            &MbglLayer::SetFn);                                                   \
        return thisVar;                                                           \
    }

#define DEFINE_LAYER_GETTER(NapiCls, MbglLayer, Fn, GetFn, ...)                   \
    napi_value NapiCls::Fn(napi_env env, napi_callback_info info) {               \
        napi_value thisVar;                                                       \
        napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);         \
        auto* layerObj = NapiArgs::Unwrap<NapiCls>(env, thisVar);                 \
        if (!layerObj || !layerObj->getLayer()) {                                 \
            napi_value null_value;                                                \
            napi_get_null(env, &null_value);                                      \
            return null_value;                                                    \
        }                                                                         \
        return mln::harmony::getProperty<MbglLayer, __VA_ARGS__>(                \
            env, layerObj->getLayer(), &MbglLayer::GetFn);                        \
    }

// ColorRamp properties (line-gradient / heatmap-color / color-relief-color)
// go through the ColorRamp conversion path instead of getProperty.
#define DEFINE_LAYER_COLORRAMP_SETTER(NapiCls, MbglLayer, Fn, PropName, SetFn)    \
    napi_value NapiCls::Fn(napi_env env, napi_callback_info info) {               \
        napi_value thisVar;                                                       \
        size_t argc = 1;                                                          \
        napi_value argv[1];                                                       \
        napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);              \
        auto* layerObj = NapiArgs::Unwrap<NapiCls>(env, thisVar);                 \
        if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;       \
        try {                                                                     \
            NapiValue napiValue(env, argv[0]);                                    \
            mln::style::conversion::Error error;                                 \
            auto converted = mln::style::conversion::convert<                    \
                mln::style::ColorRampPropertyValue>(std::move(napiValue), error);\
            if (converted) {                                                     \
                layerObj->getLayer()->SetFn(*converted);                          \
            } else {                                                              \
                mln::harmony::Logger::error(#NapiCls,                            \
                    "Failed to convert " PropName ": %s", error.message.c_str()); \
            }                                                                     \
        } catch (const std::exception& e) {                                       \
            mln::harmony::Logger::error(#NapiCls, #Fn ": Failed - %s", e.what());\
        }                                                                         \
        return thisVar;                                                           \
    }

#define DEFINE_LAYER_COLORRAMP_GETTER(NapiCls, MbglLayer, Fn, GetFn)              \
    napi_value NapiCls::Fn(napi_env env, napi_callback_info info) {               \
        napi_value thisVar;                                                       \
        napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);         \
        auto* layerObj = NapiArgs::Unwrap<NapiCls>(env, thisVar);                 \
        if (!layerObj || !layerObj->getLayer()) {                                 \
            napi_value null_value;                                                \
            napi_get_null(env, &null_value);                                      \
            return null_value;                                                    \
        }                                                                         \
        const auto& colorRamp = layerObj->getLayer()->GetFn();                    \
        auto result = mln::harmony::conversion::colorRampPropertyValueToNapi(env, colorRamp); \
        if (result) {                                                             \
            return *result;                                                       \
        }                                                                         \
        napi_value null_value;                                                    \
        napi_get_null(env, &null_value);                                          \
        return null_value;                                                        \
    }

#endif // MAPLIBRE_HARMONY_LAYER_PROPERTY_MACROS_HPP
