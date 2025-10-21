/**
 * Geometry - GeoJSON几何体基类
 */
export abstract class Geometry {
  public type: string;
  public coordinates: any;

  constructor(type: string, coordinates: any) {
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
  public getCoordinates(): any {
    return this.coordinates;
  }

  /**
   * 设置坐标
   */
  public setCoordinates(coordinates: any): void {
    this.coordinates = coordinates;
  }

  /**
   * 转换为JSON
   */
  public toJSON(): any {
    return {
      type: this.type,
      coordinates: this.coordinates
    };
  }
}
