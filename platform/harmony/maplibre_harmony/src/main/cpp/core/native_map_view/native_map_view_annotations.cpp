#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/bindings/marker/marker_napi.hpp"
#include "napi/bindings/polyline/polyline_napi.hpp"
#include "napi/bindings/polygon/polygon_napi.hpp"
#include "napi/bindings/style/style_napi.hpp"
#include "napi/bindings/icon/icon_napi.hpp"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/projected_meters_harmony.hpp"
#include "utils/logger.h"
#include <mbgl/util/projection.hpp>
#include <mbgl/map/camera.hpp>
#include <mbgl/util/constants.hpp>
#include <mbgl/math/angles.hpp>

#include <algorithm>
#include <cmath>
#include <mutex>
#include <optional>
#include <string>
#include <vector>
#include <mbgl/style/style.hpp>
#include <napi/native_api.h>
#include <limits>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using maplibre::harmony::MarkerNAPI;
using maplibre::harmony::PolylineNAPI;
using maplibre::harmony::PolygonNAPI;
using maplibre::harmony::StyleNAPI;
using maplibre::harmony::IconNAPI;

namespace mbgl {
namespace harmony {

namespace {

bool hasNamedProperty(napi_env env, napi_value object, const char* name) {
    if (!object || !name) {
        return false;
    }

    bool hasProperty = false;
    if (napi_has_named_property(env, object, name, &hasProperty) != napi_ok) {
        return false;
    }
    return hasProperty;
}

bool getNamedProperty(napi_env env, napi_value object, const char* name, napi_value* result) {
    if (!hasNamedProperty(env, object, name) || !result) {
        return false;
    }
    return napi_get_named_property(env, object, name, result) == napi_ok;
}

struct HarmonyViewAnnotationUpdate {
    std::optional<mbgl::LatLng> anchor;
    std::optional<mbgl::Size> size;
    std::optional<mbgl::ScreenCoordinate> offset;
    std::optional<double> anchorHeight;  // Height for anchor positioning
    std::optional<double> anchorU;       // Horizontal anchor (0=left, 1=right)
    std::optional<double> anchorV;       // Vertical anchor (0=top, 1=bottom)
    std::optional<bool> visible;
    std::optional<bool> allowOverlap;
    std::optional<bool> draggable;
    std::optional<bool> scalesWithViewingDistance;
    std::optional<bool> rotatesWithCamera;
    std::optional<double> minZoom;
    std::optional<double> maxZoom;
};

double clampToDouble(double value, double fallback = 0.0) {
    if (!std::isfinite(value)) {
        return fallback;
    }
    return value;
}

std::optional<mbgl::LatLng> parseAnchorLatLng(napi_env env, NapiArgs& args, napi_value anchorObj) {
    if (!anchorObj) {
        return std::nullopt;
    }

    double latitude = args.GetDoubleProperty(anchorObj, "latitude", std::numeric_limits<double>::quiet_NaN());
    double longitude = args.GetDoubleProperty(anchorObj, "longitude", std::numeric_limits<double>::quiet_NaN());

    if (!std::isfinite(latitude) || !std::isfinite(longitude)) {
        latitude = args.GetDoubleProperty(anchorObj, "lat", std::numeric_limits<double>::quiet_NaN());
        longitude = args.GetDoubleProperty(anchorObj, "lng", std::numeric_limits<double>::quiet_NaN());
    }

    if (!std::isfinite(latitude) || !std::isfinite(longitude)) {
        return std::nullopt;
    }

    return mbgl::LatLng{latitude, longitude};
}

std::optional<mbgl::Size> parseSize(NapiArgs& args, napi_value sizeObj) {
    if (!sizeObj) {
        return std::nullopt;
    }

    double width = args.GetDoubleProperty(sizeObj, "width", std::numeric_limits<double>::quiet_NaN());
    double height = args.GetDoubleProperty(sizeObj, "height", std::numeric_limits<double>::quiet_NaN());

    if (!std::isfinite(width) || !std::isfinite(height)) {
        return std::nullopt;
    }

    width = std::max(0.0, width);
    height = std::max(0.0, height);

    return mbgl::Size{static_cast<uint32_t>(std::llround(width)), static_cast<uint32_t>(std::llround(height))};
}

std::optional<mbgl::ScreenCoordinate> parseOffset(NapiArgs& args, napi_value offsetObj, double pixelRatio) {
    if (!offsetObj) {
        return std::nullopt;
    }

    double offsetX = args.GetDoubleProperty(offsetObj, "x", std::numeric_limits<double>::quiet_NaN());
    double offsetY = args.GetDoubleProperty(offsetObj, "y", std::numeric_limits<double>::quiet_NaN());

    if (!std::isfinite(offsetX) || !std::isfinite(offsetY)) {
        offsetX = args.GetDoubleProperty(offsetObj, "dx", std::numeric_limits<double>::quiet_NaN());
        offsetY = args.GetDoubleProperty(offsetObj, "dy", std::numeric_limits<double>::quiet_NaN());
    }

    if (!std::isfinite(offsetX) || !std::isfinite(offsetY)) {
        return std::nullopt;
    }

    return mbgl::ScreenCoordinate{offsetX * pixelRatio, offsetY * pixelRatio};
}

HarmonyViewAnnotation parseAnnotationDefaults(const NativeMapView& instance) {
    HarmonyViewAnnotation annotation;
    annotation.visible = true;
    annotation.allowOverlap = false;
    annotation.draggable = false;
    annotation.scalesWithViewingDistance = false;
    annotation.rotatesWithCamera = false;
    annotation.minZoom = 0.0;
    annotation.maxZoom = mbgl::util::DEFAULT_MAX_ZOOM;
    annotation.size = mbgl::Size{0, 0};
    annotation.offset = mbgl::ScreenCoordinate{0.0, 0.0};
    annotation.anchor = mbgl::LatLng{};
    return annotation;
}

std::optional<HarmonyViewAnnotation> parseAddOptions(NativeMapView& instance, NapiArgs& args, napi_value optionsObj) {
    if (!optionsObj) {
        return std::nullopt;
    }

    HarmonyViewAnnotation annotation = parseAnnotationDefaults(instance);
    napi_env env = args.Env();

    napi_value anchorObj = nullptr;
    if (!getNamedProperty(env, optionsObj, "anchor", &anchorObj)) {
        // Support direct input { latitude, longitude }
        anchorObj = optionsObj;
    }

    auto anchor = parseAnchorLatLng(env, args, anchorObj);
    if (!anchor.has_value()) {
        Logger::error("NativeMapView", "addViewAnnotation: anchor is required and must provide latitude/longitude");
        return std::nullopt;
    }
    annotation.anchor = *anchor;

    napi_value sizeObj = nullptr;
    if (getNamedProperty(env, optionsObj, "size", &sizeObj)) {
        if (auto size = parseSize(args, sizeObj)) {
            annotation.size = *size;
        }
    } else {
        double width = args.GetDoubleProperty(optionsObj, "width", std::numeric_limits<double>::quiet_NaN());
        double height = args.GetDoubleProperty(optionsObj, "height", std::numeric_limits<double>::quiet_NaN());
        if (std::isfinite(width) && std::isfinite(height)) {
            width = std::max(0.0, width);
            height = std::max(0.0, height);
            annotation.size = mbgl::Size{static_cast<uint32_t>(std::llround(width)), static_cast<uint32_t>(std::llround(height))};
        }
    }

    napi_value offsetObj = nullptr;
    if (getNamedProperty(env, optionsObj, "offset", &offsetObj) || getNamedProperty(env, optionsObj, "centerOffset", &offsetObj)) {
        if (auto offset = parseOffset(args, offsetObj, static_cast<double>(instance.getPixelRatioValue()))) {
            annotation.offset = *offset;
        }
    } else {
        double offsetX = args.GetDoubleProperty(optionsObj, "offsetX", std::numeric_limits<double>::quiet_NaN());
        double offsetY = args.GetDoubleProperty(optionsObj, "offsetY", std::numeric_limits<double>::quiet_NaN());
        if (std::isfinite(offsetX) && std::isfinite(offsetY)) {
            annotation.offset = mbgl::ScreenCoordinate{offsetX * instance.getPixelRatioValue(), offsetY * instance.getPixelRatioValue()};
        }
    }

    // Parse anchorHeight for anchor positioning
    double anchorHeight = args.GetDoubleProperty(optionsObj, "anchorHeight", std::numeric_limits<double>::quiet_NaN());
    if (std::isfinite(anchorHeight)) {
        annotation.anchorHeight = std::max(0.0, anchorHeight) * instance.getPixelRatioValue();
    }

    // Parse anchorU/anchorV for pre-computed position (Phase 2 optimization)
    annotation.anchorU = args.GetDoubleProperty(optionsObj, "anchorU", 0.5);
    annotation.anchorV = args.GetDoubleProperty(optionsObj, "anchorV", 1.0);

    annotation.visible = args.GetBoolProperty(optionsObj, "visible", true);
    annotation.allowOverlap = args.GetBoolProperty(optionsObj, "allowOverlap", false);
    annotation.draggable = args.GetBoolProperty(optionsObj, "draggable", false);
    annotation.scalesWithViewingDistance = args.GetBoolProperty(optionsObj, "scalesWithViewingDistance", false);
    annotation.rotatesWithCamera = args.GetBoolProperty(optionsObj, "rotatesWithCamera", false);
    annotation.minZoom = args.GetDoubleProperty(optionsObj, "minZoom", 0.0);
    annotation.maxZoom = args.GetDoubleProperty(optionsObj, "maxZoom", mbgl::util::DEFAULT_MAX_ZOOM);

    return annotation;
}

std::optional<HarmonyViewAnnotationUpdate> parseUpdateOptions(NativeMapView& instance, NapiArgs& args, napi_value optionsObj) {
    if (!optionsObj) {
        return std::nullopt;
    }

    HarmonyViewAnnotationUpdate update;
    napi_env env = args.Env();

    napi_value anchorObj = nullptr;
    if (getNamedProperty(env, optionsObj, "anchor", &anchorObj)) {
        update.anchor = parseAnchorLatLng(env, args, anchorObj);
    } else if (hasNamedProperty(env, optionsObj, "latitude") && hasNamedProperty(env, optionsObj, "longitude")) {
        update.anchor = parseAnchorLatLng(env, args, optionsObj);
    }

    napi_value sizeObj = nullptr;
    if (getNamedProperty(env, optionsObj, "size", &sizeObj)) {
        update.size = parseSize(args, sizeObj);
    } else if (hasNamedProperty(env, optionsObj, "width") || hasNamedProperty(env, optionsObj, "height")) {
        double width = args.GetDoubleProperty(optionsObj, "width", std::numeric_limits<double>::quiet_NaN());
        double height = args.GetDoubleProperty(optionsObj, "height", std::numeric_limits<double>::quiet_NaN());
        if (std::isfinite(width) && std::isfinite(height)) {
            width = std::max(0.0, width);
            height = std::max(0.0, height);
            update.size = mbgl::Size{static_cast<uint32_t>(std::llround(width)), static_cast<uint32_t>(std::llround(height))};
        }
    }

    napi_value offsetObj = nullptr;
    if (getNamedProperty(env, optionsObj, "offset", &offsetObj) || getNamedProperty(env, optionsObj, "centerOffset", &offsetObj)) {
        update.offset = parseOffset(args, offsetObj, static_cast<double>(instance.getPixelRatioValue()));
    } else if (hasNamedProperty(env, optionsObj, "offsetX") || hasNamedProperty(env, optionsObj, "offsetY")) {
        double offsetX = args.GetDoubleProperty(optionsObj, "offsetX", std::numeric_limits<double>::quiet_NaN());
        double offsetY = args.GetDoubleProperty(optionsObj, "offsetY", std::numeric_limits<double>::quiet_NaN());
        if (std::isfinite(offsetX) && std::isfinite(offsetY)) {
            update.offset = mbgl::ScreenCoordinate{offsetX * instance.getPixelRatioValue(), offsetY * instance.getPixelRatioValue()};
        }
    }

    // Parse anchorHeight for anchor positioning
    if (hasNamedProperty(env, optionsObj, "anchorHeight")) {
        double anchorHeight = args.GetDoubleProperty(optionsObj, "anchorHeight", 0.0);
        update.anchorHeight = std::max(0.0, anchorHeight) * instance.getPixelRatioValue();
    }

    // Parse anchorU/anchorV for pre-computed position (Phase 2 optimization)
    if (hasNamedProperty(env, optionsObj, "anchorU")) {
        update.anchorU = args.GetDoubleProperty(optionsObj, "anchorU", 0.5);
    }
    if (hasNamedProperty(env, optionsObj, "anchorV")) {
        update.anchorV = args.GetDoubleProperty(optionsObj, "anchorV", 1.0);
    }

    if (hasNamedProperty(env, optionsObj, "visible")) {
        update.visible = args.GetBoolProperty(optionsObj, "visible", true);
    }
    if (hasNamedProperty(env, optionsObj, "allowOverlap")) {
        update.allowOverlap = args.GetBoolProperty(optionsObj, "allowOverlap", false);
    }
    if (hasNamedProperty(env, optionsObj, "draggable")) {
        update.draggable = args.GetBoolProperty(optionsObj, "draggable", false);
    }
    if (hasNamedProperty(env, optionsObj, "scalesWithViewingDistance")) {
        update.scalesWithViewingDistance = args.GetBoolProperty(optionsObj, "scalesWithViewingDistance", false);
    }
    if (hasNamedProperty(env, optionsObj, "rotatesWithCamera")) {
        update.rotatesWithCamera = args.GetBoolProperty(optionsObj, "rotatesWithCamera", false);
    }
    if (hasNamedProperty(env, optionsObj, "minZoom")) {
        update.minZoom = clampToDouble(args.GetDoubleProperty(optionsObj, "minZoom", 0.0), 0.0);
    }
    if (hasNamedProperty(env, optionsObj, "maxZoom")) {
        update.maxZoom = clampToDouble(args.GetDoubleProperty(optionsObj, "maxZoom", mbgl::util::DEFAULT_MAX_ZOOM), mbgl::util::DEFAULT_MAX_ZOOM);
    }

    return update;
}

HarmonyViewAnnotationFrame buildFrame(const HarmonyViewAnnotation& annotation,
                                     const mbgl::Map& map,
                                     double currentZoom,
                                     double pixelRatio,
                                     double currentBearing,
                                     double currentPitch) {
    HarmonyViewAnnotationFrame frame;
    frame.id = annotation.id;
    frame.size = annotation.size;
    frame.offset = annotation.offset;
    frame.draggable = annotation.draggable;
    frame.pixelRatio = pixelRatio;
    frame.scale = 1.0;
    frame.rotation = 0.0;
    frame.opacity = 1.0;
    frame.visible = annotation.visible;

    if (annotation.scalesWithViewingDistance) {
        const double pitchClamped = std::clamp(currentPitch, 0.0, 60.0);
        const double pitchFactor = std::cos(mbgl::util::deg2rad(pitchClamped));
        frame.scale = pitchFactor <= 0.0 ? 1.0 : 1.0 / pitchFactor;
    }

    if (annotation.rotatesWithCamera) {
        frame.rotation = currentBearing;
    }

    if (currentZoom < annotation.minZoom || currentZoom > annotation.maxZoom) {
        frame.visible = false;
    }

    const mbgl::ScreenCoordinate screen = map.pixelForLatLng(annotation.anchor);

    // Calculate screen position: anchor + offset.
    // Note: the icon-height offset for InfoWindows is applied on the ArkTS side
    // via centerOffset (dy = -icon height). annotation.anchorHeight is parsed
    // and stored but intentionally not applied here.
    frame.screen = mbgl::ScreenCoordinate{
        screen.x + annotation.offset.x,
        screen.y + annotation.offset.y
    };

    // Compute final render position in logical pixels
    // Eliminates per-frame pixelRatio division and anchor math on the ArkTS side
    const double ratio = pixelRatio > 0.0 ? pixelRatio : 1.0;
    frame.positionX = (frame.screen.x / ratio) - (static_cast<double>(frame.size.width) / ratio) * annotation.anchorU;
    // anchorV positions the frame's own bottom edge at the anchor+offset point;
    // combined with centerOffset.dy = -iconHeight the InfoWindow's bottom
    // aligns with the top of the marker icon.
    frame.positionY = (frame.screen.y / ratio) - (static_cast<double>(frame.size.height) / ratio) * annotation.anchorV;

    return frame;
}

// Epsilon thresholds for the push channel: a frame set is only dispatched to
// ArkTS when it drifted beyond these values from the last pushed snapshot
// (mirrors the dedup constants used by the ArkUI overlay).
constexpr double kPushPositionEpsilon = 0.1;  // logical pixels
constexpr double kPushSizeEpsilon = 0.1;      // physical pixels
constexpr double kPushValueEpsilon = 0.01;    // scale / rotation / opacity

bool pushValueClose(double first, double second, double epsilon) {
    if (!std::isfinite(first) || !std::isfinite(second)) {
        return first == second;
    }
    return std::fabs(first - second) <= epsilon;
}

// Both vectors are sorted by annotation id, so index-wise comparison is valid.
bool pushFramesEquivalent(const std::vector<HarmonyViewAnnotationFrame>& pushed,
                          const std::vector<HarmonyViewAnnotationFrame>& frames) {
    if (pushed.size() != frames.size()) {
        return false;
    }
    for (size_t i = 0; i < frames.size(); ++i) {
        const HarmonyViewAnnotationFrame& a = pushed[i];
        const HarmonyViewAnnotationFrame& b = frames[i];
        if (a.id != b.id || a.visible != b.visible) {
            return false;
        }
        if (!pushValueClose(a.positionX, b.positionX, kPushPositionEpsilon) ||
            !pushValueClose(a.positionY, b.positionY, kPushPositionEpsilon) ||
            !pushValueClose(a.size.width, b.size.width, kPushSizeEpsilon) ||
            !pushValueClose(a.size.height, b.size.height, kPushSizeEpsilon) ||
            !pushValueClose(a.scale, b.scale, kPushValueEpsilon) ||
            !pushValueClose(a.rotation, b.rotation, kPushValueEpsilon) ||
            !pushValueClose(a.opacity, b.opacity, kPushValueEpsilon)) {
            return false;
        }
    }
    return true;
}

napi_value createFrameObject(napi_env env, const HarmonyViewAnnotationFrame& frame) {
    napi_value frameObj;
    if (napi_create_object(env, &frameObj) != napi_ok) {
        return nullptr;
    }

    napi_value value;

    napi_create_int64(env, static_cast<int64_t>(frame.id), &value);
    napi_set_named_property(env, frameObj, "id", value);

    napi_create_double(env, frame.screen.x, &value);
    napi_set_named_property(env, frameObj, "x", value);
    napi_create_double(env, frame.screen.y, &value);
    napi_set_named_property(env, frameObj, "y", value);

    napi_create_uint32(env, frame.size.width, &value);
    napi_set_named_property(env, frameObj, "width", value);
    napi_create_uint32(env, frame.size.height, &value);
    napi_set_named_property(env, frameObj, "height", value);

    napi_create_double(env, frame.offset.x, &value);
    napi_set_named_property(env, frameObj, "offsetX", value);
    napi_create_double(env, frame.offset.y, &value);
    napi_set_named_property(env, frameObj, "offsetY", value);

    napi_create_double(env, frame.scale, &value);
    napi_set_named_property(env, frameObj, "scale", value);
    napi_create_double(env, frame.rotation, &value);
    napi_set_named_property(env, frameObj, "rotation", value);
    napi_create_double(env, frame.opacity, &value);
    napi_set_named_property(env, frameObj, "opacity", value);
    napi_create_double(env, frame.pixelRatio, &value);
    napi_set_named_property(env, frameObj, "pixelRatio", value);

    napi_get_boolean(env, frame.visible, &value);
    napi_set_named_property(env, frameObj, "visible", value);
    napi_get_boolean(env, frame.draggable, &value);
    napi_set_named_property(env, frameObj, "draggable", value);

    // Phase 2 optimization: pre-computed render position in logical pixels
    napi_create_double(env, frame.positionX, &value);
    napi_set_named_property(env, frameObj, "positionX", value);
    napi_create_double(env, frame.positionY, &value);
    napi_set_named_property(env, frameObj, "positionY", value);

    return frameObj;
}

napi_value createFramesArray(napi_env env, const std::vector<HarmonyViewAnnotationFrame>& frames) {
    napi_value resultArray;
    if (napi_create_array_with_length(env, frames.size(), &resultArray) != napi_ok) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    for (size_t i = 0; i < frames.size(); ++i) {
        napi_value frameObj = createFrameObject(env, frames[i]);
        if (frameObj) {
            napi_set_element(env, resultArray, static_cast<int32_t>(i), frameObj);
        }
    }

    return resultArray;
}

} // namespace

napi_value NativeMapView::updateMarker(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "updateMarker: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "updateMarker: Requires 1 argument (Marker object)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "updateMarker: Failed to unwrap NativeMapView instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "updateMarker: Map not initialized");
        return undefined;
    }
    
