
/**
 * GeoJSON 工厂函数
 *
 * 提供便捷的工厂函数来创建 GeoJSON 接口对象（普通对象）
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
// ==================== Geometry 工厂函数 ====================

/**
 * 创建 Point 对象
 *
 * @param coordinates 坐标 [longitude, latitude] 或 [longitude, latitude, altitude]
 * @returns IPoint 对象
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
 * 创建 LineString 对象
 *
 * @param coordinates 坐标数组
 * @returns ILineString 对象
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
 * 创建 Polygon 对象
 *
 * @param coordinates 坐标数组（第一个数组是外环，其余是内环）
 * @returns IPolygon 对象
 *
 * @example
* ```typescript
 * const poly = polygon([
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
export function polygon(coordinates: Position[][]): IPolygon {
  return {
    type: 'Polygon',
    coordinates
  };
}

/**
 * 创建 MultiPoint 对象
 *
 * @param coordinates 坐标数组
 * @returns IMultiPoint 对象
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
 * 创建 MultiLineString 对象
 *
 * @param coordinates 坐标数组
 * @returns IMultiLineString 对象
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
 * 创建 MultiPolygon 对象
 *
 * @param coordinates 坐标数组
 * @returns IMultiPolygon 对象
 *
 * @example
* ```typescript
 * const multiPoly = multiPolygon([
 *   [ // 第一个多边形
 *     [[116.3, 39.8], [116.5, 39.8], [116.5, 40.0], [116.3, 40.0], [116.3, 39.8]]
 *   ],
 *   [ // 第二个多边形
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
 * 创建 GeometryCollection 对象
 *
 * @param geometries Geometry 对象数组
 * @returns IGeometryCollection 对象
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

// ==================== Feature 工厂函数 ====================

/**
 * Feature 选项接口
 */
export interface CreateFeatureOptions {
  id?: string | number;
  geometry: Geometry;
  properties?: Record<string, JSONValue>;
}

/**
 * 创建 Feature 对象
 *
 * @param options Feature 选项
 * @returns IFeature 对象
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
 * 创建 Feature 对象（简化版本）
 *
 * @param geometry Geometry 对象
 * @param properties 属性对象（可选）
 * @param id Feature ID（可选）
 * @returns IFeature 对象
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

// 实现
export function feature(
  optionsOrGeometry: CreateFeatureOptions | Geometry,
  properties?: Record<string, JSONValue>,
  id?: string | number
): IFeature {
  // ArkTS 不支持 'in' 操作符，通过检查属性是否存在来判断
  const maybeGeometry = optionsOrGeometry as Geometry;
  if (maybeGeometry.type !== undefined && typeof maybeGeometry.type === 'string') {
    // 第二种重载：geometry, properties, id
    return {
      type: 'Feature',
      id,
      geometry: optionsOrGeometry as Geometry,
      properties: (properties || {}) as Record<string, JSONValue>
    };
  } else {
    // 第一种重载：options 对象
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
 * 创建 FeatureCollection 对象
 *
 * @param features Feature 对象数组
 * @returns IFeatureCollection 对象
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

// ==================== 便捷组合函数 ====================

/**
 * 创建带有 Point 几何的 Feature
 *
 * @param coordinates 坐标
 * @param properties 属性
 * @param id Feature ID
 * @returns IFeature 对象
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
 * 创建带有 LineString 几何的 Feature
 *
 * @param coordinates 坐标数组
 * @param properties 属性
 * @param id Feature ID
 * @returns IFeature 对象
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
 * 创建带有 Polygon 几何的 Feature
 *
 * @param coordinates 坐标数组
 * @param properties 属性
 * @param id Feature ID
 * @returns IFeature 对象
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

