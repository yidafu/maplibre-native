/**
 * Feature - GeoJSON特征类
 */
export class Feature {
  public type: string = 'Feature';
  public id: string | number | null = null;
  public properties: any = {};
  public geometry: any = null;

  constructor(options: {
    id?: string | number;
    properties?: any;
    geometry?: any;
  } = {}) {
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
  public getProperties(): any {
    return this.properties;
  }

  /**
   * 设置属性
   */
  public setProperties(properties: any): void {
    this.properties = properties;
  }

  /**
   * 获取几何体
   */
  public getGeometry(): any {
    return this.geometry;
  }

  /**
   * 设置几何体
   */
  public setGeometry(geometry: any): void {
    this.geometry = geometry;
  }

  /**
   * 转换为JSON
   */
  public toJSON(): any {
    return {
      type: this.type,
      id: this.id,
      properties: this.properties,
      geometry: this.geometry
    };
  }
}
