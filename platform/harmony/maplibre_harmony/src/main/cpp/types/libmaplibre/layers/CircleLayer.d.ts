/**
 * MapLibre Native for HarmonyOS - CircleLayer type definitions.
 * Circle layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * CircleLayer - renders point features as circles.
 */
export class CircleLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a circle layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set circle radius.
   * @param radius Radius value or expression.
   */
  setCircleRadius(radius: PropertyValue<number>): this;

  /**
   * Set circle color.
   * @param color Color value or expression.
   */
  setCircleColor(color: PropertyValue<string>): this;

  /**
   * Set circle opacity.
   * @param opacity Opacity value or expression (0.0 - 1.0).
   */
  setCircleOpacity(opacity: PropertyValue<number>): this;

  /**
   * Set circle blur.
   * @param blur Blur amount or expression (0.0 - 1.0).
   */
  setCircleBlur(blur: PropertyValue<number>): this;

  /**
   * Set circle stroke width.
   * @param width Width value or expression.
   */
  setCircleStrokeWidth(width: PropertyValue<number>): this;

  /**
   * Set circle stroke color.
   * @param color Color value or expression.
   */
  setCircleStrokeColor(color: PropertyValue<string>): this;

  /**
   * Set circle stroke opacity.
   * @param opacity Opacity value or expression.
   */
  setCircleStrokeOpacity(opacity: PropertyValue<number>): this;

  /**
   * Get circle radius.
   */
  getCircleRadius(): number | undefined;

  /**
   * Get circle color.
   */
  getCircleColor(): string | undefined;

  /**
   * Get circle opacity.
   */
  getCircleOpacity(): number | undefined;

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
   * Set circle translation.
   * @param translate Translation vector or expression.
   */
  setCircleTranslate(translate: PropertyValue<number[]>): this;

  getCircleTranslate(): number[] | undefined;

  /**
   * Set circle translation anchor.
   * @param anchor 'map' | 'viewport' or expression.
   */
  setCircleTranslateAnchor(anchor: PropertyValue<string>): this;

  getCircleTranslateAnchor(): string | undefined;

  /**
   * Set circle pitch scale behavior.
   * @param scale 'map' | 'viewport' or expression.
   */
  setCirclePitchScale(scale: PropertyValue<string>): this;

  getCirclePitchScale(): string | undefined;

  /**
   * Set circle pitch alignment.
   * @param alignment 'map' | 'viewport' or expression.
   */
  setCirclePitchAlignment(alignment: PropertyValue<string>): this;

  getCirclePitchAlignment(): string | undefined;

  /**
   * Set circle sort key.
   * @param sortKey Sort key value or expression.
   */
  setCircleSortKey(sortKey: PropertyValue<number>): this;

  getCircleSortKey(): number | undefined;

  /**
   * Set a single property (generic helper).
   * @param propertyName Property name (for example 'circle-color', 'circle-radius').
   * @param value Property value (literal or expression).
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * Set multiple properties (generic helper).
   * @param properties Object whose keys are property names and values are property payloads.
   * @example
   * layer.setProperties({
   *   'circle-color': '#00FF00',
   *   'circle-radius': 10,
   *   'circle-stroke-width': 2
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
