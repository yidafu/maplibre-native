import type { LightSpecification, TransitionOptions } from '../CommonTypes';

/**
 * Light - 样式光照控制类
 *
 * 与 Android/iOS 的 Light API 对齐，提供光照 anchor、position、color、intensity 以及过渡动画设置能力。
 * 通过 Style.getLight() 或 MapLibreMap.getLight() 获取实例，禁止直接构造。
 */
export class Light {
  /**
   * 获取光照锚点
   * @returns 'map' 或 'viewport'
   */
  getAnchor(): 'map' | 'viewport';

  /**
   * 设置光照锚点
   * @param anchor 'map' 或 'viewport'
   */
  setAnchor(anchor: 'map' | 'viewport'): void;

  /**
   * 获取光照位置（球坐标）
   * @returns 包含 radial、azimuthal、polar 的对象，单位与 MapLibre Style 规范一致
   */
  getPosition(): { radial: number; azimuthal: number; polar: number };

  /**
   * 设置光照位置（球坐标）
   * @param position 可为对象 { radial, azimuthal, polar } 或长度 ≥2 的数组 [radial, azimuthal, polar?]
   */
  setPosition(position: { radial: number; azimuthal: number; polar?: number } | number[]): void;

  /**
   * 获取位置过渡动画
   * @returns 过渡配置（毫秒）
   */
  getPositionTransition(): TransitionOptions;

  /**
   * 设置位置过渡动画
   * @param duration 持续时间（毫秒）
   * @param delay 延迟（毫秒）
   */
  setPositionTransition(duration: number, delay: number): void;

  /**
   * 获取光照颜色
   * @returns CSS 颜色字符串
   */
  getColor(): string;

  /**
   * 设置光照颜色
   * @param color CSS 颜色字符串
   */
  setColor(color: string): void;

  /**
   * 获取颜色过渡动画
   */
  getColorTransition(): TransitionOptions;

  /**
   * 设置颜色过渡动画
   * @param duration 持续时间（毫秒）
   * @param delay 延迟（毫秒）
   */
  setColorTransition(duration: number, delay: number): void;

  /**
   * 获取光照强度
   * @returns 光照强度（0-1）
   */
  getIntensity(): number;

  /**
   * 设置光照强度
   * @param intensity 光照强度（0-1）
   */
  setIntensity(intensity: number): void;

  /**
   * 获取强度过渡动画
   */
  getIntensityTransition(): TransitionOptions;

  /**
   * 设置强度过渡动画
   * @param duration 持续时间（毫秒）
   * @param delay 延迟（毫秒）
   */
  setIntensityTransition(duration: number, delay: number): void;

}

