import type { Geometry } from './Geometry';

/**
 * GeometryCollection - GeoJSON GeometryCollection 几何体接口
 * 
 * 表示一个 GeoJSON GeometryCollection 对象，包含多个不同类型的几何体。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
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
   * GeoJSON 对象类型，固定为 "GeometryCollection"
   */
  type: 'GeometryCollection';

  /**
   * 几何体数组
   * 可以包含任意类型的 GeoJSON 几何体对象
   */
  geometries: Geometry[];
}

