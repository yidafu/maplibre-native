/**
 * MultiPolygon - GeoJSON MultiPolygon 几何体类型
 */
export class MultiPolygon {
  /**
   * 创建空 MultiPolygon
   */
  constructor();
  
  /**
   * 从坐标数组创建 MultiPolygon
   * @param coordinates [[[[lng, lat], ...], ...], ...]
   */
  constructor(coordinates: number[][][][]);
  
  /**
   * 获取坐标数组
   * @returns [[[[lng, lat], ...], ...], ...]
   */
  getCoordinates(): number[][][][];
  
  /**
   * 设置坐标
   * @param coordinates [[[[lng, lat], ...], ...], ...]
   */
  setCoordinates(coordinates: number[][][][]): this;
  
  /**
   * 转换为 JSON 对象
   */
  toJSON(): { type: 'MultiPolygon', coordinates: number[][][][] };
}

