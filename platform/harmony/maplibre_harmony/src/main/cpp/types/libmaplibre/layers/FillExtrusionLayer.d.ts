/**
 * MapLibre Native for HarmonyOS - FillExtrusionLayer Type Definitions
 * 3D填充拉伸图层 API (NAPI 类)
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';

/**
 * FillExtrusionLayer - 3D 填充拉伸图层
 * 用于渲染 3D 建筑物等拉伸效果
 *
 * Note: 此为简化实现，完整功能待后续补充
 */
export class FillExtrusionLayer {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 创建3D填充拉伸图层
   * @param layerId 图层 ID
   * @param sourceId 数据源 ID
   */
  constructor(layerId: string, sourceId: string);

  /**
   * 设置拉伸高度
   * @param height 高度或Expression
   */
  setFillExtrusionHeight(height: PropertyValue<number>): this;

  /**
   * 设置拉伸基准高度
   * @param base 基准高度或Expression
   */
  setFillExtrusionBase(base: PropertyValue<number>): this;

  /**
   * 设置拉伸颜色
   * @param color 颜色值或Expression
   */
  setFillExtrusionColor(color: PropertyValue<string>): this;

  /**
   * 设置拉伸不透明度
   * @param opacity 不透明度或Expression（0.0 - 1.0）
   */
  setFillExtrusionOpacity(opacity: PropertyValue<number>): this;

  /**
   * 设置拉伸图案
   * @param pattern 图案名称或 Expression
   *
   * @example
  * ```typescript
   * // 使用图案名称
   * layer.setFillExtrusionPattern('building-pattern');
   *
   * // 使用 Expression
   * layer.setFillExtrusionPattern(['get', 'pattern_name']);
   * ```
   */
  setFillExtrusionPattern(pattern: PropertyValue<string>): this;

  /**
   * 设置拉伸平移（用于偏移 3D 建筑物的位置）
   * @param translate 平移量 [x, y]（像素）或 Expression
   *
   * @example
  * ```typescript
   * // 固定平移
   * layer.setFillExtrusionTranslate([10, 20]);
   *
   * // 使用 Expression（数据驱动）
   * layer.setFillExtrusionTranslate(['literal', [5, 10]]);
   * ```
   */
  setFillExtrusionTranslate(translate: PropertyValue<[number, number]>): this;

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
   * 设置填充挤出平移锚点
   * @param anchor 'map' | 'viewport'
   */
  setFillExtrusionTranslateAnchor(anchor: string): this;

  getFillExtrusionTranslateAnchor(): string | undefined;
}
