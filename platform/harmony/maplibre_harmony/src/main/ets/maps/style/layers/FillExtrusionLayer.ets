/**
 * FillExtrusionLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import type { ExpressionLiteral } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';


class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class FillExtrusionLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'FillExtrusionLayer';
  private nativeInstance: maplibre.FillExtrusionLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "",
    nativeOrNothing?: maplibre.FillExtrusionLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.FillExtrusionLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid FillExtrusionLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): FillExtrusionLayer {
    return new FillExtrusionLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.FillExtrusionLayer): FillExtrusionLayer {
    return new FillExtrusionLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.FillExtrusionLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getType(): string {
    return this.nativeInstance.getType();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  getSourceLayer(): string {
    return this.nativeInstance.getSourceLayer();
  }

  setVisibility(visibility: 'visible' | 'none'): FillExtrusionLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  getVisibility(): 'visible' | 'none' {
    return this.nativeInstance.getVisibility();
  }

  setMinZoom(zoom: number): FillExtrusionLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  getMinZoom(): number {
    return this.nativeInstance.getMinZoom();
  }

  setMaxZoom(zoom: number): FillExtrusionLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  getMaxZoom(): number {
    return this.nativeInstance.getMaxZoom();
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): FillExtrusionLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  getFilter(): ExpressionLiteral | null {
    return this.nativeInstance.getFilter();
  }

  setSourceLayer(sourceLayer: string): FillExtrusionLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
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
  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): FillExtrusionLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'fill-extrusion-height': 100
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): FillExtrusionLayer {
    const convertedProps: Record<string, NativePropertyValue<JSONValue>> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]) as NativePropertyValue<JSONValue>;
    }
    this.nativeInstance.setProperties(convertedProps);
    return this;
  }

}
