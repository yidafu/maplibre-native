import type { Geometry } from './Geometry';
import type { JSONValue } from '../CommonTypes';

/**
 * Feature - GeoJSON Feature 类型
 */
export class Feature {
  /**
   * 创建 Feature
   * @param options 可选配置对象
   */
  constructor(options?: {
    id?: string | number;
    geometry?: Geometry;
    properties?: Record<string, JSONValue>;
  });

  /**
   * 获取特征 ID
   */
  getId(): string | number | null;

  /**
   * 设置特征 ID
   */
  setId(id: string | number | null): this;

  /**
   * 获取属性对象
   */
  getProperties(): Record<string, JSONValue>;

  /**
   * 设置属性对象
   */
  setProperties(properties: Record<string, JSONValue>): this;

  /**
   * 获取几何体对象
   */
  getGeometry(): Geometry;

  /**
   * 设置几何体对象
   */
  setGeometry(geometry: Geometry): this;

  /**
   * 转换为 JSON 对象
   */
  toJSON(): {
    type: 'Feature';
    id?: string | number;
    geometry: object;
    properties: Record<string, JSONValue>;
  };
}

