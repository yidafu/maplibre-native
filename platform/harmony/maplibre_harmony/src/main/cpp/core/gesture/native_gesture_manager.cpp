#include "native_gesture_manager.hpp"
#include "../../utils/logger.h"
#include <arkui/native_interface.h>
#include <arkui/ui_input_event.h>
#include <cmath>
#include <chrono>
#include <algorithm>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {
namespace gesture {

// ============================================================================
// Constructor / Destructor
// ============================================================================

NativeGestureManager::NativeGestureManager() = default;

NativeGestureManager::~NativeGestureManager() {
    destroy();
}

// ============================================================================
// Initialize — acquire API table, create recognizers, attach to node
// ============================================================================

bool NativeGestureManager::initialize(ArkUI_NodeHandle node, mbgl::Map* map, float pixelRatio,
                                          std::function<void(std::function<void()>)> dispatcher) {
    if (!node || !map) {
        Logger::error("NativeGestureManager", "initialize: node or map is null");
        return false;
    }

    map_ = map;
    pixelRatio_ = pixelRatio > 0.0f ? pixelRatio : 1.0f;
    renderThreadDispatcher_ = std::move(dispatcher);

    // 1. Acquire the native gesture API function table
    gestureAPI_ = reinterpret_cast<ArkUI_NativeGestureAPI_1*>(
        OH_ArkUI_QueryModuleInterfaceByName(ARKUI_NATIVE_GESTURE, "ArkUI_NativeGestureAPI_1"));
    if (!gestureAPI_) {
        Logger::error("NativeGestureManager", "Failed to acquire ArkUI_NativeGestureAPI_1");
        return false;
    }

    // 2. Create gesture recognizers
    panGesture_       = gestureAPI_->createPanGesture(1, GESTURE_DIRECTION_ALL, 5.0);
    pinchGesture_     = gestureAPI_->createPinchGesture(2, 5.0);
    rotationGesture_  = gestureAPI_->createRotationGesture(2, 1.0);
    tapGesture_       = gestureAPI_->createTapGesture(1, 1);
    doubleTapGesture_ = gestureAPI_->createTapGesture(2, 1);
    longPressGesture_ = gestureAPI_->createLongPressGesture(1, false, 500);
    tiltGesture_      = gestureAPI_->createPanGesture(2, GESTURE_DIRECTION_VERTICAL, 10.0);

    if (!panGesture_ || !pinchGesture_ || !rotationGesture_ || !tapGesture_ ||
        !doubleTapGesture_ || !longPressGesture_ || !tiltGesture_) {
        Logger::error("NativeGestureManager", "Failed to create one or more gesture recognizers");
        destroy();
        return false;
    }

    // 3. Set gesture event callbacks
    // Continuous gestures (Pan/Pinch/Rotate/Tilt): ACCEPT | UPDATE | END
    // Discrete gestures (Tap/LongPress): ACCEPT only
    const int continuousMask = GESTURE_EVENT_ACTION_ACCEPT | GESTURE_EVENT_ACTION_UPDATE | GESTURE_EVENT_ACTION_END;
    const int discreteMask = GESTURE_EVENT_ACTION_ACCEPT;

    gestureAPI_->setGestureEventTarget(panGesture_,      continuousMask, this, onPanCallback);
    gestureAPI_->setGestureEventTarget(pinchGesture_,    continuousMask, this, onPinchCallback);
    gestureAPI_->setGestureEventTarget(rotationGesture_, continuousMask, this, onRotateCallback);
    gestureAPI_->setGestureEventTarget(tapGesture_,      discreteMask,   this, onTapCallback);
    gestureAPI_->setGestureEventTarget(doubleTapGesture_, discreteMask,  this, onDoubleTapCallback);
    gestureAPI_->setGestureEventTarget(longPressGesture_, discreteMask,  this, onLongPressCallback);
    gestureAPI_->setGestureEventTarget(tiltGesture_,     continuousMask, this, onTiltCallback);

    // 4. Create parallel gesture group (Pan + Pinch + Rotate simultaneous)
    parallelGroup_ = gestureAPI_->createGroupGesture(PARALLEL_GROUP);
    if (!parallelGroup_) {
        Logger::error("NativeGestureManager", "Failed to create parallel gesture group");
        destroy();
        return false;
    }
    gestureAPI_->addChildGesture(parallelGroup_, panGesture_);
    gestureAPI_->addChildGesture(parallelGroup_, pinchGesture_);
    gestureAPI_->addChildGesture(parallelGroup_, rotationGesture_);

    // 5. Attach gestures to the XComponent node
    // Parallel group (Pan+Pinch+Rotate) at normal priority
    gestureAPI_->addGestureToNode(node, parallelGroup_, NORMAL, NORMAL_GESTURE_MASK);
    // Double-tap at higher priority (to avoid being consumed by tap)
    gestureAPI_->addGestureToNode(node, doubleTapGesture_, PRIORITY, NORMAL_GESTURE_MASK);
    // Tap at normal priority
    gestureAPI_->addGestureToNode(node, tapGesture_, NORMAL, NORMAL_GESTURE_MASK);
    // Long-press at normal priority
    gestureAPI_->addGestureToNode(node, longPressGesture_, NORMAL, NORMAL_GESTURE_MASK);
    // Tilt (2-finger vertical pan) at normal priority
    gestureAPI_->addGestureToNode(node, tiltGesture_, NORMAL, NORMAL_GESTURE_MASK);

    Logger::info("NativeGestureManager", "Initialized successfully (pixelRatio=%.2f)", pixelRatio_);
    return true;
}

void NativeGestureManager::destroy() {
    if (gestureAPI_) {
        // Dispose all gesture recognizers
        if (panGesture_)       { gestureAPI_->dispose(panGesture_);       panGesture_ = nullptr; }
        if (pinchGesture_)     { gestureAPI_->dispose(pinchGesture_);     pinchGesture_ = nullptr; }
        if (rotationGesture_)  { gestureAPI_->dispose(rotationGesture_);  rotationGesture_ = nullptr; }
        if (tapGesture_)       { gestureAPI_->dispose(tapGesture_);       tapGesture_ = nullptr; }
        if (doubleTapGesture_) { gestureAPI_->dispose(doubleTapGesture_); doubleTapGesture_ = nullptr; }
        if (longPressGesture_) { gestureAPI_->dispose(longPressGesture_); longPressGesture_ = nullptr; }
        if (tiltGesture_)      { gestureAPI_->dispose(tiltGesture_);      tiltGesture_ = nullptr; }
        if (parallelGroup_)    { gestureAPI_->dispose(parallelGroup_);    parallelGroup_ = nullptr; }

        gestureAPI_ = nullptr;
    }
    map_ = nullptr;
    Logger::info("NativeGestureManager", "Destroyed");
}

// ============================================================================
// UiSettings control
// ============================================================================

void NativeGestureManager::setScrollEnabled(bool enabled)  { scrollEnabled_ = enabled; }
void NativeGestureManager::setZoomEnabled(bool enabled)    { zoomEnabled_ = enabled; }
void NativeGestureManager::setRotateEnabled(bool enabled)  { rotateEnabled_ = enabled; }
void NativeGestureManager::setPitchEnabled(bool enabled)   { pitchEnabled_ = enabled; }
void NativeGestureManager::setDoubleTapEnabled(bool enabled) { doubleTapEnabled_ = enabled; }
void NativeGestureManager::setQuickZoomEnabled(bool enabled) { quickZoomEnabled_ = enabled; }

// ============================================================================
// Timestamp helper
// ============================================================================

double NativeGestureManager::currentTimeMs() {
    auto now = std::chrono::steady_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch());
    return static_cast<double>(ms.count());
}

