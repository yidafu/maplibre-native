/**
 * FillLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';

import { PropertyValue } from '../expressions/Expression';
import { convertValue } from './LayerUtils';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class FillLayer extends SourcedLayer<maplibre.FillLayer, FillLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'FillLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.FillLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.FillLayer(id, sid), "FillLayer"));
  }

  static create(id: string, sourceId: string = ""): FillLayer {
    return new FillLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.FillLayer): FillLayer {
    return new FillLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  // ========== Fill style property helpers ==========

  setFillColor(color: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillColor(convertValue(color));
    return this;
  }

  setFillOpacity(opacity: PropertyValue<number>): FillLayer {
    this.nativeInstance.setFillOpacity(convertValue(opacity));
    return this;
  }

  setFillOutlineColor(color: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillOutlineColor(convertValue(color));
    return this;
  }

  setFillPattern(pattern: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillPattern(convertValue(pattern));
    return this;
  }

  setFillAntialias(antialias: PropertyValue<boolean>): FillLayer {
    this.nativeInstance.setFillAntialias(convertValue(antialias));
    return this;
  }

  setFillTranslate(translate: PropertyValue<number[]>): FillLayer {
    this.nativeInstance.setFillTranslate(convertValue(translate));
    return this;
  }

  setFillTranslateAnchor(anchor: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillTranslateAnchor(convertValue(anchor));
    return this;
  }

  setFillSortKey(sortKey: PropertyValue<number>): FillLayer {
    this.nativeInstance.setFillSortKey(convertValue(sortKey));
    return this;
  }

  // ========== Getter helpers ==========

  getFillColor(): string | undefined {
    return this.nativeInstance.getFillColor();
  }

  getFillOpacity(): number | undefined {
    return this.nativeInstance.getFillOpacity();
  }

  getFillTranslateAnchor(): string | undefined {
    return this.nativeInstance.getFillTranslateAnchor();
  }

  getFillSortKey(): number | undefined {
    return this.nativeInstance.getFillSortKey();
  }
}
