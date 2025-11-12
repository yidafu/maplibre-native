/**
 * LineLayer - Wrapper class
 */
import maplibre, { ExpressionLiteral } from 'libmaplibre.so';
import type { ExpressionLiteral as NapiExpressionLiteral, PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class LineLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'LineLayer';
  private nativeInstance: maplibre.LineLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.LineLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.LineLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid LineLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): LineLayer {
    return new LineLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.LineLayer): LineLayer {
    return new LineLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.LineLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): LineLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): LineLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): LineLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: PropertyValue<boolean>): LineLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): LineLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
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

  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key (for example, 'line-color', 'line-width')
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): LineLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'line-color': '#0000FF',
   *   'line-width': 3,
   *   'line-dasharray': [2, 4]
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): LineLayer {
    const convertedProps: Record<string, NativePropertyValue<JSONValue>> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]) as NativePropertyValue<JSONValue>;
    }
    this.nativeInstance.setProperties(convertedProps);
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
