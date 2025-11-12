/**
 * MapLibre Native for HarmonyOS - LineLayer type definitions.
 * Line layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * LineLayer - renders line features.
 */
export class LineLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a line layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set line color.
   * @param color Color value or expression.
   */
  setLineColor(color: PropertyValue<string>): this;

  /**
   * Set line width.
   * @param width Width value or expression.
   */
  setLineWidth(width: PropertyValue<number>): this;

  /**
   * Set line opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setLineOpacity(opacity: PropertyValue<number>): this;

  /**
   * Set line pattern.
   * @param pattern Pattern name or expression.
   */
  setLinePattern(pattern: PropertyValue<string>): this;

  /**
   * Set line gap width.
   * @param gapWidth Gap width value or expression.
   */
  setLineGapWidth(gapWidth: PropertyValue<number>): this;

  /**
   * Set line dash pattern.
   * @param dasharray Dash array or expression.
   */
  setLineDasharray(dasharray: PropertyValue<number[]>): this;

  /**
   * Set line blur.
   * @param blur Blur amount or expression.
   */
  setLineBlur(blur: PropertyValue<number>): this;

  /**
   * Set line offset.
   * @param offset Offset value or expression.
   */
  setLineOffset(offset: PropertyValue<number>): this;

  /**
   * Set line cap style.
   * @param cap Cap style or expression.
   */
  setLineCap(cap: PropertyValue<string>): this;

  /**
   * Set line join style.
   * @param join Join style or expression.
   */
  setLineJoin(join: PropertyValue<string>): this;

  /**
   * Get line color.
   */
  getLineColor(): string | undefined;

  /**
   * Get line width.
   */
  getLineWidth(): number | undefined;

  /**
   * Get line opacity.
   */
  getLineOpacity(): number | undefined;

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
   * Set line translation.
   * @param translate Translation vector or expression.
   */
  setLineTranslate(translate: PropertyValue<number[]>): this;

  getLineTranslate(): number[] | undefined;

  /**
   * Set line translation anchor.
   * @param anchor 'map' | 'viewport' or expression.
   */
  setLineTranslateAnchor(anchor: PropertyValue<string>): this;

  getLineTranslateAnchor(): string | undefined;

  /**
   * Set line miter limit.
   * @param limit Limit value or expression.
   */
  setLineMiterLimit(limit: PropertyValue<number>): this;

  getLineMiterLimit(): number | undefined;

  /**
   * Set line round limit.
   * @param limit Limit value or expression.
   */
  setLineRoundLimit(limit: PropertyValue<number>): this;

  getLineRoundLimit(): number | undefined;

  /**
   * Set line gradient (expression only).
   * @param gradient Gradient expression.
   */
  setLineGradient(gradient: PropertyValue<string>): this;

  getLineGradient(): ExpressionLiteral | undefined;

  /**
   * Set line sort key.
   * @param sortKey Sort key value or expression.
   */
  setLineSortKey(sortKey: PropertyValue<number>): this;

  getLineSortKey(): number | undefined;

  /**
   * Set a single property (generic helper).
   * @param propertyName Property name (for example 'line-color', 'line-width').
   * @param value Property value (literal or expression).
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * Set multiple properties (generic helper).
   * @param properties Object whose keys are property names and values are property payloads.
   * @example
   * layer.setProperties({
   *   'line-color': '#0000FF',
   *   'line-width': 3,
   *   'line-dasharray': [2, 4]
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
