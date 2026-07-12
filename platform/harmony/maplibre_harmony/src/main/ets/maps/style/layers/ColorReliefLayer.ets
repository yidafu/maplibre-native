/**
 * ColorReliefLayer - Wrapper class
 * Wraps the NAPI ColorReliefLayer for terrain RGB rendering.
 * Properties:
 *   - colorReliefColor (ColorRampPropertyValue)
 *   - colorReliefOpacity (PropertyValue<number>)
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue as NativePropertyValue, JSONValue, ExpressionLiteral } from 'libmaplibre.so';
import { Expression } from '../expressions/index';
import { convertValue } from './LayerUtils';
import { PropertyValue } from '../expressions/Expression';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class ColorReliefLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'ColorReliefLayer';
  private nativeInstance: maplibre.ColorReliefLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.ColorReliefLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.ColorReliefLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid ColorReliefLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): ColorReliefLayer {
    return new ColorReliefLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.ColorReliefLayer): ColorReliefLayer {
    return new ColorReliefLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.ColorReliefLayer {
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

  setVisibility(visibility: 'visible' | 'none'): ColorReliefLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  getVisibility(): 'visible' | 'none' {
    return this.nativeInstance.getVisibility();
  }

  setMinZoom(zoom: number): ColorReliefLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  getMinZoom(): number {
    return this.nativeInstance.getMinZoom();
  }

  setMaxZoom(zoom: number): ColorReliefLayer {
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
  setFilter(filter: Expression<boolean> | ExpressionLiteral): ColorReliefLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  getFilter(): ExpressionLiteral | null {
    return this.nativeInstance.getFilter();
  }

  setSourceLayer(sourceLayer: string): ColorReliefLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
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

  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): ColorReliefLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'color-relief-color': 'interpolate(...)',
   *   'color-relief-opacity': 0.8
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): ColorReliefLayer {
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
