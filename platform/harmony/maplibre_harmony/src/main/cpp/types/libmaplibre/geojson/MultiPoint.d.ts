/**
 * MultiPoint - GeoJSON MultiPoint 几何体类型
 */
export class MultiPoint {
  /**
   * 创建空 MultiPoint
   */
  constructor();

  /**
   * 从坐标数组创建 MultiPoint
   * @param coordinates [[lng, lat], [lng, lat], ...]
   */
  constructor(coordinates: number[][]);

  /**
   * 获取坐标数组
   * @returns [[lng, lat], [lng, lat], ...]
   */
  getCoordinates(): number[][];

  /**
   * 设置坐标
   * @param coordinates [[lng, lat], [lng, lat], ...]
   */
  setCoordinates(coordinates: number[][]): this;

  /**
   * 转换为 JSON 对象
   */
  toJSON(): { type: 'MultiPoint', coordinates: number[][] };
}

