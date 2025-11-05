import type { LightSpecification } from 'libmaplibre.so';

/**
 * Light - 光照类型
 * 
 * 从 libmaplibre.so 重新导出 LightSpecification。
 * C++ 层返回的是符合此规范的普通 JavaScript 对象（对象字面量）。
 * 
 * 规范参考：https://maplibre.org/maplibre-style-spec/light/
 * 
 * @example
 * ```typescript
 * // 获取当前光照
 * const light = map.getLight();
 * 
 * // 创建光照配置
 * const lightConfig: Light = {
 *   anchor: 'viewport',
 *   position: [1.15, 210, 30],
 *   color: '#ffffff',
 *   intensity: 0.5
 * };
 * ```
 */
export type Light = LightSpecification;

/**
 * LightOptions - 光照选项接口（向后兼容）
 * 
 * @deprecated 请使用 Light 或 LightSpecification 类型
 */
export type LightOptions = LightSpecification;
