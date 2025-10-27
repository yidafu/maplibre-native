/**
 * Point - GeoJSON Point 几何体类型
 */
export class Point {
  /**
   * 从经纬度数组创建 Point
   * @param lng 经度
   * @param lat 纬度
   * @param altitude 可选的海拔高度
   */
  constructor(lng: number, lat: number, altitude?: number);
  
  /**
   * 从坐标数组创建 Point
   * @param coordinates [lng, lat] 或 [lng, lat, altitude]
   */
  constructor(coordinates: number[]);
  
  /**
   * 获取坐标数组
   * @returns [lng, lat] 或 [lng, lat, altitude]
   */
  getCoordinates(): number[];
  
  /**
   * 设置坐标
   * @param coordinates [lng, lat] 或 [lng, lat, altitude]
   */
  setCoordinates(coordinates: number[]): this;
  
  /**
   * 获取经度
   */
  getLongitude(): number;
  
  /**
   * 获取纬度
   */
  getLatitude(): number;
  
  /**
   * 获取海拔高度
   */
  getAltitude(): number | undefined;
  
  /**
   * 设置经度
   */
  setLongitude(lng: number): this;
  
  /**
   * 设置纬度
   */
  setLatitude(lat: number): this;
  
  /**
   * 设置海拔高度
   */
  setAltitude(altitude: number): this;
  
  /**
   * 转换为 JSON 对象
   */
  toJSON(): { type: 'Point', coordinates: number[] };
}

