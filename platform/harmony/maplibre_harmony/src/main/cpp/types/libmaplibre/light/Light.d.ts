import type { LightSpecification, TransitionOptions } from '../CommonTypes';

/**
 * Light - style lighting controller.
 *
 * Mirrors the Android/iOS Light API, exposing anchor, position, color, intensity, and transition configuration.
 * Retrieve instances via Style.getLight() or MapLibreMap.getLight(); do not construct directly.
 */
export class Light {
  /**
   * Get the light anchor.
   * @returns 'map' or 'viewport'.
   */
  getAnchor(): 'map' | 'viewport';

  /**
   * Set the light anchor.
   * @param anchor 'map' or 'viewport'.
   */
  setAnchor(anchor: 'map' | 'viewport'): void;

  /**
   * Get the light position in spherical coordinates.
   * @returns Object with radial, azimuthal, and polar values (same units as MapLibre style spec).
   */
  getPosition(): { radial: number; azimuthal: number; polar: number };

  /**
   * Set the light position in spherical coordinates.
   * @param position Object { radial, azimuthal, polar } or array [radial, azimuthal, polar?].
   */
  setPosition(position: { radial: number; azimuthal: number; polar?: number } | number[]): void;

  /**
   * Get the position transition.
   * @returns Transition configuration (milliseconds).
   */
  getPositionTransition(): TransitionOptions;

  /**
   * Set the position transition.
   * @param duration Duration in milliseconds.
   * @param delay Delay in milliseconds.
   */
  setPositionTransition(duration: number, delay: number): void;

  /**
   * Get the light color.
   * @returns CSS color string.
   */
  getColor(): string;

  /**
   * Set the light color.
   * @param color CSS color string.
   */
  setColor(color: string): void;

  /**
   * Get the color transition.
   */
  getColorTransition(): TransitionOptions;

  /**
   * Set the color transition.
   * @param duration Duration in milliseconds.
   * @param delay Delay in milliseconds.
   */
  setColorTransition(duration: number, delay: number): void;

  /**
   * Get the light intensity.
   * @returns Intensity (0-1).
   */
  getIntensity(): number;

  /**
   * Set the light intensity.
   * @param intensity Intensity (0-1).
   */
  setIntensity(intensity: number): void;

  /**
   * Get the intensity transition.
   */
  getIntensityTransition(): TransitionOptions;

  /**
   * Set the intensity transition.
   * @param duration Duration in milliseconds.
   * @param delay Delay in milliseconds.
   */
  setIntensityTransition(duration: number, delay: number): void;

}

