/**
 * MapLibre Native for HarmonyOS - LineLayer Type Definitions
 * 线图层 API (NAPI 类)
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * LineLayer - 线图层
 * 用于渲染线要素
 */
export class LineLayer {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 创建线图层
   * @param layerId 图层 ID
   * @param sourceId 数据源 ID
   */
  constructor(layerId: string, sourceId: string);

  /**
   * 设置线条颜色
   * @param color 颜色值或Expression
   */
  setLineColor(color: PropertyValue<string>): this;

  /**
   * 设置线条宽度
   * @param width 宽度或Expression
   */
  setLineWidth(width: PropertyValue<number>): this;

  /**
   * 设置线条不透明度
   * @param opacity 不透明度或Expression（0.0 - 1.0）
   */
  setLineOpacity(opacity: PropertyValue<number>): this;

  /**
   * 设置线条图案
   * @param pattern 图案名称或Expression
   */
  setLinePattern(pattern: PropertyValue<string>): this;

  /**
   * 设置线条间隙宽度
   * @param gapWidth 间隙宽度或Expression
   */
  setLineGapWidth(gapWidth: PropertyValue<number>): this;

  /**
   * 设置虚线样式
   * @param dasharray 虚线数组或Expression
   */
  setLineDasharray(dasharray: PropertyValue<number[]>): this;

  /**
   * 设置线条模糊
   * @param blur 模糊量或Expression
   */
  setLineBlur(blur: PropertyValue<number>): this;

  /**
   * 设置线条偏移
   * @param offset 偏移量或Expression
   */
  setLineOffset(offset: PropertyValue<number>): this;

  /**
   * 设置线条端点样式
   * @param cap 端点样式或Expression
   */
  setLineCap(cap: PropertyValue<string>): this;

  /**
   * 设置线条连接样式
   * @param join 连接样式或Expression
   */
  setLineJoin(join: PropertyValue<string>): this;

  /**
   * 获取线条颜色
   */
  getLineColor(): string | undefined;

  /**
   * 获取线条宽度
   */
  getLineWidth(): number | undefined;

  /**
   * 获取线条不透明度
   */
  getLineOpacity(): number | undefined;

  /**
   * 获取图层 ID
   */
  getId(): string;

  /**
   * 获取图层类型
   */
  getType(): string;

  /**
   * 获取数据源 ID
   */
  getSourceId(): string;

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
   * 设置源图层
   */
  setSourceLayer(sourceLayer: string): this;

  getSourceLayer(): string;

  /**
   * 设置图层过滤器
   * @param filter 过滤器表达式字面量（JSON 数组格式）
   */
  setFilter(filter: ExpressionLiteral): this;

  /**
   * 获取图层过滤器
   * @returns 过滤器表达式字面量或 null
   */
  getFilter(): ExpressionLiteral | null;

  /**
   * 设置线条平移
   * @param translate 平移量或Expression
   */
  setLineTranslate(translate: PropertyValue<number[]>): this;

  getLineTranslate(): number[] | undefined;

  /**
   * 设置线条平移锚点
   * @param anchor 'map' | 'viewport' 或Expression
   */
  setLineTranslateAnchor(anchor: PropertyValue<string>): this;

  getLineTranslateAnchor(): string | undefined;

  /**
   * 设置斜接限制
   * @param limit 斜接限制值或Expression
   */
  setLineMiterLimit(limit: PropertyValue<number>): this;

  getLineMiterLimit(): number | undefined;

  /**
   * 设置圆角限制
   * @param limit 圆角限制值或Expression
   */
  setLineRoundLimit(limit: PropertyValue<number>): this;

  getLineRoundLimit(): number | undefined;

  /**
   * 设置线条渐变色（仅支持 Expression）
   * @param gradient 渐变色表达式
   */
  setLineGradient(gradient: PropertyValue<string>): this;

  getLineGradient(): ExpressionLiteral | undefined;

  /**
   * 设置线条排序键
   * @param sortKey 排序键或Expression
   */
  setLineSortKey(sortKey: PropertyValue<number>): this;

  getLineSortKey(): number | undefined;

  /**
   * 设置单个属性（通用方法）
   * @param propertyName 属性名称（如 'line-color', 'line-width'）
   * @param value 属性值（常量值或Expression）
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * 批量设置属性（通用方法）
   * @param properties 属性对象，键为属性名，值为属性值
   * @example
   * layer.setProperties({
   *   'line-color': '#0000FF',
   *   'line-width': 3,
   *   'line-dasharray': [2, 4]
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