// ============================================================================
// Pan gesture callback
// ============================================================================

void NativeGestureManager::onPanCallback(ArkUI_GestureEvent* event, void* userData) {
    auto* self = static_cast<NativeGestureManager*>(userData);
    if (!self || !self->map_ || !self->renderThreadDispatcher_) return;

    // Read gesture data on UI thread (event pointer is only valid during callback)
    auto action = OH_ArkUI_GestureEvent_GetActionType(event);
    float offsetX = OH_ArkUI_PanGesture_GetOffsetX(event);
    float offsetY = OH_ArkUI_PanGesture_GetOffsetY(event);

    if (action == GESTURE_EVENT_ACTION_ACCEPT) {
        self->isPanning_ = true;
        // Reset cumulative offset tracking (OH_ArkUI_PanGesture_GetOffsetX/Y returns
        // cumulative offset from gesture start; we compute per-frame deltas from it).
        self->lastPanCumulativeX_ = offsetX;
        self->lastPanCumulativeY_ = offsetY;
        // Dispatch map operations to the render thread
        self->renderThreadDispatcher_([self]() {
            if (self->map_) self->map_->setGestureInProgress(true);
        });

    } else if (action == GESTURE_EVENT_ACTION_UPDATE) {
        if (!self->scrollEnabled_) return;

        // OH_ArkUI_PanGesture_GetOffsetX/Y returns cumulative offset from
        // gesture start in logical pixels (vp). Compute per-frame delta by
        // subtracting the previous cumulative value, then update tracking.
        float deltaX = offsetX - self->lastPanCumulativeX_;
        float deltaY = offsetY - self->lastPanCumulativeY_;
        self->lastPanCumulativeX_ = offsetX;
        self->lastPanCumulativeY_ = offsetY;
        // Dispatch map operations to the render thread
        self->renderThreadDispatcher_([self, deltaX, deltaY]() {
            if (self->map_) {
                self->map_->moveBy(mbgl::ScreenCoordinate{
                    static_cast<double>(deltaX),
                    static_cast<double>(deltaY)
                }, mbgl::AnimationOptions{});
            }
        });

    } else if (action == GESTURE_EVENT_ACTION_END || action == GESTURE_EVENT_ACTION_CANCEL) {
        self->isPanning_ = false;

        // Read velocity on UI thread (event pointer is only valid here)
        float vx = OH_ArkUI_PanGesture_GetVelocityX(event);
        float vy = OH_ArkUI_PanGesture_GetVelocityY(event);

        // Dispatch all end logic to the render thread so timestamp checks and
        // map operations share the same thread (avoid data race on timestamps).
        self->renderThreadDispatcher_([self, vx, vy]() {
            if (!self->map_) return;

            // Check grace period (suppress fling after multi-touch gestures)
            double now = currentTimeMs();
            if ((now - self->lastScaleEndTimestamp_) < GRACE_PERIOD_MS ||
                (now - self->lastRotateEndTimestamp_) < GRACE_PERIOD_MS ||
                (now - self->lastTiltEndTimestamp_) < GRACE_PERIOD_MS) {
                self->map_->setGestureInProgress(false);
                return;
            }

            // Perform fling if velocity is sufficient
            if (vx != 0.0f || vy != 0.0f) {
                self->performPanFling(vx, vy);
            }
            self->map_->setGestureInProgress(false);
        });
    }
}

