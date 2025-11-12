/**
 * CameraPosition - camera position interfaces.
 * Simplified to ArkTS interfaces.
 */
import { LatLng } from '../geometry/LatLng';

/**
 * EdgeInsets - represents padding around a rectangle.
 */
export interface EdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * CameraPosition - describes map camera position and orientation.
 * 
 * @example
 * ```typescript
 * const position: CameraPosition = {
 *   target: { latitude: 39.9, longitude: 116.4 },
 *   zoom: 15,
 *   bearing: 30,  // Bearing angle (0-360 degrees, 0 = north)
 *   tilt: 45      // Tilt angle (0-60 degrees, 0 = straight down)
 * };
 * ```
 */
export interface CameraPosition {
  /** Target location (latitude/longitude). */
  target: LatLng;
  /** Zoom level. */
  zoom: number;
  /** Bearing angle (0-360, 0 = north). */
  bearing: number;
  /** Tilt angle (0-60, 0 = straight down). */
  tilt: number;
}

/**
 * CameraOptions - configuration for camera parameters (compatible with NAPI CameraOptions).
 */
export interface CameraOptions {
  /** Center coordinate. */
  center?: LatLng;

  /** Zoom level. */
  zoom?: number;

  /** Bearing angle (degrees). */
  bearing?: number;

  /** Pitch/tilt angle (degrees). */
  pitch?: number;

  /** Padding around the viewport. */
  padding?: EdgeInsets;
}

