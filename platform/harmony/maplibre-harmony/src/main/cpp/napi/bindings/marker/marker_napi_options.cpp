#include "marker_napi.hpp"
#include "napi/bindings/annotation_napi_accessors.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include "geometry/lat_lng_harmony.hpp"

namespace mbgl {
namespace harmony {

// Use Logger from mbgl::harmony namespace
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Note: Static member initialization, Constructor, Destructor, and Init function are defined in marker_napi_base.cpp

// Marker 的 setter 契约与 Polygon/Polyline 不同：解包失败返回 nullptr（而非
// thisVar）、成功返回 undefined（而非 thisVar），因此这里用带返回值参数的
// DEFINE_NAPI_SETTER / DEFINE_ANNOTATION_GETTER，而不是注解版 setter 宏。
#define MARKER_SETTER(Fn, ...) \
    DEFINE_NAPI_SETTER(MarkerNAPI, Fn, nullptr, annotation_napi::JsUndefined(env), __VA_ARGS__)

MARKER_SETTER(SetAlpha,
    args.RequireMinArgs(1);
    self->alpha = args.GetDouble(0, "alpha"))

MARKER_SETTER(SetRotation,
    args.RequireMinArgs(1);
    self->rotation = args.GetDouble(0, "rotation"))

MARKER_SETTER(SetDraggable,
    args.RequireMinArgs(1);
    self->draggable = args.GetBool(0, "draggable"))

MARKER_SETTER(SetZIndex,
    args.RequireMinArgs(1);
    self->zIndex = args.GetInt32(0, "zIndex"))

// remove()：转发调用 mapLibreMap.removeMarker(this)；无法转发时仅重置 ID。
napi_value MarkerNAPI::Remove(napi_env env, napi_callback_info info) {
    ANN_NAPI_THIS(MarkerNAPI, marker);
    if (!marker) {
        Logger::error("MarkerNAPI", "Remove: Failed to unwrap marker");
        return annotation_napi::JsUndefined(env);
    }

    Logger::info("MarkerNAPI", "[MarkerDebug] Marker.remove() called for ID=%ld", marker->annotationId);

    // If the Marker is already associated with MapLibreMap, call its removeMarker method
    if (marker->mapLibreMapRef) {
        napi_value mapLibreMapValue;
        napi_status status = napi_get_reference_value(env, marker->mapLibreMapRef, &mapLibreMapValue);

        if (status == napi_ok && mapLibreMapValue != nullptr) {
            // Retrieve removeMarker method
            napi_value removeMarkerFunc;
            status = napi_get_named_property(env, mapLibreMapValue, "removeMarker", &removeMarkerFunc);

            if (status == napi_ok) {
                // Invoke mapLibreMap.removeMarker(this)
                napi_value argv[] = { thisVar };
                napi_value result;
                napi_call_function(env, mapLibreMapValue, removeMarkerFunc, 1, argv, &result);
            } else {
                Logger::warn("MarkerNAPI", "Remove: removeMarker method not found on MapLibreMap");
                // If the method is missing, at least reset the ID
                marker->annotationId = -1;
            }
        } else {
            Logger::warn("MarkerNAPI", "Remove: MapLibreMap reference is invalid");
            marker->annotationId = -1;
        }
    } else {
        Logger::warn("MarkerNAPI", "Remove: Marker not associated with MapLibreMap");
        marker->annotationId = -1;
    }

    return annotation_napi::JsUndefined(env);
}

MARKER_SETTER(SetId,
    args.RequireMinArgs(1);
    self->annotationId = static_cast<mbgl::AnnotationID>(args.GetInt64(0, "id")))

napi_value MarkerNAPI::SetMapLibreMap(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);

    ANN_NAPI_THIS(MarkerNAPI, marker);
    if (!marker) {
        Logger::error("MarkerNAPI", "SetMapLibreMap: Failed to unwrap marker");
        return annotation_napi::JsUndefined(env);
    }

