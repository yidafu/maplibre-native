/**
 * Polygon - GeoJSON Polygon 几何体类型
 */
export class Polygon {
  /**
   * 创建空 Polygon
   */
  constructor();

  /**
   * 从坐标数组创建 Polygon
   * @param coordinates [[[lng, lat], [lng, lat], ...], ...] (外环 + 可选内环)
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
  toJSON(): { type: 'Polygon', coordinates: number[][][] };
}

