import type { Feature } from './Feature';

/**
 * FeatureCollection - GeoJSON feature collection interface.
 *
 * Represents a GeoJSON FeatureCollection object.
 * The C++ layer returns plain JavaScript objects matching this structure rather than class instances.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const featureCollection: FeatureCollection = {
 *   type: 'FeatureCollection',
 *   features: [
 *     {
 *       type: 'Feature',
 *       geometry: { type: 'Point', coordinates: [116.4, 39.9] },
 *       properties: { name: 'Beijing' }
 *     },
 *     {
 *       type: 'Feature',
 *       geometry: { type: 'Point', coordinates: [121.5, 31.2] },
 *       properties: { name: 'Shanghai' }
 *     }
 *   ]
 * };
 * ```
 */
export interface FeatureCollection {
  /**
   * GeoJSON object type, always "FeatureCollection".
   */
  type: 'FeatureCollection';

  /**
   * Array of feature objects.
   */
  features: Feature[];
}

