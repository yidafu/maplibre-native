#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "geometry/lat_lng_harmony.hpp"
#include "geometry/point_harmony.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "geometry/rect_harmony.hpp"
#include "camera/camera_position_harmony.hpp"
#include "geojson/geojson_converter.hpp"
#include "rendering/harmony_renderer.hpp"
#include <mbgl/style/style.hpp>
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/map/camera.hpp>
#include <mbgl/util/geo.hpp>
#include <mbgl/util/geojson.hpp>
#include <mbgl/util/geometry.hpp>
#include <vector>
#include <cstring>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using maplibre::harmony::geojson::GeoJsonConverter;

namespace mbgl {
namespace harmony {

// Camera move reason constants (matching CameraChangeTracker behavior)
namespace CameraMoveReason {
    constexpr int REASON_UNKNOWN = 0;
    constexpr int REASON_GESTURE = 1;
    constexpr int REASON_API_ANIMATION = 2;
    constexpr int REASON_DEVELOPER_ANIMATION = 3;
    constexpr int REASON_ANIMATION_CANCELLED = 4;
}

napi_value NativeMapView::resizeView(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return args.Undefined();
    
    // Parse width and height
    int32_t newWidth = args.GetInt32(0, "width");
    int32_t newHeight = args.GetInt32(1, "height");
    if (args.HasError()) return args.Undefined();
    
    Logger::info("NativeMapView", "🔍 [DPI] resizeView called: %dx%d (logical)", newWidth, newHeight);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Update stored dimensions
    instance->width = newWidth;
    instance->height = newHeight;
    
    Logger::info("NativeMapView", "Resize details:");
    Logger::info("NativeMapView", "  - New size: %dx%d (logical pixels)", instance->width, instance->height);
    Logger::info("NativeMapView", "  - PixelRatio: %.2f", instance->pixelRatio);
    
    // Resize if the renderer is already initialized
    if (instance->harmonyRenderer) {
        instance->harmonyRenderer->resize(instance->width, instance->height);
    }
    
    Logger::info("NativeMapView", "View resized to %d x %d", instance->width, instance->height);
    
    return args.Undefined();
}

// Note: getStyleUrl, setStyleUrl, getStyleJson, setStyleJson, and setLatLngBounds are now defined in native_map_view_style.cpp

napi_value NativeMapView::cancelTransitions(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "cancelTransitions: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "cancelTransitions: Map not initialized");
        return args.Undefined();
    }
    
    // Execute the map operation on the render thread
    instance->invokeOnMapThread([&](mbgl::Map* m) {
        Logger::info("NativeMapView", "🔵 map->cancelTransitions() on render thread");
        m->cancelTransitions();
        m->triggerRepaint();
    });

    // Fire callbacks on the current thread
    if (instance->callbackManager_) {
        instance->callbackManager_->InvokeCallbackEmpty("onCameraMoveCanceled");
        instance->callbackManager_->InvokeCallbackEmpty("onCameraIdle");
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setGestureInProgress(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Read the boolean argument
    bool inProgress = args.GetBool(0, "inProgress");
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setGestureInProgress: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "setGestureInProgress: Map not initialized");
        return args.Undefined();
    }
    
    instance->invokeOnMapThread([inProgress](mbgl::Map* m) {
        m->setGestureInProgress(inProgress);
    });
    
