/**
 * MapLibre Native for HarmonyOS - SymbolLayer Type Definitions
 * 符号图层 API (NAPI 类)
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * SymbolLayer - 符号图层
 * 用于渲染图标和文本标注
 */
export class SymbolLayer {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 创建 SymbolLayer
   * @param layerId 图层ID
   * @param sourceId 数据源ID
   */
  constructor(layerId: string, sourceId: string);

  // ==================== 基本方法 ====================

  /**
   * 获取图层ID
   */
  getId(): string;

  /**
   * 获取图层类型
   */
  getType(): string;

  /**
   * 获取数据源ID
   */
  getSourceId(): string;

  /**
   * 设置源图层
   * @param sourceLayer 源图层名称
   * @returns this（支持链式调用）
   */
  setSourceLayer(sourceLayer: string): SymbolLayer;

  /**
   * 获取源图层
   */
  getSourceLayer(): string;

  /**
   * 设置最小缩放级别
   * @param minZoom 最小缩放级别
   * @returns this（支持链式调用）
   */
  setMinZoom(minZoom: number): SymbolLayer;

  /**
   * 获取最小缩放级别
   */
  getMinZoom(): number;

  /**
   * 设置最大缩放级别
   * @param maxZoom 最大缩放级别
   * @returns this（支持链式调用）
   */
  setMaxZoom(maxZoom: number): SymbolLayer;

  /**
   * 获取最大缩放级别
   */
  getMaxZoom(): number;

  // ==================== 图标布局属性 ====================

  /**
   * 设置图标图片
   * @param iconImage 图片名称或Expression
   * @returns this（支持链式调用）
   */
  setIconImage(iconImage: PropertyValue<string>): SymbolLayer;

  /**
   * 获取图标图片
   */
  getIconImage(): string;

  /**
   * 设置图标大小
   * @param size 大小比例或Expression
   * @returns this（支持链式调用）
   */
  setIconSize(size: PropertyValue<number>): SymbolLayer;

  /**
   * 获取图标大小
   */
  getIconSize(): number;

  /**
   * 设置图标旋转角度
   * @param rotate 旋转角度（度）或Expression
   * @returns this（支持链式调用）
   */
  setIconRotate(rotate: PropertyValue<number>): SymbolLayer;

  /**
   * 获取图标旋转角度
   */
  getIconRotate(): number;

  /**
   * 设置图标偏移
   * @param offset 偏移量或Expression
   * @returns this（支持链式调用）
   */
  setIconOffset(offset: PropertyValue<number[]>): SymbolLayer;

  /**
   * 获取图标偏移
   */
  getIconOffset(): number[];

  /**
   * 设置图标锚点
   * @param anchor 锚点位置或Expression
   * @returns this（支持链式调用）
   */
  setIconAnchor(anchor: PropertyValue<string>): SymbolLayer;

  /**
   * 获取图标锚点
   */
  getIconAnchor(): string;

  /**
   * 设置图标是否允许重叠
   * @param allow 是否允许或Expression
   * @returns this（支持链式调用）
   */
  setIconAllowOverlap(allow: PropertyValue<boolean>): SymbolLayer;

  /**
   * 获取图标是否允许重叠
   */
  getIconAllowOverlap(): boolean;

  // ==================== 文本布局属性 ====================

  /**
   * 设置文本内容
   * @param text 文本内容或Expression
   * @returns this（支持链式调用）
   */
  setTextField(text: PropertyValue<string>): SymbolLayer;

  /**
   * 获取文本内容
   */
  getTextField(): string;

  /**
   * 设置文本字体
   * @param font 字体名称或Expression
   * @returns this（支持链式调用）
   */
  setTextFont(font: PropertyValue<string[]>): SymbolLayer;

  /**
   * 获取文本字体
   */
  getTextFont(): string[];

  /**
   * 设置文本大小
   * @param size 字体大小或Expression
   * @returns this（支持链式调用）
   */
  setTextSize(size: PropertyValue<number>): SymbolLayer;

  /**
   * 获取文本大小
   */
  getTextSize(): number;

  /**
   * 设置文本最大宽度
   * @param maxWidth 最大宽度或Expression
   * @returns this（支持链式调用）
   */
  setTextMaxWidth(maxWidth: PropertyValue<number>): SymbolLayer;

  /**
   * 获取文本最大宽度
   */
  getTextMaxWidth(): number;

  /**
   * 设置文本偏移
   * @param offset 偏移量或Expression
   * @returns this（支持链式调用）
   */
  setTextOffset(offset: PropertyValue<number[]>): SymbolLayer;

  /**
   * 获取文本偏移
   */
  getTextOffset(): number[];

  /**
   * 设置文本锚点
   * @param anchor 锚点位置或Expression
   * @returns this（支持链式调用）
   */
  setTextAnchor(anchor: PropertyValue<string>): SymbolLayer;

  /**
   * 获取文本锚点
   */
  getTextAnchor(): string;

  /**
   * 设置文本是否允许重叠
   * @param allow 是否允许或Expression
   * @returns this（支持链式调用）
   */
  setTextAllowOverlap(allow: PropertyValue<boolean>): SymbolLayer;