    // Unwrap the Marker NAPI object
    maplibre::harmony::MarkerNAPI* marker = nullptr;
    if (napi_unwrap(env, args[0], reinterpret_cast<void**>(&marker)) != napi_ok || !marker) {
        Logger::error("NativeMapView", "updateMarker: Failed to unwrap Marker object");
        return undefined;
    }
    
    // Extract data from the Marker
    auto annotationId = marker->getAnnotationId();
    if (annotationId == static_cast<mbgl::AnnotationID>(-1)) {
        Logger::error("NativeMapView", "updateMarker: Marker has invalid ID (not added to map yet)");
        return undefined;
    }
    
    auto position = marker->getPositionPoint();
    auto iconId = marker->getIconId();
    
    try {
        // Update the marker using SymbolAnnotation
        mbgl::SymbolAnnotation annotation(position, iconId);
        instance->invokeOnMapThread([instance, annotationId, annotation](mbgl::Map* m){
            m->updateAnnotation(annotationId, annotation);
            m->triggerRepaint();
            // Marker position changed: re-evaluate view annotation frames on
            // the same push path as camera updates (keeps InfoWindows glued
            // to moving markers without waiting for a camera event).
            instance->pushViewAnnotationFrames();
        });

    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "[MarkerDebug] updateMarker: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::addMarkers(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "addMarkers: Requires 1 argument (markers array)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addMarkers: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addMarkers: Map not initialized");
        return undefined;
    }
    
