/**
 * MapLibre Native for HarmonyOS - HillshadeLayer Type Definitions
 * 山体阴影图层 API (NAPI 类)
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';

/**
 * HillshadeLayer - 山体阴影图层
 * 用于渲染地形阴影效果
 *
 * Note: 此为简化实现，完整功能待后续补充
 */
export class HillshadeLayer {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 创建山体阴影图层
   * @param layerId 图层 ID
   * @param sourceId 数据源 ID
   */
  constructor(layerId: string, sourceId: string);

  /**
   * 设置光照方向
   * @param direction 光照方向角度或Expression（0-359 度）
   */
  setHillshadeIlluminationDirection(direction: PropertyValue<number>): this;

  /**
   * 设置夸张程度
   * @param exaggeration 夸张系数或Expression（0.0 - 1.0）
   */
  setHillshadeExaggeration(exaggeration: PropertyValue<number>): this;

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
}
