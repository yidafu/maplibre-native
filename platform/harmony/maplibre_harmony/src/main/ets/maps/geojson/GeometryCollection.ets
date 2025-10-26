import { Geometry } from './Geometry';

/**
 * GeometryCollection - GeoJSON GeometryCollection 几何体
 */
export class GeometryCollection {
  public type: string = 'GeometryCollection';
  public geometries: Geometry[];

  constructor(geometries: Geometry[]) {
    this.geometries = geometries;
  }

  /**
   * 从几何体数组创建 GeometryCollection
   */
  static fromGeometries(geometries: Geometry[]): GeometryCollection {
    return new GeometryCollection(geometries);
  }

  /**
   * 获取几何体数量
   */
  getGeometryCount(): number {
    return this.geometries.length;
  }

  /**
   * 获取指定索引的几何体
   */
  getGeometry(index: number): Geometry {
    if (index < 0 || index >= this.geometries.length) {
      throw new Error(`Index ${index} out of bounds`);
    }
    return this.geometries[index];
  }

  /**
   * 添加几何体
   */
  addGeometry(geometry: Geometry): void {
    this.geometries.push(geometry);
  }

  /**
   * 转换为 JSON
   */
  toJSON(): ESObject {
    return {
      type: this.type,
      geometries: this.geometries.map(g => g.toJSON())
    };
  }
}