    // Verify that the argument is an array
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "addMarkers: First argument must be an array");
        return undefined;
    }
    
    // Retrieve the array length
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to get array length");
        return undefined;
    }
    
    // Parse all markers on this (JS) thread first...
    struct PendingMarker {
        mbgl::SymbolAnnotation annotation;
        maplibre::harmony::MarkerNAPI* marker;
    };
    std::vector<PendingMarker> pending;
    pending.reserve(length);
    bool warnedEmptyIcon = false;

    for (uint32_t i = 0; i < length; i++) {
        napi_value markerObj;
        if (napi_get_element(env, args[0], i, &markerObj) != napi_ok) {
            Logger::error("NativeMapView", "addMarkers: Failed to get marker at index %u", i);
            continue;
        }

        // Unwrap the MarkerNAPI object
        maplibre::harmony::MarkerNAPI* marker = nullptr;
        if (napi_unwrap(env, markerObj, reinterpret_cast<void**>(&marker)) != napi_ok || !marker) {
            Logger::error("NativeMapView", "addMarkers: Failed to unwrap Marker at index %u", i);
            continue;
        }

        if (marker->getIconId().empty() && !warnedEmptyIcon) {
            warnedEmptyIcon = true;
            Logger::warn("NativeMapView",
                         "addMarkers: marker without icon may be invisible; "
                         "call addAnnotationIcon() or ensure the style has a default marker icon");
        }

        pending.push_back({mbgl::SymbolAnnotation(marker->getPositionPoint(), marker->getIconId()), marker});
    }

    // ...then add them all with a single round trip to the render thread
    // (one blocking hop total, not one per marker).
    std::vector<mbgl::AnnotationID> ids;
    ids.reserve(pending.size());
    if (!pending.empty()) {
        auto addedIds = instance->invokeOnMapThreadSync(
            [&](mbgl::Map* m) {
                std::vector<mbgl::AnnotationID> result;
                result.reserve(pending.size());
                for (auto& p : pending) {
                    result.push_back(m->addAnnotation(p.annotation));
                }
                return result;
            },
            std::vector<mbgl::AnnotationID>{});

        for (size_t i = 0; i < addedIds.size() && i < pending.size(); i++) {
            pending[i].marker->setAnnotationId(addedIds[i]);
        }
        ids = std::move(addedIds);
    }

    if (ids.size() < pending.size()) {
        Logger::warn("NativeMapView", "addMarkers: %u of %zu markers failed to add",
                     static_cast<uint32_t>(pending.size() - ids.size()), pending.size());
    }
    
    // Trigger a repaint
    if (!ids.empty()) {
        instance->invokeOnMapThread([](mbgl::Map* m){ m->triggerRepaint(); });
        Logger::info("NativeMapView", "[MarkerDebug] NAPI-Repaint: Repaint triggered for %zu markers", ids.size());
    } else {
        Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Repaint: ⚠️ No markers added, skipping repaint");
    }
    
    // Create the array of returned IDs
    napi_value resultArray;
    if (napi_create_array_with_length(env, ids.size(), &resultArray) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to create result array");
        return undefined;
    }
    
    // Populate the ID array
    for (size_t i = 0; i < ids.size(); i++) {
        napi_value idValue;
        if (napi_create_int64(env, static_cast<int64_t>(ids[i]), &idValue) == napi_ok) {
            napi_set_element(env, resultArray, i, idValue);
        }
    }
    
    Logger::info("NativeMapView", "========== addMarkers() END - SUCCESS ==========");
    return resultArray;
}

