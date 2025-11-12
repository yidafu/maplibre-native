/**
 * Gesture listener interface definitions.
 *
 * Inspired by Android `MapGestureDetector` and iOS `MLNMapView` gesture listener designs.
 */

/**
 * Pan gesture listener.
 * Triggered when the user drags the map with one finger.
 */
export interface OnMoveListener {
  /**
   * Pan gesture begins.
   */
  onMoveBegin(): void;

  /**
   * Pan gesture in progress.
   * @param distanceX Movement along the X axis (pixels).
   * @param distanceY Movement along the Y axis (pixels).
   */
  onMove(distanceX: number, distanceY: number): void;

  /**
   * Pan gesture ends.
   */
  onMoveEnd(): void;
}

/**
 * Scale gesture listener.
 * Triggered when the user pinches or spreads two fingers.
 */
export interface OnScaleListener {
  /**
   * Scale gesture begins.
   * @param focalX Focal point X coordinate.
   * @param focalY Focal point Y coordinate.
   */
  onScaleBegin(focalX: number, focalY: number): void;

  /**
   * Scale gesture in progress.
   * @param scaleFactor Scale factor (>1 to zoom in, <1 to zoom out).
   * @param focalX Focal point X coordinate.
   * @param focalY Focal point Y coordinate.
   */
  onScale(scaleFactor: number, focalX: number, focalY: number): void;

  /**
   * Scale gesture ends.
   */
  onScaleEnd(): void;
}

/**
 * Rotate gesture listener.
 * Triggered when the user rotates with two fingers.
 */
export interface OnRotateListener {
  /**
   * Rotate gesture begins.
   * @param focalX Rotation focal point X coordinate.
   * @param focalY Rotation focal point Y coordinate.
   */
  onRotateBegin(focalX: number, focalY: number): void;

  /**
   * Rotate gesture in progress.
   * @param rotationDelta Rotation delta (degrees).
   * @param focalX Rotation focal point X coordinate.
   * @param focalY Rotation focal point Y coordinate.
   */
  onRotate(rotationDelta: number, focalX: number, focalY: number): void;

  /**
   * Rotate gesture ends.
   */
  onRotateEnd(): void;
}

/**
 * Map tap listener.
 */
export interface OnMapClickListener {
  /**
   * Map tap event.
   * @param x Tap position X coordinate.
   * @param y Tap position Y coordinate.
   * @returns Whether the event was consumed.
   */
  onMapClick(x: number, y: number): boolean;
}

/**
 * Map long-press listener.
 */
export interface OnMapLongClickListener {
  /**
   * Map long-press event.
   * @param x Long-press position X coordinate.
   * @param y Long-press position Y coordinate.
   * @returns Whether the event was consumed.
   */
  onMapLongClick(x: number, y: number): boolean;
}

/**
 * Double-tap listener (reserved for future extensions).
 */
export interface OnDoubleTapListener {
  /**
   * Map double-tap event.
   * @param x Double-tap position X coordinate.
   * @param y Double-tap position Y coordinate.
   * @returns Whether the event was consumed.
   */
  onDoubleTap(x: number, y: number): boolean;
}

/**
 * Fling listener (reserved for future extensions).
 */
export interface OnFlingListener {
  /**
   * Fling event.
   * @param velocityX Velocity along the X axis.
   * @param velocityY Velocity along the Y axis.
   */
  onFling(velocityX: number, velocityY: number): void;
}

/**
 * Two-finger tap listener (reserved for future extensions).
 */
export interface OnTwoFingerTapListener {
  /**
   * Two-finger tap event.
   * @param x Tap position X coordinate.
   * @param y Tap position Y coordinate.
   */
  onTwoFingerTap(x: number, y: number): void;
}

/**
 * Tilt gesture listener.
 * Triggered when the user drags two fingers vertically to adjust pitch.
 */
export interface OnTiltListener {
  /**
   * Tilt gesture begins.
   */
  onTiltBegin(): void;

  /**
   * Tilt gesture in progress.
   * @param pitch Current pitch angle (degrees, 0-60).
   */
  onTilt(pitch: number): void;

  /**
   * Tilt gesture ends.
   */
  onTiltEnd(): void;
}

/**
 * Shove gesture listener (Android naming).
 * Triggered when the user drags two fingers vertically to adjust pitch.
 * Equivalent to `OnTiltListener`, provided for Android-style compatibility.
 *
 * Reference: Android `MapLibreMap.OnShoveListener`.
 */
export interface OnShoveListener {
  /**
   * Shove gesture begins.
   */
  onShoveBegin(): void;

  /**
   * Shove gesture in progress.
   * @param pitch Current pitch angle (degrees, 0-60).
   */
  onShove(pitch: number): void;

  /**
   * Shove gesture ends.
   */
  onShoveEnd(): void;
}

/**
 * Quick Zoom listener.
 * Triggered when the user double-taps and drags to zoom quickly.
 */
export interface OnQuickZoomListener {
  /**
   * Quick Zoom begins.
   */
  onQuickZoomBegin(): void;

  /**
   * Quick Zoom in progress.
   * @param zoom Current zoom level.
   */
  onQuickZoom(zoom: number): void;

  /**
   * Quick Zoom ends.
   */
  onQuickZoomEnd(): void;
}

/**
 * Touch move listener.
 * Triggered whenever a finger moves on screen (regardless of finger count).
 * Useful for marker dragging or other continuous touch tracking.
 */
export interface OnTouchMoveListener {
  /**
   * Touch move event.
   * @param x Current touch X coordinate (screen coordinates).
   * @param y Current touch Y coordinate (screen coordinates).
   * @returns Whether the event was consumed (returning true prevents other listeners from receiving it).
   */
  onTouchMove(x: number, y: number): boolean;
}

/**
 * Touch release listener.
 * Triggered when the finger lifts from the screen.
 * Useful for marker drag completion or other touch-end detection.
 */
export interface OnTouchUpListener {
  /**
   * Touch release event.
   * @param x Release position X coordinate (screen coordinates).
   * @param y Release position Y coordinate (screen coordinates).
   * @returns Whether the event was consumed (returning true prevents other listeners from receiving it).
   */
  onTouchUp(x: number, y: number): boolean;
}