  /**
   * 获取文本是否允许重叠
   */
  getTextAllowOverlap(): boolean;

  // ==================== 图标绘制属性 ====================

  /**
   * 设置图标不透明度
   * @param opacity 不透明度 (0-1) 或 Expression
   * @returns this（支持链式调用）
   */
  setIconOpacity(opacity: PropertyValue<number>): SymbolLayer;

  /**
   * 获取图标不透明度
   */
  getIconOpacity(): number;

  /**
   * 设置图标颜色
   * @param color 颜色值或Expression
   * @returns this（支持链式调用）
   */
  setIconColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * 获取图标颜色
   */
  getIconColor(): string;

  /**
   * 设置图标光晕颜色
   * @param color 颜色值或Expression
   * @returns this（支持链式调用）
   */
  setIconHaloColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * 获取图标光晕颜色
   */
  getIconHaloColor(): string;

  /**
   * 设置图标光晕宽度
   * @param width 宽度或Expression
   * @returns this（支持链式调用）
   */
  setIconHaloWidth(width: PropertyValue<number>): SymbolLayer;

  /**
   * 获取图标光晕宽度
   */
  getIconHaloWidth(): number;

  // ==================== 文本绘制属性 ====================

  /**
   * 设置文本不透明度
   * @param opacity 不透明度 (0-1) 或Expression
   * @returns this（支持链式调用）
   */
  setTextOpacity(opacity: PropertyValue<number>): SymbolLayer;

  /**
   * 获取文本不透明度
   */
  getTextOpacity(): number;

  /**
   * 设置文本颜色
   * @param color 颜色值或Expression
   * @returns this（支持链式调用）
   */
  setTextColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * 获取文本颜色
   */
  getTextColor(): string;

  /**
   * 设置文本光晕颜色
   * @param color 颜色值或Expression
   * @returns this（支持链式调用）
   */
  setTextHaloColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * 获取文本光晕颜色
   */
  getTextHaloColor(): string;

  /**
   * 设置文本光晕宽度
   * @param width 宽度或Expression
   * @returns this（支持链式调用）
   */
  setTextHaloWidth(width: PropertyValue<number>): SymbolLayer;

  /**
   * 获取文本光晕宽度
   */
  getTextHaloWidth(): number;

  // ==================== 新增图标布局属性 ====================

  /**
   * 设置图标忽略放置
   * @returns this（支持链式调用）
   */
  setIconIgnorePlacement(ignore: boolean): SymbolLayer;

  getIconIgnorePlacement(): boolean;

  /**
   * 设置图标可选
   * @returns this（支持链式调用）
   */
  setIconOptional(optional: boolean): SymbolLayer;

  getIconOptional(): boolean;

  /**
   * 设置图标填充
   * @returns this（支持链式调用）
   */
  setIconPadding(padding: number): SymbolLayer;

  getIconPadding(): number;

  /**
   * 设置防止图标上下颠倒
   * @returns this（支持链式调用）
   */
  setIconKeepUpright(keep: boolean): SymbolLayer;

  getIconKeepUpright(): boolean;

  /**
   * 设置图标倾斜对齐
   * @returns this（支持链式调用）
   */
  setIconPitchAlignment(alignment: string): SymbolLayer;

  getIconPitchAlignment(): string;

  /**
   * 设置图标旋转对齐
   * @returns this（支持链式调用）
   */
  setIconRotationAlignment(alignment: string): SymbolLayer;

  getIconRotationAlignment(): string;

  /**
   * 设置图标文本适配
   * @returns this（支持链式调用）
   */
  setIconTextFit(fit: string): SymbolLayer;

  getIconTextFit(): string;

  /**
   * 设置图标文本适配填充
   * @returns this（支持链式调用）
   */
  setIconTextFitPadding(padding: number[]): SymbolLayer;

  getIconTextFitPadding(): number[];

  /**
   * 设置图标平移
   * @returns this（支持链式调用）
   */
  setIconTranslate(translate: number[]): SymbolLayer;

  getIconTranslate(): number[];

  /**
   * 设置图标平移锚点
   * @returns this（支持链式调用）
   */
  setIconTranslateAnchor(anchor: string): SymbolLayer;

  getIconTranslateAnchor(): string;

  /**
   * 设置图标光晕模糊
   * @returns this（支持链式调用）
   */
  setIconHaloBlur(blur: number): SymbolLayer;

  getIconHaloBlur(): number;

  // ==================== 新增文本布局属性 ====================

  /**
   * 设置文本字母间距
   * @returns this（支持链式调用）
   */
  setTextLetterSpacing(spacing: number): SymbolLayer;

  getTextLetterSpacing(): number;

  /**
   * 设置文本对齐方式
   * @returns this（支持链式调用）
   */
  setTextJustify(justify: string): SymbolLayer;

  getTextJustify(): string;

  /**
   * 设置文本径向偏移
   * @returns this（支持链式调用）
   */
  setTextRadialOffset(offset: number): SymbolLayer;

  getTextRadialOffset(): number;

  /**
   * 设置文本可变锚点
   * @returns this（支持链式调用）
   */
  setTextVariableAnchor(anchors: string[]): SymbolLayer;