napi_value NativeMapView::onLowMemory(napi_env env, napi_callback_info info) {
    // Low memory handling is managed by the Harmony system
    NapiArgs args(env, info);
    return args.Undefined();
}

napi_value NativeMapView::addPolylines(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addPolylines: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "addPolylines: Requires 1 argument (polylines array)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addPolylines: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addPolylines: Map not initialized");
        return undefined;
    }
    
    // Verify that the argument is an array
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "addPolylines: First argument must be an array");
        return undefined;
    }
    
    // Retrieve the array length
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "addPolylines: Failed to get array length");
        return undefined;
    }
    
    // Store the generated annotation IDs
    std::vector<mbgl::AnnotationID> ids;
    ids.reserve(length);
    
    // Parse all polylines on this thread first...
    struct PendingPolyline {
        mbgl::LineAnnotation annotation;
        PolylineNAPI* polyline;
    };
    std::vector<PendingPolyline> pending;
    pending.reserve(length);

    for (uint32_t i = 0; i < length; i++) {
        napi_value polylineObj;
        if (napi_get_element(env, args[0], i, &polylineObj) != napi_ok) {
            Logger::error("NativeMapView", "addPolylines: Failed to get polyline at index %u", i);
            continue;
        }

        // Unwrap the PolylineNAPI object
        PolylineNAPI* polyline = nullptr;
        if (napi_unwrap(env, polylineObj, reinterpret_cast<void**>(&polyline)) != napi_ok || !polyline) {
            Logger::error("NativeMapView", "addPolylines: Failed to unwrap Polyline at index %u", i);
            continue;
        }

        pending.push_back({polyline->toAnnotation(), polyline});
    }

    // ...then add them all with a single round trip to the render thread.
    {
        auto addedIds = instance->invokeOnMapThreadSync(
            [&](mbgl::Map* m) {
                std::vector<mbgl::AnnotationID> result;
                result.reserve(pending.size());
                for (auto& p : pending) {
                    result.push_back(m->addAnnotation(p.annotation));
                }
                return result;
            },
            std::vector<mbgl::AnnotationID>{});

        for (size_t i = 0; i < addedIds.size() && i < pending.size(); i++) {
            pending[i].polyline->setAnnotationId(addedIds[i]);
        }
        ids = std::move(addedIds);
    }
    
    // Trigger a repaint
    if (!ids.empty()) {
        instance->invokeOnMapThread([](mbgl::Map* m){ m->triggerRepaint(); });
    }
    
    // Create the array of returned IDs
    napi_value resultArray;
    if (napi_create_array_with_length(env, ids.size(), &resultArray) != napi_ok) {
        Logger::error("NativeMapView", "addPolylines: Failed to create result array");
        return undefined;
    }
    
    // Populate the ID array
    for (size_t i = 0; i < ids.size(); i++) {
        napi_value idValue;
        if (napi_create_int64(env, static_cast<int64_t>(ids[i]), &idValue) == napi_ok) {
            napi_set_element(env, resultArray, i, idValue);
        }
    }
    
    return resultArray;
}

