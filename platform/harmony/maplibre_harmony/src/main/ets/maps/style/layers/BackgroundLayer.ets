/**
 * BackgroundLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class BackgroundLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'BackgroundLayer';
  private nativeInstance: maplibre.BackgroundLayer;

  constructor(idOrMarker: string | InternalMarker, nativeOrNothing?: maplibre.BackgroundLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.BackgroundLayer(idOrMarker);
    } else {
      throw new Error('Invalid BackgroundLayer constructor arguments');
    }
  }

  static create(id: string): BackgroundLayer {
    return new BackgroundLayer(id);
  }

  static fromNative(nativeInstance: maplibre.BackgroundLayer): BackgroundLayer {
    return new BackgroundLayer(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.BackgroundLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setVisibility(visibility: 'visible' | 'none'): BackgroundLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setBackgroundColor(color: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundColor(convertValue(color));
    return this;
  }

  setBackgroundOpacity(opacity: PropertyValue<number>): BackgroundLayer {
    this.nativeInstance.setBackgroundOpacity(convertValue(opacity));
    return this;
  }

  setBackgroundPattern(pattern: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundPattern(convertValue(pattern));
    return this;
  }

  // ========== Getter helpers ==========

  getBackgroundColor(): string | undefined {
    return this.nativeInstance.getBackgroundColor();
  }

  getBackgroundOpacity(): number | undefined {
    return this.nativeInstance.getBackgroundOpacity();
  }
  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): BackgroundLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property name to value
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'background-color': '#F0E9E1'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): BackgroundLayer {
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
