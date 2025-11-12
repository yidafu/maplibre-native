/**
 * GeoJSON Types - export GeoJSON types and helpers.
 *
 * Provides type definitions and implementations conforming to the GeoJSON specification (RFC 7946).
 */
// ==================== GeoJson object (for backward compatibility) ====================
import {
  feature,
  featureCollection,
  geometryCollection,
  lineString,
  lineStringFeature,
  multiLineString,
  multiPoint,
  multiPolygon,
  point,
  pointFeature,
  polygon,
  polygonFeature
} from './factory';

/**
 * GeoJson namespace class.
 *
 * Exposes GeoJSON factory helpers.
 *
 * @example
* ```typescript
 * const pt = GeoJson.point([116.4, 39.9]);
 * const line = GeoJson.lineString([[116.4, 39.9], [121.5, 31.2]]);
 * const ft = GeoJson.feature(pt, { name: 'Beijing' });
 * ```
 */
export class GeoJson {
  // Lowercase factory functions
  static point = point;
  static lineString = lineString;
  static polygon = polygon;
  static multiPoint = multiPoint;
  static multiLineString = multiLineString;
  static multiPolygon = multiPolygon;
  static geometryCollection = geometryCollection;
  static feature = feature;
  static featureCollection = featureCollection;
  static pointFeature = pointFeature;
  static lineStringFeature = lineStringFeature;
  static polygonFeature = polygonFeature;
}

// Re-export interfaces (IPoint, IPolygon, etc.) to avoid naming conflicts
export * from './types';