napi_value NativeMapView::addPolygons(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addPolygons: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "addPolygons: Requires 1 argument (polygons array)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addPolygons: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addPolygons: Map not initialized");
        return undefined;
    }
    
    // Verify that the argument is an array
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "addPolygons: First argument must be an array");
        return undefined;
    }
    
    // Retrieve the array length
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "addPolygons: Failed to get array length");
        return undefined;
    }
    
    // Store the generated annotation IDs
    std::vector<mbgl::AnnotationID> ids;
    ids.reserve(length);
    
    // Parse all polygons on this thread first...
    struct PendingPolygon {
        mbgl::FillAnnotation annotation;
        PolygonNAPI* polygon;
    };
    std::vector<PendingPolygon> pending;
    pending.reserve(length);

    for (uint32_t i = 0; i < length; i++) {
        napi_value polygonObj;
        if (napi_get_element(env, args[0], i, &polygonObj) != napi_ok) {
            Logger::error("NativeMapView", "addPolygons: Failed to get polygon at index %u", i);
            continue;
        }

        // Unwrap the PolygonNAPI object
        PolygonNAPI* polygon = nullptr;
        if (napi_unwrap(env, polygonObj, reinterpret_cast<void**>(&polygon)) != napi_ok || !polygon) {
            Logger::error("NativeMapView", "addPolygons: Failed to unwrap Polygon at index %u", i);
            continue;
        }

        pending.push_back({polygon->toAnnotation(), polygon});
    }

    // ...then add them all with a single round trip to the render thread.
    {
        auto addedIds = instance->invokeOnMapThreadSync(
            [&](mbgl::Map* m) {
                std::vector<mbgl::AnnotationID> result;
                result.reserve(pending.size());
                for (auto& p : pending) {
                    result.push_back(m->addAnnotation(p.annotation));
                }
                return result;
            },
            std::vector<mbgl::AnnotationID>{});

        for (size_t i = 0; i < addedIds.size() && i < pending.size(); i++) {
            pending[i].polygon->setAnnotationId(addedIds[i]);
        }
        ids = std::move(addedIds);
    }
    
    // Trigger a repaint
    if (!ids.empty()) {
        instance->invokeOnMapThread([](mbgl::Map* m){ m->triggerRepaint(); });
    }
    
    // Create the array of returned IDs
    napi_value resultArray;
    if (napi_create_array_with_length(env, ids.size(), &resultArray) != napi_ok) {
        Logger::error("NativeMapView", "addPolygons: Failed to create result array");
        return undefined;
    }
    
    // Populate the ID array
    for (size_t i = 0; i < ids.size(); i++) {
        napi_value idValue;
        if (napi_create_int64(env, static_cast<int64_t>(ids[i]), &idValue) == napi_ok) {
            napi_set_element(env, resultArray, i, idValue);
        }
    }
    
    return resultArray;
}

