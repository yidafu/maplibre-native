/**
 * LocationIndicatorLayer - Wrapper class
 *
 * Renders a location indicator (bearing/shadow/top images) at a geographic
 * position. Not tied to a source.
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class LocationIndicatorLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'LocationIndicatorLayer';
  private nativeInstance: maplibre.LocationIndicatorLayer;

  constructor(idOrMarker: string | InternalMarker, nativeOrNothing?: maplibre.LocationIndicatorLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.LocationIndicatorLayer(idOrMarker);
    } else {
      throw new Error('Invalid LocationIndicatorLayer constructor arguments');
    }
  }

  static create(id: string): LocationIndicatorLayer {
    return new LocationIndicatorLayer(id);
  }

  static fromNative(nativeInstance: maplibre.LocationIndicatorLayer): LocationIndicatorLayer {
    return new LocationIndicatorLayer(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.LocationIndicatorLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getType(): string {
    return this.nativeInstance.getType();
  }

  setVisibility(visibility: 'visible' | 'none'): LocationIndicatorLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  getVisibility(): 'visible' | 'none' {
    return this.nativeInstance.getVisibility();
  }

  setMinZoom(zoom: number): LocationIndicatorLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  getMinZoom(): number {
    return this.nativeInstance.getMinZoom();
  }

  setMaxZoom(zoom: number): LocationIndicatorLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  getMaxZoom(): number {
    return this.nativeInstance.getMaxZoom();
  }

  // ========== Location indicator style property helpers ==========

  /**
   * Set the image used for the bearing (heading) part of the indicator.
   * @param image Image name registered in the style's sprite
   */
  setBearingImage(image: PropertyValue<string>): LocationIndicatorLayer {
    this.nativeInstance.setBearingImage(convertValue(image));
    return this;
  }

  getBearingImage(): string | undefined {
    return this.nativeInstance.getBearingImage();
  }

  /**
   * Set the image used for the shadow part of the indicator.
   */
  setShadowImage(image: PropertyValue<string>): LocationIndicatorLayer {
    this.nativeInstance.setShadowImage(convertValue(image));
    return this;
  }

  getShadowImage(): string | undefined {
    return this.nativeInstance.getShadowImage();
  }

  /**
   * Set the image used for the top (puck) part of the indicator.
   */
  setTopImage(image: PropertyValue<string>): LocationIndicatorLayer {
    this.nativeInstance.setTopImage(convertValue(image));
    return this;
  }

  getTopImage(): string | undefined {
    return this.nativeInstance.getTopImage();
  }

  /**
   * Set the accuracy radius, in device independent pixels.
   */
  setAccuracyRadius(radius: PropertyValue<number>): LocationIndicatorLayer {
    this.nativeInstance.setAccuracyRadius(convertValue(radius));
    return this;
  }

  getAccuracyRadius(): number | undefined {
    return this.nativeInstance.getAccuracyRadius();
  }

  setAccuracyRadiusBorderColor(color: PropertyValue<string>): LocationIndicatorLayer {
    this.nativeInstance.setAccuracyRadiusBorderColor(convertValue(color));
    return this;
  }

  getAccuracyRadiusBorderColor(): string | undefined {
    return this.nativeInstance.getAccuracyRadiusBorderColor();
  }

  setAccuracyRadiusColor(color: PropertyValue<string>): LocationIndicatorLayer {
    this.nativeInstance.setAccuracyRadiusColor(convertValue(color));
    return this;
  }

  getAccuracyRadiusColor(): string | undefined {
    return this.nativeInstance.getAccuracyRadiusColor();
  }

  /**
   * Set the bearing of the indicator, in degrees (clockwise).
   */
  setBearing(bearing: PropertyValue<number>): LocationIndicatorLayer {
    this.nativeInstance.setBearing(convertValue(bearing));
    return this;
  }

  getBearing(): number | undefined {
    return this.nativeInstance.getBearing();
  }

  setBearingImageSize(size: PropertyValue<number>): LocationIndicatorLayer {
    this.nativeInstance.setBearingImageSize(convertValue(size));
    return this;
  }

  getBearingImageSize(): number | undefined {
    return this.nativeInstance.getBearingImageSize();
  }

  /**
   * Set the vertical displacement of the images with tilt, in device independent pixels.
   */
  setImageTiltDisplacement(displacement: PropertyValue<number>): LocationIndicatorLayer {
    this.nativeInstance.setImageTiltDisplacement(convertValue(displacement));
    return this;
  }

  getImageTiltDisplacement(): number | undefined {
    return this.nativeInstance.getImageTiltDisplacement();
  }

  /**
   * Set the location of the indicator as [latitude, longitude, altitude].
   */
  setLocation(location: PropertyValue<number[]>): LocationIndicatorLayer {
    this.nativeInstance.setLocation(convertValue(location));
    return this;
  }

  getLocation(): number[] | undefined {
    return this.nativeInstance.getLocation();
  }

  /**
   * Set the perspective compensation (0 = no compensation, 1 = full compensation).
   */
  setPerspectiveCompensation(compensation: PropertyValue<number>): LocationIndicatorLayer {
    this.nativeInstance.setPerspectiveCompensation(convertValue(compensation));
    return this;
  }

  getPerspectiveCompensation(): number | undefined {
    return this.nativeInstance.getPerspectiveCompensation();
  }

  setShadowImageSize(size: PropertyValue<number>): LocationIndicatorLayer {
    this.nativeInstance.setShadowImageSize(convertValue(size));
    return this;
  }

  getShadowImageSize(): number | undefined {
    return this.nativeInstance.getShadowImageSize();
  }

  setTopImageSize(size: PropertyValue<number>): LocationIndicatorLayer {
    this.nativeInstance.setTopImageSize(convertValue(size));
    return this;
  }

  getTopImageSize(): number | undefined {
    return this.nativeInstance.getTopImageSize();
  }

  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key (e.g. 'accuracy-radius', 'bearing-image')
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): LocationIndicatorLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'top-image': 'location-top',
   *   'accuracy-radius-color': 'rgba(255, 0, 0, 0.2)'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): LocationIndicatorLayer {
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
