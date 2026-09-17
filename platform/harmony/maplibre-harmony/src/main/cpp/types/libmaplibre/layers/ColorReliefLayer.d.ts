/**
 * MapLibre Native for HarmonyOS - ColorReliefLayer type definitions.
 * ColorRelief layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * ColorReliefLayer - renders terrain RGB (color relief) data.
 *
 * Converts elevation data from raster DEM sources into color-coded relief maps.
 * Uses a ColorRamp to map elevation values to colors.
 */
export class ColorReliefLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a color relief layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier (raster-dem source).
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set the color ramp for color-relief rendering.
   * @param color ColorRamp value or expression (e.g. interpolate expression with elevation stops).
   */
  setColorReliefColor(color: PropertyValue<string>): this;

  /**
   * Set color relief opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setColorReliefOpacity(opacity: PropertyValue<number>): this;

  /**
   * Get the color ramp value.
   */
  getColorReliefColor(): string | undefined;

  /**
   * Get the current opacity.
   */
  getColorReliefOpacity(): number | undefined;

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
   *   'color-relief-color': 'interpolate(...)',
   *   'color-relief-opacity': 0.8
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
