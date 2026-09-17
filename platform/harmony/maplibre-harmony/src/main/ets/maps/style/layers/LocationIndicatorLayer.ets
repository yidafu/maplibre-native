/**
 * LocationIndicatorLayer - Wrapper class
 *
 * Renders a location indicator (bearing/shadow/top images) at a geographic
 * position. Not tied to a source.
 */
import maplibre from 'libmaplibre.so';

import type { PropertyValue } from '../expressions/index';

import { convertValue } from './LayerUtils';
import { LayerInternalTag, PropertyLayer, resolveLayerNative } from './BaseLayer';

export class LocationIndicatorLayer extends PropertyLayer<maplibre.LocationIndicatorLayer, LocationIndicatorLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'LocationIndicatorLayer';

  constructor(idOrMarker: string | LayerInternalTag, nativeOrNothing?: maplibre.LocationIndicatorLayer) {
    super(resolveLayerNative(idOrMarker, "", nativeOrNothing, (id) => new maplibre.LocationIndicatorLayer(id), "LocationIndicatorLayer"));
  }

  static create(id: string): LocationIndicatorLayer {
    return new LocationIndicatorLayer(id);
  }

  static fromNative(nativeInstance: maplibre.LocationIndicatorLayer): LocationIndicatorLayer {
    return new LocationIndicatorLayer(LayerInternalTag.INSTANCE, nativeInstance);
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

}
