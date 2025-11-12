/**
 * MultiPoint - GeoJSON MultiPoint interface.
 *
 * Represents a GeoJSON MultiPoint containing multiple points.
 * The C++ layer returns plain JavaScript objects matching this shape.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const multiPoint: MultiPoint = {
 *   type: 'MultiPoint',
 *   coordinates: [
*     [116.4, 39.9],  // Beijing
*     [121.5, 31.2],  // Shanghai
*     [113.3, 23.1]   // Guangzhou
 *   ]
 * };
 * ```
 */
export interface MultiPoint {
  /**
   * GeoJSON object type, always "MultiPoint".
   */
  type: 'MultiPoint';

  /**
   * Coordinate array containing multiple positions.
   * Each position is [longitude, latitude] or [longitude, latitude, altitude].
   */
  coordinates: number[][];
}

