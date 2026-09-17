/**
 * Common Type Definitions for MapLibre Native HarmonyOS
 * 
 * Shared type definitions used across the project to improve type safety.
 */

/**
 * JSONValue - JSON-serializable value type.
 *
 * Represents every value accepted by JSON.stringify/parse.
 * Used for dynamic properties, GeoJSON properties, and similar scenarios.
 */
export type JSONValue = 
  | string 
  | number 
  | boolean 
  | null 
  | JSONValue[] 
  | JSONObject;

/**
 * JSONObject - JSON object type.
 *
 * Represents a key-value object whose values are JSON-serializable.
 */
export type JSONObject = { [key: string]: JSONValue };

/**
 * LightSpecification - lighting configuration specification.
 *
 * Defines 3D lighting for the map.
 * @see https://maplibre.org/maplibre-style-spec/light/
 */
export interface LightSpecification {
  /**
   * Light anchor.
   * - 'map': light rotates with the map.
   * - 'viewport': light stays fixed to the viewport.
   */
  anchor?: 'map' | 'viewport';

  /**
   * Light position [azimuth, polar].
   * - Azimuth: horizontal angle around the map center (0-360).
   * - Polar: angle relative to the ground plane (0-90).
   */
  position?: [number, number] | [number, number, number];

  /**
   * Light color.
   * CSS color value such as '#ffffff' or 'rgb(255,255,255)'.
   */
  color?: string;

  /**
   * Light intensity.
   * Range 0-1, default 0.5.
   */
  intensity?: number;
}

/**
 * TransitionOptions - transition animation options.
 *
 * Defines how style properties transition when they change.
 */
export interface TransitionOptions {
  /**
   * Transition duration in milliseconds.
   */
  duration?: number;

  /**
   * Transition delay in milliseconds.
   */
  delay?: number;
}

/**
 * MapSnapshotterObserver - snapshot observer interface.
 *
 * Listens to snapshotter state changes.
 */
export interface MapSnapshotterObserver {
  /**
   * Invoked when the style finishes loading.
   */
  onDidFinishLoadingStyle(): void;

  /**
   * Invoked when a style image is missing.
   * @param imageName Name of the missing image.
   */
  onStyleImageMissing(imageName: string): void;
}

