/**
 * MultiLineString - GeoJSON MultiLineString 几何体接口
 * 
 * 表示一个 GeoJSON MultiLineString 对象，包含多条线。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const multiLineString: MultiLineString = {
 *   type: 'MultiLineString',
 *   coordinates: [
 *     // 第一条线
 *     [
 *       [116.4, 39.9],
 *       [121.5, 31.2]
 *     ],
 *     // 第二条线
 *     [
 *       [113.3, 23.1],
 *       [114.1, 22.5]
 *     ]
 *   ]
 * };
 * ```
 */
export interface MultiLineString {
  /**
   * GeoJSON 对象类型，固定为 "MultiLineString"
   */
  type: 'MultiLineString';

  /**
   * 坐标数组
   * 由多条 LineString 的坐标数组组成
   */
  coordinates: number[][][];
}

