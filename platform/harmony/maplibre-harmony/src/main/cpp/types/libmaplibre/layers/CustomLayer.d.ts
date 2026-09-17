/**
 * MapLibre Native for HarmonyOS - CustomLayer type definitions.
 * Custom layer API (NAPI class).
 */

/**
 * CustomLayer - custom rendering layer.
 *
 * Lets developers provide bespoke rendering logic.
 *
 * Note: simplified implementation; comprehensive features will follow later.
 */
export class CustomLayer {
  /**
   * Create a custom layer.
   * @param layerId Layer identifier.
   */
  constructor(layerId: string);

  /**
   * Get the layer identifier.
   */
  getId(): string;

  /**
   * Get the layer type.
   */
  getType(): string;

  /**
   * Set layer visibility.
   */
  setVisibility(visibility: 'visible' | 'none'): this;

  getVisibility(): 'visible' | 'none';

  /**
   * Configure minimum/maximum zoom levels.
   */
  setMinZoom(zoom: number): this;

  getMinZoom(): number;

  setMaxZoom(zoom: number): this;

  getMaxZoom(): number;

  /**
   * Set custom layer color (RGBA).
   * @param r Red channel (0.0 - 1.0).
   * @param g Green channel (0.0 - 1.0).
   * @param b Blue channel (0.0 - 1.0).
   * @param a Alpha channel (0.0 - 1.0).
   */
  setColor(r: number, g: number, b: number, a: number): this;

  /**
   * Get custom layer color.
   * @returns Color array [r, g, b, a].
   */
  getColor(): number[];
}

