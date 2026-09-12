/**
 * HillshadeLayer - Wrapper class
 */

import maplibre from 'libmaplibre.so';

import { Expression } from '../expressions/index';
import { convertValue } from './LayerUtils';
import { PropertyValue } from '../expressions/Expression';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class HillshadeLayer extends SourcedLayer<maplibre.HillshadeLayer, HillshadeLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'HillshadeLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.HillshadeLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.HillshadeLayer(id, sid), "HillshadeLayer"));
  }

  static create(id: string, sourceId: string = ""): HillshadeLayer {
    return new HillshadeLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.HillshadeLayer): HillshadeLayer {
    return new HillshadeLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  // ========== Hillshade style property helpers ==========

  setHillshadeIlluminationDirection(direction: PropertyValue<number>): HillshadeLayer {
    this.nativeInstance.setHillshadeIlluminationDirection(convertValue(direction));
    return this;
  }

  setHillshadeExaggeration(exaggeration: PropertyValue<number>): HillshadeLayer {
    this.nativeInstance.setHillshadeExaggeration(convertValue(exaggeration));
    return this;
  }

}
