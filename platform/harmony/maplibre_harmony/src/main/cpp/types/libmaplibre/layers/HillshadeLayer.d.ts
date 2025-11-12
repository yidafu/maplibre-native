/**
 * MapLibre Native for HarmonyOS - HillshadeLayer type definitions.
 * Hillshade layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * HillshadeLayer - renders terrain shading effects.
 *
 * Note: simplified implementation; full feature set will be added later.
 */
export class HillshadeLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a hillshade layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

  /**
   * Set illumination direction.
   * @param direction Direction angle or expression (0-359 degrees).
   */
  setHillshadeIlluminationDirection(direction: PropertyValue<number>): this;

  /**
   * Set exaggeration factor.
   * @param exaggeration Exaggeration value or expression (0.0 - 1.0).
   */
  setHillshadeExaggeration(exaggeration: PropertyValue<number>): this;

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
   *   'hillshade-exaggeration': 0.5
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
