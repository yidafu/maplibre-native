/**
 * Map gesture detector.
 *
 * Centralizes all map gesture interactions.
 * Inspired by Android MapGestureDetector and iOS MLNMapView gesture handling.
 */

import { DOMAIN } from '../../constants/HiLogConstants';
import {
  OnDoubleTapListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnMoveListener,
  OnQuickZoomListener,
  OnRotateListener,
  OnScaleListener,
  OnShoveListener,
  OnTiltListener,
  OnTouchMoveListener,
  OnTouchUpListener
} from './GestureListeners';
import { FocalPoint, UiSettings } from '../UiSettings';
import { VelocityTracker } from './VelocityTracker';
import { hilog } from '@kit.PerformanceAnalysisKit';
import display from '@ohos.display';
import { NativeMapView } from 'libmaplibre.so';
import type { MapLibreMap } from '../MapLibreMap';
// Type definitions
type NativeMapViewType = NativeMapView;

const TAG = 'MapGestureDetector';
const ZOOM_RATE = 0.65; // Android MapLibreConstants.ZOOM_RATE - zoom rate factor
const ROTATION_RATE = 0.1; // Rotation rate factor - smaller values slow rotation (~50% reduction)

// Gesture priority constants (see MapGestureDetector.java)
const MINIMUM_GESTURE_SPEED = 3.0; // Minimum gesture speed (pixels/ms)
const MINIMUM_ANGLED_GESTURE_SPEED = 1.5; // Minimum scaling speed during rotation (pixels/ms)
const ROTATION_ANGLE_THRESHOLD = 0.4; // Rotation threshold (degrees)

// Scale inertia constants (see MapLibreConstants.java)
const MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE = 2.5; // Maximum change in scale velocity
const SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER = 150; // Animation duration multiplier (ms)
const MIN_SCALE_VELOCITY_THRESHOLD = 0.5; // Do not trigger inertia below this speed

// Rotate inertia constants (see MapLibreConstants.java)
const MAXIMUM_ANGULAR_VELOCITY = 30; // Maximum angular velocity (deg/s)
const MIN_ANGULAR_VELOCITY_THRESHOLD = 5; // Minimum angular velocity threshold (deg/s)

/**
 * Map gesture detector implementation.
 */
export class MapGestureDetector {
  // Listener collections
  private moveListeners: OnMoveListener[] = [];
  private scaleListeners: OnScaleListener[] = [];
  private rotateListeners: OnRotateListener[] = [];
  private clickListeners: OnMapClickListener[] = [];
  private longClickListeners: OnMapLongClickListener[] = [];
  private doubleTapListeners: OnDoubleTapListener[] = [];
  private tiltListeners: OnTiltListener[] = [];
  private shoveListeners: OnShoveListener[] = []; // Android naming, equivalent to tilt
  private quickZoomListeners: OnQuickZoomListener[] = [];
  private touchMoveListeners: OnTouchMoveListener[] = []; // Touch move listeners (e.g., marker drag)
  private touchUpListeners: OnTouchUpListener[] = []; // Touch release listeners (e.g., marker drag)

  // UI settings
  private uiSettings: UiSettings;
  // Gesture state tracking
  private isMoving: boolean = false;
  private isScaling: boolean = false;
  private isRotating: boolean = false;
  private isTilting: boolean = false;
  private isQuickZooming: boolean = false;
  // Gesture exclusivity (see Android disableRotateWhenScaling)
  private shouldIgnoreRotation: boolean = false;
  // Zoom end timestamp (used to disable pan fling shortly after zoom)
  private lastScaleEndTimestamp: number = 0;
  private readonly SCALE_END_GRACE_PERIOD = 100; // Suppress pan fling within 100 ms after zoom ends

  // Rotation end timestamp (used to disable pan fling shortly after rotate)
  private lastRotateEndTimestamp: number = 0;
  private readonly ROTATE_END_GRACE_PERIOD = 100; // Suppress pan fling within 100 ms after rotate ends

  // Tilt end timestamp (used to disable pan fling shortly after tilt)
  private lastTiltEndTimestamp: number = 0;
  private readonly TILT_END_GRACE_PERIOD = 100; // Suppress pan fling within 100 ms after tilt ends

  // Gesture exclusivity - tilt specific
  private shouldIgnoreTilt: boolean = false;
  // Zoom-related state
  private currentScale: number = 1.0;
  private lastScale: number = 1.0;
  private initialZoom: number = 0;
  private currentZoomLevel: number = 0; // 🔑 Cache zoom level to avoid frequent getZoom() calls
  // Gesture priority tracking (see Android)
  private previousPinchSpan: number = 0; // Previous frame pinch span
  private previousPinchTimestamp: number = 0; // Previous frame timestamp
  private rotationDeltaAccumulated: number = 0; // Accumulated rotation delta (for priority checks)

  // Rotation-related state
  private lastRotation: number = 0;
  private totalRotation: number = 0;
  private rotationAnchorX: number = 0; // 🔑 Fixed rotation anchor X (set when gesture begins)
  private rotationAnchorY: number = 0; // 🔑 Fixed rotation anchor Y (set when gesture begins)
  
  // 🔧 FIX: maintain a fixed scale anchor throughout the gesture.
  // Reference: Android `zoomBy` keeps a constant focal point to avoid drift caused by anchor shifts.
  private fixedScaleAnchorX: number = 0;  // Fixed scale anchor X (set when gesture begins)
  private fixedScaleAnchorY: number = 0;  // Fixed scale anchor Y (set when gesture begins)

  // Pan-related state
  private lastPanX: number = 0;
  private lastPanY: number = 0;
  // Tilt-related state
  private initialPitch: number = 0;
  private tiltStartY: number = 0;
  // Quick Zoom-related state
  private quickZoomStartY: number = 0;
  private quickZoomStartZoom: number = 0;
  private screenHeight: number = 0;
  private doubleTapTimestamp: number = 0;
  private doubleTapX: number = 0;
  private doubleTapY: number = 0;
  private readonly QUICK_ZOOM_TIME_THRESHOLD = 300; // Start Quick Zoom if drag within 300 ms of double-tap

  // Map controller reference (`NativeMapView` instance)
  private mapController: NativeMapViewType | null = null;
  // MapLibreMap reference (used to notify higher-level listeners)
  private mapLibreMapInstance: MapLibreMap | null = null;
  // Velocity trackers
  private panVelocityTracker: VelocityTracker = new VelocityTracker();
  private scaleVelocityTracker: VelocityTracker = new VelocityTracker();
  private rotateVelocityTracker: VelocityTracker = new VelocityTracker();
  // Android fling coefficient (empirical value)
  // Reference: platform/android/MapLibreAndroid/src/main/java/org/maplibre/android/maps/MapGestureDetector.java:444
  // Ensures inertia animation velocity matches the release velocity.
  private readonly FLING_VELOCITY_COEFFICIENT = 0.28;
  // Cached device pixel ratio (fetch once to avoid per-frame queries)
  private cachedPixelRatio: number = 1.0;

  constructor(uiSettings: UiSettings) {
    this.uiSettings = uiSettings;
    // Cache pixelRatio during initialization
    this.cachedPixelRatio = this.initializePixelRatio();
  }

  /**
   * Set the native map controller.
   */
  setMapController(controller: NativeMapViewType): void {
    this.mapController = controller;
  }

  /**
   * Attach the MapLibreMap instance.
   * Connects gesture detector with the MapLibreMap listener system.
   */
  setMapLibreMapInstance(mapLibreMap: MapLibreMap): void {
    this.mapLibreMapInstance = mapLibreMap;
  }

  // ==================== Listener management ====================

  /**
   * Add a pan listener.
   */
  addOnMoveListener(listener: OnMoveListener): void {
    if (!this.moveListeners.includes(listener)) {
      this.moveListeners.push(listener);
    }
  }

  /**
   * Remove a pan listener.
   */
  removeOnMoveListener(listener: OnMoveListener): void {
    const index = this.moveListeners.indexOf(listener);
    if (index > -1) {
      this.moveListeners.splice(index, 1);
    }
  }

