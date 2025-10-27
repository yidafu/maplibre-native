import type { Point } from './Point';
import type { LineString } from './LineString';
import type { Polygon } from './Polygon';
import type { MultiPoint } from './MultiPoint';
import type { MultiLineString } from './MultiLineString';
import type { MultiPolygon } from './MultiPolygon';
import type { GeometryCollection } from './GeometryCollection';

/**
 * Geometry - GeoJSON 几何体联合类型
 * 
 * 所有几何体类型的联合类型，用于类型安全的几何体操作。
 * 每个具体类型都是 C++ NAPI 类实例。
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
 * GeoJSON 坐标类型定义
 */
export type Position = number[];  // [lng, lat] 或 [lng, lat, altitude]
export type Position2D = [number, number];  // [lng, lat]
export type Position3D = [number, number, number];  // [lng, lat, altitude]

/**
 * GeoJSON 对象基础接口
 */
export interface GeoJSONObject {
  type: string;
  coordinates?: any;
}

