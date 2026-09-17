/**
 * LineLayer - Wrapper class
 */
import maplibre, { ExpressionLiteral } from 'libmaplibre.so';

import type { PropertyValue } from '../expressions/index';

import { convertValue } from './LayerUtils';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

export class LineLayer extends SourcedLayer<maplibre.LineLayer, LineLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'LineLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.LineLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.LineLayer(id, sid), "LineLayer"));
  }

  static create(id: string, sourceId: string = ""): LineLayer {
    return new LineLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.LineLayer): LineLayer {
    return new LineLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  // ========== Line style property helpers ==========

  setLineColor(color: PropertyValue<string>): LineLayer {
    this.nativeInstance.setLineColor(convertValue(color));
    return this;
  }

  setLineWidth(width: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineWidth(convertValue(width));
    return this;
  }

  setLineOpacity(opacity: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineOpacity(convertValue(opacity));
    return this;
  }

  setLinePattern(pattern: PropertyValue<string>): LineLayer {
    this.nativeInstance.setLinePattern(convertValue(pattern));
    return this;
  }

  setLineGapWidth(gapWidth: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineGapWidth(convertValue(gapWidth));
    return this;
  }

  setLineDasharray(dasharray: PropertyValue<number[]>): LineLayer {
    this.nativeInstance.setLineDasharray(convertValue(dasharray));
    return this;
  }

  setLineBlur(blur: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineBlur(convertValue(blur));
    return this;
  }

  setLineOffset(offset: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineOffset(convertValue(offset));
    return this;
  }

  setLineCap(cap: PropertyValue<string>): LineLayer {
    this.nativeInstance.setLineCap(convertValue(cap));
    return this;
  }

  setLineJoin(join: PropertyValue<string>): LineLayer {
    this.nativeInstance.setLineJoin(convertValue(join));
    return this;
  }

  setLineTranslate(translate: PropertyValue<number[]>): LineLayer {
    this.nativeInstance.setLineTranslate(convertValue(translate));
    return this;
  }

  setLineTranslateAnchor(anchor: PropertyValue<string>): LineLayer {
    this.nativeInstance.setLineTranslateAnchor(convertValue(anchor));
    return this;
  }

  setLineMiterLimit(limit: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineMiterLimit(convertValue(limit));
    return this;
  }

  setLineRoundLimit(limit: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineRoundLimit(convertValue(limit));
    return this;
  }

  setLineGradient(gradient: PropertyValue<string>): LineLayer {
    this.nativeInstance.setLineGradient(convertValue(gradient));
    return this;
  }

  setLineSortKey(sortKey: PropertyValue<number>): LineLayer {
    this.nativeInstance.setLineSortKey(convertValue(sortKey));
    return this;
  }

  // ========== Getter helpers ==========

  getLineColor(): string | undefined {
    return this.nativeInstance.getLineColor();
  }

  getLineWidth(): number | undefined {
    return this.nativeInstance.getLineWidth();
  }

  getLineOpacity(): number | undefined {
    return this.nativeInstance.getLineOpacity();
  }

  getLineTranslate(): number[] | undefined {
    return this.nativeInstance.getLineTranslate();
  }

  getLineTranslateAnchor(): string | undefined {
    return this.nativeInstance.getLineTranslateAnchor();
  }

  getLineMiterLimit(): number | undefined {
    return this.nativeInstance.getLineMiterLimit();
  }

  getLineRoundLimit(): number | undefined {
    return this.nativeInstance.getLineRoundLimit();
  }

  getLineGradient(): ExpressionLiteral | undefined {
    return this.nativeInstance.getLineGradient();
  }

  getLineSortKey(): number | undefined {
    return this.nativeInstance.getLineSortKey();
  }
}
