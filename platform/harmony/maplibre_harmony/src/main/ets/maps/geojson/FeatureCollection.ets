/**
 * FeatureCollection - GeoJSON FeatureCollection 类
 * 
 * 提供符合 GeoJSON 规范的 FeatureCollection 对象实现
 */
import type { IFeatureCollection, IFeature } from './types';


/**
 * FeatureCollection 类
 * 
 * 表示一个 Feature 对象集合
 */
export class FeatureCollection implements IFeatureCollection {
  type: 'FeatureCollection' = 'FeatureCollection';
  features: IFeature[];

  /**
   * 构造函数
   * 
   * @param features Feature 数组
   * 
   * @example
   * ```typescript
   * const collection = new FeatureCollection([
   *   new Feature({ geometry: { type: 'Point', coordinates: [116.4, 39.9] }, properties: {} }),
   *   new Feature({ geometry: { type: 'Point', coordinates: [121.5, 31.2] }, properties: {} })
   * ]);
   * ```
   */
  constructor(features: IFeature[]) {
    this.features = features;
  }

  /**
   * 获取 Feature 数组
   * 
   * @returns Feature 数组
   */
  getFeatures(): IFeature[] {
    return this.features;
  }

  /**
   * 设置 Feature 数组
   * 
   * @param features Feature 数组
   * @returns this，支持链式调用
   */
  setFeatures(features: IFeature[]): FeatureCollection {
    this.features = features;
    return this;
  }

  /**
   * 添加 Feature
   * 
   * @param feature Feature 对象
   * @returns this，支持链式调用
   */
  addFeature(feature: IFeature): FeatureCollection {
    this.features.push(feature);
    return this;
  }

  /**
   * 在指定位置插入 Feature
   * 
   * @param index 插入位置
   * @param feature Feature 对象
   * @returns this，支持链式调用
   */
  insertFeature(index: number, feature: IFeature): FeatureCollection {
    this.features.splice(index, 0, feature);
    return this;
  }

  /**
   * 移除指定索引的 Feature
   * 
   * @param index Feature 索引
   * @returns 被移除的 Feature，如果索引无效则返回 undefined
   */
  removeFeature(index: number): IFeature | undefined {
    if (index >= 0 && index < this.features.length) {
      return this.features.splice(index, 1)[0];
    }
    return undefined;
  }

  /**
   * 根据 ID 查找 Feature
   * 
   * @param id Feature ID
   * @returns Feature 对象，如果未找到则返回 undefined
   */
  findFeatureById(id: string | number): IFeature | undefined {
    return this.features.find(f => f.id === id);
  }

  /**
   * 根据条件查找 Feature
   * 
   * @param predicate 判断函数
   * @returns Feature 对象，如果未找到则返回 undefined
   */
  findFeature(predicate: (feature: IFeature) => boolean): IFeature | undefined {
    return this.features.find(predicate);
  }

  /**
   * 根据条件过滤 Feature
   * 
   * @param predicate 判断函数
   * @returns 符合条件的 Feature 数组
   */
  filterFeatures(predicate: (feature: IFeature) => boolean): IFeature[] {
    return this.features.filter(predicate);
  }

  /**
   * 获取指定索引的 Feature
   * 
   * @param index Feature 索引
   * @returns Feature 对象，如果索引无效则返回 undefined
   */
  getFeature(index: number): IFeature | undefined {
    return this.features[index];
  }

  /**
   * 获取 Feature 数量
   * 
   * @returns Feature 数量
   */
  getFeatureCount(): number {
    return this.features.length;
  }

  /**
   * 清空所有 Feature
   * 
   * @returns this，支持链式调用
   */
  clear(): FeatureCollection {
    this.features = [];
    return this;
  }

  /**
   * 遍历所有 Feature
   * 
   * @param callback 回调函数
   */
  forEach(callback: (feature: IFeature, index: number) => void): void {
    this.features.forEach(callback);
  }

  /**
   * 转换为标准 GeoJSON 对象
   * 
   * @returns IFeatureCollection 对象
   */
  toJSON(): IFeatureCollection {
    return {
      type: 'FeatureCollection',
      features: this.features
    };
  }

  /**
   * 从普通对象创建 FeatureCollection
   * 
   * @param obj 普通对象
   * @returns FeatureCollection 实例
   */
  static fromObject(obj: IFeatureCollection): FeatureCollection {
    return new FeatureCollection(obj.features);
  }

  /**
   * 创建空的 FeatureCollection
   * 
   * @returns 空的 FeatureCollection 实例
   */
  static empty(): FeatureCollection {
    return new FeatureCollection([]);
  }
}

