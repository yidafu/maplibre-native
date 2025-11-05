/**
 * Polygon - GeoJSON Polygon 几何体接口
 * 
 * 表示一个 GeoJSON Polygon 对象。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const polygon: Polygon = {
 *   type: 'Polygon',
 *   coordinates: [
 *     // 外环（必需）
 *     [
 *       [116.4, 39.9],
 *       [116.5, 39.9],
 *       [116.5, 40.0],
 *       [116.4, 40.0],
 *       [116.4, 39.9]  // 首尾相连形成闭环
 *     ],
 *     // 内环（可选，表示孔洞）
 *     [
 *       [116.42, 39.92],
 *       [116.48, 39.92],
 *       [116.48, 39.98],
 *       [116.42, 39.98],
 *       [116.42, 39.92]
 *     ]
 *   ]
 * };
 * ```
 */
export interface Polygon {
  /**
   * GeoJSON 对象类型，固定为 "Polygon"
   */
  type: 'Polygon';

  /**
   * 坐标数组
   * 由一个或多个线性环（LinearRing）组成的数组
   * - 第一个环是外环（外边界）
   * - 后续环是内环（孔洞），可选
   * 每个环必须首尾相连形成闭环
   */
  coordinates: number[][][];
}

