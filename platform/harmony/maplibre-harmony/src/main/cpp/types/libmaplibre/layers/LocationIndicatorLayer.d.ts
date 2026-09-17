/**
 * MapLibre Native for HarmonyOS - LocationIndicatorLayer type definitions.
 * Location indicator layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * LocationIndicatorLayer - device location indicator renderer.
 *
 * Draws bearing/shadow/top images at a geographic position with an optional
 * accuracy radius circle. Not tied to a source.
 */
export class LocationIndicatorLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a location indicator layer.
   * @param layerId Layer identifier.
   */
  constructor(layerId: string);

  // ==================== Layout properties ====================

  /**
   * Set the image used for the bearing (heading) part of the indicator.
   * @param image Image name or expression.
   */
  setBearingImage(image: PropertyValue<string>): this;

  getBearingImage(): string | undefined;

  /**
   * Set the image used for the shadow part of the indicator.
   */
  setShadowImage(image: PropertyValue<string>): this;

  getShadowImage(): string | undefined;

  /**
   * Set the image used for the top (puck) part of the indicator.
   */
  setTopImage(image: PropertyValue<string>): this;

  getTopImage(): string | undefined;

  // ==================== Paint properties ====================

  /**
   * Set the accuracy radius, in device independent pixels.
   */
  setAccuracyRadius(radius: PropertyValue<number>): this;

  getAccuracyRadius(): number | undefined;

  /**
   * Set the color of the accuracy radius border.
   */
  setAccuracyRadiusBorderColor(color: PropertyValue<string>): this;

  getAccuracyRadiusBorderColor(): string | undefined;

  /**
   * Set the color of the accuracy radius circle.
   */
  setAccuracyRadiusColor(color: PropertyValue<string>): this;

  getAccuracyRadiusColor(): string | undefined;

  /**
   * Set the bearing of the indicator, in degrees (clockwise).
   */
  setBearing(bearing: PropertyValue<number>): this;

  getBearing(): number | undefined;

  /**
   * Set the size of the bearing image, as a scale factor.
   */
  setBearingImageSize(size: PropertyValue<number>): this;

  getBearingImageSize(): number | undefined;

  /**
   * Set the vertical displacement of the images with tilt,
   * in device independent pixels.
   */
  setImageTiltDisplacement(displacement: PropertyValue<number>): this;

  getImageTiltDisplacement(): number | undefined;

  /**
   * Set the location of the indicator as [latitude, longitude, altitude].
   */
  setLocation(location: PropertyValue<number[]>): this;

  getLocation(): number[] | undefined;

  /**
   * Set the perspective compensation
   * (0 = no compensation, 1 = full compensation).
   */
  setPerspectiveCompensation(compensation: PropertyValue<number>): this;

  getPerspectiveCompensation(): number | undefined;

  /**
   * Set the size of the shadow image, as a scale factor.
   */
  setShadowImageSize(size: PropertyValue<number>): this;

  getShadowImageSize(): number | undefined;

  /**
   * Set the size of the top image, as a scale factor.
   */
  setTopImageSize(size: PropertyValue<number>): this;

  getTopImageSize(): number | undefined;

  // ==================== Base layer methods ====================

  getId(): string;

  getType(): string;

  setVisibility(visibility: 'visible' | 'none'): this;

  getVisibility(): 'visible' | 'none';

  setMinZoom(zoom: number): this;

  getMinZoom(): number;

  setMaxZoom(zoom: number): this;

  getMaxZoom(): number;

  // ==================== Extended properties ====================

  /**
   * Set a single property (generic helper).
   * @param propertyName Property name (e.g. 'accuracy-radius').
   * @param value Property value (literal or expression).
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * Set multiple properties (generic helper).
   * @param properties Object whose keys are property names and values are property payloads.
   * @example
   * layer.setProperties({
   *   'top-image': 'location-top',
   *   'accuracy-radius-color': 'rgba(255, 0, 0, 0.2)'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
