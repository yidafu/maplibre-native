/**
 * MultiPolygon - GeoJSON MultiPolygon 几何体接口
 * 
 * 表示一个 GeoJSON MultiPolygon 对象，包含多个多边形。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const multiPolygon: MultiPolygon = {
 *   type: 'MultiPolygon',
 *   coordinates: [
 *     // 第一个多边形
 *     [
 *       // 外环
 *       [
 *         [116.4, 39.9],
 *         [116.5, 39.9],
 *         [116.5, 40.0],
 *         [116.4, 40.0],
 *         [116.4, 39.9]
 *       ]
 *     ],
 *     // 第二个多边形
 *     [
 *       [
 *         [121.4, 31.2],
 *         [121.5, 31.2],
 *         [121.5, 31.3],
 *         [121.4, 31.3],
 *         [121.4, 31.2]
 *       ]
 *     ]
 *   ]
 * };
 * ```
 */
export interface MultiPolygon {
  /**
   * GeoJSON 对象类型，固定为 "MultiPolygon"
   */
  type: 'MultiPolygon';

  /**
   * 坐标数组
   * 由多个 Polygon 的坐标数组组成
   */
  coordinates: number[][][][];
}

