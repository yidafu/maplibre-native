/**
 * LineString - GeoJSON LineString interface.
 *
 * Represents a GeoJSON LineString object.
 * The C++ layer returns plain JavaScript objects with this structure.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const lineString: LineString = {
 *   type: 'LineString',
 *   coordinates: [
 *     [116.4, 39.9],  // start point
 *     [121.5, 31.2]   // end point
 *   ]
 * };
 * ```
 */
export interface LineString {
  /**
   * GeoJSON object type, always "LineString".
   */
  type: 'LineString';

  /**
   * Array of coordinates consisting of two or more positions.
   * Each position is [longitude, latitude] or [longitude, latitude, altitude].
   */
  coordinates: number[][];
}