// ============================================================================
// Pinch gesture callback
// ============================================================================

void NativeGestureManager::onPinchCallback(ArkUI_GestureEvent* event, void* userData) {
    auto* self = static_cast<NativeGestureManager*>(userData);
    if (!self || !self->map_ || !self->renderThreadDispatcher_) return;

    // Read gesture data on UI thread (event pointer is only valid during callback)
    auto action = OH_ArkUI_GestureEvent_GetActionType(event);
    float scale = OH_ArkUI_PinchGesture_GetScale(event);
    float centerX = OH_ArkUI_PinchGesture_GetCenterX(event);
    float centerY = OH_ArkUI_PinchGesture_GetCenterY(event);

    if (action == GESTURE_EVENT_ACTION_ACCEPT) {
        self->isScaling_ = true;
        self->isRotating_ = false;  // Gesture exclusivity: scaling suppresses rotation
        self->isTilting_ = false;

        // Lock zoom level and anchor using values read on UI thread
        self->fixedScaleAnchorX_ = static_cast<double>(centerX);
        self->fixedScaleAnchorY_ = static_cast<double>(centerY);
        // Dispatch initial zoom read and gesture flag to render thread
        self->renderThreadDispatcher_([self]() {
            if (!self->map_) return;
            self->initialZoom_ = self->map_->getCameraOptions().zoom.value_or(0.0);
            self->map_->setGestureInProgress(true);
        });

    } else if (action == GESTURE_EVENT_ACTION_UPDATE) {
        if (!self->zoomEnabled_) return;
        if (scale <= 0.0f) return;

        double newZoom = self->initialZoom_ + std::log2(static_cast<double>(scale));
        double anchorX = self->fixedScaleAnchorX_;
        double anchorY = self->fixedScaleAnchorY_;
        // Dispatch zoom update to render thread
        self->renderThreadDispatcher_([self, newZoom, anchorX, anchorY]() {
            if (!self->map_) return;
            self->map_->jumpTo(mbgl::CameraOptions()
                .withZoom(newZoom)
                .withAnchor(mbgl::ScreenCoordinate{anchorX, anchorY}));
        });

    } else if (action == GESTURE_EVENT_ACTION_END || action == GESTURE_EVENT_ACTION_CANCEL) {
        self->isScaling_ = false;
        self->lastScaleEndTimestamp_ = currentTimeMs();

        // Scale inertia dispatched to render thread
        if (scale > 0.0f && std::abs(std::log2(scale)) > 0.01) {
            float scaleVelocity = std::log2(scale) * 1000.0f / 16.0f;
            self->renderThreadDispatcher_([self, scaleVelocity]() {
                if (self->map_) self->performScaleInertia(scaleVelocity);
            });
        }
        self->renderThreadDispatcher_([self]() {
            if (self->map_) self->map_->setGestureInProgress(false);
        });
    }
}

