/**
 * ListenerFactories - concrete class implementations of listener/handler interfaces.
 *
 * These classes wrap callback lambdas into properly-typed interface instances
 * for use with MapLibre APIs. Use `new` directly instead of factory functions.
 */

import {
  // Snapshot types
  MapSnapshot, SnapshotReadyCallback, SnapshotErrorHandler,
  // Camera animation types
  CameraAnimationCallback,
  // Camera listener types
  OnCameraIdleListener,
  // Gesture listener types
  OnMapClickListener, OnMapLongClickListener,
  // Marker listener types
  OnMarkerClickListener, Marker,
  // Style listener types
  OnStyleLoadedListener, Style,
  // Location listener types
  OnCameraTrackingChangedListener,
} from 'maplibre_harmony';

// ========== Snapshot ==========

/**
 * Concrete implementation of SnapshotReadyCallback.
 */
export class SnapshotReadyCallbackImpl implements SnapshotReadyCallback {
  private handlerFn: (snapshot: MapSnapshot) => void;

  constructor(handler: (snapshot: MapSnapshot) => void) {
    this.handlerFn = handler;
  }

  onSnapshotReady(snapshot: MapSnapshot): void {
    this.handlerFn(snapshot);
  }
}

/**
 * Concrete implementation of SnapshotErrorHandler.
 */
export class SnapshotErrorHandlerImpl implements SnapshotErrorHandler {
  private handlerFn: (error: string) => void;

  constructor(handler: (error: string) => void) {
    this.handlerFn = handler;
  }

  onError(error: string): void {
    this.handlerFn(error);
  }
}

// ========== Camera Animation ==========

/**
 * Concrete implementation of CameraAnimationCallback.
 * Helps avoid type mismatches when using object literals.
 */
export class CameraAnimationCallbackImpl implements CameraAnimationCallback {
  private finishFn: () => void;
  private cancelFn?: () => void;

  constructor(onFinish: () => void, onCancel?: () => void) {
    this.finishFn = onFinish;
    this.cancelFn = onCancel;
  }

  onFinish(): void {
    this.finishFn();
  }

  onCancel(): void {
    if (this.cancelFn) {
      this.cancelFn();
    }
  }
}

// ========== Camera Idle Listener ==========

/**
 * Concrete implementation of OnCameraIdleListener.
 */
export class CameraIdleListener implements OnCameraIdleListener {
  private handler: () => void;

  constructor(handler: () => void) {
    this.handler = handler;
  }

  onCameraIdle(): void {
    this.handler();
  }
}

// ========== Gesture Listeners ==========

/**
 * Concrete implementation of OnMapClickListener.
 */
export class MapClickListener implements OnMapClickListener {
  private handler: (x: number, y: number) => boolean;

  constructor(handler: (x: number, y: number) => boolean) {
    this.handler = handler;
  }

  onMapClick(x: number, y: number): boolean {
    return this.handler(x, y);
  }
}

/**
 * Concrete implementation of OnMapLongClickListener.
 */
export class MapLongClickListener implements OnMapLongClickListener {
  private handler: (x: number, y: number) => boolean;

  constructor(handler: (x: number, y: number) => boolean) {
    this.handler = handler;
  }

  onMapLongClick(x: number, y: number): boolean {
    return this.handler(x, y);
  }
}

// ========== Marker Click Listener ==========

/**
 * Concrete implementation of OnMarkerClickListener.
 */
export class MarkerClickListener implements OnMarkerClickListener {
  private handler: (marker: Marker) => boolean;

  constructor(handler: (marker: Marker) => boolean) {
    this.handler = handler;
  }

  onMarkerClick(marker: Marker): boolean {
    return this.handler(marker);
  }
}

// ========== Style Loaded Listener ==========

/**
 * Concrete implementation of OnStyleLoadedListener.
 */
export class StyleLoadedListener implements OnStyleLoadedListener {
  private handler: (style: Style | null) => void;

  constructor(handler: (style: Style | null) => void) {
    this.handler = handler;
  }

  onStyleLoaded(style: Style | null): void {
    this.handler(style);
  }
}

// ========== Camera Tracking Changed Listener ==========

/**
 * Concrete implementation of OnCameraTrackingChangedListener.
 *
 * @param handler Callback invoked when camera tracking changes.
 * @param dismissedHandler Optional callback invoked when camera tracking is dismissed.
 */
export class CameraTrackingChangedListener implements OnCameraTrackingChangedListener {
  private handler: (currentMode: number) => void;
  private dismissedHandler?: () => void;

  constructor(handler: (currentMode: number) => void, dismissedHandler?: () => void) {
    this.handler = handler;
    this.dismissedHandler = dismissedHandler;
  }

  onCameraTrackingChanged(currentMode: number): void {
    this.handler(currentMode);
  }

  onCameraTrackingDismissed(): void {
    if (this.dismissedHandler) {
      this.dismissedHandler();
    }
  }
}
