
/**
 * GeoJSON factory utilities.
 *
 * Provides convenience factory methods for creating GeoJSON interface objects (plain objects).
 */
import type {
    Position,
    IPoint,
    ILineString,
    IPolygon,
    IMultiPoint,
    IMultiLineString,
    IMultiPolygon,
    IGeometryCollection,
    IFeature,
    IFeatureCollection,
    Geometry
} from './types';
import type { JSONValue } from 'libmaplibre.so';
// ==================== Geometry factory functions ====================

/**
 * Create a Point object.
 *
 * @param coordinates Coordinates [longitude, latitude] or [longitude, latitude, altitude].
 * @returns IPoint object.
 *
 * @example
* ```typescript
 * const pt = point([116.4, 39.9]);
 * ```
 */
export function point(coordinates: Position): IPoint {
  return {
    type: 'Point',
    coordinates
  };
}

/**
 * Create a LineString object.
 *
 * @param coordinates Array of coordinates.
 * @returns ILineString object.
 *
 * @example
* ```typescript
 * const line = lineString([
 *   [116.4, 39.9],
 *   [121.5, 31.2]
 * ]);
 * ```
 */
export function lineString(coordinates: Position[]): ILineString {
  return {
    type: 'LineString',
    coordinates
  };
}

/**
 * Create a Polygon object.
 *
 * @param coordinates Coordinate array (first array is outer ring, remaining arrays are inner rings).
 * @returns IPolygon object.
 *
 * @example
* ```typescript
 * const poly = polygon([
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
export function polygon(coordinates: Position[][]): IPolygon {
  return {
    type: 'Polygon',
    coordinates
  };
}

/**
 * Create a MultiPoint object.
 *
 * @param coordinates Array of coordinates.
 * @returns IMultiPoint object.
 *
 * @example
* ```typescript
 * const multiPt = multiPoint([
 *   [116.4, 39.9],
 *   [121.5, 31.2],
 *   [113.3, 23.1]
 * ]);
 * ```
 */
export function multiPoint(coordinates: Position[]): IMultiPoint {
  return {
    type: 'MultiPoint',
    coordinates
  };
}

/**
 * Create a MultiLineString object.
 *
 * @param coordinates Array of coordinate arrays.
 * @returns IMultiLineString object.
 *
 * @example
* ```typescript
 * const multiLine = multiLineString([
 *   [[116.4, 39.9], [121.5, 31.2]],
 *   [[113.3, 23.1], [114.1, 22.5]]
 * ]);
 * ```
 */
export function multiLineString(coordinates: Position[][]): IMultiLineString {
  return {
    type: 'MultiLineString',
    coordinates
  };
}

/**
 * Create a MultiPolygon object.
 *
 * @param coordinates Array of polygon coordinate arrays.
 * @returns IMultiPolygon object.
 *
 * @example
* ```typescript
 * const multiPoly = multiPolygon([
*   [ // First polygon
 *     [[116.3, 39.8], [116.5, 39.8], [116.5, 40.0], [116.3, 40.0], [116.3, 39.8]]
 *   ],
*   [ // Second polygon
 *     [[121.4, 31.1], [121.6, 31.1], [121.6, 31.3], [121.4, 31.3], [121.4, 31.1]]
 *   ]
 * ]);
 * ```
 */
export function multiPolygon(coordinates: Position[][][]): IMultiPolygon {
  return {
    type: 'MultiPolygon',
    coordinates
  };
}

/**
 * Create a GeometryCollection object.
 *
 * @param geometries Array of geometry objects.
 * @returns IGeometryCollection object.
 *
 * @example
* ```typescript
 * const collection = geometryCollection([
 *   point([116.4, 39.9]),
 *   lineString([[116.4, 39.9], [121.5, 31.2]])
 * ]);
 * ```
 */
export function geometryCollection(geometries: Geometry[]): IGeometryCollection {
  return {
    type: 'GeometryCollection',
    geometries
  };
}

// ==================== Feature factory functions ====================

/**
 * Feature options interface.
 */
export interface CreateFeatureOptions {
  id?: string | number;
  geometry: Geometry;
  properties?: Record<string, JSONValue>;
}

