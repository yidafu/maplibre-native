/**
 * CustomDrawableLayer - Wrapper for drawable-based custom layers
 *
 * Upstream counterpart: mbgl::style::CustomDrawableLayer (iOS
 * MLNCustomDrawableStyleLayer). The host's update() callback runs on the
 * render thread, so a JS host cannot manipulate drawables synchronously;
 * instead this wrapper keeps a declarative scene: JS calls
 * addPolyline/addFill/clear and the native host rebuilds the drawables on
 * the next frame.
 */

import maplibre from 'libmaplibre.so';
import { BaseLayer, LayerInternalTag, resolveLayerNative } from './BaseLayer';

/**
 * Line draw options
 */
export interface DrawableLineOptions {
  /** Line color as CSS string or [r, g, b, (a)] array (0-1 floats) */
  color?: string | number[];
  /** Line width in pixels (default 1) */
  width?: number;
  /** Line blur in pixels (default 0) */
  blur?: number;
  /** Line opacity 0-1 (default 1) */
  opacity?: number;
  /** Gap width for double strokes (default 0) */
  gapWidth?: number;
  /** Line offset (default 0) */
  offset?: number;
  /** Cap style: 'butt' | 'round' | 'square' (default 'butt') */
  beginCap?: string;
  /** Cap style: 'butt' | 'round' | 'square' (default 'butt') */
  endCap?: string;
  /** Join style: 'miter' | 'bevel' | 'round' (default 'miter') */
  join?: string;
  /** Shader flavor: 'classic' | 'widevector' (default 'classic') */
  shaderType?: string;
}

/**
 * Fill draw options
 */
export interface DrawableFillOptions {
  /** Fill color as CSS string or [r, g, b, (a)] array (0-1 floats) */
  color?: string | number[];
  /** Fill opacity 0-1 (default 1) */
  opacity?: number;
}

/**
 * CustomDrawableLayer implementation
 */
export class CustomDrawableLayer extends BaseLayer<maplibre.CustomDrawableLayer, CustomDrawableLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'CustomDrawableLayer';

  constructor(idOrMarker: string | LayerInternalTag, nativeOrNothing?: maplibre.CustomDrawableLayer) {
    super(resolveLayerNative(idOrMarker, "", nativeOrNothing, (id) => new maplibre.CustomDrawableLayer(id), "CustomDrawableLayer"));
  }

  static create(id: string): CustomDrawableLayer {
    return new CustomDrawableLayer(id);
  }

  static fromNative(nativeInstance: maplibre.CustomDrawableLayer): CustomDrawableLayer {
    return new CustomDrawableLayer(LayerInternalTag.INSTANCE, nativeInstance);
  }

  /**
   * Add a polyline from geographic coordinates.
   *
   * The scene is rebuilt on the render thread; new drawables appear on the
   * following frame.
   *
   * @param coordinates [[lng, lat], ...] vertex list
   * @param options Optional line styling
   */
  addPolyline(coordinates: number[][], options?: DrawableLineOptions): CustomDrawableLayer {
    this.nativeInstance.addPolyline(coordinates, options);
    return this;
  }

  /**
   * Add an area fill from geographic rings.
   *
   * @param rings [[[lng, lat], ...], ...] - first ring is the outer shell,
   * remaining rings are holes (winding order follows GeoJSON conventions)
   * @param options Optional fill styling
   */
  addFill(rings: number[][][], options?: DrawableFillOptions): CustomDrawableLayer {
    this.nativeInstance.addFill(rings, options);
    return this;
  }

  /**
   * Remove all drawables from the scene
   */
  clear(): CustomDrawableLayer {
    this.nativeInstance.clear();
    return this;
  }
}
