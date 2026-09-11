/**
 * MapLibre Native for HarmonyOS - CustomDrawableLayer type definitions.
 * Drawable-based custom layer API (NAPI class).
 */

/**
 * Line draw options.
 */
export interface DrawableLineOptions {
  color?: string | number[];
  width?: number;
  blur?: number;
  opacity?: number;
  gapWidth?: number;
  offset?: number;
  beginCap?: string;
  endCap?: string;
  join?: string;
  shaderType?: string;
}

/**
 * Fill draw options.
 */
export interface DrawableFillOptions {
  color?: string | number[];
  opacity?: number;
}

/**
 * CustomDrawableLayer - drawable-based custom layer.
 *
 * JS authors a declarative scene (addPolyline/addFill/clear); the native
 * host rebuilds the drawables on the render thread.
 */
export class CustomDrawableLayer {
  /**
   * Create a custom drawable layer.
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

  setVisibility(visibility: 'visible' | 'none'): this;

  getVisibility(): 'visible' | 'none';

  setMinZoom(zoom: number): this;

  getMinZoom(): number;

  setMaxZoom(zoom: number): this;

  getMaxZoom(): number;

  /**
   * Add a polyline from geographic coordinates.
   * @param coordinates [[lng, lat], ...] vertex list.
   * @param options Optional line styling.
   * @returns this (chainable).
   */
  addPolyline(coordinates: number[][], options?: DrawableLineOptions): this;

  /**
   * Add an area fill from geographic rings.
   * @param rings [[[lng, lat], ...], ...] outer shell first, then holes.
   * @param options Optional fill styling.
   * @returns this (chainable).
   */
  addFill(rings: number[][][], options?: DrawableFillOptions): this;

  /**
   * Remove all drawables from the scene.
   * @returns this (chainable).
   */
  clear(): this;
}
