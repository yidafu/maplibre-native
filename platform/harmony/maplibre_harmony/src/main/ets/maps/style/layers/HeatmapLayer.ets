/**
 * HeatmapLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import type { ExpressionLiteral, NumberValue } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class HeatmapLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'HeatmapLayer';
  private nativeInstance: maplibre.HeatmapLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.HeatmapLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.HeatmapLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid HeatmapLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): HeatmapLayer {
    return new HeatmapLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.HeatmapLayer): HeatmapLayer {
    return new HeatmapLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.HeatmapLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): HeatmapLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): HeatmapLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): HeatmapLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): HeatmapLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): HeatmapLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  // ========== Heatmap style property helpers ==========

  setHeatmapRadius(radius: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapRadius(convertValue(radius));
    return this;
  }

  setHeatmapWeight(weight: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapWeight(convertValue(weight));
    return this;
  }

  setHeatmapIntensity(intensity: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapIntensity(convertValue(intensity));
    return this;
  }

  setHeatmapColor(color: PropertyValue<string>): HeatmapLayer {
    this.nativeInstance.setHeatmapColor(convertValue(color) as ExpressionLiteral);
    return this;
  }

  setHeatmapOpacity(opacity: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapOpacity(convertValue(opacity));
    return this;
  }
  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): HeatmapLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'heatmap-radius': 30
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): HeatmapLayer {
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
