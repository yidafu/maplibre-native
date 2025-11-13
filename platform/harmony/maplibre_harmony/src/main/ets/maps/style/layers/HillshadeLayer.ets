/**
 * HillshadeLayer - Wrapper class
 */
import type { ExpressionLiteral, NumberValue } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';
import type { PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import { Expression } from '../expressions/index';
import { convertValue } from './LayerUtils';
import { PropertyValue } from '../expressions/Expression';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class HillshadeLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'HillshadeLayer';
  private nativeInstance: maplibre.HillshadeLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.HillshadeLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.HillshadeLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid HillshadeLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): HillshadeLayer {
    return new HillshadeLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.HillshadeLayer): HillshadeLayer {
    return new HillshadeLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.HillshadeLayer {
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

  setVisibility(visibility: 'visible' | 'none'): HillshadeLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  getVisibility(): 'visible' | 'none' {
    return this.nativeInstance.getVisibility();
  }

  setMinZoom(zoom: number): HillshadeLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  getMinZoom(): number {
    return this.nativeInstance.getMinZoom();
  }

  setMaxZoom(zoom: number): HillshadeLayer {
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
  setFilter(filter: Expression<boolean> | ExpressionLiteral): HillshadeLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  getFilter(): ExpressionLiteral | null {
    return this.nativeInstance.getFilter();
  }

  setSourceLayer(sourceLayer: string): HillshadeLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
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
  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): HillshadeLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'hillshade-exaggeration': 0.5
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): HillshadeLayer {
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
