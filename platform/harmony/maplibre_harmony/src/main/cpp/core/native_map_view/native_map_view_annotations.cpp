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

    // Use anchorHeight for anchor positioning calculation
    // anchorHeight represents the height of the underlying element (e.g., marker icon)
    // This ensures InfoWindow positions correctly relative to the marker anchor point
    const double anchorHeightForPosition = annotation.anchorHeight > 0 ?
        annotation.anchorHeight : static_cast<double>(annotation.size.height);

    // Calculate screen position: anchor + offset
    // Note: anchorHeight offset is applied in JS layer for consistent positioning
    frame.screen = mbgl::ScreenCoordinate{
        screen.x + annotation.offset.x,
        screen.y + annotation.offset.y
    };

    // Compute final render position in logical pixels
    // Eliminates per-frame pixelRatio division and anchor math on the ArkTS side
    const double ratio = pixelRatio > 0.0 ? pixelRatio : 1.0;
    frame.positionX = (frame.screen.x / ratio) - (static_cast<double>(frame.size.width) / ratio) * annotation.anchorU;
    // Use the frame's own height for anchorV-based positioning (anchorHeight is
    // already handled via centerOffset on the ArkTS side). This ensures that
    // with anchorV=1.0 and centerOffset.dy=-iconHeight, the InfoWindow's bottom
    // aligns with the top of the marker icon — placing the InfoWindow entirely
    // above the marker instead of covering it.
    frame.positionY = (frame.screen.y / ratio) - (static_cast<double>(frame.size.height) / ratio) * annotation.anchorV;

    return frame;
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
    
    Logger::info("NativeMapView", "[MarkerDebug] updateMarker: ID=%lu, lat=%f, lon=%f, icon=\"%s\"", 
                  annotationId, position.y, position.x, iconId.c_str());
    
    try {
        // Update the marker using SymbolAnnotation
        mbgl::SymbolAnnotation annotation(position, iconId);
        instance->invokeOnMapThread([annotationId, annotation](mbgl::Map* m){
            m->updateAnnotation(annotationId, annotation);
            m->triggerRepaint();
        });
        
        Logger::info("NativeMapView", "[MarkerDebug] updateMarker: Marker updated successfully");
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
    
    Logger::info("NativeMapView", "addMarkers: Processing %u markers", length);
    
    // Store the generated annotation IDs
    std::vector<mbgl::AnnotationID> ids;
    ids.reserve(length);
    
    // Iterate over the marker array (now MarkerNAPI objects)
    for (uint32_t i = 0; i < length; i++) {
        napi_value markerObj;
        if (napi_get_element(env, args[0], i, &markerObj) != napi_ok) {
            Logger::error("NativeMapView", "addMarkers: Failed to get marker at index %u", i);
            continue;
        }
        
        // Unwrap the MarkerNAPI object
        maplibre::harmony::MarkerNAPI* marker = nullptr;
        if (napi_unwrap(env, markerObj, reinterpret_cast<void**>(&marker)) != napi_ok || !marker) {
            Logger::error("NativeMapView", "[MarkerDebug] NAPI-Error: Failed to unwrap Marker at index %u", i);
            continue;
        }
        
        // Pull data directly from the MarkerNAPI object
        auto position = marker->getPositionPoint();
        auto iconId = marker->getIconId();
        
        // [MarkerDebug] Log the incoming data
        if (iconId.empty()) {
            Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Input: marker[%u] has EMPTY icon, may not be visible!", i);
            Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Warning: Use addAnnotationIcon() to add custom icon or ensure style has default marker icon");
        }
        
        Logger::info("NativeMapView", "[MarkerDebug] NAPI-Input: marker[%u] lat=%f, lon=%f, icon=\"%s\"", 
                     i, position.y, position.x, iconId.empty() ? "(empty)" : iconId.c_str());
        
        try {
            // Create a SymbolAnnotation
            mbgl::SymbolAnnotation annotation(position, iconId);
            
            // Add it to the map and obtain the ID
            mbgl::AnnotationID annotationId = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->addAnnotation(annotation); }, mbgl::AnnotationID{});
            ids.push_back(annotationId);
            
            // Write the annotation ID back to the marker
            marker->setAnnotationId(annotationId);
            
            Logger::info("NativeMapView", "[MarkerDebug] NAPI-Result: marker[%u] created with ID=%lu", i, annotationId);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "[MarkerDebug] NAPI-Error: marker[%u] failed to add - %s", i, e.what());
        }
    }
    
    // [MarkerDebug] Summarize the add results
    Logger::info("NativeMapView", "[MarkerDebug] NAPI-Summary: Added %zu/%u markers successfully", ids.size(), length);
    if (ids.size() < length) {
        Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Summary: ⚠️ %u markers failed to add", length - static_cast<uint32_t>(ids.size()));
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
    
    // Iterate over the polyline array
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
        
        try {
            // Convert to a LineAnnotation
            mbgl::LineAnnotation annotation = polyline->toAnnotation();
            
            // Add it to the map and obtain the ID
            mbgl::AnnotationID annotationId = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->addAnnotation(annotation); }, mbgl::AnnotationID{});
            ids.push_back(annotationId);
            
            // Write the annotation ID back to the polyline
            polyline->setAnnotationId(annotationId);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "addPolylines: polyline[%u] failed to add - %s", i, e.what());
        }
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
    
    // Iterate over the polygon array
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
        
        try {
            // Convert to a FillAnnotation
            mbgl::FillAnnotation annotation = polygon->toAnnotation();
            
            // Add it to the map and obtain the ID
            mbgl::AnnotationID annotationId = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->addAnnotation(annotation); }, mbgl::AnnotationID{});
            ids.push_back(annotationId);
            
            // Write the annotation ID back to the polygon
            polygon->setAnnotationId(annotationId);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "addPolygons: polygon[%u] failed to add - %s", i, e.what());
        }
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
            Logger::info("NativeMapView", "🎯 Adding icon '%s' to style.addImage()...", iconId.c_str());
            m->getStyle().addImage(std::move(styleImage));
            Logger::info("NativeMapView", "✅ Icon '%s' successfully added to style", iconId.c_str());
        });
        
        Logger::info("NativeMapView", "addAnnotationIcon: Icon '%s' scheduled to add (using Icon object)", iconId.c_str());
        Logger::info("NativeMapView", "========== addAnnotationIcon() END (Icon object) ==========");
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
    
    Logger::info("NativeMapView", "addAnnotationIcon: symbol=%s, width=%d, height=%d, scale=%f, pixelLength=%zu", 
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
            Logger::info("NativeMapView", "addAnnotationIcon: Icon '%s' scheduled to add", symbol.c_str());
        } else {
            Logger::error("NativeMapView", "addAnnotationIcon: Invalid pixel data size (expected %zu, got %zu)", 
                         expectedSize, pixelLength);
        }
    }
    
    Logger::info("NativeMapView", "========== addAnnotationIcon() END (byte array) ==========");
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

    instance->invokeOnMapThread([](mbgl::Map* map) {
        if (map) {
            map->triggerRepaint();
        }
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
        instance->invokeOnMapThread([](mbgl::Map* map) {
            if (map) {
                map->triggerRepaint();
            }
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
        instance->invokeOnMapThread([](mbgl::Map* map) {
            if (map) {
                map->triggerRepaint();
            }
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

    napi_value resultArray;
    napi_create_array_with_length(env, frames.size(), &resultArray);

    // Log frame data for debugging
    Logger::info("NativeMapView", "[ViewAnnotation] getViewAnnotationFrames: %zu annotations, pixelRatio=%.2f",
                 frames.size(), pixelRatio);
    for (size_t i = 0; i < frames.size(); ++i) {
        Logger::info("NativeMapView", "[ViewAnnotation] Frame[%zu]: id=%ld, screen=(%.2f, %.2f), size=%dx%d",
                     i, frames[i].id, frames[i].screen.x, frames[i].screen.y,
                     frames[i].size.width, frames[i].size.height);
    }

    for (size_t i = 0; i < frames.size(); ++i) {
        const auto& frame = frames[i];
        napi_value frameObj;
        napi_create_object(env, &frameObj);

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

        napi_set_element(env, resultArray, i, frameObj);
    }

    return resultArray;
}


} // namespace harmony
} // namespace mbgl
