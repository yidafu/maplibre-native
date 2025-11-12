/**
 * MapLibre Native for HarmonyOS - FillExtrusionLayer type definitions.
 * 3D fill-extrusion layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * FillExtrusionLayer - 3D fill extrusion layer.
 * Renders extruded surfaces such as buildings.
 *
 * Note: simplified implementation; full feature set will be added later.
 */
export class FillExtrusionLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a 3D fill extrusion layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set extrusion height.
   * @param height Height value or expression.
   */
  setFillExtrusionHeight(height: PropertyValue<number>): this;

  /**
   * Set extrusion base height.
   * @param base Base height value or expression.
   */
  setFillExtrusionBase(base: PropertyValue<number>): this;

  /**
   * Set extrusion color.
   * @param color Color value or expression.
   */
  setFillExtrusionColor(color: PropertyValue<string>): this;

  /**
   * Set extrusion opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setFillExtrusionOpacity(opacity: PropertyValue<number>): this;

  /**
   * Set extrusion pattern.
   * @param pattern Pattern name or expression.
   *
   * @example
  * ```typescript
   * // Use a static pattern name.
   * layer.setFillExtrusionPattern('building-pattern');
   *
   * // Use an expression.
   * layer.setFillExtrusionPattern(['get', 'pattern_name']);
   * ```
   */
  setFillExtrusionPattern(pattern: PropertyValue<string>): this;

  /**
   * Set extrusion translation (offset 3D objects).
   * @param translate Translation [x, y] in pixels or expression.
   *
   * @example
  * ```typescript
   * // Constant translation.
   * layer.setFillExtrusionTranslate([10, 20]);
   *
   * // Data-driven translation via expression.
   * layer.setFillExtrusionTranslate(['literal', [5, 10]]);
   * ```
   */
  setFillExtrusionTranslate(translate: PropertyValue<[number, number]>): this;

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
   * Set the extrusion translation anchor.
   * @param anchor 'map' | 'viewport'.
   */
  setFillExtrusionTranslateAnchor(anchor: string): this;

  getFillExtrusionTranslateAnchor(): string | undefined;

  /**
   * Enable or disable the vertical gradient.
   * @param gradient Boolean flag or expression.
   */
  setFillExtrusionVerticalGradient(gradient: PropertyValue<boolean>): this;

  getFillExtrusionVerticalGradient(): boolean | undefined;
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
   *   'fill-extrusion-height': 100, 'fill-extrusion-color': '#FF0000'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