napi_value NativeMapView::updatePolyline(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "updatePolyline: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "updatePolyline: Requires 1 argument (Polyline object)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "updatePolyline: Failed to unwrap NativeMapView instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "updatePolyline: Map not initialized");
        return undefined;
    }
    
    // Unwrap the Polyline NAPI object
    PolylineNAPI* polyline = nullptr;
    if (napi_unwrap(env, args[0], reinterpret_cast<void**>(&polyline)) != napi_ok || !polyline) {
        Logger::error("NativeMapView", "updatePolyline: Failed to unwrap Polyline object");
        return undefined;
    }
    
    // Extract data from the polyline
    auto annotationId = polyline->getAnnotationId();
    if (annotationId == static_cast<mbgl::AnnotationID>(-1)) {
        Logger::error("NativeMapView", "updatePolyline: Polyline has invalid ID (not added to map yet)");
        return undefined;
    }
    
    try {
        // Update the polyline using LineAnnotation
        mbgl::LineAnnotation annotation = polyline->toAnnotation();
        instance->invokeOnMapThread([annotationId, annotation](mbgl::Map* m){
            m->updateAnnotation(annotationId, annotation);
            m->triggerRepaint();
        });
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "updatePolyline: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::updatePolygon(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "updatePolygon: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "updatePolygon: Requires 1 argument (Polygon object)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "updatePolygon: Failed to unwrap NativeMapView instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "updatePolygon: Map not initialized");
        return undefined;
    }
    
    // Unwrap the Polygon NAPI object
    PolygonNAPI* polygon = nullptr;
    if (napi_unwrap(env, args[0], reinterpret_cast<void**>(&polygon)) != napi_ok || !polygon) {
        Logger::error("NativeMapView", "updatePolygon: Failed to unwrap Polygon object");
        return undefined;
    }
    
    // Extract data from the polygon
    auto annotationId = polygon->getAnnotationId();
    if (annotationId == static_cast<mbgl::AnnotationID>(-1)) {
        Logger::error("NativeMapView", "updatePolygon: Polygon has invalid ID (not added to map yet)");
        return undefined;
    }
    
    try {
        // Update the polygon using FillAnnotation
        mbgl::FillAnnotation annotation = polygon->toAnnotation();
        
        instance->invokeOnMapThread([annotationId, annotation](mbgl::Map* m){
            m->updateAnnotation(annotationId, annotation);
            m->triggerRepaint();
        });
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "updatePolygon: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::removeAnnotations(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "removeAnnotations: Requires 1 argument (annotation IDs array)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "removeAnnotations: Map not initialized");
        return undefined;
    }
    
    // Verify that the argument is an array
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "removeAnnotations: First argument must be an array");
        return undefined;
    }
    
    // Retrieve the array length
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to get array length");
        return undefined;
    }
    
    Logger::info("NativeMapView", "removeAnnotations: Removing %u annotations", length);
    
    // Iterate through the ID array and delete each entry
    for (uint32_t i = 0; i < length; i++) {
        napi_value idValue;
        if (napi_get_element(env, args[0], i, &idValue) != napi_ok) {
            Logger::error("NativeMapView", "removeAnnotations: Failed to get ID at index %u", i);
            continue;
        }
        
        int64_t annotationId;
        if (napi_get_value_int64(env, idValue, &annotationId) != napi_ok) {
            Logger::error("NativeMapView", "removeAnnotations: Failed to parse ID at index %u", i);
            continue;
        }
        
        if (annotationId == -1) {
            continue; // Skip invalid IDs
        }
        
        try {
            instance->invokeOnMapThread([annotationId](mbgl::Map* m){ m->removeAnnotation(static_cast<mbgl::AnnotationID>(annotationId)); });
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "removeAnnotations[%u]: Failed to remove ID=%ld - %s", i, annotationId, e.what());
        }
    }
    
    // Trigger a repaint
    if (length > 0) {
        instance->invokeOnMapThread([](mbgl::Map* m){ m->triggerRepaint(); });
    }
    
    return undefined;
}

napi_value NativeMapView::addAnnotationIcon(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Get NativeMapView instance
    NativeMapView* instance = nullptr;
    napi_value thisObj = args.This();
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to unwrap instance");
        return args.Undefined();
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addAnnotationIcon: Map not initialized");
        return args.Undefined();
    }
    
    // Check if using new Icon object API (1 argument) or old byte array API (5 arguments)
    if (args.Count() == 1) {
        // New way: Icon object
        Logger::info("NativeMapView", "addAnnotationIcon: Using Icon object API");
        
        napi_value iconObj = args.GetObject(0, "icon");
        if (args.HasError()) {
            Logger::error("NativeMapView", "addAnnotationIcon: Failed to get Icon object");
            return args.Undefined();
        }
        
        // Try to unwrap Icon object to get direct access to image data
        IconNAPI* iconNapi = nullptr;
        if (napi_unwrap(env, iconObj, reinterpret_cast<void**>(&iconNapi)) != napi_ok || !iconNapi) {
            Logger::error("NativeMapView", "addAnnotationIcon: Argument is not a valid Icon object");
            return args.Undefined();
        }
        
        // Direct access to image data
        auto image = iconNapi->getImage();
        if (!image) {
            Logger::error("NativeMapView", "addAnnotationIcon: Icon has been released");
            return args.Undefined();
        }
        
        std::string iconId = iconNapi->getId();
        float scale = iconNapi->getScale();
        
        Logger::info("NativeMapView", "addAnnotationIcon: Icon object - id=%s, size=%dx%d, scale=%f",
                     iconId.c_str(), iconNapi->getWidth(), iconNapi->getHeight(), scale);
        
        // Add image to style directly (no data copy needed!)
        instance->invokeOnMapThread([iconId, scale, image](mbgl::Map* m) {
            auto styleImage = std::make_unique<mbgl::style::Image>(
                iconId, 
                image->clone(),  // Clone the image for the style
                scale
            );
            Logger::debug("NativeMapView", "addAnnotationIcon: icon '%s' added to style", iconId.c_str());
            m->getStyle().addImage(std::move(styleImage));
        });

        Logger::debug("NativeMapView", "addAnnotationIcon: Icon '%s' scheduled to add (using Icon object)", iconId.c_str());
        return args.Undefined();
    }
    
    // Old way: byte array (backward compatibility)
    if (args.Count() < 5) {
        Logger::error("NativeMapView", "addAnnotationIcon: Requires either 1 argument (Icon) or 5 arguments (symbol, width, height, scale, pixels)");
        return args.Undefined();
    }
    
    Logger::info("NativeMapView", "addAnnotationIcon: Using byte array API (backward compatibility)");
    
    // Parse arguments using NapiArgs
    std::string symbol = args.GetString(0, "symbol");
    int32_t width = args.GetInt32(1, "width");
    int32_t height = args.GetInt32(2, "height");
    double scale = args.GetDouble(3, "scale");
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to parse arguments: %s", args.GetError().c_str());
        return args.Undefined();
    }
    
    // Get Uint8Array pixel data (still need manual handling for TypedArray)
    napi_value pixelsArg = args.Get(4);
    void* pixelData = nullptr;
    size_t pixelLength = 0;
    napi_value arrayBuffer;
    
    if (napi_get_typedarray_info(env, pixelsArg, nullptr, &pixelLength, &pixelData, &arrayBuffer, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to get pixel data");
        return args.Undefined();
    }
    
    Logger::debug("NativeMapView", "addAnnotationIcon: symbol=%s, width=%d, height=%d, scale=%f, pixelLength=%zu",
                  symbol.c_str(), width, height, scale, pixelLength);
    
    // Construct and add the image on the render thread to avoid moving a unique_ptr across threads
    {
        size_t expectedSize = static_cast<size_t>(width) * static_cast<size_t>(height) * 4; // RGBA
        if (pixelLength >= expectedSize && pixelData) {
            std::vector<uint8_t> pixels(expectedSize);
            std::memcpy(pixels.data(), pixelData, expectedSize);
            std::string symbolCopy = symbol;
            float scaleCopy = static_cast<float>(scale);
            int w = width, h = height;
            instance->invokeOnMapThread([symbolCopy, scaleCopy, w, h, pixels = std::move(pixels)](mbgl::Map* m) {
                mbgl::PremultipliedImage image({static_cast<uint32_t>(w), static_cast<uint32_t>(h)});
                std::memcpy(image.data.get(), pixels.data(), pixels.size());
                auto styleImage = std::make_unique<mbgl::style::Image>(symbolCopy, std::move(image), scaleCopy);
                m->getStyle().addImage(std::move(styleImage));
            });
            Logger::debug("NativeMapView", "addAnnotationIcon: Icon '%s' scheduled to add", symbol.c_str());
        } else {
            Logger::error("NativeMapView", "addAnnotationIcon: Invalid pixel data size (expected %zu, got %zu)",
                         expectedSize, pixelLength);
        }
    }

    return args.Undefined();
}

