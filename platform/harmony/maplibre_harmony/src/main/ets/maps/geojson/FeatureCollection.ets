import { Feature } from './Feature';

/**
 * FeatureCollection - GeoJSON FeatureCollection
 */
export class FeatureCollection {
  public type: string = 'FeatureCollection';
  public features: Feature[];

  constructor(features: Feature[] = []) {
    this.features = features;
  }

  /**
   * 从 Feature 数组创建 FeatureCollection
   */
  static fromFeatures(features: Feature[]): FeatureCollection {
    return new FeatureCollection(features);
  }

  /**
   * 获取 Feature 数量
   */
  getFeatureCount(): number {
    return this.features.length;
  }

  /**
   * 获取指定索引的 Feature
   */
  getFeature(index: number): Feature {
    if (index < 0 || index >= this.features.length) {
      throw new Error(`Index ${index} out of bounds`);
    }
    return this.features[index];
  }

  /**
   * 添加 Feature
   */
  addFeature(feature: Feature): void {
    this.features.push(feature);
  }

  /**
   * 移除指定索引的 Feature
   */
  removeFeature(index: number): void {
    if (index < 0 || index >= this.features.length) {
      throw new Error(`Index ${index} out of bounds`);
    }
    this.features.splice(index, 1);
  }

  /**
   * 清空所有 Features
   */
  clear(): void {
    this.features = [];
  }

  /**
   * 转换为 JSON
   */
  toJSON(): ESObject {
    return {
      type: this.type,
      features: this.features.map(f => f.toJSON())
    };
  }
}

