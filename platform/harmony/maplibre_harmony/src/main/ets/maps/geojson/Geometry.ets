/**
 * 坐标类型定义
 * 可以是单个坐标、坐标数组或嵌套坐标数组
 */
export type Coordinates = number[] | number[][] | number[][][] | number[][][][];

/**
 * GeoJSON对象接口
 */
export interface GeoJSONObject {
  type: string;
  coordinates: Coordinates;
}

/**
 * Geometry - GeoJSON几何体基类
 */
export abstract class Geometry {
  public type: string;
  public coordinates: Coordinates;

  constructor(type: string, coordinates: Coordinates) {
    this.type = type;
    this.coordinates = coordinates;
  }

  /**
   * 获取类型
   */
  public getType(): string {
    return this.type;
  }

  /**
   * 获取坐标
   */
  public getCoordinates(): Coordinates {
    return this.coordinates;
  }

  /**
   * 设置坐标
   */
  public setCoordinates(coordinates: Coordinates): void {
    this.coordinates = coordinates;
  }

  /**
   * 转换为JSON
   */
  public toJSON(): GeoJSONObject {
    return {
      type: this.type,
      coordinates: this.coordinates
    };
  }
}
