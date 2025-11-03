/**
 * LineString - GeoJSON LineString 几何体类型
 */
export class LineString {
  /**
   * 创建空 LineString
   */
  constructor();

  /**
   * 从坐标数组创建 LineString
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
   * 添加点到 LineString
   * @param lng 经度
   * @param lat 纬度
   */
  addPoint(lng: number, lat: number): this;

  /**
   * 获取点数量
   */
  getPointCount(): number;

  /**
   * 转换为 JSON 对象
   */
  toJSON(): { type: 'LineString', coordinates: number[][] };
}

