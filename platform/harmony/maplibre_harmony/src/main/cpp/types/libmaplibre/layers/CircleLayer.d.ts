/**
 * MapLibre Native for HarmonyOS - CircleLayer Type Definitions
 * 圆形图层 API (NAPI 类)
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * CircleLayer - 圆形图层
 * 用于渲染圆形点要素
 */
export class CircleLayer {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 创建圆形图层
   * @param layerId 图层 ID
   * @param sourceId 数据源 ID
   */
  constructor(layerId: string, sourceId: string);

  /**
   * 设置圆形半径
   * @param radius 半径或Expression
   */
  setCircleRadius(radius: PropertyValue<number>): this;

  /**
   * 设置圆形颜色
   * @param color 颜色值或Expression
   */
  setCircleColor(color: PropertyValue<string>): this;

  /**
   * 设置圆形不透明度
   * @param opacity 不透明度或Expression（0.0 - 1.0）
   */
  setCircleOpacity(opacity: PropertyValue<number>): this;

  /**
   * 设置圆形模糊
   * @param blur 模糊量或Expression（0.0 - 1.0）
   */
  setCircleBlur(blur: PropertyValue<number>): this;

  /**
   * 设置圆形边框宽度
   * @param width 边框宽度或Expression
   */
  setCircleStrokeWidth(width: PropertyValue<number>): this;

  /**
   * 设置圆形边框颜色
   * @param color 颜色值或Expression
   */
  setCircleStrokeColor(color: PropertyValue<string>): this;

  /**
   * 设置圆形边框不透明度
   * @param opacity 不透明度或Expression
   */
  setCircleStrokeOpacity(opacity: PropertyValue<number>): this;

  /**
   * 获取圆形半径
   */
  getCircleRadius(): number | undefined;

  /**
   * 获取圆形颜色
   */
  getCircleColor(): string | undefined;

  /**
   * 获取圆形不透明度
   */
  getCircleOpacity(): number | undefined;

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
   * 设置圆形平移
   * @param translate 平移量或Expression
   */
  setCircleTranslate(translate: PropertyValue<number[]>): this;

  getCircleTranslate(): number[] | undefined;

  /**
   * 设置圆形平移锚点
   * @param anchor 'map' | 'viewport' 或Expression
   */
  setCircleTranslateAnchor(anchor: PropertyValue<string>): this;

  getCircleTranslateAnchor(): string | undefined;

  /**
   * 设置圆形缩放行为
   * @param scale 'map' | 'viewport' 或Expression
   */
  setCirclePitchScale(scale: PropertyValue<string>): this;

  getCirclePitchScale(): string | undefined;

  /**
   * 设置圆形倾斜对齐
   * @param alignment 'map' | 'viewport' 或Expression
   */
  setCirclePitchAlignment(alignment: PropertyValue<string>): this;

  getCirclePitchAlignment(): string | undefined;

  /**
   * 设置圆形排序键
   * @param sortKey 排序键或Expression
   */
  setCircleSortKey(sortKey: PropertyValue<number>): this;

  getCircleSortKey(): number | undefined;

  /**
   * 设置单个属性（通用方法）
   * @param propertyName 属性名称（如 'circle-color', 'circle-radius'）
   * @param value 属性值（常量值或Expression）
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * 批量设置属性（通用方法）
   * @param properties 属性对象，键为属性名，值为属性值
   * @example
   * layer.setProperties({
   *   'circle-color': '#00FF00',
   *   'circle-radius': 10,
   *   'circle-stroke-width': 2
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