// ============================================================================
// Rotation gesture callback
// ============================================================================

void NativeGestureManager::onRotateCallback(ArkUI_GestureEvent* event, void* userData) {
    auto* self = static_cast<NativeGestureManager*>(userData);
    if (!self || !self->map_ || !self->renderThreadDispatcher_) return;

    // Skip if scaling is active (gesture exclusivity)
    if (self->isScaling_) return;

    // Read gesture data on UI thread (event pointer is only valid during callback)
    auto action = OH_ArkUI_GestureEvent_GetActionType(event);
    float angle = OH_ArkUI_RotationGesture_GetAngle(event);

    if (action == GESTURE_EVENT_ACTION_ACCEPT) {
        self->isRotating_ = true;
        self->isTilting_ = false;

        // Dispatch bearing read and gesture flag to render thread.
        // All cached state is read/written on the render thread to avoid data races.
        self->renderThreadDispatcher_([self]() {
            if (!self->map_) return;
            self->cachedBearing_ = self->map_->getCameraOptions().bearing.value_or(0.0);
            // Lock the rotation anchor to the map center at gesture start
            // for a natural rotation pivot (instead of top-left corner).
            mbgl::Size mapSize = self->map_->getMapOptions().size();
            self->rotationAnchorX_ = mapSize.width / 2.0;
            self->rotationAnchorY_ = mapSize.height / 2.0;
            self->map_->setGestureInProgress(true);
        });

    } else if (action == GESTURE_EVENT_ACTION_UPDATE) {
        if (!self->rotateEnabled_) return;

        // Capture angle on UI thread, then dispatch all map operations to
        // the render thread where cachedBearing_ and map size are safe to read.
        self->renderThreadDispatcher_([self, angle]() {
            if (!self->map_) return;
            double newBearing = std::fmod(
                self->cachedBearing_ - static_cast<double>(angle) * ROTATION_RATE, 360.0);
            if (newBearing < 0.0) newBearing += 360.0;
            self->map_->jumpTo(mbgl::CameraOptions()
                .withBearing(newBearing)
                .withAnchor(mbgl::ScreenCoordinate{
                    self->rotationAnchorX_, self->rotationAnchorY_}));
        });

    } else if (action == GESTURE_EVENT_ACTION_END || action == GESTURE_EVENT_ACTION_CANCEL) {
        self->isRotating_ = false;

        // Capture timestamp and angular velocity on UI thread, then
        // dispatch inertia and cleanup to render thread.
        double endTimestamp = currentTimeMs();
        float angularVelocity = -angle * 1000.0f / 16.0f;
        self->renderThreadDispatcher_([self, endTimestamp, angularVelocity]() {
            self->lastRotateEndTimestamp_ = endTimestamp;
            if (self->map_) self->performRotateInertia(angularVelocity);
            if (self->map_) self->map_->setGestureInProgress(false);
        });
    }
}

// ============================================================================
// Tap gesture callback
// ============================================================================

void NativeGestureManager::onTapCallback(ArkUI_GestureEvent* event, void* userData) {
    auto* self = static_cast<NativeGestureManager*>(userData);
    if (!self) return;

    auto action = OH_ArkUI_GestureEvent_GetActionType(event);
    if (action == GESTURE_EVENT_ACTION_ACCEPT) {
        // Tap detected — fire map click listener
        // Coordinates from the raw input event (logical pixels / vp)
        const auto* rawEvent = OH_ArkUI_GestureEvent_GetRawInputEvent(event);
        if (rawEvent) {
            float x = OH_ArkUI_PointerEvent_GetX(rawEvent);
            float y = OH_ArkUI_PointerEvent_GetY(rawEvent);
            Logger::debug("NativeGestureManager", "Tap detected at (%.1f, %.1f)", x, y);

            // Dispatch to JS/ETS via the registered click callback
            if (self->clickCallback_) {
                self->clickCallback_(static_cast<double>(x), static_cast<double>(y));
            }
        }
    }
}

