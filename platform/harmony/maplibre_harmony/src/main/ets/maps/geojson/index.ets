/**
 * GeoJSON Types - GeoJSON 类型和类导出
 *
 * 提供符合 GeoJSON 规范 (RFC 7946) 的类型定义和实现
 */
// ==================== GeoJson 对象（向后兼容）====================
import {
  point,
  lineString,
  polygon,
  multiPoint,
  multiLineString,
  multiPolygon,
  geometryCollection,
  feature,
  featureCollection,
  pointFeature,
  lineStringFeature,
  polygonFeature
} from './factory';

/**
 * GeoJson 命名空间类
 * 
 * 提供 GeoJSON 工厂函数的访问方式
 * 
 * @example
 * ```typescript
 * const pt = GeoJson.point([116.4, 39.9]);
 * const line = GeoJson.lineString([[116.4, 39.9], [121.5, 31.2]]);
 * const ft = GeoJson.feature(pt, { name: 'Beijing' });
 * ```
 */
export class GeoJson {
  // 小写工厂函数
  static point = point;
  static lineString = lineString;
  static polygon = polygon;
  static multiPoint = multiPoint;
  static multiLineString = multiLineString;
  static multiPolygon = multiPolygon;
  static geometryCollection = geometryCollection;
  static feature = feature;
  static featureCollection = featureCollection;
  static pointFeature = pointFeature;
  static lineStringFeature = lineStringFeature;
  static polygonFeature = polygonFeature;
}

// 导出了 IPoint IPolygon 接口避免类型冲突
export * from './types';