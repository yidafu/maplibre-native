/**
 * MapLibre Native for HarmonyOS - BackgroundLayer type definitions.
 * Background layer API (NAPI class).
 */

import type { ColorValue, ExpressionType, NumberValue, StringValue, PropertyValue } from '../LayerPropertyTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * BackgroundLayer - renders the map background.
 */
export class BackgroundLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a background layer.
   * @param layerId Layer identifier.
   */
  constructor(layerId: string);

  /**
   * Set the background color.
   * @param color Color value or expression.
   */
  setBackgroundColor(color: PropertyValue<string>): this;

  /**
   * Set the background opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setBackgroundOpacity(opacity: PropertyValue<number>): this;

  /**
   * Set the background pattern.
   * @param pattern Pattern name or expression.
   */
  setBackgroundPattern(pattern: PropertyValue<string>): this;

  /**
   * Get the background color.
   * @returns Color string, or undefined if defined via expression.
   */
  getBackgroundColor(): string | undefined;

  /**
   * Get the background opacity.
   * @returns Opacity value, or undefined if defined via expression.
   */
  getBackgroundOpacity(): number | undefined;

  /**
   * Get the layer identifier.
   */
  getId(): string;

  /**
   * Get the layer type.
   */
  getType(): string;

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
   * Set a single property (generic helper).
   * @param propertyName Property key (e.g., 'background-color', 'background-opacity').
   * @param value Property value (literal or expression).
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * Set multiple properties (generic helper).
   * @param properties Object whose keys are property names and values are property payloads.
   * @example
   * layer.setProperties({
   *   'background-color': '#F0E9E1',
   *   'background-opacity': 1.0
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
