/**
 * FeatureProperties - Feature 属性类型
 */
export type FeatureProperties = Record<string, Object>;

/**
 * FeatureGeometry - Feature 几何体类型
 */
export type FeatureGeometry = Object | null;

/**
 * FeatureOptions - Feature 选项接口
 */
export interface FeatureOptions {
  id?: string | number;
  properties?: FeatureProperties;
  geometry?: FeatureGeometry;
}

/**
 * Feature - GeoJSON特征类
 */
export class Feature {
  public type: string = 'Feature';
  public id: string | number | null = null;
  public properties: FeatureProperties = {};
  public geometry: FeatureGeometry = null;

  constructor(options: FeatureOptions = {}) {
    this.id = options.id || null;
    this.properties = options.properties || {};
    this.geometry = options.geometry || null;
  }

  /**
   * 获取ID
   */
  public getId(): string | number | null {
    return this.id;
  }

  /**
   * 设置ID
   */
  public setId(id: string | number | null): void {
    this.id = id;
  }

  /**
   * 获取属性
   */
  public getProperties(): FeatureProperties {
    return this.properties;
  }

  /**
   * 设置属性
   */
  public setProperties(properties: FeatureProperties): void {
    this.properties = properties;
  }

  /**
   * 获取几何体
   */
  public getGeometry(): FeatureGeometry {
    return this.geometry;
  }

  /**
   * 设置几何体
   */
  public setGeometry(geometry: FeatureGeometry): void {
    this.geometry = geometry;
  }

  /**
   * 转换为JSON
   */
  public toJSON(): ESObject {
    return {
      type: this.type,
      id: this.id,
      properties: this.properties,
      geometry: this.geometry
    };
  }
}
