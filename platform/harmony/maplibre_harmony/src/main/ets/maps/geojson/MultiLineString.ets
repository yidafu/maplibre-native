import { Geometry, Coordinates } from './Geometry';

/**
 * MultiLineString - GeoJSON MultiLineString 几何体
 */
export class MultiLineString extends Geometry {
  constructor(coordinates: number[][][]) {
    super('MultiLineString', coordinates);
  }

  /**
   * 从 LineString 数组创建 MultiLineString
   */
  static fromLineStrings(lineStrings: number[][][]): MultiLineString {
    return new MultiLineString(lineStrings);
  }

  /**
   * 获取 LineString 的数量
   */
  getLineStringCount(): number {
    return (this.coordinates as number[][][]).length;
  }

  /**
   * 获取指定索引的 LineString
   */
  getLineString(index: number): number[][] {
    const coords = this.coordinates as number[][][];
    if (index < 0 || index >= coords.length) {
      throw new Error(`Index ${index} out of bounds`);
    }
    return coords[index];
  }

  /**
   * 添加 LineString
   */
  addLineString(lineString: number[][]): void {
    (this.coordinates as number[][][]).push(lineString);
  }
}

