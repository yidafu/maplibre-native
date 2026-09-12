/**
 * BackgroundLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';

import type { PropertyValue } from '../expressions/index';
import { convertValue } from './LayerUtils';
import { LayerInternalTag, PropertyLayer, resolveLayerNative } from './BaseLayer';

export class BackgroundLayer extends PropertyLayer<maplibre.BackgroundLayer, BackgroundLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'BackgroundLayer';

  constructor(idOrMarker: string | LayerInternalTag, nativeOrNothing?: maplibre.BackgroundLayer) {
    super(resolveLayerNative(idOrMarker, "", nativeOrNothing, (id) => new maplibre.BackgroundLayer(id), "BackgroundLayer"));
  }

  static create(id: string): BackgroundLayer {
    return new BackgroundLayer(id);
  }

  static fromNative(nativeInstance: maplibre.BackgroundLayer): BackgroundLayer {
    return new BackgroundLayer(LayerInternalTag.INSTANCE, nativeInstance);
  }

  setBackgroundColor(color: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundColor(convertValue(color));
    return this;
  }

  setBackgroundOpacity(opacity: PropertyValue<number>): BackgroundLayer {
    this.nativeInstance.setBackgroundOpacity(convertValue(opacity));
    return this;
  }

  setBackgroundPattern(pattern: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundPattern(convertValue(pattern));
    return this;
  }

  // ========== Getter helpers ==========

  getBackgroundColor(): string | undefined {
    return this.nativeInstance.getBackgroundColor();
  }

  getBackgroundOpacity(): number | undefined {
    return this.nativeInstance.getBackgroundOpacity();
  }

}
