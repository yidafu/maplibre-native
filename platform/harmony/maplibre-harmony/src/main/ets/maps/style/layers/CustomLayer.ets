/**
 * CustomLayer - Wrapper for custom rendering layers
 *
 * Android counterpart: org.maplibre.android.style.layers.CustomLayer
 *
 * Enables developers to render directly on the map using OpenGL ES
 */
import maplibre from 'libmaplibre.so';
import { BaseLayer, LayerInternalTag, resolveLayerNative } from './BaseLayer';

/**
 * RGBA color interface
 */
export interface RGBAColor {
  r: number; // Red component (0.0 - 1.0)
  g: number; // Green component (0.0 - 1.0)
  b: number; // Blue component (0.0 - 1.0)
  a: number; // Alpha component (0.0 - 1.0)
}

/**
 * CustomLayer - Custom rendering layer
 *
 * Allows developers to render custom content on the map via OpenGL ES
 *
 * @example
* ```typescript
 * const customLayer = new CustomLayer('custom-layer');
 * customLayer.setColor(1.0, 0.0, 0.0, 0.5);  // semi-transparent red
 * map.getStyle().addLayer(customLayer);
 * ```
 */
export class CustomLayer extends BaseLayer<maplibre.CustomLayer, CustomLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'CustomLayer';

  constructor(idOrMarker: string | LayerInternalTag, nativeOrNothing?: maplibre.CustomLayer) {
    super(resolveLayerNative(idOrMarker, "", nativeOrNothing, (id) => new maplibre.CustomLayer(id), "CustomLayer"));
  }

  static create(id: string): CustomLayer {
    return new CustomLayer(id);
  }

  static fromNative(nativeInstance: maplibre.CustomLayer): CustomLayer {
    return new CustomLayer(LayerInternalTag.INSTANCE, nativeInstance);
  }

  /**
   * Set the render color (example implementation)
   * @param r Red component (0.0 - 1.0)
   * @param g Green component (0.0 - 1.0)
   * @param b Blue component (0.0 - 1.0)
   * @param a Alpha component (0.0 - 1.0)
   */
  setColor(r: number, g: number, b: number, a: number): CustomLayer {
    this.nativeInstance.setColor(r, g, b, a);
    return this;
  }

  /**
   * Get the current color (example implementation)
   * @returns Color array [r, g, b, a]
   */
  getColor(): number[] {
    return this.nativeInstance.getColor();
  }
}

/**
 * Helper: create a CustomLayer with the specified color
 *
 * @param id Layer identifier
 * @param color Color object
 * @returns CustomLayer instance
 */
export function createCustomLayerWithColor(id: string, color: RGBAColor): CustomLayer {
  const layer = new CustomLayer(id);
  layer.setColor(color.r, color.g, color.b, color.a);
  return layer;
}
