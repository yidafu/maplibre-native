/**
 * MultiPolygon - GeoJSON MultiPolygon interface.
 *
 * Represents a GeoJSON MultiPolygon containing multiple polygons.
 * The C++ layer returns plain JavaScript objects matching this structure.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const multiPolygon: MultiPolygon = {
 *   type: 'MultiPolygon',
 *   coordinates: [
 *     // First polygon
 *     [
 *       // Outer ring
 *       [
 *         [116.4, 39.9],
 *         [116.5, 39.9],
 *         [116.5, 40.0],
 *         [116.4, 40.0],
 *         [116.4, 39.9]
 *       ]
 *     ],
 *     // Second polygon
 *     [
 *       [
 *         [121.4, 31.2],
 *         [121.5, 31.2],
 *         [121.5, 31.3],
 *         [121.4, 31.3],
 *         [121.4, 31.2]
 *       ]
 *     ]
 *   ]
 * };
 * ```
 */
export interface MultiPolygon {
  /**
   * GeoJSON object type, always "MultiPolygon".
   */
  type: 'MultiPolygon';

  /**
   * Coordinate array composed of multiple Polygon coordinate arrays.
   */
  coordinates: number[][][][];
}

