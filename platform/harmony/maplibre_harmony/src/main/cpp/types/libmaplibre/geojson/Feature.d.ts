import type { Geometry } from './Geometry';
import type { JSONValue } from '../CommonTypes';

/**
 * Feature - GeoJSON Feature 接口
 * 
 * 表示一个 GeoJSON Feature 对象。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量），而非类实例。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const feature: Feature = {
 *   type: 'Feature',
 *   id: 'feature-1',
 *   geometry: {
 *     type: 'Point',
 *     coordinates: [116.4, 39.9]
 *   },
 *   properties: {
 *     name: 'Beijing',
 *     population: 21540000
 *   },
 *   layer: 'poi-layer'  // MapLibre 扩展字段
 * };
 * ```
 */
export interface Feature {
  /**
   * GeoJSON 对象类型，固定为 "Feature"
   */
  type: 'Feature';

  /**
   * Feature 的唯一标识符（可选）
   * 可以是字符串或数字
   */
  id?: string | number;

  /**
   * Feature 的几何形状
   * 可以是 Point, LineString, Polygon 等任意 GeoJSON Geometry 类型
   */
  geometry: Geometry;

  /**
   * Feature 的属性对象
   * 存储与该 Feature 相关的任意键值对数据
   */
  properties: Record<string, JSONValue>;

  /**
   * MapLibre 扩展字段：样式图层 ID
   * 在 queryRenderedFeatures 返回的结果中，表示该 Feature 所属的样式图层
   * 
   * 注意：这不是 GeoJSON 标准字段，而是 MapLibre 的扩展
   */
  layer?: string;

  /**
   * MapLibre 扩展字段：数据源 ID
   * 表示该 Feature 来源的数据源
   * 
   * 注意：这不是 GeoJSON 标准字段，而是 MapLibre 的扩展
   */
  source?: string;
}