  getTextVariableAnchor(): string[];

  /**
   * 设置文本可变锚点偏移
   * @returns this（支持链式调用）
   */
  setTextVariableAnchorOffset(offset: number[]): SymbolLayer;

  getTextVariableAnchorOffset(): number[];

  /**
   * 设置文本旋转角度
   * @returns this（支持链式调用）
   */
  setTextRotate(rotate: number): SymbolLayer;

  getTextRotate(): number;

  /**
   * 设置文本填充
   * @returns this（支持链式调用）
   */
  setTextPadding(padding: number): SymbolLayer;

  getTextPadding(): number;

  /**
   * 设置防止文本上下颠倒
   * @returns this（支持链式调用）
   */
  setTextKeepUpright(keep: boolean): SymbolLayer;

  getTextKeepUpright(): boolean;

  /**
   * 设置文本转换
   * @returns this（支持链式调用）
   */
  setTextTransform(transform: string): SymbolLayer;

  getTextTransform(): string;

  /**
   * 设置文本最大角度
   * @returns this（支持链式调用）
   */
  setTextMaxAngle(angle: number): SymbolLayer;

  getTextMaxAngle(): number;

  /**
   * 设置文本旋转对齐
   * @returns this（支持链式调用）
   */
  setTextRotationAlignment(alignment: string): SymbolLayer;

  getTextRotationAlignment(): string;

  /**
   * 设置文本倾斜对齐
   * @returns this（支持链式调用）
   */
  setTextPitchAlignment(alignment: string): SymbolLayer;

  getTextPitchAlignment(): string;

  /**
   * 设置文本行高
   * @returns this（支持链式调用）
   */
  setTextLineHeight(lineHeight: number): SymbolLayer;

  getTextLineHeight(): number;

  /**
   * 设置文本书写模式
   * @returns this（支持链式调用）
   */
  setTextWritingMode(mode: string[]): SymbolLayer;

  getTextWritingMode(): string[];

  /**
   * 设置文本忽略放置
   * @returns this（支持链式调用）
   */
  setTextIgnorePlacement(ignore: boolean): SymbolLayer;

  getTextIgnorePlacement(): boolean;

  /**
   * 设置文本可选
   * @returns this（支持链式调用）
   */
  setTextOptional(optional: boolean): SymbolLayer;

  getTextOptional(): boolean;

  // ==================== 新增文本绘制属性 ====================

  /**
   * 设置文本光晕模糊
   * @returns this（支持链式调用）
   */
  setTextHaloBlur(blur: number): SymbolLayer;

  getTextHaloBlur(): number;

  /**
   * 设置文本平移
   * @returns this（支持链式调用）
   */
  setTextTranslate(translate: number[]): SymbolLayer;

  getTextTranslate(): number[];

  /**
   * 设置文本平移锚点
   * @returns this（支持链式调用）
   */
  setTextTranslateAnchor(anchor: string): SymbolLayer;

  getTextTranslateAnchor(): string;

  // ==================== 符号通用属性 ====================

  /**
   * 设置符号放置方式
   * @returns this（支持链式调用）
   */
  setSymbolPlacement(placement: string): SymbolLayer;

  getSymbolPlacement(): string;

  /**
   * 设置符号间距
   * @returns this（支持链式调用）
   */
  setSymbolSpacing(spacing: number): SymbolLayer;

  getSymbolSpacing(): number;

  /**
   * 设置符号避免边缘
   * @returns this（支持链式调用）
   */
  setSymbolAvoidEdges(avoid: boolean): SymbolLayer;

  getSymbolAvoidEdges(): boolean;

  /**
   * 设置符号排序键
   * @returns this（支持链式调用）
   */
  setSymbolSortKey(sortKey: number): SymbolLayer;

  getSymbolSortKey(): number;

  /**
   * 设置符号Z顺序
   * @returns this（支持链式调用）
   */
  setSymbolZOrder(zOrder: string): SymbolLayer;

  getSymbolZOrder(): string;

  // ==================== 通用 Layer 方法 ====================

  /**
   * 设置图层可见性
   * @returns this（支持链式调用）
   */
  setVisibility(visibility: 'visible' | 'none'): SymbolLayer;

  getVisibility(): 'visible' | 'none';

  /**
   * 设置图层过滤器
   * @param filter 过滤器表达式字面量（JSON 数组格式）
   * @returns this（支持链式调用）
   */
  setFilter(filter: ExpressionLiteral): SymbolLayer;

  /**
   * 获取图层过滤器
   * @returns 过滤器表达式字面量或 null
   */
  getFilter(): ExpressionLiteral | null;

  /**
   * 设置单个属性（通用方法）
   * @param propertyName 属性名称（如 'icon-image', 'text-field', 'text-color'）
   * @param value 属性值（常量值或Expression）
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * 批量设置属性（通用方法）
   * @param properties 属性对象，键为属性名，值为属性值
   * @example
   * layer.setProperties({
   *   'icon-image': 'marker',
   *   'icon-size': 1.5,
   *   'text-field': ['get', 'name'],
   *   'text-color': '#000000'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