napi_value NativeMapView::removeAnnotationIcon(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Requires 1 argument (symbol)");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Map not initialized");
        return undefined;
    }
    
    // Fetch the symbol string
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbol;
    if (symbolLength > 0) {
        symbol.resize(symbolLength);
        napi_get_value_string_utf8(env, args[0], &symbol[0], symbolLength + 1, &symbolLength);
    }
    
    Logger::info("NativeMapView", "removeAnnotationIcon: symbol=%s", symbol.c_str());
    
    try {
        instance->invokeOnMapThread([symbol](mbgl::Map* m){ m->getStyle().removeImage(symbol); });
        Logger::info("NativeMapView", "removeAnnotationIcon: Icon '%s' removed successfully", symbol.c_str());
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::getTopOffsetPixelsForAnnotationSymbol(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::warn("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Missing symbol name argument, returning 0.0");
        return result;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Map not initialized, returning 0.0");
        return result;
    }
    
    // Fetch the symbol name
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbolName(symbolLength, '\0');
    napi_get_value_string_utf8(env, args[0], &symbolName[0], symbolLength + 1, &symbolLength);
    symbolName.resize(symbolLength);
    
    try {
        double offset = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getTopOffsetPixelsForAnnotationImage(symbolName); }, 0.0);
        napi_create_double(env, offset, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::addViewAnnotation(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    NativeMapView* instance = nullptr;
    napi_value thisObj = args.This();
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        napi_throw_error(env, nullptr, "Failed to unwrap NativeMapView instance");
        return nullptr;
    }

    napi_value optionsObj = args.GetObject(0, "options");
    if (args.HasError()) {
        return nullptr;
    }

    auto annotationOpt = parseAddOptions(*instance, args, optionsObj);
    if (!annotationOpt.has_value()) {
        napi_throw_error(env, nullptr, "Invalid ViewAnnotation options");
        return nullptr;
    }

    HarmonyViewAnnotation annotation = *annotationOpt;
    int64_t annotationId = 0;

    {
        std::lock_guard<std::mutex> lock(instance->viewAnnotationMutex_);
        annotationId = instance->nextViewAnnotationId_++;
        annotation.id = annotationId;
        instance->viewAnnotations_[annotationId] = annotation;
    }

    instance->invokeOnMapThread([instance](mbgl::Map* map) {
        if (map) {
            map->triggerRepaint();
        }
        // Push the initial frame so the annotation appears without waiting
        // for the next camera event.
        instance->pushViewAnnotationFrames();
    });

    napi_value result;
    napi_create_int64(env, annotationId, &result);
    return result;
}

napi_value NativeMapView::updateViewAnnotation(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }

    NativeMapView* instance = nullptr;
    napi_value thisObj = args.This();
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        napi_throw_error(env, nullptr, "Failed to unwrap NativeMapView instance");
        return nullptr;
    }

    const int64_t id = args.GetInt64(0, "annotationId");
    if (args.HasError()) {
        return nullptr;
    }

    napi_value optionsObj = args.GetObject(1, "options");
    if (args.HasError()) {
        return nullptr;
    }

    auto updateOpt = parseUpdateOptions(*instance, args, optionsObj);
    if (!updateOpt.has_value()) {
        napi_value resultValue;
        napi_get_boolean(env, false, &resultValue);
        return resultValue;
    }

    bool updated = false;
    {
        std::lock_guard<std::mutex> lock(instance->viewAnnotationMutex_);
        auto it = instance->viewAnnotations_.find(id);
        if (it != instance->viewAnnotations_.end()) {
            HarmonyViewAnnotation& data = it->second;
            const HarmonyViewAnnotationUpdate& update = *updateOpt;

            if (update.anchor) {
                data.anchor = *update.anchor;
            }
            if (update.size) {
                data.size = *update.size;
            }
            if (update.offset) {
                data.offset = *update.offset;
            }
            if (update.visible) {
                data.visible = *update.visible;
            }
            if (update.allowOverlap) {
                data.allowOverlap = *update.allowOverlap;
            }
            if (update.draggable) {
                data.draggable = *update.draggable;
            }
            if (update.scalesWithViewingDistance) {
                data.scalesWithViewingDistance = *update.scalesWithViewingDistance;
            }
            if (update.rotatesWithCamera) {
                data.rotatesWithCamera = *update.rotatesWithCamera;
            }
            if (update.minZoom) {
                data.minZoom = *update.minZoom;
            }
            if (update.maxZoom) {
                data.maxZoom = *update.maxZoom;
            }
            if (update.anchorHeight) {
                data.anchorHeight = *update.anchorHeight;
            }
            if (update.anchorU) {
                data.anchorU = *update.anchorU;
            }
            if (update.anchorV) {
                data.anchorV = *update.anchorV;
            }

            updated = true;
        }
    }

    if (updated) {
        instance->invokeOnMapThread([instance](mbgl::Map* map) {
            if (map) {
                map->triggerRepaint();
            }
            // Push updated frames (e.g. measured-size feedback, anchor moves).
            instance->pushViewAnnotationFrames();
        });
    }

    napi_value resultValue;
    napi_get_boolean(env, updated, &resultValue);
    return resultValue;
}

napi_value NativeMapView::removeViewAnnotation(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    NativeMapView* instance = nullptr;
    napi_value thisObj = args.This();
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        napi_throw_error(env, nullptr, "Failed to unwrap NativeMapView instance");
        return nullptr;
    }

    const int64_t id = args.GetInt64(0, "annotationId");
    if (args.HasError()) {
        return nullptr;
    }

    bool removed = false;
    {
        std::lock_guard<std::mutex> lock(instance->viewAnnotationMutex_);
        removed = instance->viewAnnotations_.erase(id) > 0;
    }

    if (removed) {
        instance->invokeOnMapThread([instance](mbgl::Map* map) {
            if (map) {
                map->triggerRepaint();
            }
            // Push the retraction so ArkUI drops the removed frame promptly.
            instance->pushViewAnnotationFrames();
        });
    }

    napi_value resultValue;
    napi_get_boolean(env, removed, &resultValue);
    return resultValue;
}

