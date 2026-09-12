#pragma once

#include <arkui/native_gesture.h>
#include <arkui/native_node.h>
#include <mbgl/map/map.hpp>
#include <mbgl/util/geo.hpp>
#include <atomic>
#include <functional>
#include <memory>

namespace mbgl {
namespace harmony {
namespace gesture {

/**
 * NativeGestureManager - manages gesture recognizers using HarmonyOS native_gesture.h C API.
 *
 * Replaces the ArkTS MapGestureDetector (1849 lines) by creating gesture recognizers
 * directly in C++ via ArkUI_NativeGestureAPI_1. Gesture callbacks are received in C++
 * and directly manipulate mbgl::Map camera methods — zero NAPI calls during gesture.
 *
 * Gesture types supported:
 *   Pan (1-finger), Pinch (2-finger), Rotation (2-finger),
 *   Tap (1-finger), Double-tap, Long-press, Tilt (2-finger vertical pan)
 *
 * Reference: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-native-gesture-h
 */
class NativeGestureManager {
public:
    NativeGestureManager();
    ~NativeGestureManager();

    /**
     * Initialize all gesture recognizers and attach them to the XComponent node.
     *
     * Must be called on the main thread after the map and XComponent node are available.
     *
     * @param xcomponentNode  ArkUI_NodeHandle of the XComponent (the rendering surface)
     * @param map             mbgl::Map pointer for camera manipulation
     * @param pixelRatio       Device pixel ratio (e.g., 2.0, 3.0)
     * @return true if initialization succeeded
     */
    bool initialize(ArkUI_NodeHandle xcomponentNode,
                       mbgl::Map* map,
                       float pixelRatio,
                       std::function<void(std::function<void()>)> renderThreadDispatcher);

    /**
     * Rebind to a new mbgl::Map after the renderer (and its Map) was rebuilt
     * (hardReset / initializeRenderer / ensureResourcesReadyOrRecover). Pass
     * nullptr while the old Map is being torn down so in-flight gesture
     * callbacks on any thread observe a null map instead of a freed one.
     */
    void reattach(mbgl::Map* map) { map_.store(map, std::memory_order_release); }

    /** Current map pointer (safe to read from any thread). */
    mbgl::Map* map() const { return map_.load(std::memory_order_acquire); }

    /** Destroy all gesture recognizers and release resources. */
    void destroy();

    // ---- UiSettings control ----

    void setScrollEnabled(bool enabled);
    void setZoomEnabled(bool enabled);
    void setRotateEnabled(bool enabled);
    void setPitchEnabled(bool enabled);
    void setDoubleTapEnabled(bool enabled);
    void setQuickZoomEnabled(bool enabled);

    // ---- Gesture listener management (user callbacks via C++ listener pattern) ----
    // These are registered on the gesture detector and fire when gestures occur.
    // Users register via NAPI → CallbackManager.

    using MoveListener = std::function<void(double dx, double dy)>;
    using ScaleListener = std::function<void(double scaleFactor, double focusX, double focusY)>;
    using RotateListener = std::function<void(double angle, double focusX, double focusY)>;
    using MapClickListener = std::function<void(double x, double y)>;
    using MapLongClickListener = std::function<void(double x, double y)>;
    using DoubleTapListener = std::function<void(double x, double y)>;

    /**
     * Set the map click listener callback.
     * Invoked when a tap gesture is detected, with logical pixel coordinates.
     */
    void setOnMapClickListener(MapClickListener listener) { clickCallback_ = std::move(listener); }

    /**
     * Set the map long-click listener callback.
     * Invoked when a long-press gesture is detected, with logical pixel coordinates.
     */
    void setOnMapLongClickListener(MapLongClickListener listener) { longClickCallback_ = std::move(listener); }

private:
    // ---- Gesture API function table ----
    ArkUI_NativeGestureAPI_1* gestureAPI_ = nullptr;

    // ---- Map reference ----
    // Atomic because gesture callbacks read it on the UI thread, dispatched
    // lambdas read it on the render thread, and rebuild paths write it on the
    // JS thread (see reattach()).
    std::atomic<mbgl::Map*> map_{nullptr};
    float pixelRatio_ = 1.0f;

    // ---- Render thread dispatcher ----
    std::function<void(std::function<void()>)> renderThreadDispatcher_;

    // ---- UiSettings mirror ----
    bool scrollEnabled_ = true;
    bool zoomEnabled_ = true;
    bool rotateEnabled_ = true;
    bool pitchEnabled_ = true;
    bool doubleTapEnabled_ = true;
    bool quickZoomEnabled_ = true;

