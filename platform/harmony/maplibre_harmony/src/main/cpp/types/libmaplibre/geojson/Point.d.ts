/**
 * Point - GeoJSON Point 几何体接口
 * 
 * 表示一个 GeoJSON Point 对象。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const point: Point = {
 *   type: 'Point',
 *   coordinates: [116.4, 39.9]  // [经度, 纬度]
 * };
 * ```
 */
export interface Point {
  /**
   * GeoJSON 对象类型，固定为 "Point"
   */
  type: 'Point';

  /**
   * 坐标数组
   * - 2D: [经度, 纬度]
   * - 3D: [经度, 纬度, 海拔]
   */
  coordinates: number[];
}

