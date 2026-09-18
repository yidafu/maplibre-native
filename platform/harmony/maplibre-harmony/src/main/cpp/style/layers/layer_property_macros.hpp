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
// ============================================================================

#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"

#define DEFINE_LAYER_SETTER(NapiCls, MbglLayer, Fn, Helper, PropName, SetFn, ...) \
    napi_value NapiCls::Fn(napi_env env, napi_callback_info info) {               \
        napi_value thisVar;                                                       \
        size_t argc = 1;                                                          \
        napi_value argv[1];                                                       \
        napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);              \
        auto* layerObj = NapiArgs::Unwrap<NapiCls>(env, thisVar);                 \
        if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;       \
        mbgl::harmony::Helper<MbglLayer, __VA_ARGS__>(                            \
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
        return mbgl::harmony::getProperty<MbglLayer, __VA_ARGS__>(                \
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
            mbgl::style::conversion::Error error;                                 \
            auto converted = mbgl::style::conversion::convert<                    \
                mbgl::style::ColorRampPropertyValue>(std::move(napiValue), error);\
            if (converted) {                                                     \
                layerObj->getLayer()->SetFn(*converted);                          \
            } else {                                                              \
                mbgl::harmony::Logger::error(#NapiCls,                            \
                    "Failed to convert " PropName ": %s", error.message.c_str()); \
            }                                                                     \
        } catch (const std::exception& e) {                                       \
            mbgl::harmony::Logger::error(#NapiCls, #Fn ": Failed - %s", e.what());\
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
        auto result = mbgl::harmony::conversion::colorRampPropertyValueToNapi(env, colorRamp); \
        if (result) {                                                             \
            return *result;                                                       \
        }                                                                         \
        napi_value null_value;                                                    \
        napi_get_null(env, &null_value);                                          \
        return null_value;                                                        \
    }

#endif // MAPLIBRE_HARMONY_LAYER_PROPERTY_MACROS_HPP
