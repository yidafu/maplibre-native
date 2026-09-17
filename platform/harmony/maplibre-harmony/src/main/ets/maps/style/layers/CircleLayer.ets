/**
 * CircleLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';

import type { PropertyValue } from '../expressions/index';

import { convertValue } from './LayerUtils';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class CircleLayer extends SourcedLayer<maplibre.CircleLayer, CircleLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'CircleLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.CircleLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.CircleLayer(id, sid), "CircleLayer"));
  }

  static create(id: string, sourceId: string = ""): CircleLayer {
    return new CircleLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.CircleLayer): CircleLayer {
    return new CircleLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  // ========== Circle style property helpers ==========

  setCircleRadius(radius: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleRadius(convertValue(radius));
    return this;
  }

  setCircleColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleColor(convertValue(color));
    return this;
  }

  setCircleOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleOpacity(convertValue(opacity));
    return this;
  }

  setCircleBlur(blur: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleBlur(convertValue(blur));
    return this;
  }

  setCircleStrokeWidth(width: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeWidth(convertValue(width));
    return this;
  }

  setCircleStrokeColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleStrokeColor(convertValue(color));
    return this;
  }

  setCircleStrokeOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeOpacity(convertValue(opacity));
    return this;
  }

  setCircleTranslate(translate: PropertyValue<number[]>): CircleLayer {
    this.nativeInstance.setCircleTranslate(convertValue(translate));
    return this;
  }

  setCircleTranslateAnchor(anchor: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleTranslateAnchor(convertValue(anchor));
    return this;
  }

  setCirclePitchScale(scale: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchScale(convertValue(scale));
    return this;
  }

  setCirclePitchAlignment(alignment: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchAlignment(convertValue(alignment));
    return this;
  }

  setCircleSortKey(sortKey: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleSortKey(convertValue(sortKey));
    return this;
  }

  // ========== Getter helpers ==========

  getCircleRadius(): number | undefined {
    return this.nativeInstance.getCircleRadius();
  }

  getCircleColor(): string | undefined {
    return this.nativeInstance.getCircleColor();
  }

  getCircleOpacity(): number | undefined {
    return this.nativeInstance.getCircleOpacity();
  }

  getCircleTranslate(): number[] | undefined {
    return this.nativeInstance.getCircleTranslate();
  }

  getCircleTranslateAnchor(): string | undefined {
    return this.nativeInstance.getCircleTranslateAnchor();
  }

  getCirclePitchScale(): string | undefined {
    return this.nativeInstance.getCirclePitchScale();
  }

  getCirclePitchAlignment(): string | undefined {
    return this.nativeInstance.getCirclePitchAlignment();
  }

  getCircleSortKey(): number | undefined {
    return this.nativeInstance.getCircleSortKey();
  }
}
