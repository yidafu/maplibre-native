import { Geometry, Coordinates } from './Geometry';

/**
 * Polygon - GeoJSON Polygon 几何体
 */
export class Polygon extends Geometry {
  constructor(coordinates: number[][][]) {
    super('Polygon', coordinates);
    if (coordinates.length < 1) {
      throw new Error('Polygon must have at least one ring (exterior)');
    }
  }

  /**
   * 从外环创建 Polygon
   */
  static fromOuterRing(outerRing: number[][]): Polygon {
    return new Polygon([outerRing]);
  }

  /**
   * 从外环和内环（holes）创建 Polygon
   */
  static fromRings(outerRing: number[][], innerRings?: number[][][]): Polygon {
    const coordinates = [outerRing];
    if (innerRings && innerRings.length > 0) {
      coordinates.push(...innerRings);
    }
    return new Polygon(coordinates);
  }

  /**
   * 获取外环
   */
  getOuterRing(): number[][] {
    return (this.coordinates as number[][][])[0];
  }

  /**
   * 获取内环（holes）
   */
  getInnerRings(): number[][][] {
    const coords = this.coordinates as number[][][];
    return coords.slice(1);
  }

  /**
   * 获取环的数量（外环 + 内环）
   */
  getRingCount(): number {
    return (this.coordinates as number[][][]).length;
  }

  /**
   * 添加内环（hole）
   */
  addInnerRing(ring: number[][]): void {
    (this.coordinates as number[][][]).push(ring);
  }
}

