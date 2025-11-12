import type { Geometry } from './Geometry';
import type { JSONValue } from '../CommonTypes';

/**
 * Feature - GeoJSON feature interface.
 *
 * Represents a GeoJSON Feature object.
 * The C++ layer returns plain JavaScript objects matching this shape rather than class instances.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const feature: Feature = {
 *   type: 'Feature',
 *   id: 'feature-1',
 *   geometry: {
 *     type: 'Point',
 *     coordinates: [116.4, 39.9]
 *   },
 *   properties: {
 *     name: 'Beijing',
 *     population: 21540000
 *   },
*   layer: 'poi-layer'  // MapLibre extension
 * };
 * ```
 */
export interface Feature {
  /**
   * GeoJSON object type, always "Feature".
   */
  type: 'Feature';

  /**
   * Optional feature identifier (string or number).
   */
  id?: string | number;

  /**
   * Feature geometry (Point, LineString, Polygon, or any GeoJSON geometry type).
   */
  geometry: Geometry;

  /**
   * Feature properties as a key/value object.
   */
  properties: Record<string, JSONValue>;

  /**
   * MapLibre extension: style layer identifier.
   * Present in queryRenderedFeatures results to indicate the owning layer.
   *
   * Note: this is a MapLibre extension, not part of the GeoJSON spec.
   */
  layer?: string;

  /**
   * MapLibre extension: source identifier.
   * Indicates which source produced the feature.
   *
   * Note: this is a MapLibre extension, not part of the GeoJSON spec.
   */
  source?: string;
}

