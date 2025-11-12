/**
 * Point - GeoJSON Point interface.
 *
 * Represents a GeoJSON Point object.
 * The C++ layer returns plain JavaScript objects matching this shape.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const point: Point = {
 *   type: 'Point',
*   coordinates: [116.4, 39.9]  // [longitude, latitude]
 * };
 * ```
 */
export interface Point {
  /**
   * GeoJSON object type, always "Point".
   */
  type: 'Point';

  /**
   * Coordinate array.
   * - 2D: [longitude, latitude]
   * - 3D: [longitude, latitude, altitude]
   */
  coordinates: number[];
}

