/**
 * LineString - GeoJSON LineString 几何体接口
 * 
 * 表示一个 GeoJSON LineString 对象。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const lineString: LineString = {
 *   type: 'LineString',
 *   coordinates: [
 *     [116.4, 39.9],  // 起点
 *     [121.5, 31.2]   // 终点
 *   ]
 * };
 * ```
 */
export interface LineString {
  /**
   * GeoJSON 对象类型，固定为 "LineString"
   */
  type: 'LineString';

  /**
   * 坐标数组
   * 由两个或更多位置坐标组成的数组
   * 每个位置为 [经度, 纬度] 或 [经度, 纬度, 海拔]
   */
  coordinates: number[][];
}

