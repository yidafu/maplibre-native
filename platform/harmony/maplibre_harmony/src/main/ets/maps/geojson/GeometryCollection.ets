/**
 * GeometryCollection - GeoJSON GeometryCollection 类
 */
import type { IGeometryCollection, Geometry } from './types';

/**
 * GeometryCollection 类
 * 
 * 表示一个几何对象集合
 */
export class GeometryCollection implements IGeometryCollection {
  type: 'GeometryCollection' = 'GeometryCollection';
  geometries: Geometry[];

  /**
   * 构造函数
   * 
   * @param geometries Geometry 对象数组
   * 
   * @example
   * ```typescript
   * const collection = new GeometryCollection([
   *   { type: 'Point', coordinates: [116.4, 39.9] },
   *   { type: 'LineString', coordinates: [[116.4, 39.9], [121.5, 31.2]] }
   * ]);
   * ```
   */
  constructor(geometries: Geometry[]) {
    this.geometries = geometries;
  }

  /**
   * 获取几何对象数组
   * 
   * @returns 几何对象数组
   */
  getGeometries(): Geometry[] {
    return this.geometries;
  }

  /**
   * 设置几何对象数组
   * 
   * @param geometries 几何对象数组
   * @returns this，支持链式调用
   */
  setGeometries(geometries: Geometry[]): GeometryCollection {
    this.geometries = geometries;
    return this;
  }

  /**
   * 添加几何对象
   * 
   * @param geometry 几何对象
   * @returns this，支持链式调用
   */
  addGeometry(geometry: Geometry): GeometryCollection {
    this.geometries.push(geometry);
    return this;
  }

  /**
   * 在指定位置插入几何对象
   * 
   * @param index 插入位置
   * @param geometry 几何对象
   * @returns this，支持链式调用
   */
  insertGeometry(index: number, geometry: Geometry): GeometryCollection {
    this.geometries.splice(index, 0, geometry);
    return this;
  }

  /**
   * 移除指定索引的几何对象
   * 
   * @param index 几何对象索引
   * @returns 被移除的几何对象，如果索引无效则返回 undefined
   */
  removeGeometry(index: number): Geometry | undefined {
    if (index >= 0 && index < this.geometries.length) {
      return this.geometries.splice(index, 1)[0];
    }
    return undefined;
  }

  /**
   * 获取指定索引的几何对象
   * 
   * @param index 几何对象索引
   * @returns 几何对象，如果索引无效则返回 undefined
   */
  getGeometry(index: number): Geometry | undefined {
    return this.geometries[index];
  }

  /**
   * 获取几何对象数量
   * 
   * @returns 几何对象数量
   */
  getGeometryCount(): number {
    return this.geometries.length;
  }

  /**
   * 清空所有几何对象
   * 
   * @returns this，支持链式调用
   */
  clear(): GeometryCollection {
    this.geometries = [];
    return this;
  }

  /**
   * 遍历所有几何对象
   * 
   * @param callback 回调函数
   */
  forEach(callback: (geometry: Geometry, index: number) => void): void {
    this.geometries.forEach(callback);
  }

  /**
   * 根据条件过滤几何对象
   * 
   * @param predicate 判断函数
   * @returns 符合条件的几何对象数组
   */
  filter(predicate: (geometry: Geometry) => boolean): Geometry[] {
    return this.geometries.filter(predicate);
  }

  /**
   * 转换为标准 GeoJSON 对象
   * 
   * @returns IGeometryCollection 对象
   */
  toJSON(): IGeometryCollection {
    return {
      type: 'GeometryCollection',
      geometries: this.geometries
    };
  }

  /**
   * 从普通对象创建 GeometryCollection
   * 
   * @param obj 普通对象
   * @returns GeometryCollection 实例
   */
  static fromObject(obj: IGeometryCollection): GeometryCollection {
    return new GeometryCollection(obj.geometries);
  }

  /**
   * 创建空的 GeometryCollection
   * 
   * @returns 空的 GeometryCollection 实例
   */
  static empty(): GeometryCollection {
    return new GeometryCollection([]);
  }
}

