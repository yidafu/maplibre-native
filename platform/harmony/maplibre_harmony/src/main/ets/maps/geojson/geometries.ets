/**
 * Geometry factory helpers.
 *
 * Provides convenient methods for creating Geometry objects.
 */
import type {
  Geometry,
  IGeometryCollection,
  ILineString,
  IMultiLineString,
  IMultiPoint,
  IMultiPolygon,
  IPoint,
  IPolygon,
  Position
} from './types';

/**
 * Create a Point geometry.
 *
 * @param coordinates Coordinates [longitude, latitude] or [longitude, latitude, altitude].
 * @returns Point object.
 *
 * @example
* ```typescript
 * const point = Point([116.4, 39.9]);
 * ```
 */
export function Point(coordinates: Position): IPoint {
  return {
    type: 'Point',
    coordinates
  };
}

/**
 * Create a LineString geometry.
 *
 * @param coordinates Coordinate array.
 * @returns LineString object.
 *
 * @example
* ```typescript
 * const line = LineString([
 *   [116.4, 39.9],
 *   [121.5, 31.2]
 * ]);
 * ```
 */
export function LineString(coordinates: Position[]): ILineString {
  return {
    type: 'LineString',
    coordinates
  };
}

/**
 * Create a Polygon geometry.
 *
 * @param coordinates Coordinate array (first array is outer ring, remaining arrays are inner rings).
 * @returns Polygon object.
 *
 * @example
* ```typescript
 * const polygon = Polygon([
*   [ // Outer ring
 *     [116.3, 39.8],
 *     [116.5, 39.8],
 *     [116.5, 40.0],
 *     [116.3, 40.0],
 *     [116.3, 39.8]
 *   ]
 * ]);
 * ```
 */
export function Polygon(coordinates: Position[][]): IPolygon {
  return {
    type: 'Polygon',
    coordinates
  };
}

/**
 * Create a MultiPoint geometry.
 *
 * @param coordinates Coordinate array.
 * @returns MultiPoint object.
 *
 * @example
* ```typescript
 * const multiPoint = MultiPoint([
 *   [116.4, 39.9],
 *   [121.5, 31.2],
 *   [113.3, 23.1]
 * ]);
 * ```
 */
export function MultiPoint(coordinates: Position[]): IMultiPoint {
  return {
    type: 'MultiPoint',
    coordinates
  };
}

/**
 * Create a MultiLineString geometry.
 *
 * @param coordinates Coordinate array.
 * @returns MultiLineString object.
 *
 * @example
* ```typescript
 * const multiLine = MultiLineString([
 *   [[116.4, 39.9], [121.5, 31.2]],
 *   [[113.3, 23.1], [114.1, 22.5]]
 * ]);
 * ```
 */
export function MultiLineString(coordinates: Position[][]): IMultiLineString {
  return {
    type: 'MultiLineString',
    coordinates
  };
}

/**
 * Create a MultiPolygon geometry.
 *
 * @param coordinates Coordinate array.
 * @returns MultiPolygon object.
 *
 * @example
* ```typescript
 * const multiPolygon = MultiPolygon([
*   [ // First polygon
 *     [[116.3, 39.8], [116.5, 39.8], [116.5, 40.0], [116.3, 40.0], [116.3, 39.8]]
 *   ],
*   [ // Second polygon
 *     [[121.4, 31.1], [121.6, 31.1], [121.6, 31.3], [121.4, 31.3], [121.4, 31.1]]
 *   ]
 * ]);
 * ```
 */
export function MultiPolygon(coordinates: Position[][][]): IMultiPolygon {
  return {
    type: 'MultiPolygon',
    coordinates
  };
}

/**
 * Create a GeometryCollection.
 *
 * @param geometries Array of Geometry objects.
 * @returns GeometryCollection object.
 *
 * @example
* ```typescript
 * const collection = GeometryCollection([
 *   Point([116.4, 39.9]),
 *   LineString([[116.4, 39.9], [121.5, 31.2]])
 * ]);
 * ```
 */
export function GeometryCollection(geometries: Geometry[]): IGeometryCollection {
  return {
    type: 'GeometryCollection',
    geometries
  };
}