  /**
   * Add a scale listener.
   */
  addOnScaleListener(listener: OnScaleListener): void {
    if (!this.scaleListeners.includes(listener)) {
      this.scaleListeners.push(listener);
    }
  }

  /**
   * Remove a scale listener.
   */
  removeOnScaleListener(listener: OnScaleListener): void {
    const index = this.scaleListeners.indexOf(listener);
    if (index > -1) {
      this.scaleListeners.splice(index, 1);
    }
  }

  /**
   * Add a rotate listener.
   */
  addOnRotateListener(listener: OnRotateListener): void {
    if (!this.rotateListeners.includes(listener)) {
      this.rotateListeners.push(listener);
    }
  }

  /**
   * Remove a rotate listener.
   */
  removeOnRotateListener(listener: OnRotateListener): void {
    const index = this.rotateListeners.indexOf(listener);
    if (index > -1) {
      this.rotateListeners.splice(index, 1);
    }
  }

  /**
   * Add a tap listener.
   */
  addOnMapClickListener(listener: OnMapClickListener): void {
    if (!this.clickListeners.includes(listener)) {
      this.clickListeners.push(listener);
    }
  }

  /**
   * Remove a tap listener.
   */
  removeOnMapClickListener(listener: OnMapClickListener): void {
    const index = this.clickListeners.indexOf(listener);
    if (index > -1) {
      this.clickListeners.splice(index, 1);
    }
  }

