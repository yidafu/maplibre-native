/**
 * MultiPoint - GeoJSON MultiPoint 几何体接口
 * 
 * 表示一个 GeoJSON MultiPoint 对象，包含多个点。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const multiPoint: MultiPoint = {
 *   type: 'MultiPoint',
 *   coordinates: [
 *     [116.4, 39.9],  // 北京
 *     [121.5, 31.2],  // 上海
 *     [113.3, 23.1]   // 广州
 *   ]
 * };
 * ```
 */
export interface MultiPoint {
  /**
   * GeoJSON 对象类型，固定为 "MultiPoint"
   */
  type: 'MultiPoint';

  /**
   * 坐标数组
   * 由多个位置坐标组成的数组
   * 每个位置为 [经度, 纬度] 或 [经度, 纬度, 海拔]
   */
  coordinates: number[][];
}