    return args.Undefined();
}

napi_value NativeMapView::moveBy(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return args.Undefined();
    
    // Read the move distance
    double dx = args.GetDouble(0, "dx");
    double dy = args.GetDouble(1, "dy");
    // Optional animation duration (default 0 for immediate)
    uint64_t duration = static_cast<uint64_t>(args.GetDoubleOr(2, 0.0));
    if (args.HasError()) return args.Undefined();
    
    if (duration > 0) {
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "moveBy: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "moveBy: Map not initialized");
        return args.Undefined();
    }
    
    // Emit camera move-start event (UI thread)
    if (instance->callbackManager_) {
        int reason = duration > 0 ? CameraMoveReason::REASON_DEVELOPER_ANIMATION
                                  : CameraMoveReason::REASON_API_ANIMATION;
        instance->callbackManager_->InvokeCallback("onCameraMoveStarted",
            [reason](napi_env env) -> napi_value {
                napi_value reasonValue; napi_create_int32(env, reason, &reasonValue); return reasonValue;
            });
    }

    // Perform the actual move on the render thread
    instance->invokeOnMapThread([dx, dy, duration, instance](mbgl::Map* m) {
        if (duration > 0) {
            m->moveBy(mbgl::ScreenCoordinate{dx, dy}, mbgl::AnimationOptions(std::chrono::milliseconds(duration)));
        } else {
            m->moveBy(mbgl::ScreenCoordinate{dx, dy});
        }
        m->triggerRepaint();
    });

    // Trigger idle immediately when no animation is used
    if (duration == 0 && instance->callbackManager_) {
        instance->callbackManager_->InvokeCallbackEmpty("onCameraIdle");
    }
    
    return args.Undefined();
}

napi_value NativeMapView::jumpTo(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(5);
    if (args.HasError()) return args.Undefined();
    
    // Parse parameters: angle, latitude, longitude, pitch, zoom
    double angle = args.GetDouble(0, "angle");
    double latitude = args.GetDouble(1, "latitude");
    double longitude = args.GetDouble(2, "longitude");
    double pitch = args.GetDouble(3, "pitch");
    double zoom = args.GetDouble(4, "zoom");
    if (args.HasError()) return args.Undefined();
    
    Logger::info("NativeMapView", "jumpTo: angle=%f, lat=%f, lng=%f, pitch=%f, zoom=%f", 
                  angle, latitude, longitude, pitch, zoom);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "jumpTo: Failed to unwrap instance or instance is null");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "jumpTo: Map not initialized yet, will skip jumpTo");
        return args.Undefined();
    }
    
    // Build CameraOptions
    CameraOptions cameraOptions;
    cameraOptions.center = LatLng{latitude, longitude};
    cameraOptions.zoom = zoom;
    cameraOptions.bearing = angle;
    cameraOptions.pitch = pitch;
    
    // Parse optional padding argument when provided
    // padding format: [left, top, right, bottom]
    if (args.Count() >= 6) {
        napi_value paddingValue = args.GetValue(5);
        bool isArray = false;
        napi_is_array(env, paddingValue, &isArray);
        
        if (isArray) {
            uint32_t length = 0;
            napi_get_array_length(env, paddingValue, &length);
            
            if (length == 4) {
                napi_value leftVal, topVal, rightVal, bottomVal;
                double left = 0, top = 0, right = 0, bottom = 0;
                
                if (napi_get_element(env, paddingValue, 0, &leftVal) == napi_ok &&
                    napi_get_element(env, paddingValue, 1, &topVal) == napi_ok &&
                    napi_get_element(env, paddingValue, 2, &rightVal) == napi_ok &&
                    napi_get_element(env, paddingValue, 3, &bottomVal) == napi_ok) {
                    
                    napi_get_value_double(env, leftVal, &left);
                    napi_get_value_double(env, topVal, &top);
                    napi_get_value_double(env, rightVal, &right);
                    napi_get_value_double(env, bottomVal, &bottom);
                    
                    // Apply pixelRatio scaling
                    cameraOptions.padding = EdgeInsets{
                        top * instance->pixelRatio,
                        left * instance->pixelRatio,
                        bottom * instance->pixelRatio,
                        right * instance->pixelRatio
                    };
                    
                    Logger::info("NativeMapView", "jumpTo: padding=[%.1f, %.1f, %.1f, %.1f]", 
                                left, top, right, bottom);
                }
            }
        }
    } else {
        // If padding is omitted, fall back to stored contentPadding_.
        // contentPadding_ order: [0]=left, [1]=top, [2]=right, [3]=bottom
        // EdgeInsets constructor order: (top, left, bottom, right)
        if (instance->contentPadding_[0] != 0 || instance->contentPadding_[1] != 0 ||
            instance->contentPadding_[2] != 0 || instance->contentPadding_[3] != 0) {
            cameraOptions.padding = EdgeInsets{
                instance->contentPadding_[1] * instance->pixelRatio, // top = contentPadding_[1]
                instance->contentPadding_[0] * instance->pixelRatio, // left = contentPadding_[0]
                instance->contentPadding_[3] * instance->pixelRatio, // bottom = contentPadding_[3]
                instance->contentPadding_[2] * instance->pixelRatio  // right = contentPadding_[2]
            };
            
            Logger::info("NativeMapView", "jumpTo: using stored contentPadding_: left=%.1f, top=%.1f, right=%.1f, bottom=%.1f",
                        instance->contentPadding_[0], instance->contentPadding_[1],
                        instance->contentPadding_[2], instance->contentPadding_[3]);
        }
    }
    
    // Perform the camera jump
    // Fire start events (UI thread)
    if (instance->callbackManager_) {
        instance->callbackManager_->InvokeCallback("onCameraMoveStarted",
            [](napi_env env) -> napi_value { napi_value v; napi_create_int32(env, CameraMoveReason::REASON_API_ANIMATION, &v); return v; });
    }

    // Execute on the render thread
    instance->invokeOnMapThread([cameraOptions](mbgl::Map* m) {
        m->jumpTo(cameraOptions);
        m->triggerRepaint();
    });

    // jumpTo completes immediately; trigger idle
    if (instance->callbackManager_) {
        instance->callbackManager_->InvokeCallbackEmpty("onCameraIdle");
    }
    
    return args.Undefined();
}

