/**
 * FillLayer - Wrapper class
 */
import maplibre, { JSONValue } from 'libmaplibre.so';
import type { ExpressionLiteral, PropertyValue as NativePropertyValue } from 'libmaplibre.so';
import { PropertyValue, Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class FillLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'FillLayer';
  private nativeInstance: maplibre.FillLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.FillLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.FillLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid FillLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): FillLayer {
    return new FillLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.FillLayer): FillLayer {
    return new FillLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.FillLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): FillLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): FillLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): FillLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): FillLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): FillLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
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

  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key (for example, 'fill-color', 'fill-opacity')
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): FillLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value));
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'fill-color': '#FF0000',
   *   'fill-opacity': 0.5,
   *   'fill-outline-color': '#000000'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): FillLayer {
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
