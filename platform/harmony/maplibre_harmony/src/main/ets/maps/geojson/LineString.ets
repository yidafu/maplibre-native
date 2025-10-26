import { Geometry, Coordinates } from './Geometry';

/**
 * LineString - GeoJSON LineString 几何体
 */
export class LineString extends Geometry {
  constructor(coordinates: number[][]) {
    super('LineString', coordinates);
    if (coordinates.length < 2) {
      throw new Error('LineString must have at least 2 coordinates');
    }
  }

  /**
   * 从坐标数组创建 LineString
   */
  static fromLngLats(coordinates: number[][]): LineString {
    return new LineString(coordinates);
  }

  /**
   * 获取坐标点数量
   */
  getPointCount(): number {
    return (this.coordinates as number[][]).length;
  }

  /**
   * 获取指定索引的坐标点
   */
  getPoint(index: number): number[] {
    const coords = this.coordinates as number[][];
    if (index < 0 || index >= coords.length) {
      throw new Error(`Index ${index} out of bounds`);
    }
    return coords[index];
  }

  /**
   * 添加坐标点
   */
  addPoint(lng: number, lat: number): void {
    (this.coordinates as number[][]).push([lng, lat]);
  }
}

