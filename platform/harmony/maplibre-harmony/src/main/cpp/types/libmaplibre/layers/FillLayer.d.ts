/**
 * MapLibre Native for HarmonyOS - FillLayer type definitions.
 * Fill layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * FillLayer - renders polygon areas.
 */
export class FillLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a fill layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set fill color.
   * @param color Color value or expression.
   */
  setFillColor(color: PropertyValue<string>): this;

  /**
   * Set fill opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setFillOpacity(opacity: PropertyValue<number>): this;

  /**
   * Set fill outline color.
   * @param color Color value or expression.
   */
  setFillOutlineColor(color: PropertyValue<string>): this;

  /**
   * Set fill pattern.
   * @param pattern Pattern name or expression.
   */
  setFillPattern(pattern: PropertyValue<string>): this;

  /**
   * Enable or disable fill antialiasing.
   * @param antialias Boolean flag or expression.
   */
  setFillAntialias(antialias: PropertyValue<boolean>): this;

  /**
   * Set fill translation.
   * @param translate Translation vector or expression.
   */
  setFillTranslate(translate: PropertyValue<number[]>): this;

  /**
   * Get fill color.
   */
  getFillColor(): string | undefined;

  /**
   * Get fill opacity.
   */
  getFillOpacity(): number | undefined;

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
   * @param visibility Visibility state.
   */
  setVisibility(visibility: 'visible' | 'none'): this;

  getVisibility(): 'visible' | 'none';

  /**
   * Set minimum zoom level.
   */
  setMinZoom(zoom: number): this;

  getMinZoom(): number;

  /**
   * Set maximum zoom level.
   */
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
   * Set fill translation anchor.
   * @param anchor 'map' | 'viewport' or expression.
   */
  setFillTranslateAnchor(anchor: PropertyValue<string>): this;

  getFillTranslateAnchor(): string | undefined;

  /**
   * Set fill sort key.
   * @param sortKey Sort key value or expression.
   */
  setFillSortKey(sortKey: PropertyValue<number>): this;

  getFillSortKey(): number | undefined;

  /**
   * Set a single property (generic helper).
   * @param propertyName Property name (for example 'fill-color', 'fill-opacity').
   * @param value Property value (literal or expression).
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * Set multiple properties (generic helper).
   * @param properties Object whose keys are property names and values are property payloads.
   * @example
   * layer.setProperties({
   *   'fill-color': '#FF0000',
   *   'fill-opacity': 0.5,
   *   'fill-outline-color': '#000000'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
