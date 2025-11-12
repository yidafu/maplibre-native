/**
 * Polygon - GeoJSON Polygon interface.
 *
 * Represents a GeoJSON Polygon object.
 * The C++ layer returns plain JavaScript objects matching this structure.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const polygon: Polygon = {
 *   type: 'Polygon',
 *   coordinates: [
 *     // Outer ring (required)
 *     [
 *       [116.4, 39.9],
 *       [116.5, 39.9],
 *       [116.5, 40.0],
 *       [116.4, 40.0],
*       [116.4, 39.9]  // Closed loop
 *     ],
*     // Inner ring (optional hole)
 *     [
 *       [116.42, 39.92],
 *       [116.48, 39.92],
 *       [116.48, 39.98],
 *       [116.42, 39.98],
 *       [116.42, 39.92]
 *     ]
 *   ]
 * };
 * ```
 */
export interface Polygon {
  /**
   * GeoJSON object type, always "Polygon".
   */
  type: 'Polygon';

  /**
   * Coordinate array consisting of one or more LinearRings.
   * - The first ring is the outer boundary.
   * - Subsequent rings are optional holes.
   * Each ring must form a closed loop.
   */
  coordinates: number[][][];
}

