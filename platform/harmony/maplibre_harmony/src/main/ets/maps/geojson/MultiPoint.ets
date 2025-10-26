import { Geometry, Coordinates } from './Geometry';

/**
 * MultiPoint - GeoJSON MultiPoint 几何体
 */
export class MultiPoint extends Geometry {
  constructor(coordinates: number[][]) {
    super('MultiPoint', coordinates);
  }

  /**
   * 从坐标数组创建 MultiPoint
   */
  static fromLngLats(coordinates: number[][]): MultiPoint {
    return new MultiPoint(coordinates);
  }

  /**
   * 获取点的数量
   */
  getPointCount(): number {
    return (this.coordinates as number[][]).length;
  }

  /**
   * 获取指定索引的点
   */
  getPoint(index: number): number[] {
    const coords = this.coordinates as number[][];
    if (index < 0 || index >= coords.length) {
      throw new Error(`Index ${index} out of bounds`);
    }
    return coords[index];
  }

  /**
   * 添加点
   */
  addPoint(lng: number, lat: number): void {
    (this.coordinates as number[][]).push([lng, lat]);
  }
}

