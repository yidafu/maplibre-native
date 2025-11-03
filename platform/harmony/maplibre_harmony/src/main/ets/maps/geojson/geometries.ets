/**
 * Geometry 工厂函数
 *
 * 提供便捷的 Geometry 对象创建方法
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
 * 创建 Point 几何对象
 *
 * @param coordinates 坐标 [longitude, latitude] 或 [longitude, latitude, altitude]
 * @returns Point 对象
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
 * 创建 LineString 几何对象
 *
 * @param coordinates 坐标数组
 * @returns LineString 对象
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
 * 创建 Polygon 几何对象
 *
 * @param coordinates 坐标数组（第一个数组是外环，其余是内环）
 * @returns Polygon 对象
 *
 * @example
* ```typescript
 * const polygon = Polygon([
 *   [ // 外环
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
 * 创建 MultiPoint 几何对象
 *
 * @param coordinates 坐标数组
 * @returns MultiPoint 对象
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
 * 创建 MultiLineString 几何对象
 *
 * @param coordinates 坐标数组
 * @returns MultiLineString 对象
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
 * 创建 MultiPolygon 几何对象
 *
 * @param coordinates 坐标数组
 * @returns MultiPolygon 对象
 *
 * @example
* ```typescript
 * const multiPolygon = MultiPolygon([
 *   [ // 第一个多边形
 *     [[116.3, 39.8], [116.5, 39.8], [116.5, 40.0], [116.3, 40.0], [116.3, 39.8]]
 *   ],
 *   [ // 第二个多边形
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
 * 创建 GeometryCollection 几何对象
 *
 * @param geometries Geometry 对象数组
 * @returns GeometryCollection 对象
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

