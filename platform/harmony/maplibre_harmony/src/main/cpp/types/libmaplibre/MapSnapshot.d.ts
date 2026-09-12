/**
 * MapSnapshot - map snapshot result type definitions.
 *
 * Mirrors Android's MapSnapshot.
 */

import { LatLng } from './NativeMapView';

/**
 * MapSnapshot interface.
 *
 * Snapshot result object that contains image data and coordinate conversion helpers.
 */
export interface MapSnapshot {
  /**
   * Image data (ArrayBuffer, RGBA).
   */
  data: ArrayBuffer;
  
  /**
   * Image width in pixels.
   */
  width: number;
  
  /**
   * Image height in pixels.
   */
  height: number;
  
  /**
   * Pixel ratio.
   */
  pixelRatio: number;
  
  /**
   * Attribution strings.
   */
  attributions?: string[];
  
  /**
   * Convert geographic coordinates to snapshot pixel coordinates.
   *
   * Matches Android's `MapSnapshot.pixelForLatLng(LatLng)`.
   *
   * @param latitude Latitude.
   * @param longitude Longitude.
   * @returns Pixel coordinate {x, y}.
   */
  pixelForLatLng(latitude: number, longitude: number): { x: number; y: number; };
  
  /**
   * Convert snapshot pixel coordinates to geographic coordinates.
   *
   * Matches Android's `MapSnapshot.latLngForPixel(PointF)`.
   *
   * @param x Pixel X coordinate.
   * @param y Pixel Y coordinate.
   * @returns Geographic coordinate.
   */
  latLngForPixel(x: number, y: number): LatLng;
}

