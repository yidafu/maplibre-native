/**
 * Common Type Definitions for MapLibre Native HarmonyOS
 * 
 * Shared type definitions used across the project to improve type safety.
 */

/**
 * JSONValue - JSON 可序列化的值类型
 * 
 * 表示所有可以被 JSON.stringify/parse 处理的值类型
 * 用于动态属性、GeoJSON properties 等场景
 */
export type JSONValue = 
  | string 
  | number 
  | boolean 
  | null 
  | JSONValue[] 
  | JSONObject;

/**
 * JSONObject - JSON 对象类型
 * 
 * 表示键值对象，其中值可以是任何 JSON 可序列化的类型
 */
export type JSONObject = { [key: string]: JSONValue };

/**
 * LightSpecification - 光照配置规范
 * 
 * 定义地图的 3D 光照效果
 * @see https://maplibre.org/maplibre-style-spec/light/
 */
export interface LightSpecification {
  /**
   * 光源锚点
   * - 'map': 光源相对于地图旋转
   * - 'viewport': 光源相对于视口固定
   */
  anchor?: 'map' | 'viewport';

  /**
   * 光源位置 [方位角, 极角]
   * - 方位角: 光源围绕地图中心的水平角度 (0-360)
   * - 极角: 光源相对于地平面的角度 (0-90)
   */
  position?: [number, number] | [number, number, number];

  /**
   * 光源颜色
   * CSS 颜色值，如 '#ffffff', 'rgb(255,255,255)'
   */
  color?: string;

  /**
   * 光照强度
   * 范围 0-1，默认 0.5
   */
  intensity?: number;
}

/**
 * TransitionOptions - 过渡动画选项
 * 
 * 定义样式属性变化时的过渡效果
 */
export interface TransitionOptions {
  /**
   * 过渡持续时间（毫秒）
   */
  duration?: number;

  /**
   * 过渡延迟时间（毫秒）
   */
  delay?: number;
}

/**
 * MapSnapshotterObserver - 快照器观察者接口
 * 
 * 用于监听快照器的状态变化
 */
export interface MapSnapshotterObserver {
  /**
   * 样式加载完成时调用
   */
  onDidFinishLoadingStyle(): void;

  /**
   * 样式图片缺失时调用
   * @param imageName 缺失的图片名称
   */
  onStyleImageMissing(imageName: string): void;
}