// ============================================================================
// Double-tap gesture callback
// ============================================================================

void NativeGestureManager::onDoubleTapCallback(ArkUI_GestureEvent* event, void* userData) {
    auto* self = static_cast<NativeGestureManager*>(userData);
    if (!self || !self->map_ || !self->renderThreadDispatcher_) return;
    if (!self->doubleTapEnabled_) return;

    auto action = OH_ArkUI_GestureEvent_GetActionType(event);
    if (action == GESTURE_EVENT_ACTION_ACCEPT) {
        self->doubleTapTimestamp_ = currentTimeMs();

        // Dispatch zoom animation to render thread
        self->renderThreadDispatcher_([self]() {
            if (!self->map_) return;
            double currentZoom = self->map_->getCameraOptions().zoom.value_or(0.0);
            self->map_->easeTo(mbgl::CameraOptions().withZoom(currentZoom + 1.0),
                               mbgl::AnimationOptions{mbgl::Milliseconds(300)});
            Logger::debug("NativeGestureManager", "Double-tap zoom: %.2f -> %.2f", currentZoom, currentZoom + 1.0);
        });
    }
}

// ============================================================================
// Long-press gesture callback
// ============================================================================

void NativeGestureManager::onLongPressCallback(ArkUI_GestureEvent* event, void* userData) {
    auto* self = static_cast<NativeGestureManager*>(userData);
    if (!self) return;

    auto action = OH_ArkUI_GestureEvent_GetActionType(event);
    if (action == GESTURE_EVENT_ACTION_ACCEPT) {
        // Long-press detected — fire map long-click listener
        const auto* rawEvent = OH_ArkUI_GestureEvent_GetRawInputEvent(event);
        if (rawEvent) {
            float x = OH_ArkUI_PointerEvent_GetX(rawEvent);
            float y = OH_ArkUI_PointerEvent_GetY(rawEvent);
            Logger::debug("NativeGestureManager", "Long-press detected at (%.1f, %.1f)", x, y);

            // Dispatch to JS/ETS via the registered long-click callback
            if (self->longClickCallback_) {
                self->longClickCallback_(static_cast<double>(x), static_cast<double>(y));
            }
        }
    }
}

// ============================================================================
// Tilt gesture callback (2-finger vertical pan)
// ============================================================================

void NativeGestureManager::onTiltCallback(ArkUI_GestureEvent* event, void* userData) {
    auto* self = static_cast<NativeGestureManager*>(userData);
    if (!self || !self->map_ || !self->renderThreadDispatcher_) return;

    if (self->isScaling_ || self->isRotating_) return;

    // Read gesture data on UI thread
    auto action = OH_ArkUI_GestureEvent_GetActionType(event);
    float offsetY = OH_ArkUI_PanGesture_GetOffsetY(event);

    if (action == GESTURE_EVENT_ACTION_ACCEPT) {
        self->isTilting_ = true;
        // Reset cumulative offset tracking for tilt (also uses PanGesture offset)
        self->lastTiltCumulativeY_ = offsetY;
        self->renderThreadDispatcher_([self]() {
            if (self->map_) self->map_->setGestureInProgress(true);
        });

    } else if (action == GESTURE_EVENT_ACTION_UPDATE) {
        if (!self->pitchEnabled_) return;

        // Compute per-frame delta from cumulative offset
        float deltaY = offsetY - self->lastTiltCumulativeY_;
        self->lastTiltCumulativeY_ = offsetY;
        double deltaPitch = static_cast<double>(deltaY) * 0.1;
        // Dispatch pitch update to render thread (read current value there to avoid stale data)
        self->renderThreadDispatcher_([self, deltaPitch]() {
            if (!self->map_) return;
            double currentPitch = self->map_->getCameraOptions().pitch.value_or(0.0);
            double newPitch = std::clamp(currentPitch + deltaPitch, 0.0, 60.0);
            self->map_->jumpTo(mbgl::CameraOptions().withPitch(newPitch));
        });

    } else if (action == GESTURE_EVENT_ACTION_END || action == GESTURE_EVENT_ACTION_CANCEL) {
        self->isTilting_ = false;
        self->lastTiltEndTimestamp_ = currentTimeMs();
        self->renderThreadDispatcher_([self]() {
            if (self->map_) self->map_->setGestureInProgress(false);
        });
    }
}

