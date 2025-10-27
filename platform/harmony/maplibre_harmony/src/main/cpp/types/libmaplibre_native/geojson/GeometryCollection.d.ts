import type { Geometry } from './Geometry';

/**
 * GeometryCollection - GeoJSON GeometryCollection 几何体类型
 */
export class GeometryCollection {
  /**
   * 创建空 GeometryCollection
   */
  constructor();
  
  /**
   * 获取几何体数组
   * @returns Geometry[] - NAPI 几何体类实例数组
   */
  getGeometries(): Geometry[];
  
  /**
   * 转换为 JSON 对象
   */
  toJSON(): { type: 'GeometryCollection', geometries: object[] };
}