    // Fetch MapLibreMap object
    napi_value mapLibreMapValue = args.GetObject(0, "mapLibreMap");
    if (args.HasError()) {
        Logger::error("MarkerNAPI", "SetMapLibreMap: Failed to get mapLibreMap argument");
        return annotation_napi::JsUndefined(env);
    }

    // Delete existing reference if present
    if (marker->mapLibreMapRef) {
        napi_delete_reference(env, marker->mapLibreMapRef);
        marker->mapLibreMapRef = nullptr;
    }

    // Create new reference
    if (napi_create_reference(env, mapLibreMapValue, 1, &marker->mapLibreMapRef) != napi_ok) {
        Logger::error("MarkerNAPI", "SetMapLibreMap: Failed to create reference");
    }

    return annotation_napi::JsUndefined(env);
}

// InfoWindow methods
MARKER_SETTER(ShowInfoWindow,
    self->infoWindowShown = true)

MARKER_SETTER(HideInfoWindow,
    self->infoWindowShown = false)

DEFINE_ANNOTATION_GETTER(MarkerNAPI, IsInfoWindowShown, annotation_napi::JsBool(env, self->infoWindowShown))

// Selection methods
DEFINE_ANNOTATION_GETTER(MarkerNAPI, IsSelected, annotation_napi::JsBool(env, self->selected))

MARKER_SETTER(SetSelected,
    args.RequireMinArgs(1);
    self->selected = args.GetBool(0, "selected"))

// Drag state methods
DEFINE_ANNOTATION_GETTER(MarkerNAPI, GetDragState, annotation_napi::JsInt32(env, self->dragState))

MARKER_SETTER(SetDragState,
    args.RequireMinArgs(1);
    self->dragState = args.GetInt32(0, "dragState"))

// Animation methods - Animation logic lives in the ETS layer; only target values updated here
MARKER_SETTER(AnimateToPosition,
    args.RequireMinArgs(2);
    napi_value targetPosValue = args.GetObject(0, "targetPosition");
    if (!args.HasError()) {
        mbgl::LatLng latLng;
        if (LatLngHarmony::ParseLatLng(env, targetPosValue, latLng)) {
            self->position = mbgl::Point<double>(latLng.longitude(), latLng.latitude());
            Logger::info("MarkerNAPI", "[Animation] animateToPosition: target=(%f, %f)", latLng.latitude(), latLng.longitude());
        } else {
            Logger::error("MarkerNAPI", "AnimateToPosition: Failed to parse target LatLng");
        }
    })

MARKER_SETTER(AnimateAlpha,
    args.RequireMinArgs(1);
    // duration and callback parameters are ignored; NAPI layer only sets the final value
    self->alpha = args.GetDouble(0, "targetAlpha");
    Logger::info("MarkerNAPI", "[Animation] animateAlpha: set target=%f (animation should be handled in ETS layer)",
                 self->alpha))

MARKER_SETTER(AnimateRotation,
    args.RequireMinArgs(1);
    self->rotation = args.GetDouble(0, "targetRotation");
    Logger::info("MarkerNAPI", "[Animation] animateRotation: target=%f", self->rotation))

// Anchor methods
namespace {

napi_value CreateAnchorObject(napi_env env, double u, double v) {
    // Create anchor object { u: number, v: number }
    napi_value result;
    napi_create_object(env, &result);

    napi_value uValue, vValue;
    napi_create_double(env, u, &uValue);
    napi_create_double(env, v, &vValue);

    napi_set_named_property(env, result, "u", uValue);
    napi_set_named_property(env, result, "v", vValue);

    return result;
}

} // namespace

DEFINE_ANNOTATION_GETTER(MarkerNAPI, GetAnchor, CreateAnchorObject(env, self->anchorU, self->anchorV))

MARKER_SETTER(SetAnchor,
    args.RequireMinArgs(2);
    self->anchorU = args.GetDouble(0, "u");
    self->anchorV = args.GetDouble(1, "v"))

} // namespace harmony
} // namespace mbgl
