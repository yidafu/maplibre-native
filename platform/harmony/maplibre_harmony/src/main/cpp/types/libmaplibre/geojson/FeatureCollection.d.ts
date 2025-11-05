import type { Feature } from './Feature';

/**
 * FeatureCollection - GeoJSON FeatureCollection 接口
 * 
 * 表示一个 GeoJSON FeatureCollection 对象。
 * C++ 层返回的是符合此结构的普通 JavaScript 对象（对象字面量），而非类实例。
 * 
 * 规范参考：RFC 7946 (GeoJSON)
 * 
 * @example
 * ```typescript
 * const featureCollection: FeatureCollection = {
 *   type: 'FeatureCollection',
 *   features: [
 *     {
 *       type: 'Feature',
 *       geometry: { type: 'Point', coordinates: [116.4, 39.9] },
 *       properties: { name: 'Beijing' }
 *     },
 *     {
 *       type: 'Feature',
 *       geometry: { type: 'Point', coordinates: [121.5, 31.2] },
 *       properties: { name: 'Shanghai' }
 *     }
 *   ]
 * };
 * ```
 */
export interface FeatureCollection {
  /**
   * GeoJSON 对象类型，固定为 "FeatureCollection"
   */
  type: 'FeatureCollection';

  /**
   * Feature 对象数组
   */
  features: Feature[];
}