napi_value NativeMapView::getViewAnnotationFrames(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    NativeMapView* instance = nullptr;
    napi_value thisObj = args.This();
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        napi_throw_error(env, nullptr, "Failed to unwrap NativeMapView instance");
        return nullptr;
    }

    std::vector<HarmonyViewAnnotation> annotations;
    double pixelRatio = instance->getPixelRatioValue();

    {
        std::lock_guard<std::mutex> lock(instance->viewAnnotationMutex_);
        annotations.reserve(instance->viewAnnotations_.size());
        for (const auto& entry : instance->viewAnnotations_) {
            annotations.push_back(entry.second);
        }
    }

    auto frames = instance->invokeOnMapThreadSync(
        [annotations, pixelRatio](mbgl::Map* map) {
            std::vector<HarmonyViewAnnotationFrame> result;
            if (!map) {
                return result;
            }

            result.reserve(annotations.size());
            const auto camera = map->getCameraOptions();
            const double currentZoom = camera.zoom.value_or(0.0);
            const double currentBearing = camera.bearing.value_or(0.0);
            const double currentPitch = camera.pitch.value_or(0.0);

            for (const auto& annotation : annotations) {
                result.emplace_back(buildFrame(annotation, *map, currentZoom, pixelRatio, currentBearing, currentPitch));
            }

            return result;
        },
        std::vector<HarmonyViewAnnotationFrame>{});

    // One-shot pull path (e.g. clear()-time enumeration). The per-frame path
    // is the push channel in pushViewAnnotationFrames(); per-frame logging was
    // removed with it.
    return createFramesArray(env, frames);
}

void NativeMapView::pushViewAnnotationFrames() {
    // Runs on the map/render thread: invoked from the camera observers and
    // from the map-thread lambdas of the annotation mutation entry points.
    if (isDestroying.load(std::memory_order_acquire)) {
        return;
    }

    std::shared_ptr<ThreadSafeCallback> callback;
    {
        std::lock_guard<std::mutex> lock(viewAnnotationFrameMutex_);
        callback = viewAnnotationFramesCallback_;
    }
    if (!callback || !callback->IsValid() || !map) {
        return;
    }

    // Native short-circuit: nothing on screen and no stale state to retract —
    // skip the per-frame work entirely.
    {
        std::lock_guard<std::mutex> lock(viewAnnotationMutex_);
        if (viewAnnotations_.empty() && lastPushedViewAnnotationFrames_.empty()) {
            return;
        }
    }

    std::vector<HarmonyViewAnnotation> annotations;
    {
        std::lock_guard<std::mutex> lock(viewAnnotationMutex_);
        annotations.reserve(viewAnnotations_.size());
        for (const auto& entry : viewAnnotations_) {
            annotations.push_back(entry.second);
        }
    }

    const double pixelRatio = getPixelRatioValue();
    const auto camera = map->getCameraOptions();
    const double currentZoom = camera.zoom.value_or(0.0);
    const double currentBearing = camera.bearing.value_or(0.0);
    const double currentPitch = camera.pitch.value_or(0.0);

    std::vector<HarmonyViewAnnotationFrame> frames;
    frames.reserve(annotations.size());
    for (const auto& annotation : annotations) {
        frames.emplace_back(buildFrame(annotation, *map, currentZoom, pixelRatio, currentBearing, currentPitch));
    }
    // Sort by id so the epsilon comparison against the last pushed snapshot is
    // stable regardless of unordered_map iteration order.
    std::sort(frames.begin(), frames.end(),
              [](const HarmonyViewAnnotationFrame& a, const HarmonyViewAnnotationFrame& b) {
                  return a.id < b.id;
              });

    {
        std::lock_guard<std::mutex> lock(viewAnnotationFrameMutex_);
        if (pushFramesEquivalent(lastPushedViewAnnotationFrames_, frames)) {
            return;
        }
        lastPushedViewAnnotationFrames_ = frames;
    }

    // The builder runs on the JS thread inside ThreadSafeCallback::CallJS; keep
    // the frame data alive via shared_ptr instead of capturing by reference.
    auto framesSnapshot = std::make_shared<std::vector<HarmonyViewAnnotationFrame>>(std::move(frames));
    callback->Call([framesSnapshot](napi_env env) -> napi_value {
        return createFramesArray(env, *framesSnapshot);
    });
}

napi_value NativeMapView::setViewAnnotationFramesListener(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    NativeMapView* instance = nullptr;
    napi_value thisObj = args.This();
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        napi_throw_error(env, nullptr, "Failed to unwrap NativeMapView instance");
        return nullptr;
    }

    if (instance->isDestroying.load(std::memory_order_acquire)) {
        return args.Undefined();
    }

    napi_value callback = args.GetValue(0);
    napi_valuetype type = napi_undefined;
    napi_typeof(env, callback, &type);

    if (type == napi_null || type == napi_undefined) {
        // Remove the listener, and clear the pushed snapshot so a subsequent
        // registration receives a fresh push instead of a dedupe hit.
        std::lock_guard<std::mutex> lock(instance->viewAnnotationFrameMutex_);
        instance->viewAnnotationFramesCallback_.reset();
        instance->lastPushedViewAnnotationFrames_.clear();
        return args.Undefined();
    }

    if (type != napi_function) {
        napi_throw_error(env, nullptr, "setViewAnnotationFramesListener: callback must be a function or null");
        return nullptr;
    }

    auto callbackPtr = ThreadSafeCallback::Create(env, callback, "OnViewAnnotationFrames");
    if (!callbackPtr) {
        Logger::error("NativeMapView", "setViewAnnotationFramesListener: Failed to create ThreadSafeCallback");
        return args.Undefined();
    }

    {
        std::lock_guard<std::mutex> lock(instance->viewAnnotationFrameMutex_);
        instance->viewAnnotationFramesCallback_ = std::move(callbackPtr);
        instance->lastPushedViewAnnotationFrames_.clear();
    }

    // Deliver the current state to the new listener (async hop to the map
    // thread; the cleared snapshot above bypasses the epsilon dedupe).
    instance->invokeOnMapThread([instance](mbgl::Map*) {
        instance->pushViewAnnotationFrames();
    });

    return args.Undefined();
}

} // namespace harmony
} // namespace mbgl
