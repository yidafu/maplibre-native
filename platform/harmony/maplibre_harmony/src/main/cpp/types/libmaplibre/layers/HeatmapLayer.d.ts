/**
 * MapLibre Native for HarmonyOS - HeatmapLayer Type Definitions
 * 热力图层 API (NAPI 类)
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';

/**
 * HeatmapLayer - 热力图层
 * 用于渲染密度热力图
 *
 * Note: 此为简化实现，完整功能待后续补充
 */
export class HeatmapLayer {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 创建热力图层
   * @param layerId 图层 ID
   * @param sourceId 数据源 ID
   */
  constructor(layerId: string, sourceId: string);

  /**
   * 设置热力图半径
   * @param radius 半径或Expression
   */
  setHeatmapRadius(radius: PropertyValue<number>): this;

  /**
   * 设置热力图权重
   * @param weight 权重值或Expression（用于计算每个点对热力图的贡献）
   */
  setHeatmapWeight(weight: PropertyValue<number>): this;

  /**
   * 设置热力图强度
   * @param intensity 强度值或Expression
   */
  setHeatmapIntensity(intensity: PropertyValue<number>): this;

  /**
   * 设置热力图不透明度
   * @param opacity 不透明度或Expression（0.0 - 1.0）
   */
  setHeatmapOpacity(opacity: PropertyValue<number>): this;

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

  // ==================== 新增属性 ====================

  /**
   * 设置热力图颜色渐变（仅支持 Expression）
   * 必须使用 heatmap-density 表达式
   *
   * @param color 颜色表达式（通常使用 interpolate 表达式）
   *
   * @example
  * ```typescript
   * layer.setHeatmapColor([
   *   "interpolate",
   *   ["linear"],
   *   ["heatmap-density"],
   *   0, "rgba(0, 0, 255, 0)",
   *   0.1, "royalblue",
   *   0.3, "cyan",
   *   0.5, "lime",
   *   0.7, "yellow",
   *   1, "red"
   * ]);
   * ```
   */
  setHeatmapColor(color: ExpressionLiteral): this;

  /**
   * 获取热力图颜色渐变表达式
   * @returns 颜色表达式，如果未设置则返回 undefined
   */
  getHeatmapColor(): ExpressionLiteral | undefined;
  /**
   * 设置单个属性（通用方法）
   * @param propertyName 属性名称
   * @param value 属性值（常量值或Expression）
   */
  setProperty(propertyName: string, value: any): this;

  /**
   * 批量设置属性（通用方法）
   * @param properties 属性对象，键为属性名，值为属性值
   * @example
   * layer.setProperties({
   *   'heatmap-radius': 30, 'heatmap-weight': 1
   * });
   */
  setProperties(properties: Record<string, any>): this;
}
