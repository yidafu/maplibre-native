/**
 * MultiLineString - GeoJSON MultiLineString 几何体类型
 */
export class MultiLineString {
  /**
   * 创建空 MultiLineString
   */
  constructor();
  
  /**
   * 从坐标数组创建 MultiLineString
   * @param coordinates [[[lng, lat], [lng, lat], ...], ...]
   */
  constructor(coordinates: number[][][]);
  
  /**
   * 获取坐标数组
   * @returns [[[lng, lat], [lng, lat], ...], ...]
   */
  getCoordinates(): number[][][];
  
  /**
   * 设置坐标
   * @param coordinates [[[lng, lat], [lng, lat], ...], ...]
   */
  setCoordinates(coordinates: number[][][]): this;
  
  /**
   * 转换为 JSON 对象
   */
  toJSON(): { type: 'MultiLineString', coordinates: number[][][] };
}