    // ---- Gesture recognizer instances ----
    ArkUI_GestureRecognizer* panGesture_ = nullptr;
    ArkUI_GestureRecognizer* pinchGesture_ = nullptr;
    ArkUI_GestureRecognizer* rotationGesture_ = nullptr;
    ArkUI_GestureRecognizer* tapGesture_ = nullptr;
    ArkUI_GestureRecognizer* doubleTapGesture_ = nullptr;
    ArkUI_GestureRecognizer* longPressGesture_ = nullptr;
    ArkUI_GestureRecognizer* tiltGesture_ = nullptr;  // 2-finger Pan(Vertical)

    // Gesture groups
    ArkUI_GestureRecognizer* parallelGroup_ = nullptr;  // Pan + Pinch + Rotate

    // ---- Gesture state tracking ----
    bool isPanning_ = false;
    bool isScaling_ = false;
    bool isRotating_ = false;
    bool isTilting_ = false;

    // Cached zoom/bearing for incremental gesture calculations
    double initialZoom_ = 0.0;
    double cachedBearing_ = 0.0;  // Updated by camera observer

    // Fixed anchor points (locked at gesture start to prevent drift)
    double fixedScaleAnchorX_ = 0.0;
    double fixedScaleAnchorY_ = 0.0;
    double rotationAnchorX_ = 0.0;
    double rotationAnchorY_ = 0.0;

    // Grace period timestamps (suppress pan fling after multi-touch gesture ends)
    double lastScaleEndTimestamp_ = 0.0;
    double lastRotateEndTimestamp_ = 0.0;
    double lastTiltEndTimestamp_ = 0.0;
    static constexpr double GRACE_PERIOD_MS = 100.0;

    // Double-tap tracking (for Quick Zoom detection)
    double doubleTapTimestamp_ = 0.0;
    double doubleTapX_ = 0.0;
    double doubleTapY_ = 0.0;
    static constexpr double QUICK_ZOOM_TIME_THRESHOLD_MS = 300.0;

    // ---- Pan/tilt cumulative offset tracking ----
    // OH_ArkUI_PanGesture_GetOffsetX/Y returns cumulative offset from gesture start.
    // We track last frame's value to compute per-frame deltas for moveBy.
    float lastPanCumulativeX_ = 0.0f;
    float lastPanCumulativeY_ = 0.0f;
    float lastTiltCumulativeY_ = 0.0f;

    // ---- Static gesture callbacks ----
    static void onPanCallback(ArkUI_GestureEvent* event, void* userData);
    static void onPinchCallback(ArkUI_GestureEvent* event, void* userData);
    static void onRotateCallback(ArkUI_GestureEvent* event, void* userData);
    static void onTapCallback(ArkUI_GestureEvent* event, void* userData);
    static void onLongPressCallback(ArkUI_GestureEvent* event, void* userData);
    static void onDoubleTapCallback(ArkUI_GestureEvent* event, void* userData);
    static void onTiltCallback(ArkUI_GestureEvent* event, void* userData);

    // ---- Gesture event dispatchers (bridge to JS/ETS via CallbackManager) ----
    MapClickListener clickCallback_;
    MapLongClickListener longClickCallback_;

    // ---- Fling / Inertia ----

    /** Perform pan fling animation after gesture ends with velocity. */
    void performPanFling(float velocityX, float velocityY);

    /** Perform scale inertia animation after pinch gesture ends. */
    void performScaleInertia(float scaleVelocity);

    /** Perform rotation inertia animation after rotate gesture ends. */
    void performRotateInertia(float angularVelocity);

    /** Get current timestamp in milliseconds. */
    static double currentTimeMs();

    // ---- Fling constants (ported from MapGestureDetector.ets) ----
    static constexpr double FLING_VELOCITY_COEFFICIENT = 0.28;
    static constexpr double ZOOM_RATE = 0.65;
    static constexpr double ROTATION_RATE = 1.0;
    static constexpr double MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE = 2.5;
    static constexpr double SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER = 150.0;
    static constexpr double MIN_SCALE_VELOCITY_THRESHOLD = 0.5;
    static constexpr double MAXIMUM_ANGULAR_VELOCITY = 30.0;
    static constexpr double MIN_ANGULAR_VELOCITY_THRESHOLD = 5.0;
};

} // namespace gesture
} // namespace harmony
} // namespace mbgl