napi_value NativeMapView::easeTo(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the camera options object
    napi_value cameraObj = args.GetObject(0, "cameraOptions");
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "easeTo: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::error("NativeMapView", "easeTo: Map not initialized");
        return args.Undefined();
    }
    
    CameraOptions cameraOptions;
    
    // Retrieve the center (LatLng)
    napi_value centerValue;
    if (napi_get_named_property(env, cameraObj, "center", &centerValue) == napi_ok) {
        napi_value latValue, lngValue;
        if (napi_get_named_property(env, centerValue, "latitude", &latValue) == napi_ok &&
            napi_get_named_property(env, centerValue, "longitude", &lngValue) == napi_ok) {
            double lat, lng;
            if (napi_get_value_double(env, latValue, &lat) == napi_ok &&
                napi_get_value_double(env, lngValue, &lng) == napi_ok) {
                cameraOptions.center = LatLng{lat, lng};
            }
        }
    }
    
    // Retrieve zoom
    napi_value zoomValue;
    if (napi_get_named_property(env, cameraObj, "zoom", &zoomValue) == napi_ok) {
        double zoom;
        if (napi_get_value_double(env, zoomValue, &zoom) == napi_ok) {
            cameraOptions.zoom = zoom;
        }
    }
    
    // Retrieve bearing
    napi_value bearingValue;
    if (napi_get_named_property(env, cameraObj, "bearing", &bearingValue) == napi_ok) {
        double bearing;
        if (napi_get_value_double(env, bearingValue, &bearing) == napi_ok) {
            cameraOptions.bearing = bearing;
        }
    }
    
    // Retrieve pitch
    napi_value pitchValue;
    if (napi_get_named_property(env, cameraObj, "pitch", &pitchValue) == napi_ok) {
        double pitch;
        if (napi_get_value_double(env, pitchValue, &pitch) == napi_ok) {
            cameraOptions.pitch = pitch;
        }
    }
    
    // Retrieve padding (optional)
    // padding format: [left, top, right, bottom] or {left, top, right, bottom}
    napi_value paddingValue;
    if (napi_get_named_property(env, cameraObj, "padding", &paddingValue) == napi_ok) {
        bool isArray = false;
        napi_is_array(env, paddingValue, &isArray);
        
        if (isArray) {
            uint32_t length = 0;
            napi_get_array_length(env, paddingValue, &length);
            
            if (length == 4) {
                napi_value leftVal, topVal, rightVal, bottomVal;
                double left = 0, top = 0, right = 0, bottom = 0;
                
                if (napi_get_element(env, paddingValue, 0, &leftVal) == napi_ok &&
                    napi_get_element(env, paddingValue, 1, &topVal) == napi_ok &&
                    napi_get_element(env, paddingValue, 2, &rightVal) == napi_ok &&
                    napi_get_element(env, paddingValue, 3, &bottomVal) == napi_ok) {
                    
                    napi_get_value_double(env, leftVal, &left);
                    napi_get_value_double(env, topVal, &top);
                    napi_get_value_double(env, rightVal, &right);
                    napi_get_value_double(env, bottomVal, &bottom);
                    
                    // Apply pixelRatio scaling
                    cameraOptions.padding = EdgeInsets{
                        top * instance->pixelRatio,
                        left * instance->pixelRatio,
                        bottom * instance->pixelRatio,
                        right * instance->pixelRatio
                    };
                    
                    Logger::info("NativeMapView", "easeTo: padding=[%.1f, %.1f, %.1f, %.1f]", 
                                left, top, right, bottom);
                }
            }
        }
    }
    
    // Retrieve anchor (optional)
    napi_value anchorValue;
    if (napi_get_named_property(env, cameraObj, "anchor", &anchorValue) == napi_ok) {
        napi_value anchorX, anchorY;
        if (napi_get_named_property(env, anchorValue, "x", &anchorX) == napi_ok &&
            napi_get_named_property(env, anchorValue, "y", &anchorY) == napi_ok) {
            double x, y;
            if (napi_get_value_double(env, anchorX, &x) == napi_ok &&
                napi_get_value_double(env, anchorY, &y) == napi_ok) {
                cameraOptions.anchor = mbgl::ScreenCoordinate{x, y};
            }
        }
    }
    
    // Optional animation duration (defaults to 300 ms)
    uint64_t duration = static_cast<uint64_t>(args.GetDoubleOr(1, 300.0));
    // Run the easeTo camera animation
    // Fire start event (UI thread)
    if (instance->callbackManager_) {
        instance->callbackManager_->InvokeCallback("onCameraMoveStarted",
            [](napi_env env) -> napi_value { napi_value v; napi_create_int32(env, CameraMoveReason::REASON_DEVELOPER_ANIMATION, &v); return v; });
    }
    // Execute on the render thread
    instance->invokeOnMapThread([cameraOptions, duration](mbgl::Map* m) {
        m->easeTo(cameraOptions, mbgl::AnimationOptions(std::chrono::milliseconds(duration)));
        m->triggerRepaint();
    });
    
    return args.Undefined();
}

napi_value NativeMapView::flyTo(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the camera options object
    napi_value cameraObj = args.GetObject(0, "cameraOptions");
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "flyTo: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    CameraOptions cameraOptions;
    
    // Retrieve the center (LatLng)
    napi_value centerValue;
    if (napi_get_named_property(env, cameraObj, "center", &centerValue) == napi_ok) {
        napi_value latValue, lngValue;
        if (napi_get_named_property(env, centerValue, "latitude", &latValue) == napi_ok &&
            napi_get_named_property(env, centerValue, "longitude", &lngValue) == napi_ok) {
            double lat, lng;
            if (napi_get_value_double(env, latValue, &lat) == napi_ok &&
                napi_get_value_double(env, lngValue, &lng) == napi_ok) {
                cameraOptions.center = LatLng{lat, lng};
            }
        }
    }
    
    // Retrieve zoom
    napi_value zoomValue;
    if (napi_get_named_property(env, cameraObj, "zoom", &zoomValue) == napi_ok) {
        double zoom;
        if (napi_get_value_double(env, zoomValue, &zoom) == napi_ok) {
            cameraOptions.zoom = zoom;
        }
    }
    
    // Retrieve bearing
    napi_value bearingValue;
    if (napi_get_named_property(env, cameraObj, "bearing", &bearingValue) == napi_ok) {
        double bearing;
        if (napi_get_value_double(env, bearingValue, &bearing) == napi_ok) {
            cameraOptions.bearing = bearing;
        }
    }
    
    // Retrieve pitch
    napi_value pitchValue;
    if (napi_get_named_property(env, cameraObj, "pitch", &pitchValue) == napi_ok) {
        double pitch;
        if (napi_get_value_double(env, pitchValue, &pitch) == napi_ok) {
            cameraOptions.pitch = pitch;
        }
    }
    
    // Optional animation duration (defaults to flyTo automatic duration)
    uint64_t duration = static_cast<uint64_t>(args.GetDoubleOr(1, 0.0));
    if (duration > 0) {
    }
    
    // Run the flyTo camera animation
    // Execute on the render thread
    instance->invokeOnMapThread([cameraOptions, duration](mbgl::Map* m) {
        mbgl::AnimationOptions anim;
        if (duration > 0) anim.duration.emplace(mbgl::Milliseconds(duration));
        m->flyTo(cameraOptions, anim);
        m->triggerRepaint();
    });
    
    return args.Undefined();
}

