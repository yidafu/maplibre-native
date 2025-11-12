/**
 * GeoJSON type definitions.
 *
 * Defines types that conform to the GeoJSON specification (RFC 7946).
 * 
 * Note: all types are re-exported from libmaplibre.so (prefixed with `I` to avoid naming collisions),
 * ensuring ETS and C++ type definitions remain in sync.
 */

// ==================== Re-export GeoJSON types from libmaplibre.so ====================

import type {
  Position,
  Position2D,
  Position3D,
  Geometry,
  IPoint,
  ILineString,
  IPolygon,
  IMultiPoint,
  IMultiLineString,
  IMultiPolygon,
  IGeometryCollection,
  IFeature,
  IFeatureCollection
} from 'libmaplibre.so';

// ==================== Re-export all types ====================

export type { Position, Position2D, Position3D };

export type { Geometry };

export type { IPoint };

export type { ILineString };

export type { IPolygon };

export type { IMultiPoint };

export type { IMultiLineString };

export type { IMultiPolygon };

export type { IGeometryCollection };

export type { IFeature };

export type { IFeatureCollection };
