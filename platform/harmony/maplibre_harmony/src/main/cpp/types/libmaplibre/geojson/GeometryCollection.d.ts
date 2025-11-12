import type { Geometry } from './Geometry';

/**
 * GeometryCollection - GeoJSON geometry collection interface.
 *
 * Represents a GeoJSON GeometryCollection containing multiple geometries of different types.
 * The C++ layer returns plain JavaScript objects matching this shape.
 *
 * Specification: RFC 7946 (GeoJSON)
 *
 * @example
 * ```typescript
 * const geometryCollection: GeometryCollection = {
 *   type: 'GeometryCollection',
 *   geometries: [
 *     {
 *       type: 'Point',
 *       coordinates: [116.4, 39.9]
 *     },
 *     {
 *       type: 'LineString',
 *       coordinates: [
 *         [116.4, 39.9],
 *         [121.5, 31.2]
 *       ]
 *     },
 *     {
 *       type: 'Polygon',
 *       coordinates: [
 *         [
 *           [116.4, 39.9],
 *           [116.5, 39.9],
 *           [116.5, 40.0],
 *           [116.4, 40.0],
 *           [116.4, 39.9]
 *         ]
 *       ]
 *     }
 *   ]
 * };
 * ```
 */
export interface GeometryCollection {
  /**
   * GeoJSON object type, always "GeometryCollection".
   */
  type: 'GeometryCollection';

  /**
   * Array of geometries.
   * May contain any GeoJSON geometry type.
   */
  geometries: Geometry[];
}

