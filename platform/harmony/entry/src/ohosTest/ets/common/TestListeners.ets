/**
 * TestListeners - concrete listener implementations for ohosTest suites.
 *
 * ArkTS rejects object literals typed against interfaces that come from
 * another compilation unit (the maplibre_harmony HAR), so tests must pass
 * concrete class instances instead of `{ ... }` literals.
 * Mirrors the pattern used by `entry/src/main/ets/utils/ListenerFactories.ets`.
 */
import {
  Marker,
  Style,
  OnStyleLoadedListener,
  OnCameraIdleListener,
  OnCameraMoveStartedListener,
  OnCameraMoveListener,
  OnCameraMoveCanceledListener,
  OnFpsChangedListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnMarkerClickListener,
  CameraMoveReason
} from 'maplibre_harmony';

export class TestStyleLoadedListener implements OnStyleLoadedListener {
  private handler: (style: Style | null) => void;

  constructor(handler: (style: Style | null) => void) {
    this.handler = handler;
  }

  onStyleLoaded(style: Style | null): void {
    this.handler(style);
  }
}

export class TestCameraIdleListener implements OnCameraIdleListener {
  onCameraIdle(): void {}
}

export class TestCameraMoveStartedListener implements OnCameraMoveStartedListener {
  onCameraMoveStarted(reason: CameraMoveReason): void {}
}

export class TestCameraMoveListener implements OnCameraMoveListener {
  onCameraMove(): void {}
}

export class TestCameraMoveCanceledListener implements OnCameraMoveCanceledListener {
  onCameraMoveCanceled(): void {}
}

export class TestFpsChangedListener implements OnFpsChangedListener {
  onFpsChanged(fps: number): void {}
}

export class TestMapClickListener implements OnMapClickListener {
  onMapClick(x: number, y: number): boolean {
    return false;
  }
}

export class TestMapLongClickListener implements OnMapLongClickListener {
  onMapLongClick(x: number, y: number): boolean {
    return false;
  }
}

export class TestMarkerClickListener implements OnMarkerClickListener {
  private handler: (marker: Marker) => boolean;

  constructor(handler: (marker: Marker) => boolean) {
    this.handler = handler;
  }

  onMarkerClick(marker: Marker): boolean {
    return this.handler(marker);
  }
}
