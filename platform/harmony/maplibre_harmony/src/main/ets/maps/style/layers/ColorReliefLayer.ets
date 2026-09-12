/**
 * ColorReliefLayer - Wrapper class
 * Wraps the NAPI ColorReliefLayer for terrain RGB rendering.
 * Properties:
 *   - colorReliefColor (ColorRampPropertyValue)
 *   - colorReliefOpacity (PropertyValue<number>)
 */
import maplibre from 'libmaplibre.so';

import { Expression } from '../expressions/index';
import { convertValue } from './LayerUtils';
import { PropertyValue } from '../expressions/Expression';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class ColorReliefLayer extends SourcedLayer<maplibre.ColorReliefLayer, ColorReliefLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'ColorReliefLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.ColorReliefLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.ColorReliefLayer(id, sid), "ColorReliefLayer"));
  }

  static create(id: string, sourceId: string = ""): ColorReliefLayer {
    return new ColorReliefLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.ColorReliefLayer): ColorReliefLayer {
    return new ColorReliefLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  // ========== ColorRelief style property helpers ==========

  setColorReliefColor(color: PropertyValue<string>): ColorReliefLayer {
    this.nativeInstance.setColorReliefColor(convertValue(color));
    return this;
  }

  setColorReliefOpacity(opacity: PropertyValue<number>): ColorReliefLayer {
    this.nativeInstance.setColorReliefOpacity(convertValue(opacity));
    return this;
  }

  getColorReliefColor(): string | undefined {
    return this.nativeInstance.getColorReliefColor();
  }

  getColorReliefOpacity(): number | undefined {
    return this.nativeInstance.getColorReliefOpacity();
  }

}