/**
 * Create a Feature object.
 *
 * @param options Feature options.
 * @returns IFeature object.
 *
 * @example
* ```typescript
 * const ft = feature({
 *   id: 'feature-1',
 *   geometry: point([116.4, 39.9]),
 *   properties: { name: 'Beijing', population: 21540000 }
 * });
 * ```
 */
export function feature(options: CreateFeatureOptions): IFeature;

/**
 * Create a Feature object (convenience overload).
 *
 * @param geometry Geometry object.
 * @param properties Properties object (optional).
 * @param id Feature ID (optional).
 * @returns IFeature object.
 *
 * @example
* ```typescript
 * const ft = feature(point([116.4, 39.9]), { name: 'Beijing' });
 * ```
 */
export function feature(
  geometry: Geometry,
  properties?: Record<string, JSONValue>,
  id?: string | number
): IFeature;

// Implementation
export function feature(
  optionsOrGeometry: CreateFeatureOptions | Geometry,
  properties?: Record<string, JSONValue>,
  id?: string | number
): IFeature {
  // ArkTS does not support the 'in' operator; check property existence explicitly.
  const maybeGeometry = optionsOrGeometry as Geometry;
  if (maybeGeometry.type !== undefined && typeof maybeGeometry.type === 'string') {
    // Overload: geometry, properties, id
    return {
      type: 'Feature',
      id,
      geometry: optionsOrGeometry as Geometry,
      properties: (properties || {}) as Record<string, JSONValue>
    };
  } else {
    // Overload: options object
    const opts = optionsOrGeometry as CreateFeatureOptions;
    return {
      type: 'Feature',
      id: opts.id,
      geometry: opts.geometry,
      properties: (opts.properties || {}) as Record<string, JSONValue>
    };
  }
}

/**
 * Create a FeatureCollection object.
 *
 * @param features Array of Feature objects.
 * @returns IFeatureCollection object.
 *
 * @example
* ```typescript
 * const collection = featureCollection([
 *   feature(point([116.4, 39.9]), { name: 'Beijing' }),
 *   feature(point([121.5, 31.2]), { name: 'Shanghai' })
 * ]);
 * ```
 */
export function featureCollection(features: IFeature[]): IFeatureCollection {
  return {
    type: 'FeatureCollection',
    features
  };
}

// ==================== Convenience helpers ====================

/**
 * Create a Feature with Point geometry.
 *
 * @param coordinates Coordinates.
 * @param properties Properties.
 * @param id Feature ID.
 * @returns IFeature object.
 *
 * @example
* ```typescript
 * const ft = pointFeature([116.4, 39.9], { name: 'Beijing' });
 * ```
 */
export function pointFeature(
  coordinates: Position,
  properties?: Record<string, JSONValue>,
  id?: string | number
): IFeature {
  return feature(point(coordinates), properties, id);
}

/**
 * Create a Feature with LineString geometry.
 *
 * @param coordinates Coordinate array.
 * @param properties Properties.
 * @param id Feature ID.
 * @returns IFeature object.
 *
 * @example
* ```typescript
 * const ft = lineStringFeature([[116.4, 39.9], [121.5, 31.2]], { name: 'Route' });
 * ```
 */
export function lineStringFeature(
  coordinates: Position[],
  properties?: Record<string, JSONValue>,
  id?: string | number
): IFeature {
  return feature(lineString(coordinates), properties, id);
}

/**
 * Create a Feature with Polygon geometry.
 *
 * @param coordinates Coordinate array.
 * @param properties Properties.
 * @param id Feature ID.
 * @returns IFeature object.
 *
 * @example
* ```typescript
 * const ft = polygonFeature([
 *   [[116.3, 39.8], [116.5, 39.8], [116.5, 40.0], [116.3, 40.0], [116.3, 39.8]]
 * ], { name: 'Area' });
 * ```
 */
export function polygonFeature(
  coordinates: Position[][],
  properties?: Record<string, JSONValue>,
  id?: string | number
): IFeature {
  return feature(polygon(coordinates), properties, id);
}

