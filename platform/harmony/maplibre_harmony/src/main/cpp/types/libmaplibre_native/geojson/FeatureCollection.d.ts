import type { Feature } from './Feature';

/**
 * FeatureCollection - GeoJSON FeatureCollection 类型
 */
export class FeatureCollection {
  /**
   * 创建空 FeatureCollection
   */
  constructor();
  
  /**
   * 从 Feature 数组创建 FeatureCollection
   * @param features Feature 数组
   */
  constructor(features: Feature[]);
  
  /**
   * 获取 Feature 数组
   * @returns Feature[] - NAPI Feature 类实例数组
   */
  getFeatures(): Feature[];
  
  /**
   * 设置 Feature 数组
   * @param features Feature 数组
   */
  setFeatures(features: Feature[]): this;
  
  /**
   * 添加 Feature
   * @param feature Feature 实例
   */
  addFeature(feature: Feature): this;
  
  /**
   * 获取 Feature 数量
   */
  getFeatureCount(): number;
  
  /**
   * 转换为 JSON 对象
   */
  toJSON(): { type: 'FeatureCollection', features: object[] };
}

