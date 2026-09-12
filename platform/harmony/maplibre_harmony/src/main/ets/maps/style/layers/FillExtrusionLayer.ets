/**
 * FillExtrusionLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';

import type { PropertyValue } from '../expressions/index';

import { convertValue } from './LayerUtils';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class FillExtrusionLayer extends SourcedLayer<maplibre.FillExtrusionLayer, FillExtrusionLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'FillExtrusionLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.FillExtrusionLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.FillExtrusionLayer(id, sid), "FillExtrusionLayer"));
  }

  static create(id: string, sourceId: string = ""): FillExtrusionLayer {
    return new FillExtrusionLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.FillExtrusionLayer): FillExtrusionLayer {
    return new FillExtrusionLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  setFillExtrusionVerticalGradient(gradient: PropertyValue<boolean>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionVerticalGradient(convertValue(gradient));
    return this;
  }

  getFillExtrusionVerticalGradient(): boolean | undefined {
    return this.nativeInstance.getFillExtrusionVerticalGradient();
  }

  // ========== FillExtrusion style property helpers ==========

  setFillExtrusionColor(color: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionColor(convertValue(color));
    return this;
  }

  setFillExtrusionOpacity(opacity: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionOpacity(convertValue(opacity));
    return this;
  }

  setFillExtrusionHeight(height: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionHeight(convertValue(height));
    return this;
  }

  setFillExtrusionBase(base: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionBase(convertValue(base));
    return this;
  }

  setFillExtrusionPattern(pattern: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionPattern(convertValue(pattern));
    return this;
  }

  setFillExtrusionTranslate(translate: PropertyValue<[number, number]>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslate(convertValue(translate) as import('libmaplibre.so').PropertyValue<[number, number]>);
    return this;
  }

  setFillExtrusionTranslateAnchor(anchor: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslateAnchor(convertValue(anchor) as string);
    return this;
  }

  getFillExtrusionTranslateAnchor(): string | undefined {
    return this.nativeInstance.getFillExtrusionTranslateAnchor();
  }

}
