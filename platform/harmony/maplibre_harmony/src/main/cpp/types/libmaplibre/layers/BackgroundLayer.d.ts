/**
 * MapLibre Native for HarmonyOS - BackgroundLayer Type Definitions
 * 背景图层 API (NAPI 类)
 */

import type { ColorValue, ExpressionType, NumberValue, StringValue } from '../LayerPropertyTypes';

/**
 * BackgroundLayer - 背景图层
 * 用于渲染地图背景
 */
export class BackgroundLayer {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 创建背景图层
   * @param layerId 图层 ID
   */
  constructor(layerId: string);

  /**
   * 设置背景颜色
   * @param color 颜色值或Expression
   */
  setBackgroundColor(color: PropertyValue<string>): this;

  /**
   * 设置背景不透明度
   * @param opacity 不透明度或Expression（0.0 - 1.0）
   */
  setBackgroundOpacity(opacity: PropertyValue<number>): this;

  /**
   * 设置背景图案
   * @param pattern 图案名称或Expression
   */
  setBackgroundPattern(pattern: PropertyValue<string>): this;

  /**
   * 获取背景颜色
   * @returns 颜色字符串，如果是表达式则返回 undefined
   */
  getBackgroundColor(): string | undefined;

  /**
   * 获取背景不透明度
   * @returns 不透明度值，如果是表达式则返回 undefined
   */
  getBackgroundOpacity(): number | undefined;

  /**
   * 获取图层 ID
   */
  getId(): string;

  /**
   * 获取图层类型
   */
  getType(): string;

  /**
   * 设置图层可见性
   */
  setVisibility(visibility: 'visible' | 'none'): this;

  getVisibility(): 'visible' | 'none';

  /**
   * 设置最小/最大缩放级别
   */
  setMinZoom(zoom: number): this;

  getMinZoom(): number;

  setMaxZoom(zoom: number): this;

  getMaxZoom(): number;

  /**
   * 设置单个属性（通用方法）
   * @param propertyName 属性名称（如 'background-color', 'background-opacity'）
   * @param value 属性值（常量值或Expression）
   */
  setProperty(propertyName: string, value: any): this;

  /**
   * 批量设置属性（通用方法）
   * @param properties 属性对象，键为属性名，值为属性值
   * @example
   * layer.setProperties({
   *   'background-color': '#F0E9E1',
   *   'background-opacity': 1.0
   * });
   */
  setProperties(properties: Record<string, any>): this;
}
