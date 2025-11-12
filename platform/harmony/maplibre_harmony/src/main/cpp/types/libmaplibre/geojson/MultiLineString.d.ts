/**
 * MultiLineString - GeoJSON MultiLineString interface.
 *
 * Represents a GeoJSON MultiLineString composed of multiple lines.
 * The C++ layer returns plain JavaScript objects with this structure.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const multiLineString: MultiLineString = {
 *   type: 'MultiLineString',
 *   coordinates: [
 *     // First line
 *     [
 *       [116.4, 39.9],
 *       [121.5, 31.2]
 *     ],
 *     // Second line
 *     [
 *       [113.3, 23.1],
 *       [114.1, 22.5]
 *     ]
 *   ]
 * };
 * ```
 */
export interface MultiLineString {
  /**
   * GeoJSON object type, always "MultiLineString".
   */
  type: 'MultiLineString';

  /**
   * Coordinate array comprised of multiple LineString coordinate arrays.
   */
  coordinates: number[][][];
}

