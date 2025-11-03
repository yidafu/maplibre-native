/**
 * GeoJSON 类型定义
 *
 * 符合 GeoJSON 规范 (RFC 7946) 的类型定义
 */

// ==================== 基础类型 ====================

/**
 * 位置坐标类型 - 从 libmaplibre.so 导入
 * [longitude, latitude] 或 [longitude, latitude, altitude]
 */
import type { Position, Position2D, Position3D } from 'libmaplibre.so';

export type { Position, Position2D, Position3D };

// ==================== Geometry 接口 ====================

/**
 * Geometry 基础接口
 */
export interface IGeometry {
  type: string;
}

/**
 * Point 几何类型
 */
export interface IPoint extends IGeometry {
  type: 'Point';
  coordinates: Position;
}

/**
 * LineString 几何类型
 */
export interface ILineString extends IGeometry {
  type: 'LineString';
  coordinates: Position[];
}

/**
 * Polygon 几何类型
 */
export interface IPolygon extends IGeometry {
  type: 'Polygon';
  coordinates: Position[][];
}

/**
 * MultiPoint 几何类型
 */
export interface IMultiPoint extends IGeometry {
  type: 'MultiPoint';
  coordinates: Position[];
}

/**
 * MultiLineString 几何类型
 */
export interface IMultiLineString extends IGeometry {
  type: 'MultiLineString';
  coordinates: Position[][];
}

/**
 * MultiPolygon 几何类型
 */
export interface IMultiPolygon extends IGeometry {
  type: 'MultiPolygon';
  coordinates: Position[][][];
}

/**
 * GeometryCollection 几何类型
 */
export interface IGeometryCollection extends IGeometry {
  type: 'GeometryCollection';
  geometries: Geometry[];
}

/**
 * Geometry 联合类型
 */
export type Geometry =
  | IPoint
    | ILineString
    | IPolygon
    | IMultiPoint
    | IMultiLineString
    | IMultiPolygon
    | IGeometryCollection;

// ==================== Feature 接口 ====================

/**
 * Feature 接口
 */
export interface IFeature {
  type: 'Feature';
  id?: string | number;
  geometry: Geometry;
  properties: Record<string, Object>;
  layer?: string; // 图层ID（可选）
}

/**
 * FeatureCollection 接口
 */
export interface IFeatureCollection {
  type: 'FeatureCollection';
  features: IFeature[];
}

