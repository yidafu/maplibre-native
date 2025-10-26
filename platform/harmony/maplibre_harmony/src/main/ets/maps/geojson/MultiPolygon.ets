import { Geometry, Coordinates } from './Geometry';

/**
 * MultiPolygon - GeoJSON MultiPolygon 几何体
 */
export class MultiPolygon extends Geometry {
  constructor(coordinates: number[][][][]) {
    super('MultiPolygon', coordinates);
  }

  /**
   * 从 Polygon 数组创建 MultiPolygon
   */
  static fromPolygons(polygons: number[][][][]): MultiPolygon {
    return new MultiPolygon(polygons);
  }

  /**
   * 获取 Polygon 的数量
   */
  getPolygonCount(): number {
    return (this.coordinates as number[][][][]).length;
  }

  /**
   * 获取指定索引的 Polygon
   */
  getPolygon(index: number): number[][][] {
    const coords = this.coordinates as number[][][][];
    if (index < 0 || index >= coords.length) {
      throw new Error(`Index ${index} out of bounds`);
    }
    return coords[index];
  }

  /**
   * 添加 Polygon
   */
  addPolygon(polygon: number[][][]): void {
    (this.coordinates as number[][][][]).push(polygon);
  }
}