napi_value NativeMapView::getLatLng(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getLatLng: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    {
        auto cameraOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getCameraOptions(); }, mbgl::CameraOptions{});
        if (cameraOptions.center) {
            const auto& center = *cameraOptions.center;
            
            // Create the return object { latitude, longitude }
            napi_value result;
            napi_create_object(env, &result);
            
            napi_value latValue, lngValue;
            napi_create_double(env, center.latitude(), &latValue);
            napi_create_double(env, center.longitude(), &lngValue);
            
            napi_set_named_property(env, result, "latitude", latValue);
            napi_set_named_property(env, result, "longitude", lngValue);
            
            return result;
        }
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setLatLng(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setLatLng: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    // Read parameters: latitude, longitude, optional padding, optional duration
    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    double duration = args.GetDoubleOr(3, 0.0);
    
    if (args.HasError()) {
        return args.Undefined();
    }
    
    try {
        mbgl::CameraOptions cameraOptions;
        cameraOptions.center = mbgl::LatLng(latitude, longitude);
        
        // Handle padding argument (args[2])
        // padding format: [left, top, right, bottom]
        if (args.Count() >= 3) {
            napi_value paddingValue = args.GetValue(2);
            bool isArray = false;
            napi_is_array(env, paddingValue, &isArray);
            
            if (isArray) {
                uint32_t length = 0;
                napi_get_array_length(env, paddingValue, &length);
                
                if (length == 4) {
                    napi_value leftVal, topVal, rightVal, bottomVal;
                    double left = 0, top = 0, right = 0, bottom = 0;
                    
                    if (napi_get_element(env, paddingValue, 0, &leftVal) == napi_ok &&
                        napi_get_element(env, paddingValue, 1, &topVal) == napi_ok &&
                        napi_get_element(env, paddingValue, 2, &rightVal) == napi_ok &&
                        napi_get_element(env, paddingValue, 3, &bottomVal) == napi_ok) {
                        
                        napi_get_value_double(env, leftVal, &left);
                        napi_get_value_double(env, topVal, &top);
                        napi_get_value_double(env, rightVal, &right);
                        napi_get_value_double(env, bottomVal, &bottom);
                        
                        // Apply pixelRatio scaling
                        cameraOptions.padding = mbgl::EdgeInsets{
                            top * instance->pixelRatio,
                            left * instance->pixelRatio,
                            bottom * instance->pixelRatio,
                            right * instance->pixelRatio
                        };
                        
                        Logger::info("NativeMapView", "setLatLng: padding=[%.1f, %.1f, %.1f, %.1f]", 
                                    left, top, right, bottom);
                    }
                }
            }
        }
        
        instance->invokeOnMapThread([cameraOptions, duration](mbgl::Map* m){
            m->easeTo(cameraOptions, mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))});
            m->triggerRepaint();
        });
        Logger::info("NativeMapView", "setLatLng: lat=%.6f, lng=%.6f, duration=%.0fms", latitude, longitude, duration);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setLatLng: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getCameraForLatLngBounds(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getCameraForLatLngBounds: Map not initialized");
        return args.Undefined();
    }
    
    // Parse LatLngBounds
    napi_value boundsObj = args.GetObject(0, "bounds");
    if (args.HasError()) {
        return args.Undefined();
    }
    
    mbgl::LatLngBounds bounds;
    if (!LatLngBoundsHarmony::ParseLatLngBounds(env, boundsObj, bounds)) {
        Logger::error("NativeMapView", "getCameraForLatLngBounds: Failed to parse bounds");
        return args.Undefined();
    }
    
    // Parse padding (top, left, bottom, right)
    double top = args.GetDoubleOr(1, 0.0);
    double left = args.GetDoubleOr(2, 0.0);
    double bottom = args.GetDoubleOr(3, 0.0);
    double right = args.GetDoubleOr(4, 0.0);
    mbgl::EdgeInsets padding{top, left, bottom, right};
    
    // Parse optional bearing and tilt
    double bearing = args.GetDoubleOr(5, 0.0);
    double tilt = args.GetDoubleOr(6, 0.0);
    
    try {
        mbgl::CameraOptions cameraOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->cameraForLatLngBounds(bounds, padding, bearing, tilt); }, mbgl::CameraOptions{});
        
        napi_value result = CameraPositionHarmony::CreateCameraPositionObject(env, cameraOptions, instance->pixelRatio);
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getCameraForLatLngBounds: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::getCameraForGeometry(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getCameraForGeometry: Map not initialized");
        return args.Undefined();
    }

    // Parse the geometry, given as a GeoJSON geometry string or object
    napi_value geometryValue = args.GetValue(0);
    mbgl::Geometry<double> geometry;
    try {
        napi_valuetype valueType = napi_undefined;
        napi_typeof(env, geometryValue, &valueType);
        if (valueType == napi_string) {
            std::string geoJsonString = args.GetString(0, "geometry");
            if (args.HasError()) return args.Undefined();

            mbgl::style::conversion::Error error;
            auto parsed = mbgl::style::conversion::convertJSON<mbgl::GeoJSON>(geoJsonString, error);
            if (!parsed) {
                Logger::error("NativeMapView", "getCameraForGeometry: %s", error.message.c_str());
                return args.Undefined();
            }
            // Extract the geometry from the GeoJSON variant
            geometry = parsed->get<mbgl::Geometry<double>>();
        } else if (valueType == napi_object) {
            geometry = GeoJsonConverter::JsObjectToGeometry(env, geometryValue);
        } else {
            napi_throw_error(env, nullptr, "Geometry must be a GeoJSON string or object");
            return nullptr;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getCameraForGeometry: Failed to parse geometry - %s", e.what());
        return args.Undefined();
    }

    // Parse padding (top, left, bottom, right)
    double top = args.GetDoubleOr(1, 0.0);
    double left = args.GetDoubleOr(2, 0.0);
    double bottom = args.GetDoubleOr(3, 0.0);
    double right = args.GetDoubleOr(4, 0.0);
    mbgl::EdgeInsets padding{top, left, bottom, right};

    // Parse optional bearing and tilt
    double bearing = args.GetDoubleOr(5, 0.0);
    double tilt = args.GetDoubleOr(6, 0.0);

    try {
        mbgl::CameraOptions cameraOptions = instance->invokeOnMapThreadSync(
            [&](mbgl::Map* m) {
                return m->cameraForGeometry(geometry, padding, bearing, tilt);
            },
            mbgl::CameraOptions{});

        napi_value result = CameraPositionHarmony::CreateCameraPositionObject(env, cameraOptions, instance->pixelRatio);
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getCameraForGeometry: Failed - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::setReachability(napi_env env, napi_callback_info info) {
    // Network reachability is handled by Harmony's network manager; no manual control needed
    // Network reachability handled by Harmony network manager
    NapiArgs args(env, info);
    return args.Undefined();
}

napi_value NativeMapView::resetPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "resetPosition: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        instance->invokeOnMapThread([](mbgl::Map* m){
            m->jumpTo(mbgl::CameraOptions()
                .withCenter(mbgl::LatLng{0.0, 0.0})
                .withZoom(0.0)
                .withBearing(0.0)
                .withPitch(0.0));
            m->triggerRepaint();
        });
        Logger::info("NativeMapView", "resetPosition: Reset to origin (0,0) zoom 0");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "resetPosition: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getPitch(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getPitch: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "getPitch: Map not initialized");
        return args.Undefined();
    }
    
    try {
        auto cameraOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getCameraOptions(); }, mbgl::CameraOptions{});
        if (cameraOptions.pitch) {
            napi_value result;
            napi_create_double(env, *cameraOptions.pitch, &result);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getPitch: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setPitch(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Retrieve pitch and optional animation duration
    double pitch = args.GetDouble(0, "pitch");
    uint32_t duration = args.GetUint32Or(1, 0);
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setPitch: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "setPitch: Map not initialized");
        return args.Undefined();
    }
    
    try {
        mbgl::CameraOptions options;
        options.pitch = pitch;
        
        if (duration > 0) {
            mbgl::AnimationOptions animationOptions;
            animationOptions.duration = std::chrono::milliseconds(duration);
            instance->invokeOnMapThread([options, animationOptions](mbgl::Map* m){ m->easeTo(options, animationOptions); m->triggerRepaint(); });
        } else {
            instance->invokeOnMapThread([options](mbgl::Map* m){ m->jumpTo(options); m->triggerRepaint(); });
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setPitch: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setZoom: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    // Read parameters: zoom, optional cx/cy, optional duration
    double zoom = args.GetDouble(0, "zoom");
    if (args.HasError()) {
        return args.Undefined();
    }
    
    double cx = args.GetDoubleOr(1, 0.0);
    double cy = args.GetDoubleOr(2, 0.0);
    double duration = args.GetDoubleOr(3, 0.0);
    bool hasAnchor = args.Count() >= 3;
    
    try {
        mbgl::CameraOptions cameraOptions;
        cameraOptions.zoom = zoom;
        
        if (hasAnchor) {
            cameraOptions.anchor = mbgl::ScreenCoordinate{cx, cy};
            Logger::info("NativeMapView", "setZoom: zoom=%.2f, anchor=(%.2f, %.2f), duration=%.0fms", 
                        zoom, cx, cy, duration);
        } else {
            Logger::info("NativeMapView", "setZoom: zoom=%.2f, duration=%.0fms", zoom, duration);
        }
        
        instance->invokeOnMapThread([cameraOptions, duration](mbgl::Map* m){ m->easeTo(cameraOptions, mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))}); m->triggerRepaint(); });
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setZoom: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getZoom: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "getZoom: Map not initialized");
        return args.Undefined();
    }
    
    {
        auto cameraOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getCameraOptions(); }, mbgl::CameraOptions{});
        if (cameraOptions.zoom) {
            napi_value result;
            napi_create_double(env, *cameraOptions.zoom, &result);
            return result;
        }
    }
    
    return args.Undefined();
}