// ============================================================================
// Fling / Inertia (ported from MapGestureDetector.ets)
// ============================================================================

void NativeGestureManager::performPanFling(float velocityX, float velocityY) {
    if (!map_) return;

    double speed = std::sqrt(velocityX * velocityX + velocityY * velocityY);
    if (speed < 3.0) return;  // Minimum fling velocity threshold

    // Android fling calculation
    double pitch = map_->getCameraOptions().pitch.value_or(0.0);
    double tiltFactor = 1.0 + (pitch / 60.0) * 0.5;
    double duration = speed / 7.0 / tiltFactor + 100.0;  // base 100ms
    duration = std::clamp(duration, 100.0, 2000.0);

    // OH_ArkUI_PanGesture_GetVelocityX/Y returns velocity in logical pixels/sec.
    // map_->moveBy expects logical pixels — no pixelRatio_ conversion needed.
    double offsetX = velocityX * duration * FLING_VELOCITY_COEFFICIENT / 1000.0;
    double offsetY = velocityY * duration * FLING_VELOCITY_COEFFICIENT / 1000.0;

    Logger::debug("NativeGestureManager", "Pan fling: offset=(%.1f, %.1f) duration=%.0fms",
                  offsetX, offsetY, duration);

    map_->moveBy(mbgl::ScreenCoordinate{offsetX, offsetY},
                 mbgl::AnimationOptions{static_cast<mbgl::Milliseconds>(static_cast<int64_t>(duration))});
}

void NativeGestureManager::performScaleInertia(float scaleVelocity) {
    if (!map_ || std::abs(scaleVelocity) < MIN_SCALE_VELOCITY_THRESHOLD) return;

    double zoomDelta = std::log(std::abs(scaleVelocity) / 4.0 + 1.0) * ZOOM_RATE;
    zoomDelta = (scaleVelocity > 0) ? zoomDelta : -zoomDelta;
    zoomDelta = std::clamp(zoomDelta, -MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE, MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE);

    double duration = (std::log(std::abs(zoomDelta) + 1.0 / std::exp(2.0)) + 2.0)
                      * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER;
    duration = std::clamp(duration, 100.0, 1000.0);

    double currentZoom = map_->getCameraOptions().zoom.value_or(0.0);
    double finalZoom = currentZoom + zoomDelta;

    Logger::debug("NativeGestureManager", "Scale inertia: zoom %f -> %f, duration=%fms",
                  currentZoom, finalZoom, duration);

    map_->easeTo(mbgl::CameraOptions()
        .withZoom(finalZoom)
        .withAnchor(mbgl::ScreenCoordinate{fixedScaleAnchorX_, fixedScaleAnchorY_}),
        mbgl::AnimationOptions{static_cast<mbgl::Milliseconds>(static_cast<int64_t>(duration))});
}

void NativeGestureManager::performRotateInertia(float angularVelocity) {
    if (!map_ || std::abs(angularVelocity) < MIN_ANGULAR_VELOCITY_THRESHOLD) return;

    double clampedVelocity = std::clamp(static_cast<double>(angularVelocity),
                                        -MAXIMUM_ANGULAR_VELOCITY, MAXIMUM_ANGULAR_VELOCITY);

    double deltaBearing = clampedVelocity * 0.1;
    double duration = (std::log(std::abs(deltaBearing) + 1.0 / std::exp(2.0)) + 2.0)
                      * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER;
    duration = std::clamp(duration, 100.0, 1000.0);

    double currentBearing = map_->getCameraOptions().bearing.value_or(0.0);
    double newBearing = std::fmod(currentBearing + deltaBearing, 360.0);
    if (newBearing < 0.0) newBearing += 360.0;

    Logger::debug("NativeGestureManager", "Rotate inertia: bearing %f -> %f deg, duration=%fms",
                  currentBearing, newBearing, duration);

    map_->easeTo(mbgl::CameraOptions()
        .withBearing(newBearing)
        .withAnchor(mbgl::ScreenCoordinate{rotationAnchorX_, rotationAnchorY_}),
        mbgl::AnimationOptions{static_cast<mbgl::Milliseconds>(static_cast<int64_t>(duration))});
}

} // namespace gesture
} // namespace harmony
} // namespace mbgl
