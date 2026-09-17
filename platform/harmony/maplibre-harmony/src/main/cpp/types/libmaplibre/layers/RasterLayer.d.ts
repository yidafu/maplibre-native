/**
 * MapLibre Native for HarmonyOS - RasterLayer type definitions.
 * Raster layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * RasterLayer - renders raster tile data.
 */
export class RasterLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a raster layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set raster opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setRasterOpacity(opacity: PropertyValue<number>): this;

  /**
   * Set raster hue rotation.
   * @param hueRotate Hue rotation angle or expression.
   */
  setRasterHueRotate(hueRotate: PropertyValue<number>): this;

  /**
   * Set minimum raster brightness.
   * @param brightnessMin Brightness value or expression (0.0 - 1.0).
   */
  setRasterBrightnessMin(brightnessMin: PropertyValue<number>): this;

  /**
   * Set maximum raster brightness.
   * @param brightnessMax Brightness value or expression (0.0 - 1.0).
   */
  setRasterBrightnessMax(brightnessMax: PropertyValue<number>): this;

  /**
   * Set raster saturation.
   * @param saturation Saturation value or expression (-1.0 - 1.0).
   */
  setRasterSaturation(saturation: PropertyValue<number>): this;

  /**
   * Set raster contrast.
   * @param contrast Contrast value or expression (-1.0 - 1.0).
   */
  setRasterContrast(contrast: PropertyValue<number>): this;

  /**
   * Get the layer identifier.
   */
  getId(): string;

  /**
   * Get the layer type.
   */
  getType(): string;

  /**
   * Get the source identifier.
   */
  getSourceId(): string;

  /**
   * Set layer visibility.
   */
  setVisibility(visibility: 'visible' | 'none'): this;

  getVisibility(): 'visible' | 'none';

  /**
   * Configure minimum/maximum zoom levels.
   */
  setMinZoom(zoom: number): this;

  getMinZoom(): number;

  setMaxZoom(zoom: number): this;

  getMaxZoom(): number;

  /**
   * Set the source layer.
   */
  setSourceLayer(sourceLayer: string): this;

  getSourceLayer(): string;

  /**
   * Set the layer filter.
   * @param filter Filter expression literal (JSON array form).
   */
  setFilter(filter: ExpressionLiteral): this;

  /**
   * Get the layer filter.
   * @returns Filter expression literal or null.
   */
  getFilter(): ExpressionLiteral | null;

// ==================== Extended properties ====================

  /**
   * Set raster fade duration in milliseconds.
   * @param duration Duration value or expression.
   */
  setRasterFadeDuration(duration: PropertyValue<number>): this;

  getRasterFadeDuration(): number | undefined;

  /**
   * Set raster resampling strategy.
   * @param resampling 'linear' | 'nearest' or expression.
   */
  setRasterResampling(resampling: PropertyValue<string>): this;

  getRasterResampling(): string | undefined;
  /**
   * Set a single property (generic helper).
   * @param propertyName Property name.
   * @param value Property value (literal or expression).
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * Set multiple properties (generic helper).
   * @param properties Object whose keys are property names and values are property payloads.
   * @example
   * layer.setProperties({
   *   'raster-opacity': 0.8, 'raster-brightness-max': 1.0
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
