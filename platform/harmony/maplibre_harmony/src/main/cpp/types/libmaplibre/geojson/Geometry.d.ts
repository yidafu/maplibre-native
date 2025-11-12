import type { Point } from './Point';
import type { LineString } from './LineString';
import type { Polygon } from './Polygon';
import type { MultiPoint } from './MultiPoint';
import type { MultiLineString } from './MultiLineString';
import type { MultiPolygon } from './MultiPolygon';
import type { GeometryCollection } from './GeometryCollection';

/**
 * Geometry - union of GeoJSON geometries.
 *
 * Combines every geometry type to enable type-safe operations.
 * Each concrete type corresponds to a C++ NAPI class instance.
 */
export type Geometry =
  | Point
    | LineString
    | Polygon
    | MultiPoint
    | MultiLineString
    | MultiPolygon
    | GeometryCollection;

/**
 * GeoJSON coordinate type definitions.
 */
export type Position = number[]; // [lng, lat] or [lng, lat, altitude]

export type Position2D = [number, number]; // [lng, lat]

export type Position3D = [number, number, number]; // [lng, lat, altitude]

/**
 * GeoJSON coordinate union covering all geometry types:
 * - Point: Position
 * - LineString / MultiPoint: Position[]
 * - Polygon / MultiLineString: Position[][]
 * - MultiPolygon: Position[][][]
 */
export type Coordinates = Position | Position[] | Position[][] | Position[][][];

/**
 * Base interface for GeoJSON objects.
 */
export interface GeoJSONObject {
  type: string;
  coordinates?: Coordinates;
}

