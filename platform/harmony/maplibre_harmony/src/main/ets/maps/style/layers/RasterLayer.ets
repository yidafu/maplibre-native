/**
 * RasterLayer - Wrapper class
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

export class RasterLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'RasterLayer';
  private nativeInstance: maplibre.RasterLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.RasterLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.RasterLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid RasterLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): RasterLayer {
    return new RasterLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.RasterLayer): RasterLayer {
    return new RasterLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.RasterLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): RasterLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): RasterLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): RasterLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): RasterLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): RasterLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  // ========== Raster style property helpers ==========

  setRasterOpacity(opacity: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterOpacity(convertValue(opacity));
    return this;
  }

  setRasterHueRotate(hueRotate: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterHueRotate(convertValue(hueRotate));
    return this;
  }

  setRasterBrightnessMin(brightnessMin: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterBrightnessMin(convertValue(brightnessMin));
    return this;
  }

  setRasterBrightnessMax(brightnessMax: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterBrightnessMax(convertValue(brightnessMax));
    return this;
  }

  setRasterSaturation(saturation: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterSaturation(convertValue(saturation));
    return this;
  }

  setRasterContrast(contrast: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterContrast(convertValue(contrast));
    return this;
  }

  setRasterResampling(resampling: PropertyValue<string>): RasterLayer {
    this.nativeInstance.setRasterResampling(convertValue(resampling));
    return this;
  }

  setRasterFadeDuration(duration: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterFadeDuration(convertValue(duration));
    return this;
  }
  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): RasterLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'raster-opacity': 0.8
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): RasterLayer {
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