  /**
   * Add a long-press listener.
   */
  addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (!this.longClickListeners.includes(listener)) {
      this.longClickListeners.push(listener);
    }
  }

  /**
   * Remove a long-press listener.
   */
  removeOnMapLongClickListener(listener: OnMapLongClickListener): void {
    const index = this.longClickListeners.indexOf(listener);
    if (index > -1) {
      this.longClickListeners.splice(index, 1);
    }
  }

  /**
   * Add a double-tap listener.
   */
  addOnDoubleTapListener(listener: OnDoubleTapListener): void {
    if (!this.doubleTapListeners.includes(listener)) {
      this.doubleTapListeners.push(listener);
    }
  }

  /**
   * Remove a double-tap listener.
   */
  removeOnDoubleTapListener(listener: OnDoubleTapListener): void {
    const index = this.doubleTapListeners.indexOf(listener);
    if (index > -1) {
      this.doubleTapListeners.splice(index, 1);
    }
  }

  /**
   * Add a tilt listener.
   */
  addOnTiltListener(listener: OnTiltListener): void {
    if (!this.tiltListeners.includes(listener)) {
      this.tiltListeners.push(listener);
    }
  }

  /**
   * Remove a tilt listener.
   */
  removeOnTiltListener(listener: OnTiltListener): void {
    const index = this.tiltListeners.indexOf(listener);
    if (index > -1) {
      this.tiltListeners.splice(index, 1);
    }
  }

  /**
   * Add a shove listener (Android naming, equivalent to tilt).
   * Reference: Android `MapLibreMap.addOnShoveListener`.
   */
  addOnShoveListener(listener: OnShoveListener): void {
    if (!this.shoveListeners.includes(listener)) {
      this.shoveListeners.push(listener);
    }
  }

  /**
   * Remove a shove listener.
   */
  removeOnShoveListener(listener: OnShoveListener): void {
    const index = this.shoveListeners.indexOf(listener);
    if (index > -1) {
      this.shoveListeners.splice(index, 1);
    }
  }

  /**
   * Add a Quick Zoom listener.
   */
  addOnQuickZoomListener(listener: OnQuickZoomListener): void {
    if (!this.quickZoomListeners.includes(listener)) {
      this.quickZoomListeners.push(listener);
    }
  }

  /**
   * Remove a Quick Zoom listener.
   */
  removeOnQuickZoomListener(listener: OnQuickZoomListener): void {
    const index = this.quickZoomListeners.indexOf(listener);
    if (index > -1) {
      this.quickZoomListeners.splice(index, 1);
    }
  }

  /**
   * Add a touch-move listener (e.g. for marker drag).
   * Reference: Android `AndroidGesturesManager.setMoveGestureListener`.
   */
  addOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (!this.touchMoveListeners.includes(listener)) {
      this.touchMoveListeners.push(listener);
    }
  }

  /**
   * Remove a touch-move listener.
   */
  removeOnTouchMoveListener(listener: OnTouchMoveListener): void {
    const index = this.touchMoveListeners.indexOf(listener);
    if (index > -1) {
      this.touchMoveListeners.splice(index, 1);
    }
  }

  /**
   * Add a touch-up listener (e.g. to finish marker drag).
   */
  addOnTouchUpListener(listener: OnTouchUpListener): void {
    if (!this.touchUpListeners.includes(listener)) {
      this.touchUpListeners.push(listener);
    }
  }

  /**
   * Remove a touch-up listener.
   */
  removeOnTouchUpListener(listener: OnTouchUpListener): void {
    const index = this.touchUpListeners.indexOf(listener);
    if (index > -1) {
      this.touchUpListeners.splice(index, 1);
    }
  }

  // ==================== Gesture handling ====================

  /**
   * Pan gesture begins.
   */
  onPanStart(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🟡 onPanStart: offset=(${event.offsetX.toFixed(1)}, ${event.offsetY.toFixed(1)})`);
    
    // Detect Quick Zoom (double-tap followed by immediate drag)
    const timeSinceDoubleTap = Date.now() - this.doubleTapTimestamp;
    if (timeSinceDoubleTap < this.QUICK_ZOOM_TIME_THRESHOLD && this.doubleTapTimestamp > 0) {
      hilog.info(DOMAIN, TAG, `   🚀 Quick Zoom detected`);
      // Trigger Quick Zoom
      this.onQuickZoomStart(event, this.screenHeight || 800); // Use default screen height
      return;
    }

    // ✅ Initialize with the actual finger coordinates (consistent with onPanUpdate)
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;
    
    hilog.debug(DOMAIN, TAG, `   finger=(${fingerX.toFixed(1)}, ${fingerY.toFixed(1)})`);

    // 🎯 Check whether marker dragging should start as soon as pan begins.
    // No long press required; evaluate when the touch move starts.
    if (this.mapLibreMapInstance) {
      if (this.mapLibreMapInstance.tryStartMarkerDrag(fingerX, fingerY)) {
        // Marker drag already in progress; skip map movement.
        // Note: do not set isMoving=true so the map stays stationary.
        return;
      }
    }

    if (!this.uiSettings.isScrollGesturesEnabled()) {
      return;
    }

    this.isMoving = true;

    this.lastPanX = fingerX;
    this.lastPanY = fingerY;

    // Reset velocity tracker
    this.panVelocityTracker.reset();

    // Cancel ongoing animations
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // Notify listeners
    this.notifyMoveBegin();
  }

  /**
   * Pan gesture updates.
   */
  onPanUpdate(event: GestureEvent): void {
    hilog.debug(DOMAIN, TAG, `🔄 onPanUpdate: offset=(${event.offsetX.toFixed(1)}, ${event.offsetY.toFixed(1)})`);
    
    // Forward to Quick Zoom handler when active
    if (this.isQuickZooming) {
      this.onQuickZoomUpdate(event);
      return;
    }

    // ✅ HarmonyOS fix: use the actual finger coordinates.
    // event.offsetX/offsetY are relative offsets (too small),
    // fingerList[0].localX/localY provide true coordinates (logical pixels).
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;

    // 🎯 Dispatch touch move events (for marker drag).
    // ⚠️ Critical: dispatch before checking isMoving!
    // Long press may leave the pan gesture in DETECTING state until enough movement occurs.
    // Before the pan is accepted, onPanStart is not invoked and isMoving stays false.
    // We still need marker drag to react immediately, so fire touchMove first.
    // Reference: Android `AndroidGesturesManager.onTouchEvent` + `MoveGestureDetector`.
    if (this.mapLibreMapInstance) {
      if (this.mapLibreMapInstance.fireTouchMoveEvent(fingerX, fingerY)) {
        // Event consumed (marker drag active); stop moving the map.
        return;
      }
    }

    if (!this.uiSettings.isScrollGesturesEnabled() || !this.isMoving) {
      return;
    }

    // 🔑 Skip pan updates during/shortly after scale/rotate/tilt to prevent drift from gesture conflicts.
    const timeSinceScaleEnd = Date.now() - this.lastScaleEndTimestamp;
    const timeSinceRotateEnd = Date.now() - this.lastRotateEndTimestamp;
    const timeSinceTiltEnd = Date.now() - this.lastTiltEndTimestamp;
    
    if (this.isScaling || this.isRotating || this.isTilting ||
        timeSinceScaleEnd < this.SCALE_END_GRACE_PERIOD ||
        timeSinceRotateEnd < this.ROTATE_END_GRACE_PERIOD ||
        timeSinceTiltEnd < this.TILT_END_GRACE_PERIOD) {
      hilog.debug(DOMAIN, TAG, `   ⏸️ Pan update ignored: isScaling=${this.isScaling}, isRotating=${this.isRotating}, timeSinceScaleEnd=${timeSinceScaleEnd}ms`);
      return;
    }

    // Compute raw delta (logical pixels)
    const rawDeltaX = fingerX - this.lastPanX;
    const rawDeltaY = fingerY - this.lastPanY;

    // Apply pixelRatio scaling (use cached value to avoid per-frame lookup)
    const pixelRatio = this.getPixelRatio();
    const deltaX = rawDeltaX * pixelRatio;
    const deltaY = rawDeltaY * pixelRatio;

    // 🔍 Debug: log both raw and scaled deltas

    // Update last position using actual finger coordinates
    this.lastPanX = fingerX;
    this.lastPanY = fingerY;

    // Record velocity sample (actual finger coordinates)
    const now = Date.now();
    this.panVelocityTracker.addSample(fingerX, fingerY, now);

    // Enforce horizontal scroll restrictions
    let actualDeltaX = deltaX;
    if (!this.uiSettings.isHorizontalScrollGesturesEnabled()) {
      actualDeltaX = 0;
    }

    // Move the map (scaled by pixelRatio).
    // ✅ HarmonyOS gesture semantics: finger right swipe → map moves right (follow finger).
    if (this.mapController && (actualDeltaX !== 0 || deltaY !== 0)) {
      this.mapController.moveBy(actualDeltaX, deltaY, 0);
      
      // ✅ Notify camera movement during drag (updates InfoWindow, etc.).
      // Reason: `moveBy(0)` does not trigger Native onCameraIsChanging (only animations do),
      // so manually notify the camera dispatcher to refresh InfoWindow positions.
      // Reference: Android MapGestureDetector keeps firing onCameraMove during gestures.
      //
      // ⚠️ Delay to the next tick so moveBy() completes and state updates before querying coordinates.
      // Otherwise pixelForLatLng() may return stale values.
      if (this.mapLibreMapInstance) {
        hilog.info(DOMAIN, TAG, `   📍 Scheduling _notifyCameraMove for InfoWindow update`);
        setTimeout(() => {
          if (this.mapLibreMapInstance && !this.mapLibreMapInstance.isDestroyed()) {
            hilog.info(DOMAIN, TAG, `   📍 Calling _notifyCameraMove for InfoWindow update`);
            this.mapLibreMapInstance._notifyCameraMove();
          }
        }, 0);
      }
    }

    // Notify listeners
    this.notifyMove(actualDeltaX, deltaY);
  }

  /**
   * Pan gesture ends.
   *
   * Mirrors the Android implementation (MapGestureDetector.java:416-463).
   * Key notes:
   * 1. Normalize velocity using pixelRatio for consistent cross-device behavior.
   * 2. Use normalized velocity to compute duration.
   * 3. Apply coefficient 0.28 (empirical Android value).
   */
  onPanEnd(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔴 onPanEnd: offset=(${event.offsetX.toFixed(1)}, ${event.offsetY.toFixed(1)})`);
    
    // Forward to Quick Zoom handler when active
    if (this.isQuickZooming) {
      this.onQuickZoomEnd(event);
      return;
    }

    // 🎯 Dispatch touch-up event (e.g. to finish marker drag).
    // Reference: Android `MoveGestureDetector.onMoveEnd` + iOS `handlePan` (UIGestureRecognizerStateEnded).
    const fingerX = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const fingerY = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;

    // Dispatch via MapLibreMap
    if (this.mapLibreMapInstance) {
      if (this.mapLibreMapInstance.fireTouchUpEvent(fingerX, fingerY)) {
        // Event consumed
      }
    }

    if (!this.isMoving) {
      return;
    }

    // 🔧 Disable pan fling if scaling/rotating/tilting is active or just finished,
    // preventing unintended fling caused by multi-gesture movements.
    const timeSinceScaleEnd = Date.now() - this.lastScaleEndTimestamp;
    const timeSinceRotateEnd = Date.now() - this.lastRotateEndTimestamp;
    const timeSinceTiltEnd = Date.now() - this.lastTiltEndTimestamp;
    if (this.isScaling || this.isRotating || this.isTilting ||
      timeSinceScaleEnd < this.SCALE_END_GRACE_PERIOD ||
      timeSinceRotateEnd < this.ROTATE_END_GRACE_PERIOD ||
      timeSinceTiltEnd < this.TILT_END_GRACE_PERIOD) {
      let reason = '';
      if (this.isScaling) {
        reason = 'scaling in progress';
      } else if (this.isRotating) {
        reason = 'rotation in progress';
      } else if (this.isTilting) {
        reason = 'tilt in progress';
      } else if (timeSinceScaleEnd < this.SCALE_END_GRACE_PERIOD) {
        reason = `scaling ended ${timeSinceScaleEnd}ms ago`;
      } else if (timeSinceRotateEnd < this.ROTATE_END_GRACE_PERIOD) {
        reason = `rotation ended ${timeSinceRotateEnd}ms ago`;
      } else {
        reason = `tilt ended ${timeSinceTiltEnd}ms ago`;
      }
      this.isMoving = false;

      // Mark gesture complete
      if (this.mapController) {
        this.mapController.setGestureInProgress(false);
      }

      // Notify listeners
      this.notifyMoveEnd();
      return;
    }

    // Determine whether to start fling animation
    if (this.uiSettings.isFlingVelocityAnimationEnabled() &&
    this.panVelocityTracker.hasEnoughData()) {

      const velocity = this.panVelocityTracker.getVelocity();
      const speed = this.panVelocityTracker.getSpeed();

      // ⚠️ HarmonyOS vs Android:
      // - Android MotionEvent returns physical pixels → divide by pixelRatio to normalize.
      // - HarmonyOS GestureEvent returns logical pixels (vp) → already normalized.
      // Therefore the speed is already in logical px/sec; use it directly.

      // Check fling velocity threshold
      if (speed >= this.uiSettings.getMinFlingVelocity()) {
        // Compute animation duration
        const duration = this.calculateFlingDuration(speed);

        // Apply Android 0.28 coefficient to compute offsets.
        // factor 1000: convert ms → s.
        // factor 0.28: empirical factor aligning inertia velocity with release velocity.
        const offsetX = velocity.vx * duration * this.FLING_VELOCITY_COEFFICIENT / 1000;
        const offsetY = velocity.vy * duration * this.FLING_VELOCITY_COEFFICIENT / 1000;

        // ✅ Step 6: perform inertia animation (mirrors Android line 463).
        // HarmonyOS semantics: map follows finger direction (positive delta).
        if (this.mapController && this.mapController.moveBy) {
          this.mapController.moveBy(offsetX, offsetY, duration);
        }
      } else {
      }
    }

    this.isMoving = false;

    // Mark gesture complete
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // Notify listeners
    this.notifyMoveEnd();
  }

  /**
   * Pinch gesture begins.
   */
  onPinchStart(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔵 onPinchStart: scale=${event.scale.toFixed(3)}, center=(${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)})`);
    
    if (!this.uiSettings.isZoomGesturesEnabled()) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ Zoom gestures disabled`);
      return;
    }

    // 🔑 Android-style priority logic: compute current pinch span.
    let currentSpan = 0;
    if (event.fingerList && event.fingerList.length >= 2) {
      const dx = event.fingerList[1].localX - event.fingerList[0].localX;
      const dy = event.fingerList[1].localY - event.fingerList[0].localY;
      currentSpan = Math.sqrt(dx * dx + dy * dy);
    }

    // Calculate speed using previous frame (if available)
    if (this.previousPinchSpan > 0 && this.previousPinchTimestamp > 0) {
      const currTime = Date.now();
      const prevTime = this.previousPinchTimestamp;

      if (currTime !== prevTime) {
        const spanDelta = Math.abs(currentSpan - this.previousPinchSpan);
        const timeDelta = currTime - prevTime;
        const speed = spanDelta / timeDelta; // Pixels per millisecond

        // Ensure minimum gesture speed
        if (speed < MINIMUM_GESTURE_SPEED) {
          return;
        }

        // If rotation has not started, verify whether rotation should take priority.
        if (!this.isRotating) {
          const rotationDelta = Math.abs(this.rotationDeltaAccumulated);

          if (rotationDelta > ROTATION_ANGLE_THRESHOLD && speed < MINIMUM_ANGLED_GESTURE_SPEED) {
            // Significant rotation with slow scaling -> prioritize rotation.
            return;
          }
        }
      }
    }

    // Record current frame data for next iteration
    this.previousPinchSpan = currentSpan;
    this.previousPinchTimestamp = Date.now();

    this.isScaling = true;
    this.lastScale = 1.0;
    this.currentScale = 1.0;

    // 🔑 If rotation is active, terminate it immediately to avoid conflict.
    if (this.isRotating) {
      this.isRotating = false;
      this.notifyRotateEnd();
    }

    // 🔑 If tilt is active, terminate it immediately to avoid conflict.
    if (this.isTilting) {
      this.isTilting = false;
      this.notifyTiltEnd();
    }

    // 🔑 As in Android: disable rotation/tilt while scaling to avoid conflicts.
    this.shouldIgnoreRotation = true;
    this.shouldIgnoreTilt = true;

    // Initialize scale state
    if (this.mapController && this.mapController.getZoom) {
      this.initialZoom = this.mapController.getZoom();
      this.currentZoomLevel = this.initialZoom; // 🔑 Cache initial zoom; avoid frequent getZoom() calls later.
      hilog.info(DOMAIN, TAG, `   initialZoom=${this.initialZoom.toFixed(2)}`);
    } else {
      this.initialZoom = 0;
      this.currentZoomLevel = 0;
      hilog.warn(DOMAIN, TAG, `   ⚠️ mapController or getZoom not available`);
    }

    // Reset velocity tracker
    this.scaleVelocityTracker.reset();

    // Cancel animations and flag gesture as in progress
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 🔧 FIX: compute and lock the scale anchor for the entire gesture.
    // Reference: Android `transform.zoomBy` keeps a fixed focalPoint to prevent drift.
    let anchorX = event.pinchCenterX;
    let anchorY = event.pinchCenterY;
    
    if (event.fingerList && event.fingerList.length >= 2) {
      anchorX = (event.fingerList[0].localX + event.fingerList[1].localX) / 2;
      anchorY = (event.fingerList[0].localY + event.fingerList[1].localY) / 2;
      hilog.info(DOMAIN, TAG, `   📍 Fixed anchor from fingerList: (${anchorX.toFixed(1)}, ${anchorY.toFixed(1)})`);
    }
    
    this.fixedScaleAnchorX = anchorX;
    this.fixedScaleAnchorY = anchorY;
    
    // Obtain focal point and notify listeners
    const focalPoint = this.getFocalPoint(anchorX, anchorY);

    this.notifyScaleBegin(focalPoint.x, focalPoint.y);
  }

  /**
   * Pinch gesture updates.
   * Mirrors Android onScale implementation using incremental zoom calculations.
   */
  onPinchUpdate(event: GestureEvent): void {
    if (!this.uiSettings.isZoomGesturesEnabled() || !this.isScaling) {
      return;
    }

    // Retrieve incremental scale factor
    this.currentScale = event.scale;
    const scaleFactor = this.currentScale / this.lastScale;

    // Android-style incremental scaling (MapGestureDetector.ScaleGestureListener.onScale)
    const zoomBy = (Math.log(scaleFactor) / Math.log(Math.PI / 2)) * ZOOM_RATE * this.uiSettings.getZoomRate();
    
    hilog.debug(DOMAIN, TAG, `🔄 onPinchUpdate: scale=${event.scale.toFixed(3)}, scaleFactor=${scaleFactor.toFixed(3)}, zoomBy=${zoomBy.toFixed(4)}, center=(${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)})`);

    // 🔑 Skip frame if zoom delta is negligible (< 0.001) to avoid drift from redundant setZoom calls.
    // When fingers maintain distance but move together, a fixed anchor could cause "snapping".
    if (Math.abs(zoomBy) < 0.001) {
      // Still update lastScale to keep future calculations accurate.
      this.lastScale = this.currentScale;
      // Notify listeners (gesture still in progress) using the fixed anchor, matching Android behavior.
      const focalPoint = this.getFocalPoint(this.fixedScaleAnchorX, this.fixedScaleAnchorY);
      this.notifyScale(scaleFactor, focalPoint.x, focalPoint.y);
      return;
    }

    // Record velocity sample (for inertia)
    const now = Date.now();
    this.scaleVelocityTracker.addSample(this.currentScale, 0, now);

    // 🔧 Prevent drift: use the fixed scale anchor (see Android transform.zoomBy).
    // Android keeps the same focalPoint throughout the gesture; do the same here.
    const focalPoint = this.getFocalPoint(this.fixedScaleAnchorX, this.fixedScaleAnchorY);

    // 🔑 Use cached zoom to avoid frequent getZoom() calls and concurrency issues.
    // Apply incremental zoom similar to Android transform.zoomBy.
    if (this.mapController && this.mapController.setZoom) {
      const newZoom: number = this.currentZoomLevel + zoomBy;

      // 🔑 DPI fix: convert logical pixels to physical pixels
      const pixelRatio = this.getPixelRatio();
      const scaledAnchorX = focalPoint.x * pixelRatio;
      const scaledAnchorY = focalPoint.y * pixelRatio;

      hilog.debug(DOMAIN, TAG, `   setZoom: ${this.currentZoomLevel.toFixed(2)} -> ${newZoom.toFixed(2)}, anchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)}), pixelRatio=${pixelRatio.toFixed(2)}`);
      
      this.mapController.setZoom(newZoom, scaledAnchorX, scaledAnchorY, 0);
      
      // 🔑 Update cached zoom level
      this.currentZoomLevel = newZoom;
    }

    // Notify listeners
    this.notifyScale(scaleFactor, focalPoint.x, focalPoint.y);

    // Update previous-frame state
    this.lastScale = this.currentScale;
  }

  /**
   * Compute zoom delta for scale inertia.
   * Mirrors Android MapGestureDetector.calculateScale().
   * @param velocityXY Absolute velocity magnitude.
   * @param isScalingOut Whether the gesture is zooming out.
   * @returns Zoom delta.
   */
  private calculateScaleZoomDelta(velocityXY: number, isScalingOut: boolean): number {
    // Logarithmic scaling: larger velocity increases delta with diminishing returns.
    // log(velocityXY / 4 + 1) * ZOOM_RATE
    let zoomAddition = Math.log(velocityXY / 4 + 1) * ZOOM_RATE;

    if (isScalingOut) {
      zoomAddition = -zoomAddition;
    }

    // Clamp range (Android MathUtils.clamp)
    return Math.max(-MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE,
      Math.min(MAX_ABSOLUTE_SCALE_VELOCITY_CHANGE, zoomAddition));
  }

  /**
   * Compute duration for scale inertia animation.
   * Mirrors Android MapGestureDetector.onScaleEnd().
   * @param zoomDelta Zoom delta.
   * @returns Duration in milliseconds.
   */
  private calculateScaleAnimationDuration(zoomDelta: number): number {
    // (log(|zoomDelta| + 1/e^2) + 2) * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER
    const duration = (Math.log(Math.abs(zoomDelta) + 1 / Math.pow(Math.E, 2)) + 2)
      * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER;

    // Constrain duration between 100 ms and 1000 ms
    return Math.max(100, Math.min(1000, duration));
  }

  /**
   * Clamp angular velocity to a sensible range.
   * @param angularVelocity Angular velocity (deg/s).
   * @returns Clamped angular velocity.
   */
  private clampAngularVelocity(angularVelocity: number): number {
    return Math.max(-MAXIMUM_ANGULAR_VELOCITY,
      Math.min(MAXIMUM_ANGULAR_VELOCITY, angularVelocity));
  }

  /**
   * Compute duration for rotate inertia animation.
   * Mirrors Android MapGestureDetector.onRotateEnd().
   * @param angularVelocity Angular velocity (deg/s).
   * @returns Duration in milliseconds.
   */
  private calculateRotateAnimationDuration(angularVelocity: number): number {
    // Same logarithmic formula as scale inertia:
    // (log(|angularVelocity| + 1/e^2) + 2) * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER
    const duration = (Math.log(Math.abs(angularVelocity) + 1 / Math.pow(Math.E, 2)) + 2)
      * SCALE_VELOCITY_ANIMATION_DURATION_MULTIPLIER;

    // Constrain duration between 100 ms and 1000 ms
    return Math.max(100, Math.min(1000, duration));
  }

  /**
   * Pinch gesture ends.
   */
  onPinchEnd(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔴 onPinchEnd: scale=${event.scale.toFixed(3)}, center=(${event.pinchCenterX.toFixed(1)}, ${event.pinchCenterY.toFixed(1)}), currentZoom=${this.currentZoomLevel.toFixed(2)}`);
    
    if (!this.isScaling) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ onPinchEnd: Not in scaling state`);
      return;
    }

    // 🔧 FIX: use the fixed scale anchor for inertia (as in Android transform.zoomBy).
    // Keep the same anchor throughout the gesture to avoid cumulative drift.
    const focalPoint = this.getFocalPoint(this.fixedScaleAnchorX, this.fixedScaleAnchorY);
    
    hilog.debug(DOMAIN, TAG, `   📍 Using fixed anchor: (${this.fixedScaleAnchorX.toFixed(1)}, ${this.fixedScaleAnchorY.toFixed(1)})`);

    // 🔧 Android-style scale inertia animation (fully ported).
    // Reference: MapGestureDetector.java onScaleEnd().
    if (this.uiSettings.isScaleVelocityAnimationEnabled() &&
    this.scaleVelocityTracker.hasEnoughData()) {

      const velocity = this.scaleVelocityTracker.getVelocity();
      const scaleVelocity = velocity.vx; // Use X component as scale velocity.

      // ✅ Android approach: use constant thresholds instead of UiSettings.
      if (Math.abs(scaleVelocity) < MIN_SCALE_VELOCITY_THRESHOLD) {
        hilog.info(DOMAIN, TAG, `   ⏸️ No fling animation: velocity=${scaleVelocity.toFixed(2)} < threshold=${MIN_SCALE_VELOCITY_THRESHOLD}`);
      } else {
        // ✅ Determine zooming in or out.
        const isScalingOut = scaleVelocity < 0;
        const velocityXY = Math.abs(scaleVelocity);

        // ✅ Log-based zoom delta (Android algorithm).
        const zoomDelta = this.calculateScaleZoomDelta(velocityXY, isScalingOut);

        // ✅ Duration based on zoom delta (Android algorithm).
        const duration = this.calculateScaleAnimationDuration(zoomDelta);

        hilog.info(DOMAIN, TAG, `   🚀 Fling animation: velocity=${velocityXY.toFixed(2)}, zoomDelta=${zoomDelta.toFixed(4)}, duration=${duration}ms, isScalingOut=${isScalingOut}`);

        // 🔑 Run zoom animation using cached zoom to avoid concurrency issues.
        if (this.mapController && this.mapController.setZoom) {
          const finalZoom: number = this.currentZoomLevel + zoomDelta;

          // 🔑 DPI fix: convert logical to physical pixels.
          const pixelRatio = this.getPixelRatio();
          const scaledAnchorX = focalPoint.x * pixelRatio;
          const scaledAnchorY = focalPoint.y * pixelRatio;

          hilog.info(DOMAIN, TAG, `   setZoom with animation: ${this.currentZoomLevel.toFixed(2)} -> ${finalZoom.toFixed(2)}, anchor=(${scaledAnchorX.toFixed(1)}, ${scaledAnchorY.toFixed(1)})`);

          this.mapController.setZoom(finalZoom, scaledAnchorX, scaledAnchorY, duration);
          // Note: do not update currentZoomLevel; isScaling is already false after animation.
        }
      }
    } else {
      hilog.info(DOMAIN, TAG, `   ⏸️ No fling animation: ScaleVelocityAnimation disabled or not enough data`);
    }

    this.isScaling = false;

    // 🔧 Record end timestamp to suppress immediate pan fling.
    this.lastScaleEndTimestamp = Date.now();

    // 🔑 Reset pan state so accumulated offsets during pinch are not applied afterward.
    // Pan may still occur during pinch, but isMoving prevents updates, leaving lastPanX/Y stale.
    // Without reset, the next pan update would produce a large delta.
    if (event.fingerList && event.fingerList.length >= 1) {
      this.lastPanX = event.fingerList[0].localX;
      this.lastPanY = event.fingerList[0].localY;
      hilog.debug(DOMAIN, TAG, `   🔧 Reset Pan state to avoid accumulated offset: (${this.lastPanX.toFixed(1)}, ${this.lastPanY.toFixed(1)})`);
    }

    // 🔑 Reset priority-tracking state so next pinch starts cleanly.
    this.previousPinchSpan = 0;
    this.previousPinchTimestamp = 0;
    this.rotationDeltaAccumulated = 0;

    // 🔑 Re-enable rotation and tilt gestures (Android parity).
    this.shouldIgnoreRotation = false;
    this.shouldIgnoreTilt = false;

    // Mark gesture complete
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // Notify listeners
    this.notifyScaleEnd();
  }

  /**
   * Rotate gesture begins.
   */
  onRotateStart(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🟢 onRotateStart: angle=${event.angle.toFixed(2)}`);
    
    if (!this.uiSettings.isRotateGesturesEnabled()) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ Rotate gestures disabled`);
      return;
    }

    // 🔑 Abort if scaling or rotation is currently suppressed to avoid conflicts.
    if (this.shouldIgnoreRotation || this.isScaling) {
      return;
    }

    // 🔑 If tilt is active, terminate it immediately to prevent conflict.
    if (this.isTilting) {
      this.isTilting = false;
      this.notifyTiltEnd();
    }

    this.isRotating = true;
    this.lastRotation = 0; // Reset previous-frame angle
    this.totalRotation = 0;
    this.rotationDeltaAccumulated = 0; // Reset accumulated rotation (priority tracking)

    // Reset velocity tracker
    this.rotateVelocityTracker.reset();

    // Cancel animations and flag gesture in progress
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // 🔑 Rotation gestures must compute the center from fingerList.
    // pinchCenterX/Y exist only in pinch gestures; in rotation they are undefined.
    let centerX = 0;
    let centerY = 0;

    if (event.fingerList && event.fingerList.length >= 2) {
      const finger0X = event.fingerList[0].localX;
      const finger0Y = event.fingerList[0].localY;
      const finger1X = event.fingerList[1].localX;
      const finger1Y = event.fingerList[1].localY;

      // Compute the midpoint of the two fingers
      centerX = (finger0X + finger1X) / 2;
      centerY = (finger0Y + finger1Y) / 2;

    }

    const focalPoint = this.getFocalPoint(centerX, centerY);

    // 🔑 Store a fixed rotation anchor (iOS-style) for the entire rotation.
    this.rotationAnchorX = focalPoint.x;
    this.rotationAnchorY = focalPoint.y;

    this.notifyRotateBegin(this.rotationAnchorX, this.rotationAnchorY);
  }

  /**
   * Rotate gesture updates.
   * Mirrors Android onRotate using incremental calculations.
   */
  onRotateUpdate(event: GestureEvent): void {
    if (!this.uiSettings.isRotateGesturesEnabled() || !this.isRotating) {
      return;
    }

    // 🔑 Abort when scaling or rotation is suppressed to avoid conflicts.
    if (this.shouldIgnoreRotation || this.isScaling) {
      return;
    }

    // Convert rotation from radians to degrees.
    const currentRotation = event.angle * 180 / Math.PI;

    // 🔑 Use helper to compute deltas correctly across wrap boundaries.
    let rotationDelta = this.calculateAngleDelta(currentRotation, this.lastRotation);

    // 🔑 Reverse sign so clockwise finger motion rotates map clockwise.
    rotationDelta = -rotationDelta;

    // 🔑 Skip very small deltas (< 0.1°) to reduce jitter.
    if (Math.abs(rotationDelta) < 0.1) {
      // Still update lastRotation to keep future calculations accurate.
      this.lastRotation = currentRotation;
      return;
    }

    hilog.debug(DOMAIN, TAG, `🔄 onRotateUpdate: angle=${currentRotation.toFixed(2)}°, delta=${rotationDelta.toFixed(2)}°`);

    this.totalRotation += rotationDelta;

    // 🔑 Accumulate rotation for pinch priority checks (Android getDeltaSinceLast).
    if (!this.isScaling) {
      this.rotationDeltaAccumulated += rotationDelta;
    }

    // Record velocity sample (for inertia)
    const now = Date.now();
    this.rotateVelocityTracker.addSample(currentRotation, 0, now);

    // 🔑 Use the fixed rotation anchor (iOS approach) rather than recalculating each frame.
    const anchorX = this.rotationAnchorX;
    const anchorY = this.rotationAnchorY;

    // 🔑 Android style: read the current bearing each frame and apply delta.
    if (this.mapController && this.mapController.getBearing && this.mapController.setBearingXY) {
      const currentBearing: number = this.mapController.getBearing();

      // 🔑 Apply rotation rate factor to control speed.
      const adjustedRotationDelta = rotationDelta * ROTATION_RATE * this.uiSettings.getRotationRate();
      let newBearing: number = currentBearing + adjustedRotationDelta;

      // 🔑 Normalize bearing to [-180, 180] to avoid discontinuities.
      newBearing = this.normalizeBearing(newBearing);

      // 🔑 DPI fix: convert HarmonyOS logical pixels to physical pixels.
      const pixelRatio = this.getPixelRatio();
      const scaledAnchorX = anchorX * pixelRatio;
      const scaledAnchorY = anchorY * pixelRatio;

      this.mapController.setBearingXY(newBearing, scaledAnchorX, scaledAnchorY, 0);
    }

    // Notify listeners
    this.notifyRotate(rotationDelta, anchorX, anchorY);

    // Store current angle for next-frame delta calculation
    this.lastRotation = currentRotation;
  }

  /**
   * Rotate gesture ends.
   */
  onRotateEnd(event: GestureEvent): void {
    hilog.info(DOMAIN, TAG, `🔴 onRotateEnd: angle=${event.angle.toFixed(2)}°`);
    
    if (!this.isRotating) {
      hilog.warn(DOMAIN, TAG, `   ⚠️ Not in rotating state`);
      return;
    }

    // 🔑 Use the fixed rotation anchor for inertia calculations.
    const anchorX = this.rotationAnchorX;
    const anchorY = this.rotationAnchorY;

    // 🔧 Android-style rotate inertia animation (full port).
    // Reference: MapGestureDetector.java onRotateEnd().
    if (this.uiSettings.isRotateVelocityAnimationEnabled() &&
    this.rotateVelocityTracker.hasEnoughData()) {

      const velocity = this.rotateVelocityTracker.getVelocity();
      let angularVelocity = velocity.vx; // Degrees per second

      // ✅ Clamp angular velocity to ±30°/s (MAXIMUM_ANGULAR_VELOCITY).
      angularVelocity = this.clampAngularVelocity(angularVelocity);

      // ✅ Check angular velocity threshold (use constant instead of UiSettings).
      if (Math.abs(angularVelocity) < MIN_ANGULAR_VELOCITY_THRESHOLD) {
      } else {
        // ✅ Duration from Android logarithmic formula.
        const duration = this.calculateRotateAnimationDuration(angularVelocity);

        // ✅ Delta bearing (iOS style: velocity * duration * 0.1).
        const deltaBearing = angularVelocity * duration / 1000 * 0.1;

        // Execute rotation animation
        if (this.mapController && this.mapController.getBearing && this.mapController.setBearingXY) {
          const currentBearing: number = this.mapController.getBearing();
          let newBearing: number = currentBearing + deltaBearing;

          // Normalize resulting bearing
          newBearing = this.normalizeBearing(newBearing);

          // 🔑 DPI fix: convert logical to physical pixels.
          const pixelRatio = this.getPixelRatio();
          const scaledAnchorX = anchorX * pixelRatio;
          const scaledAnchorY = anchorY * pixelRatio;

          this.mapController.setBearingXY(newBearing, scaledAnchorX, scaledAnchorY, duration);
        }
      }
    }

    this.isRotating = false;

    // 🔧 Record rotation end timestamp to suppress immediate pan fling.
    this.lastRotateEndTimestamp = Date.now();

    // 🔑 Reset pan state to avoid applying rotation-era offsets afterward (same as onPinchEnd).
    if (event.fingerList && event.fingerList.length >= 1) {
      this.lastPanX = event.fingerList[0].localX;
      this.lastPanY = event.fingerList[0].localY;
      hilog.debug(DOMAIN, TAG, `   🔧 Reset Pan state to avoid accumulated offset: (${this.lastPanX.toFixed(1)}, ${this.lastPanY.toFixed(1)})`);
    }

    // 🔑 Reset priority tracking so the next pinch starts smoothly.
    this.previousPinchSpan = 0;
    this.previousPinchTimestamp = 0;
    this.rotationDeltaAccumulated = 0;

    // Mark gesture complete
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // Notify listeners
    this.notifyRotateEnd();
  }

  /**
   * Single tap gesture.
   */
  onSingleTap(event: GestureEvent): void {

    const x = event.fingerList[0].localX;
    const y = event.fingerList[0].localY;

    // Notify listeners
    this.notifyMapClick(x, y);
  }

  /**
   * Double-tap gesture.
   */
  onDoubleTap(event: GestureEvent): void {
    if (!this.uiSettings.isDoubleTapGesturesEnabled()) {
      return;
    }

    const x = event.fingerList[0].localX;
    const y = event.fingerList[0].localY;

    // Record double-tap for Quick Zoom detection
    this.doubleTapTimestamp = Date.now();
    this.doubleTapX = x;
    this.doubleTapY = y;

    // Note: delay zooming briefly to see if a drag (Quick Zoom) follows.
    // If no drag occurs, apply double-tap zoom after the timeout.
    setTimeout(() => {
      // If no Quick Zoom within the window, perform double-tap zoom.
      if (!this.isQuickZooming && Date.now() - this.doubleTapTimestamp < this.QUICK_ZOOM_TIME_THRESHOLD + 100) {
        // Default behavior: zoom in by one level.
        if (this.mapController && this.mapController.getZoom && this.mapController.setZoom) {
          const currentZoom: number = this.mapController.getZoom() as number;
          this.mapController.setZoom(currentZoom + 1);
        }

        // Notify listeners
        this.notifyDoubleTap(x, y);
      }
    }, this.QUICK_ZOOM_TIME_THRESHOLD);
  }

  /**
   * Two-finger tap gesture (zoom out).
   * Mirrors iOS MLNMapView handleTwoFingerTapGesture.
   */
  onTwoFingerTap(event: GestureEvent): void {
    if (!this.uiSettings.isZoomGesturesEnabled()) {
      return;
    }

    // Ensure we haven't reached min zoom.
    if (this.mapController && this.mapController.getZoom && this.mapController.getMinZoom) {
      const currentZoom: number = this.mapController.getZoom() as number;
      const minZoom: number = this.mapController.getMinZoom() as number;

      if (currentZoom <= minZoom) {
        return;
      }
    }

    // Cancel ongoing animations
    if (this.mapController) {
      this.mapController.cancelTransitions();
    }

    // Use midpoint of the two fingers as focal point.
    let centerX = 0;
    let centerY = 0;

    if (event.fingerList && event.fingerList.length >= 2) {
      const finger0X = event.fingerList[0].localX;
      const finger0Y = event.fingerList[0].localY;
      const finger1X = event.fingerList[1].localX;
      const finger1Y = event.fingerList[1].localY;

      centerX = (finger0X + finger1X) / 2;
      centerY = (finger0Y + finger1Y) / 2;

    }

    // Resolve focal point (respect custom focal point if set).
    const focalPoint = this.getFocalPoint(centerX, centerY);

    // 🔑 DPI fix: convert logical pixels to physical pixels.
    const pixelRatio = this.getPixelRatio();
    const scaledAnchorX = focalPoint.x * pixelRatio;
    const scaledAnchorY = focalPoint.y * pixelRatio;

    // New zoom level: current - 1 (iOS parity).
    if (this.mapController && this.mapController.getZoom && this.mapController.setZoom) {
      const currentZoom: number = this.mapController.getZoom() as number;
      const newZoom: number = Math.round(currentZoom) - 1.0;

      // Animate zoom over 300 ms (iOS MLNAnimationDuration).
      const duration = 300;
      this.mapController.setZoom(newZoom, scaledAnchorX, scaledAnchorY, duration);
    }

    // Notify listeners via the existing double-tap handler.
    this.notifyDoubleTap(centerX, centerY);
  }

  /**
   * Long-press gesture.
   */
  onLongPress(event: GestureEvent): void {
    const x = event.fingerList && event.fingerList[0] ? event.fingerList[0].localX : event.offsetX;
    const y = event.fingerList && event.fingerList[0] ? event.fingerList[0].localY : event.offsetY;

    // Notify listeners
    this.notifyMapLongClick(x, y);
  }

  /**
   * Two-finger pan tilt gesture begins.
   */
  onTwoFingerPanStart(event: GestureEvent): void {
    if (!this.uiSettings.isTiltGesturesEnabled()) {
      return;
    }

    // 🔑 Match Android shove behavior: skip tilt if scaling/rotating or flagged to ignore.
    if (this.shouldIgnoreTilt || this.isScaling || this.isRotating) {
      return;
    }

    this.isTilting = true;
    this.tiltStartY = event.offsetY;

    // Fetch current pitch
    if (this.mapController && this.mapController.getPitch) {
      this.initialPitch = this.mapController.getPitch() as number;
    } else {
      this.initialPitch = 0;
    }

    // Cancel animations
    if (this.mapController) {
      this.mapController.cancelTransitions();
      this.mapController.setGestureInProgress(true);
    }

    // Notify listeners
    this.notifyTiltBegin();
  }

  /**
   * Two-finger pan tilt updates.
   */
  onTwoFingerPanUpdate(event: GestureEvent): void {
    if (!this.isTilting) {
      return;
    }

    // Compute vertical delta
    const deltaY = event.offsetY - this.tiltStartY;

    // Compute new pitch (iOS slowdown factor = 2.0, Android uses SHOVE_PIXEL_CHANGE_FACTOR 0.1).
    const sensitivity = this.uiSettings.getTiltSensitivity();
    const newPitch = this.initialPitch - (deltaY / sensitivity);

    // Clamp to valid pitch range
    const clampedPitch = Math.max(
      this.uiSettings.getMinPitch(),
      Math.min(this.uiSettings.getMaxPitch(), newPitch)
    );

    // Apply pitch
    if (this.mapController && this.mapController.setPitch) {
      this.mapController.setPitch(clampedPitch, 0); // 0 means immediate update, no animation
    }

    // Notify listeners
    this.notifyTilt(clampedPitch);
  }

  /**
   * Two-finger pan tilt ends.
   */
  onTwoFingerPanEnd(event: GestureEvent): void {
    if (!this.isTilting) {
      return;
    }

    this.isTilting = false;

    // 🔧 Record tilt end timestamp to suppress immediate pan fling.
    this.lastTiltEndTimestamp = Date.now();

    // Mark gesture complete
    if (this.mapController) {
      this.mapController.setGestureInProgress(false);
    }

    // Notify listeners
    this.notifyTiltEnd();
  }

  /**
   * Quick Zoom begins (double-tap then drag).
   */
  onQuickZoomStart(event: GestureEvent, screenHeight: number): void {
    if (!this.uiSettings.isQuickZoomGesturesEnabled()) {
      return;
    }

    this.isQuickZooming = true;
    this.quickZoomStartY = event.fingerList[0].localY;
    this.screenHeight = screenHeight;

    // Capture starting zoom level
    if (this.mapController && this.mapController.getZoom) {
      this.quickZoomStartZoom = this.mapController.getZoom() as number;
    } else {
      this.quickZoomStartZoom = 10;
    }

    // Cancel ongoing animations
    if (this.mapController) {
      this.mapController.cancelTransitions();
    }

    // Notify listeners
    this.notifyQuickZoomBegin();
  }

  /**
   * Quick Zoom updates.
   */
  onQuickZoomUpdate(event: GestureEvent): void {
    if (!this.isQuickZooming) {
      return;
    }

    const currentY = event.fingerList[0].localY;
    const deltaY = currentY - this.quickZoomStartY;

    // Normalize pixel delta into zoom delta (Android approach).
    const normalizedDelta = this.normalize(
      Math.abs(deltaY),
      0,
      this.screenHeight,
      0,
      this.uiSettings.getQuickZoomMaxChange()
    );

    // Drag up to zoom in, drag down to zoom out.
    const zoomedOut = deltaY > 0;
    const targetZoom = zoomedOut
      ? this.quickZoomStartZoom - normalizedDelta
      : this.quickZoomStartZoom + normalizedDelta;

    // Apply zoom change
    if (this.mapController && this.mapController.setZoom) {
      this.mapController.setZoom(targetZoom, undefined, undefined, 0);
    }

    // Notify listeners
    this.notifyQuickZoom(targetZoom);
  }

  /**
   * Quick Zoom ends.
   */
  onQuickZoomEnd(event: GestureEvent): void {
    if (!this.isQuickZooming) {
      return;
    }

    this.isQuickZooming = false;

    // Notify listeners
    this.notifyQuickZoomEnd();
  }

  // ==================== Helpers ====================

  /**
   * Resolve gesture focal point.
   * Use user-configured focal point when available, otherwise default to gesture center.
   */
  private getFocalPoint(defaultX: number, defaultY: number): FocalPoint {
    const userFocalPoint = this.uiSettings.getFocalPoint();
    if (userFocalPoint) {
      return userFocalPoint;
    }
    return new FocalPoint(defaultX, defaultY);
  }

  /**
   * Compute the gesture anchor (unified method).
   *
   * @param event Gesture event.
   * @param gestureType Gesture type ('pinch' | 'rotate' | 'twoFinger').
   * @returns Anchor coordinates (logical pixels).
   */
  private getGestureAnchor(event: GestureEvent, gestureType: string): FocalPoint {
    let anchorX = 0;
    let anchorY = 0;

    // Compute anchor based on gesture type
    if (gestureType === 'pinch') {
      // Pinch: use event.pinchCenterX/Y
      anchorX = event.pinchCenterX || 0;
      anchorY = event.pinchCenterY || 0;
    } else if (gestureType === 'rotate' || gestureType === 'twoFinger') {
      // Rotate/TwoFinger: use midpoint of two fingers
      if (event.fingerList && event.fingerList.length >= 2) {
        const finger0X = event.fingerList[0].localX;
        const finger0Y = event.fingerList[0].localY;
        const finger1X = event.fingerList[1].localX;
        const finger1Y = event.fingerList[1].localY;

        anchorX = (finger0X + finger1X) / 2;
        anchorY = (finger0Y + finger1Y) / 2;
      }
    }

    // Apply user-defined focal point if present
    return this.getFocalPoint(anchorX, anchorY);
  }

  /**
   * Convert logical anchor to physical pixels.
   *
   * @param anchor Anchor in logical pixels.
   * @returns Anchor in physical pixels.
   */
  private applyPixelRatioToAnchor(anchor: FocalPoint): FocalPoint {
    const pixelRatio = this.getPixelRatio();
    return new FocalPoint(
      anchor.x * pixelRatio,
      anchor.y * pixelRatio
    );
  }

  /**
   * Calculate fling animation duration.
   *
   * Based on Android (MapGestureDetector.java:440):
   * duration = velocityXY / 7 / tiltFactor + baseTime
   *
   * @param speed Speed in logical pixels per second.
   * @returns Duration in milliseconds.
   */
  private calculateFlingDuration(speed: number): number {
    // Derive tilt factor (greater pitch -> weaker inertia).
    let tiltFactor = 1.0;
    if (this.mapController && this.mapController.getPitch) {
      const pitch = this.mapController.getPitch() as number;
      // Pitch range [0, 60] → tilt factor [1.0, 1.5].
      // Higher pitch increases tiltFactor, shortening inertia duration.
      tiltFactor = 1.0 + (pitch / 60.0) * 0.5;
    }
    const duration = speed / 7 / tiltFactor + this.uiSettings.getFlingAnimationBaseTime();

    // Clamp duration between 100 ms and 2000 ms
    return Math.max(100, Math.min(2000, duration));
  }

  /**
   * Initialize device pixel ratio (called once in constructor).
   * Obtains data from display API for coordinate conversion.
   */
  private initializePixelRatio(): number {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      if (defaultDisplay && defaultDisplay.densityDPI) {
        const pixelRatio = defaultDisplay.densityDPI / 160.0;
        return pixelRatio;
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, `Failed to get display DPI: ${error}, using pixelRatio=1.0`);
    }
    return 1.0;
  }

  /**
   * Retrieve cached pixel ratio (avoid repeated queries).
   */
  private getPixelRatio(): number {
    return this.cachedPixelRatio;
  }

  /**
   * Normalize a value from one range to another.
   */
  private normalize(value: number, min: number, max: number, newMin: number, newMax: number): number {
    if (max === min) {
      return newMin;
    } // Avoid division by zero
    return ((value - min) / (max - min)) * (newMax - newMin) + newMin;
  }

  /**
   * Normalize bearing into [-180, 180].
   * Matches Android handling for wrap-around.
   */
  private normalizeBearing(bearing: number): number {
    // Normalize angle into [-180, 180]
    while (bearing > 180) {
      bearing -= 360;
    }
    while (bearing < -180) {
      bearing += 360;
    }
    return bearing;
  }

  /**
   * Calculate angle delta with wrap-around handling.
   * Example: 179° → -179° should yield +2°, not -358°.
   */
  private calculateAngleDelta(currentAngle: number, lastAngle: number): number {
    let delta = currentAngle - lastAngle;

    // Adjust delta when crossing ±180°
    if (delta > 180) {
      delta -= 360;
    } else if (delta < -180) {
      delta += 360;
    }

    return delta;
  }

  // ==================== Listener dispatch helpers ====================

  private notifyMoveBegin(): void {
    for (const listener of this.moveListeners) {
      try {
        listener.onMoveBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMoveBegin listener: ${error}`);
      }
    }
  }

  private notifyMove(distanceX: number, distanceY: number): void {
    for (const listener of this.moveListeners) {
      try {
        listener.onMove(distanceX, distanceY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMove listener: ${error}`);
      }
    }
  }

  private notifyMoveEnd(): void {
    for (const listener of this.moveListeners) {
      try {
        listener.onMoveEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onMoveEnd listener: ${error}`);
      }
    }
  }

  private notifyScaleBegin(focalX: number, focalY: number): void {
    for (const listener of this.scaleListeners) {
      try {
        listener.onScaleBegin(focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onScaleBegin listener: ${error}`);
      }
    }
  }

  private notifyScale(scaleFactor: number, focalX: number, focalY: number): void {
    for (const listener of this.scaleListeners) {
      try {
        listener.onScale(scaleFactor, focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onScale listener: ${error}`);
      }
    }
  }

  private notifyScaleEnd(): void {
    for (const listener of this.scaleListeners) {
      try {
        listener.onScaleEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onScaleEnd listener: ${error}`);
      }
    }
  }

  private notifyRotateBegin(focalX: number, focalY: number): void {
    for (const listener of this.rotateListeners) {
      try {
        listener.onRotateBegin(focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onRotateBegin listener: ${error}`);
      }
    }
  }

  private notifyRotate(rotationDelta: number, focalX: number, focalY: number): void {
    for (const listener of this.rotateListeners) {
      try {
        listener.onRotate(rotationDelta, focalX, focalY);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onRotate listener: ${error}`);
      }
    }
  }

  private notifyRotateEnd(): void {
    for (const listener of this.rotateListeners) {
      try {
        listener.onRotateEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onRotateEnd listener: ${error}`);
      }
    }
  }

  private notifyMapClick(x: number, y: number): void {
    // 1. Notify MapLibreMap first (Android-style priority).
    let consumed = false;
    if (this.mapLibreMapInstance) {
      consumed = this.mapLibreMapInstance._notifyMapClick(x, y);
    }

    // 2. If not consumed, fall back to local listeners.
    if (!consumed) {
      for (const listener of this.clickListeners) {
        try {
          if (listener.onMapClick(x, y)) {
            break; // Stop propagation once consumed.
          }
        } catch (error) {
          hilog.error(DOMAIN, TAG, `Error in onMapClick listener: ${error}`);
        }
      }
    }
  }

  private notifyMapLongClick(x: number, y: number): void {
    // 1. Notify MapLibreMap first (Android-style priority).
    let consumed = false;
    if (this.mapLibreMapInstance) {
      consumed = this.mapLibreMapInstance._notifyMapLongClick(x, y);
    }

    // 2. If not consumed, fall back to local listeners.
    if (!consumed) {
      for (const listener of this.longClickListeners) {
        try {
          if (listener.onMapLongClick(x, y)) {
            break; // Stop propagation once consumed.
          }
        } catch (error) {
          hilog.error(DOMAIN, TAG, `Error in onMapLongClick listener: ${error}`);
        }
      }
    }
  }

  private notifyDoubleTap(x: number, y: number): void {
    for (const listener of this.doubleTapListeners) {
      try {
        if (listener.onDoubleTap(x, y)) {
          break; // Stop propagation once consumed.
        }
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onDoubleTap listener: ${error}`);
      }
    }
  }

  private notifyTiltBegin(): void {
    // Notify tilt listeners
    for (const listener of this.tiltListeners) {
      try {
        listener.onTiltBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTiltBegin listener: ${error}`);
      }
    }
    // Also notify shove listeners (Android naming compatibility)
    for (const listener of this.shoveListeners) {
      try {
        listener.onShoveBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onShoveBegin listener: ${error}`);
      }
    }
  }

  private notifyTilt(pitch: number): void {
    // Notify tilt listeners
    for (const listener of this.tiltListeners) {
      try {
        listener.onTilt(pitch);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTilt listener: ${error}`);
      }
    }
    // Also notify shove listeners (Android naming compatibility)
    for (const listener of this.shoveListeners) {
      try {
        listener.onShove(pitch);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onShove listener: ${error}`);
      }
    }
  }

  private notifyTiltEnd(): void {
    // Notify tilt listeners
    for (const listener of this.tiltListeners) {
      try {
        listener.onTiltEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onTiltEnd listener: ${error}`);
      }
    }
    // Also notify shove listeners (Android naming compatibility)
    for (const listener of this.shoveListeners) {
      try {
        listener.onShoveEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onShoveEnd listener: ${error}`);
      }
    }
  }

  private notifyQuickZoomBegin(): void {
    for (const listener of this.quickZoomListeners) {
      try {
        listener.onQuickZoomBegin();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onQuickZoomBegin listener: ${error}`);
      }
    }
  }

  private notifyQuickZoom(zoom: number): void {
    for (const listener of this.quickZoomListeners) {
      try {
        listener.onQuickZoom(zoom);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onQuickZoom listener: ${error}`);
      }
    }
  }

  private notifyQuickZoomEnd(): void {
    for (const listener of this.quickZoomListeners) {
      try {
        listener.onQuickZoomEnd();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Error in onQuickZoomEnd listener: ${error}`);
      }
    }
  }
}