napi_value NativeMapView::resetZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "resetZoom: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        instance->invokeOnMapThread([](mbgl::Map* m){ m->jumpTo(mbgl::CameraOptions().withZoom(0.0)); m->triggerRepaint(); });
        Logger::info("NativeMapView", "resetZoom: Reset zoom to 0");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "resetZoom: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    double zoom = args.GetDouble(0, "zoom");
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMinZoom: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        instance->invokeOnMapThread([zoom](mbgl::Map* m){ m->setBounds(mbgl::BoundOptions().withMinZoom(zoom)); });
        Logger::info("NativeMapView", "setMinZoom: Set min zoom to %.2f", zoom);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMinZoom: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMinZoom: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        auto bounds = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getBounds(); }, mbgl::BoundOptions{});
        if (bounds.minZoom) {
            napi_value result;
            napi_create_double(env, *bounds.minZoom, &result);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMinZoom: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    double zoom = args.GetDouble(0, "zoom");
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMaxZoom: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        instance->invokeOnMapThread([zoom](mbgl::Map* m){ m->setBounds(mbgl::BoundOptions().withMaxZoom(zoom)); });
        Logger::info("NativeMapView", "setMaxZoom: Set max zoom to %.2f", zoom);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMaxZoom: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMaxZoom: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        auto bounds = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getBounds(); }, mbgl::BoundOptions{});
        if (bounds.maxZoom) {
            napi_value result;
            napi_create_double(env, *bounds.maxZoom, &result);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMaxZoom: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setMinPitch(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMinPitch: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    double pitch = args.GetDouble(0, "pitch");
    if (args.HasError()) {
        return args.Undefined();
    }
    
    try {
        instance->invokeOnMapThread([pitch](mbgl::Map* m){ m->setBounds(mbgl::BoundOptions().withMinPitch(pitch)); });
        Logger::info("NativeMapView", "setMinPitch: Set min pitch to %.2f", pitch);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMinPitch: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getMinPitch(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMinPitch: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        auto bounds = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getBounds(); }, mbgl::BoundOptions{});
        if (bounds.minPitch) {
            napi_value result;
            napi_create_double(env, *bounds.minPitch, &result);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMinPitch: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setMaxPitch(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setMaxPitch: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    double pitch = args.GetDouble(0, "pitch");
    if (args.HasError()) {
        return args.Undefined();
    }
    
    try {
        instance->invokeOnMapThread([pitch](mbgl::Map* m){ m->setBounds(mbgl::BoundOptions().withMaxPitch(pitch)); });
        Logger::info("NativeMapView", "setMaxPitch: Set max pitch to %.2f", pitch);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setMaxPitch: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getMaxPitch(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getMaxPitch: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        auto bounds = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getBounds(); }, mbgl::BoundOptions{});
        if (bounds.maxPitch) {
            napi_value result;
            napi_create_double(env, *bounds.maxPitch, &result);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMaxPitch: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::rotateBy(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "rotateBy: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    // Read parameters: sx, sy, ex, ey, optional duration
    double sx = args.GetDouble(0, "sx");
    double sy = args.GetDouble(1, "sy");
    double ex = args.GetDouble(2, "ex");
    double ey = args.GetDouble(3, "ey");
    double duration = args.GetDoubleOr(4, 0.0);
    
    if (args.HasError()) {
        return args.Undefined();
    }
    
    try {
        mbgl::ScreenCoordinate first(sx, sy);
        mbgl::ScreenCoordinate second(ex, ey);
        instance->invokeOnMapThread([first, second, duration](mbgl::Map* m){ m->rotateBy(first, second, mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))}); m->triggerRepaint(); });
        Logger::info("NativeMapView", "rotateBy: (%.2f, %.2f) -> (%.2f, %.2f), duration=%.0fms", sx, sy, ex, ey, duration);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "rotateBy: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setBearing(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Retrieve bearing and optional duration
    double bearing = args.GetDouble(0, "bearing");
    uint32_t duration = args.GetUint32Or(1, 0);
    if (args.HasError()) return args.Undefined();
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setBearing: Failed to unwrap instance");
        return args.Undefined();
    }
    
    // Ensure the Map object is initialized
    if (!instance->map) {
        Logger::warn("NativeMapView", "setBearing: Map not initialized");
        return args.Undefined();
    }
    
    try {
        if (duration > 0) {
            instance->invokeOnMapThread([bearing, duration](mbgl::Map* m){ m->easeTo(mbgl::CameraOptions().withBearing(bearing), mbgl::AnimationOptions(std::chrono::milliseconds(duration))); m->triggerRepaint(); });
        } else {
            instance->invokeOnMapThread([bearing](mbgl::Map* m){ m->jumpTo(mbgl::CameraOptions().withBearing(bearing)); m->triggerRepaint(); });
        }
        instance->invokeOnMapThread([](mbgl::Map* m){ m->triggerRepaint(); });
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setBearing: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setBearingXY(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(3);
    if (args.HasError()) {
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setBearingXY: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    // Read parameters: degrees, optional cx/cy, optional duration
    double degrees = args.GetDouble(0, "degrees");
    double cx = args.GetDouble(1, "cx");
    double cy = args.GetDouble(2, "cy");
    double duration = args.GetDoubleOr(3, 0.0);
    
    if (args.HasError()) {
        return args.Undefined();
    }
    
    try {
        mbgl::ScreenCoordinate anchor(cx, cy);
        instance->invokeOnMapThread([degrees, anchor, duration](mbgl::Map* m){ m->easeTo(mbgl::CameraOptions().withBearing(degrees).withAnchor(anchor), mbgl::AnimationOptions{mbgl::Milliseconds(static_cast<int64_t>(duration))}); m->triggerRepaint(); });
        Logger::info("NativeMapView", "setBearingXY: bearing=%.2f, anchor=(%.2f, %.2f), duration=%.0fms", 
                    degrees, cx, cy, duration);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setBearingXY: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getBearing(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getBearing: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        auto cameraOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getCameraOptions(); }, mbgl::CameraOptions{});
        if (cameraOptions.bearing) {
            napi_value result;
            napi_create_double(env, *cameraOptions.bearing, &result);
            return result;
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getBearing: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::resetNorth(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "resetNorth: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        // Use easeTo to set bearing to 0 with a 500 ms animation
        instance->invokeOnMapThread([](mbgl::Map* m){ m->easeTo(mbgl::CameraOptions().withBearing(0.0), mbgl::AnimationOptions{mbgl::Milliseconds(500)}); m->triggerRepaint(); });
        Logger::info("NativeMapView", "resetNorth: Reset bearing to 0 with 500ms animation");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "resetNorth: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::setVisibleCoordinateBounds(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "setVisibleCoordinateBounds: Invalid arguments");
        return args.Undefined();
    }
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setVisibleCoordinateBounds: Map not initialized");
        return args.Undefined();
    }
    
    try {
        // 1. Parse the LatLng array (argument 0)
        napi_value coordsArray = args.Get(0);
        
        // Ensure the value is an array
        bool isArray = false;
        napi_status status = napi_is_array(env, coordsArray, &isArray);
        if (status != napi_ok || !isArray) {
            Logger::error("NativeMapView", "setVisibleCoordinateBounds: First argument must be an array");
            return args.Undefined();
        }
        
        uint32_t count = 0;
        status = napi_get_array_length(env, coordsArray, &count);
        if (status != napi_ok || count == 0) {
            Logger::error("NativeMapView", "setVisibleCoordinateBounds: Empty coordinates array");
            return args.Undefined();
        }
        
        std::vector<mbgl::LatLng> latLngs;
        latLngs.reserve(count);
        
        for (uint32_t i = 0; i < count; i++) {
            napi_value item;
            status = napi_get_element(env, coordsArray, i, &item);
            if (status == napi_ok) {
                mbgl::LatLng latLng;
                if (LatLngHarmony::ParseLatLng(env, item, latLng)) {
                    latLngs.push_back(latLng);
                } else {
                    Logger::warn("NativeMapView", "setVisibleCoordinateBounds: Failed to parse LatLng at index %u", i);
                }
            }
        }
        
        if (latLngs.empty()) {
            Logger::error("NativeMapView", "setVisibleCoordinateBounds: No valid coordinates");
            return args.Undefined();
        }
        
        // 2. Parse padding (argument 1: Rect object)
        napi_value paddingObj = args.Get(1);
        mbgl::EdgeInsets padding;
        if (!RectHarmony::ParseAsEdgeInsets(env, paddingObj, padding)) {
            Logger::error("NativeMapView", "setVisibleCoordinateBounds: Failed to parse padding");
            return args.Undefined();
        }
        
        // 3. Parse direction/bearing (argument 2)
        double direction = args.GetDoubleOr(2, -1.0);
        
        // 4. Parse duration (argument 3)
        int64_t duration = args.GetInt64Or(3, 0);
        
        // 5. Execute camera calculations and animation on the map thread
        instance->invokeOnMapThread([latLngs, padding, direction, duration](mbgl::Map* m) {
            // Compute a camera that fits all coordinates
            mbgl::CameraOptions cameraOptions = m->cameraForLatLngs(latLngs, padding);
            
            // Apply bearing if direction was specified
            if (direction >= 0) {
                cameraOptions.bearing = direction;
            }
            
            // Build animation options
            mbgl::AnimationOptions animOptions;
            if (duration > 0) {
                animOptions.duration.emplace(mbgl::Milliseconds(duration));
                // Use the same easing curve as iOS
                animOptions.easing.emplace(mbgl::util::UnitBezier{0.25, 0.1, 0.25, 0.1});
            }
            
            // Run the camera animation
            m->easeTo(cameraOptions, animOptions);
        });
        
        Logger::info("NativeMapView", "setVisibleCoordinateBounds: Successfully set camera for %zu coordinates", latLngs.size());
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setVisibleCoordinateBounds: Exception - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getVisibleCoordinateBounds(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getVisibleCoordinateBounds: Map not initialized");
        return args.Undefined();
    }
    
    try {
        auto latLngBounds = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->latLngBoundsForCameraUnwrapped(m->getCameraOptions(std::nullopt)); }, mbgl::LatLngBounds{});
        
        napi_value result = LatLngBoundsHarmony::CreateLatLngBoundsObject(env, latLngBounds);
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getVisibleCoordinateBounds: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::scheduleSnapshot(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "scheduleSnapshot: Failed to unwrap instance");
        return args.Undefined();
    }
    
    if (!instance->map || !instance->harmonyRenderer) {
        Logger::warn("NativeMapView", "scheduleSnapshot: Map or renderer not initialized");
        return args.Undefined();
    }
    
    if (!instance->callbackManager_) {
        Logger::error("NativeMapView", "scheduleSnapshot: CallbackManager not initialized");
        return args.Undefined();
    }
    
    if (!instance->callbackManager_->HasCallback("onSnapshotReady")) {
        Logger::warn("NativeMapView", "scheduleSnapshot: No snapshot listeners registered");
        return args.Undefined();
    }
    
    auto snapshotState = instance->snapshotState_;
    {
        std::lock_guard<std::mutex> lock(snapshotState->mutex);
        if (snapshotState->inProgress) {
            Logger::warn("NativeMapView", "scheduleSnapshot: Snapshot request already in progress");
            return args.Undefined();
        }
        snapshotState->inProgress = true;
    }
    
    auto callbackManager = instance->callbackManager_;
    
    try {
        instance->harmonyRenderer->requestSnapshot(
            [snapshotState, callbackManager](mbgl::PremultipliedImage&& image, float pixelRatioValue) {
                auto dataPtr = std::make_shared<std::vector<uint8_t>>(image.bytes());
                if (!dataPtr->empty()) {
                    std::memcpy(dataPtr->data(), image.data.get(), image.bytes());
                }
                uint32_t width = image.size.width;
                uint32_t height = image.size.height;
                
                if (callbackManager) {
                    callbackManager->InvokeCallbackWithObject(
                        "onSnapshotReady",
                        [dataPtr, width, height, pixelRatioValue](napi_env env, napi_value result) {
                            void* buffer = nullptr;
                            napi_value arrayBuffer;
                            napi_status status = napi_create_arraybuffer(env, dataPtr->size(), &buffer, &arrayBuffer);
                            if (status == napi_ok && buffer && !dataPtr->empty()) {
                                std::memcpy(buffer, dataPtr->data(), dataPtr->size());
                            } else {
                                Logger::error("NativeMapView", "scheduleSnapshot: Failed to create ArrayBuffer for snapshot data");
                                napi_get_undefined(env, &arrayBuffer);
                            }
                            
                            napi_set_named_property(env, result, "data", arrayBuffer);
                            
                            napi_value widthValue;
                            napi_create_uint32(env, width, &widthValue);
                            napi_set_named_property(env, result, "width", widthValue);
                            
                            napi_value heightValue;
                            napi_create_uint32(env, height, &heightValue);
                            napi_set_named_property(env, result, "height", heightValue);
                            
                            napi_value pixelRatio;
                            napi_create_double(env, static_cast<double>(pixelRatioValue), &pixelRatio);
                            napi_set_named_property(env, result, "pixelRatio", pixelRatio);
                        });
                }
                
                NativeMapView::resetSnapshotStateOn(snapshotState);
            },
            [snapshotState, callbackManager](const std::string& message) {
                Logger::error("NativeMapView", "scheduleSnapshot: %s", message.c_str());
                if (callbackManager && callbackManager->HasCallback("onSnapshotError")) {
                    callbackManager->InvokeCallbackWithString("onSnapshotError", message);
                }
                NativeMapView::resetSnapshotStateOn(snapshotState);
            });
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "scheduleSnapshot: Failed to request snapshot - %s", e.what());
        if (instance->callbackManager_->HasCallback("onSnapshotError")) {
            instance->callbackManager_->InvokeCallbackWithString("onSnapshotError", e.what());
        }
        instance->resetSnapshotState();
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getCameraPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Retrieve the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getCameraPosition: Failed to get instance or map not initialized");
        return args.Undefined();
    }
    
    try {
        auto cameraOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getCameraOptions(); }, mbgl::CameraOptions{});
        
        // Create the return object
        napi_value result;
        napi_create_object(env, &result);
        
        // Add zoom
        if (cameraOptions.zoom) {
            napi_value zoomValue;
            napi_create_double(env, *cameraOptions.zoom, &zoomValue);
            napi_set_named_property(env, result, "zoom", zoomValue);
        }
        
        // Add bearing
        if (cameraOptions.bearing) {
            napi_value bearingValue;
            napi_create_double(env, *cameraOptions.bearing, &bearingValue);
            napi_set_named_property(env, result, "bearing", bearingValue);
        }
        
        // Add pitch (tilt)
        if (cameraOptions.pitch) {
            napi_value pitchValue;
            napi_create_double(env, *cameraOptions.pitch, &pitchValue);
            napi_set_named_property(env, result, "tilt", pitchValue);
        }
        
        // Add center (target)
        if (cameraOptions.center) {
            napi_value targetObj;
            napi_create_object(env, &targetObj);
            
            napi_value latValue, lngValue;
            napi_create_double(env, cameraOptions.center->latitude(), &latValue);
            napi_create_double(env, cameraOptions.center->longitude(), &lngValue);
            
            napi_set_named_property(env, targetObj, "latitude", latValue);
            napi_set_named_property(env, targetObj, "longitude", lngValue);
            napi_set_named_property(env, result, "target", targetObj);
        }
        
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getCameraPosition: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

napi_value NativeMapView::getCameraState(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getCameraState: map not initialized");
        return args.Undefined();
    }

    try {
        auto cameraOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m) {
            return m->getCameraOptions();
        }, mbgl::CameraOptions{});

        napi_value result;
        napi_create_object(env, &result);

        if (cameraOptions.bearing) {
            napi_value v;
            napi_create_double(env, *cameraOptions.bearing, &v);
            napi_set_named_property(env, result, "bearing", v);
        }

        if (cameraOptions.center) {
            napi_value lat, lng;
            napi_create_double(env, cameraOptions.center->latitude(), &lat);
            napi_set_named_property(env, result, "latitude", lat);
            napi_create_double(env, cameraOptions.center->longitude(), &lng);
            napi_set_named_property(env, result, "longitude", lng);
        }

        if (cameraOptions.zoom) {
            napi_value v;
            napi_create_double(env, *cameraOptions.zoom, &v);
            napi_set_named_property(env, result, "zoom", v);
        }

        if (cameraOptions.pitch) {
            napi_value v;
            napi_create_double(env, *cameraOptions.pitch, &v);
            napi_set_named_property(env, result, "pitch", v);
        }

        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getCameraState: Failed - %s", e.what());
    }

    return args.Undefined();
}

void NativeMapView::resetSnapshotState() {
    resetSnapshotStateOn(snapshotState_);
}

// static: safe to call from any thread (including render-thread snapshot
// callbacks) because it only touches the shared state, never `this`.
void NativeMapView::resetSnapshotStateOn(const std::shared_ptr<SnapshotRequestState>& state) {
    if (!state) return;
    std::lock_guard<std::mutex> lock(state->mutex);
    state->inProgress = false;
}


} // namespace harmony
} // namespace mbgl
