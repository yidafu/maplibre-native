/**
 * MapLibre Native for HarmonyOS - HeatmapLayer type definitions.
 * Heatmap layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * HeatmapLayer - density heatmap renderer.
 *
 * Note: simplified implementation; full feature set will be added later.
 */
export class HeatmapLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a heatmap layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set heatmap radius.
   * @param radius Radius value or expression.
   */
  setHeatmapRadius(radius: PropertyValue<number>): this;

  /**
   * Set heatmap weight.
   * @param weight Weight value or expression (controls each point's contribution).
   */
  setHeatmapWeight(weight: PropertyValue<number>): this;

  /**
   * Set heatmap intensity.
   * @param intensity Intensity value or expression.
   */
  setHeatmapIntensity(intensity: PropertyValue<number>): this;

  /**
   * Set heatmap opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setHeatmapOpacity(opacity: PropertyValue<number>): this;

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
   * Configure the heatmap color ramp (expression only).
   * Requires the heatmap-density expression.
   *
   * @param color Color expression (typically interpolate).
   *
   * @example
   * ```typescript
   * layer.setHeatmapColor([
   *   "interpolate",
   *   ["linear"],
   *   ["heatmap-density"],
   *   0, "rgba(0, 0, 255, 0)",
   *   0.1, "royalblue",
   *   0.3, "cyan",
   *   0.5, "lime",
   *   0.7, "yellow",
   *   1, "red"
   * ]);
   * ```
   */
  setHeatmapColor(color: ExpressionLiteral): this;

  /**
   * Get the heatmap color expression.
   * @returns Color expression, or undefined when unset.
   */
  getHeatmapColor(): ExpressionLiteral | undefined;
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
   *   'heatmap-radius': 30, 'heatmap-weight': 1
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
