import { PropertyValue } from './PropertyValue';
import { PaintPropertyValue } from './PaintPropertyValue';
import { LayoutPropertyValue } from './LayoutPropertyValue';
import { Expression, ExpressionBuilder } from '../expressions/Expression';

/**
 * PropertyFactory - 属性工厂类
 * 
 * 为所有图层的布局和绘制属性提供工厂方法，支持常量值和 Expression。
 * 
 * 此类提供两类方法：
 * 1. **Layout Properties（布局属性）**: 控制图层几何形状的放置和排列
 * 2. **Paint Properties（绘制属性）**: 控制图层的视觉外观
 * 
 * 每个属性方法都支持：
 * - 常量值：直接传入原始值（如数字、字符串、布尔值、数组）
 * - Expression：传入 Expression 对象，实现数据驱动或缩放级别驱动的动态样式
 * 
 * @example
 * ```typescript
 * import { FillLayer } from 'libmaplibre.so';
 * import { Expression, Interpolator, Stop, PropertyFactory } from 'maplibre_harmony';
 * 
 * const layer = new FillLayer("regions", "regions-source");
 * 
 * // 使用常量值
 * layer.setFillColor(PropertyFactory.fillColor("#ff0000").getValue());
 * 
 * // 使用数据驱动 Expression
 * layer.setFillColor(
 *     PropertyFactory.fillColor(
 *         Expression.match(
 *             Expression.get("type"),
 *             Expression.literal("park"), Expression.literal("#00ff00"),
 *             Expression.literal("water"), Expression.literal("#0000ff"),
 *             Expression.literal("#cccccc")
 *         )
 *     ).getExpression()?.toArray()
 * );
 * 
 * // 使用缩放级别插值
 * layer.setFillOpacity(
 *     PropertyFactory.fillOpacity(
 *         Expression.interpolate(
 *             Interpolator.linear(),
 *             Expression.zoom(),
 *             Stop.stop(10, Expression.literal(0.3)),
 *             Stop.stop(15, Expression.literal(0.8))
 *         )
 *     ).getExpression()?.toArray()
 * );
 * ```
 * 
 * @see {@link Expression} - Expression 类文档
 * @see {@link https://maplibre.org/maplibre-style-spec/} - MapLibre Style Specification
 */
export class PropertyFactory {
  
  // ==================== 通用属性 ====================
  
  /**
   * 设置图层可见性
   * 
   * 控制图层是否在地图上显示。
   * 
   * @param value - 可见性值
   *   - `'visible'`: 图层可见
   *   - `'none'`: 图层隐藏
   * @returns 布局属性值包装器
   * 
   * @example
   * ```typescript
   * layer.setVisibility(PropertyFactory.visibility('visible').getValue());
   * ```
   */
  public static visibility(value: 'visible' | 'none'): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('visibility', value);
  }

  // ==================== Fill 图层属性 ====================
  
  /**
   * 设置填充颜色
   * 
   * 填充部分的颜色。支持 RGBA 格式，alpha 通道不会影响 1px 边框的不透明度。
   * 
   * @param color - CSS 颜色字符串（如 "#ff0000", "rgba(255,0,0,0.5)", "red"）
   * @returns 绘制属性值包装器
   * 
   * @example
   * ```typescript
   * // 常量颜色
   * layer.setFillColor(PropertyFactory.fillColor("#ff0000").getValue());
   * 
   * // 数据驱动颜色
   * layer.setFillColor(
   *     PropertyFactory.fillColor(
   *         Expression.match(
   *             Expression.get("type"),
   *             Expression.literal("park"), Expression.literal("#00ff00"),
   *             Expression.literal("water"), Expression.literal("#0000ff"),
   *             Expression.literal("#cccccc")
   *         )
   *     ).getExpression()?.toArray()
   * );
   * 
   * // 缩放级别插值
   * layer.setFillColor(
   *     PropertyFactory.fillColor(
   *         Expression.interpolate(
   *             Interpolator.linear(),
   *             Expression.zoom(),
   *             Stop.stop(10, Expression.literal("#e0e0e0")),
   *             Stop.stop(15, Expression.literal("#666666"))
   *         )
   *     ).getExpression()?.toArray()
   * );
   * ```
   */
  public static fillColor(color: string): PaintPropertyValue<string>;
  public static fillColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static fillColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-color', value);
  }

  public static fillOpacity(opacity: number): PaintPropertyValue<number>;
  public static fillOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static fillOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-opacity', value);
  }

  public static fillOutlineColor(color: string): PaintPropertyValue<string>;
  public static fillOutlineColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static fillOutlineColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-outline-color', value);
  }

  public static fillPattern(pattern: string): PaintPropertyValue<string>;
  public static fillPattern(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static fillPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-pattern', value);
  }

  public static fillAntialias(antialias: boolean): PaintPropertyValue<boolean>;
  public static fillAntialias(expression: ExpressionBuilder<boolean>): PaintPropertyValue<boolean>;
  public static fillAntialias(value: boolean | Expression<boolean>): PaintPropertyValue<boolean> {
    return PropertyFactory.createPaintProperty('fill-antialias', value);
  }

  public static fillTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static fillTranslate(expression: ExpressionBuilder<number[]>): PaintPropertyValue<number[]>;
  public static fillTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('fill-translate', value);
  }

  /**
   * 控制 fillTranslate 的参考框架
   * @param anchor 'map' | 'viewport'
   */
  public static fillTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static fillTranslateAnchor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static fillTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-translate-anchor', value);
  }

  /**
   * 填充的排序键，用于控制同一图层内填充的绘制顺序
   * 排序键较小的填充将绘制在排序键较大的填充下方
   */
  public static fillSortKey(sortKey: number): LayoutPropertyValue<number>;
  public static fillSortKey(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static fillSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('fill-sort-key', value);
  }

  // ==================== Line 图层属性 ====================
  
  public static lineColor(color: string): PaintPropertyValue<string>;
  public static lineColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static lineColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-color', value);
  }

  public static lineWidth(width: number): PaintPropertyValue<number>;
  public static lineWidth(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static lineWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-width', value);
  }

  public static lineOpacity(opacity: number): PaintPropertyValue<number>;
  public static lineOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static lineOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-opacity', value);
  }

  public static linePattern(pattern: string): PaintPropertyValue<string>;
  public static linePattern(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static linePattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-pattern', value);
  }

  public static lineGapWidth(gapWidth: number): PaintPropertyValue<number>;
  public static lineGapWidth(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static lineGapWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-gap-width', value);
  }

  public static lineDasharray(dasharray: number[]): PaintPropertyValue<number[]>;
  public static lineDasharray(expression: ExpressionBuilder<number[]>): PaintPropertyValue<number[]>;
  public static lineDasharray(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('line-dasharray', value);
  }

  public static lineBlur(blur: number): PaintPropertyValue<number>;
  public static lineBlur(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static lineBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-blur', value);
  }

  public static lineCap(cap: 'butt' | 'round' | 'square'): LayoutPropertyValue<string>;
  public static lineCap(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static lineCap(value: 'butt' | 'round' | 'square' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('line-cap', value);
  }

  public static lineJoin(join: 'bevel' | 'round' | 'miter'): LayoutPropertyValue<string>;
  public static lineJoin(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static lineJoin(value: 'bevel' | 'round' | 'miter' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('line-join', value);
  }

  /**
   * 线条平移，单位为像素。值为 [x, y]，负值表示向左和向上
   */
  public static lineTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static lineTranslate(expression: ExpressionBuilder<number[]>): PaintPropertyValue<number[]>;
  public static lineTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('line-translate', value);
  }

  /**
   * 控制 lineTranslate 的参考框架
   * @param anchor 'map' | 'viewport'
   */
  public static lineTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static lineTranslateAnchor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static lineTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-translate-anchor', value);
  }

  /**
   * 线条偏移，单位为像素。正值向右偏移，负值向左偏移
   */
  public static lineOffset(offset: number): PaintPropertyValue<number>;
  public static lineOffset(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static lineOffset(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-offset', value);
  }

  /**
   * 斜接限制，用于自动将斜接连接转换为斜面连接
   */
  public static lineMiterLimit(limit: number): LayoutPropertyValue<number>;
  public static lineMiterLimit(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static lineMiterLimit(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-miter-limit', value);
  }

  /**
   * 圆角限制，用于自动将圆角连接转换为斜接连接
   */
  public static lineRoundLimit(limit: number): LayoutPropertyValue<number>;
  public static lineRoundLimit(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static lineRoundLimit(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-round-limit', value);
  }

  /**
   * 定义沿线条长度的渐变颜色（仅支持 Expression）
   * 必须使用 line-progress 表达式
   */
  public static lineGradient(expression: ExpressionBuilder<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-gradient', expression);
  }

  /**
   * 线条的排序键，用于控制同一图层内线条的绘制顺序
   */
  public static lineSortKey(sortKey: number): LayoutPropertyValue<number>;
  public static lineSortKey(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static lineSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-sort-key', value);
  }

  // ==================== Circle 图层属性 ====================
  
  public static circleRadius(radius: number): PaintPropertyValue<number>;
  public static circleRadius(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static circleRadius(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-radius', value);
  }

  public static circleColor(color: string): PaintPropertyValue<string>;
  public static circleColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static circleColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-color', value);
  }

  public static circleOpacity(opacity: number): PaintPropertyValue<number>;
  public static circleOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static circleOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-opacity', value);
  }

  public static circleBlur(blur: number): PaintPropertyValue<number>;
  public static circleBlur(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static circleBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-blur', value);
  }

  public static circleStrokeWidth(width: number): PaintPropertyValue<number>;
  public static circleStrokeWidth(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static circleStrokeWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-stroke-width', value);
  }

  public static circleStrokeColor(color: string): PaintPropertyValue<string>;
  public static circleStrokeColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static circleStrokeColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-stroke-color', value);
  }

  public static circleStrokeOpacity(opacity: number): PaintPropertyValue<number>;
  public static circleStrokeOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static circleStrokeOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-stroke-opacity', value);
  }

  /**
   * 圆形平移，单位为像素。值为 [x, y]，负值表示向左和向上
   */
  public static circleTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static circleTranslate(expression: ExpressionBuilder<number[]>): PaintPropertyValue<number[]>;
  public static circleTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('circle-translate', value);
  }

  /**
   * 控制 circleTranslate 的参考框架
   * @param anchor 'map' | 'viewport'
   */
  public static circleTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static circleTranslateAnchor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static circleTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-translate-anchor', value);
  }

  /**
   * 控制圆形相对于地图的缩放行为
   * @param scale 'map' | 'viewport'
   */
  public static circlePitchScale(scale: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static circlePitchScale(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static circlePitchScale(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-pitch-scale', value);
  }

  /**
   * 控制圆形相对于地图的方向
   * @param alignment 'map' | 'viewport'
   */
  public static circlePitchAlignment(alignment: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static circlePitchAlignment(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static circlePitchAlignment(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-pitch-alignment', value);
  }

  /**
   * 圆形的排序键，用于控制同一图层内圆形的绘制顺序
   */
  public static circleSortKey(sortKey: number): LayoutPropertyValue<number>;
  public static circleSortKey(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static circleSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('circle-sort-key', value);
  }

  // ==================== Symbol 图层属性 ====================
  
  public static iconImage(iconImage: string): LayoutPropertyValue<string>;
  public static iconImage(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static iconImage(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-image', value);
  }

  public static iconSize(size: number): LayoutPropertyValue<number>;
  public static iconSize(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static iconSize(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-size', value);
  }

  public static iconRotate(rotate: number): LayoutPropertyValue<number>;
  public static iconRotate(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static iconRotate(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-rotate', value);
  }

  /**
   * 图标允许重叠
   */
  public static iconAllowOverlap(allowOverlap: boolean): LayoutPropertyValue<boolean>;
  public static iconAllowOverlap(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static iconAllowOverlap(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-allow-overlap', value);
  }

  /**
   * 图标忽略放置
   */
  public static iconIgnorePlacement(ignorePlacement: boolean): LayoutPropertyValue<boolean>;
  public static iconIgnorePlacement(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static iconIgnorePlacement(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-ignore-placement', value);
  }

  /**
   * 图标可选，当图标不可用时仍然显示文本
   */
  public static iconOptional(optional: boolean): LayoutPropertyValue<boolean>;
  public static iconOptional(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static iconOptional(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-optional', value);
  }

  /**
   * 图标锚点位置
   */
  public static iconAnchor(anchor: string): LayoutPropertyValue<string>;
  public static iconAnchor(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static iconAnchor(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-anchor', value);
  }

  /**
   * 图标偏移量 [x, y]
   */
  public static iconOffset(offset: number[]): LayoutPropertyValue<number[]>;
  public static iconOffset(expression: ExpressionBuilder<number[]>): LayoutPropertyValue<number[]>;
  public static iconOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('icon-offset', value);
  }

  /**
   * 图标填充
   */
  public static iconPadding(padding: number): LayoutPropertyValue<number>;
  public static iconPadding(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static iconPadding(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-padding', value);
  }

  /**
   * 防止图标上下颠倒
   */
  public static iconKeepUpright(keepUpright: boolean): LayoutPropertyValue<boolean>;
  public static iconKeepUpright(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static iconKeepUpright(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-keep-upright', value);
  }

  /**
   * 图标倾斜对齐方式
   */
  public static iconPitchAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;
  public static iconPitchAlignment(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static iconPitchAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-pitch-alignment', value);
  }

  /**
   * 图标旋转对齐方式
   */
  public static iconRotationAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;
  public static iconRotationAlignment(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static iconRotationAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-rotation-alignment', value);
  }

  /**
   * 图标文本适配方式
   */
  public static iconTextFit(fit: 'none' | 'width' | 'height' | 'both'): LayoutPropertyValue<string>;
  public static iconTextFit(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static iconTextFit(value: 'none' | 'width' | 'height' | 'both' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-text-fit', value);
  }

  /**
   * 图标文本适配填充 [top, right, bottom, left]
   */
  public static iconTextFitPadding(padding: number[]): LayoutPropertyValue<number[]>;
  public static iconTextFitPadding(expression: ExpressionBuilder<number[]>): LayoutPropertyValue<number[]>;
  public static iconTextFitPadding(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('icon-text-fit-padding', value);
  }

  /**
   * 图标平移 [x, y]
   */
  public static iconTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static iconTranslate(expression: ExpressionBuilder<number[]>): PaintPropertyValue<number[]>;
  public static iconTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('icon-translate', value);
  }

  /**
   * 控制 iconTranslate 的参考框架
   */
  public static iconTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static iconTranslateAnchor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static iconTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-translate-anchor', value);
  }

  /**
   * 图标光晕宽度
   */
  public static iconHaloWidth(width: number): PaintPropertyValue<number>;
  public static iconHaloWidth(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static iconHaloWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-halo-width', value);
  }

  /**
   * 图标光晕颜色
   */
  public static iconHaloColor(color: string): PaintPropertyValue<string>;
  public static iconHaloColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static iconHaloColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-halo-color', value);
  }

  /**
   * 图标光晕模糊
   */
  public static iconHaloBlur(blur: number): PaintPropertyValue<number>;
  public static iconHaloBlur(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static iconHaloBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-halo-blur', value);
  }

  public static iconColor(color: string): PaintPropertyValue<string>;
  public static iconColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static iconColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-color', value);
  }

  public static iconOpacity(opacity: number): PaintPropertyValue<number>;
  public static iconOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static iconOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-opacity', value);
  }

  public static textField(textField: string): LayoutPropertyValue<string>;
  public static textField(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static textField(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-field', value);
  }

  public static textSize(size: number): LayoutPropertyValue<number>;
  public static textSize(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textSize(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-size', value);
  }

  public static textFont(fonts: string[]): LayoutPropertyValue<string[]>;
  public static textFont(expression: ExpressionBuilder<string[]>): LayoutPropertyValue<string[]>;
  public static textFont(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-font', value);
  }

  public static textOffset(offset: number[]): LayoutPropertyValue<number[]>;
  public static textOffset(expression: ExpressionBuilder<number[]>): LayoutPropertyValue<number[]>;
  public static textOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('text-offset', value);
  }

  public static textAnchor(anchor: string): LayoutPropertyValue<string>;
  public static textAnchor(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static textAnchor(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-anchor', value);
  }

  /**
   * 文本最大宽度（单位：ems）
   */
  public static textMaxWidth(maxWidth: number): LayoutPropertyValue<number>;
  public static textMaxWidth(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textMaxWidth(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-max-width', value);
  }

  /**
   * 文本字母间距（单位：ems）
   */
  public static textLetterSpacing(letterSpacing: number): LayoutPropertyValue<number>;
  public static textLetterSpacing(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textLetterSpacing(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-letter-spacing', value);
  }

  /**
   * 文本对齐方式
   */
  public static textJustify(justify: 'auto' | 'left' | 'center' | 'right'): LayoutPropertyValue<string>;
  public static textJustify(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static textJustify(value: 'auto' | 'left' | 'center' | 'right' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-justify', value);
  }

  /**
   * 文本径向偏移
   */
  public static textRadialOffset(radialOffset: number): LayoutPropertyValue<number>;
  public static textRadialOffset(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textRadialOffset(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-radial-offset', value);
  }

  /**
   * 文本可变锚点
   */
  public static textVariableAnchor(variableAnchor: string[]): LayoutPropertyValue<string[]>;
  public static textVariableAnchor(expression: ExpressionBuilder<string[]>): LayoutPropertyValue<string[]>;
  public static textVariableAnchor(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-variable-anchor', value);
  }

  /**
   * 文本可变锚点偏移
   */
  public static textVariableAnchorOffset(offset: number[]): LayoutPropertyValue<number[]>;
  public static textVariableAnchorOffset(expression: ExpressionBuilder<number[]>): LayoutPropertyValue<number[]>;
  public static textVariableAnchorOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('text-variable-anchor-offset', value);
  }

  /**
   * 文本旋转角度
   */
  public static textRotate(rotate: number): LayoutPropertyValue<number>;
  public static textRotate(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textRotate(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-rotate', value);
  }

  /**
   * 文本填充
   */
  public static textPadding(padding: number): LayoutPropertyValue<number>;
  public static textPadding(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textPadding(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-padding', value);
  }

  /**
   * 防止文本上下颠倒
   */
  public static textKeepUpright(keepUpright: boolean): LayoutPropertyValue<boolean>;
  public static textKeepUpright(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static textKeepUpright(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-keep-upright', value);
  }

  /**
   * 文本转换（大小写）
   */
  public static textTransform(transform: 'none' | 'uppercase' | 'lowercase'): LayoutPropertyValue<string>;
  public static textTransform(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static textTransform(value: 'none' | 'uppercase' | 'lowercase' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-transform', value);
  }

  /**
   * 文本最大角度
   */
  public static textMaxAngle(maxAngle: number): LayoutPropertyValue<number>;
  public static textMaxAngle(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textMaxAngle(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-max-angle', value);
  }

  /**
   * 文本旋转对齐方式
   */
  public static textRotationAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;
  public static textRotationAlignment(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static textRotationAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-rotation-alignment', value);
  }

  /**
   * 文本倾斜对齐方式
   */
  public static textPitchAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;
  public static textPitchAlignment(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static textPitchAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-pitch-alignment', value);
  }

  /**
   * 文本行高（单位：ems）
   */
  public static textLineHeight(lineHeight: number): LayoutPropertyValue<number>;
  public static textLineHeight(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static textLineHeight(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-line-height', value);
  }

  /**
   * 文本书写模式
   */
  public static textWritingMode(writingMode: string[]): LayoutPropertyValue<string[]>;
  public static textWritingMode(expression: ExpressionBuilder<string[]>): LayoutPropertyValue<string[]>;
  public static textWritingMode(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-writing-mode', value);
  }

  /**
   * 文本允许重叠
   */
  public static textAllowOverlap(allowOverlap: boolean): LayoutPropertyValue<boolean>;
  public static textAllowOverlap(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static textAllowOverlap(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-allow-overlap', value);
  }

  /**
   * 文本忽略放置
   */
  public static textIgnorePlacement(ignorePlacement: boolean): LayoutPropertyValue<boolean>;
  public static textIgnorePlacement(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static textIgnorePlacement(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-ignore-placement', value);
  }

  /**
   * 文本可选，当文本不可用时仍然显示图标
   */
  public static textOptional(optional: boolean): LayoutPropertyValue<boolean>;
  public static textOptional(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static textOptional(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-optional', value);
  }

  public static textColor(color: string): PaintPropertyValue<string>;
  public static textColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static textColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-color', value);
  }

  public static textOpacity(opacity: number): PaintPropertyValue<number>;
  public static textOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static textOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-opacity', value);
  }

  public static textHaloColor(color: string): PaintPropertyValue<string>;
  public static textHaloColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static textHaloColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-halo-color', value);
  }

  public static textHaloWidth(width: number): PaintPropertyValue<number>;
  public static textHaloWidth(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static textHaloWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-halo-width', value);
  }

  /**
   * 文本光晕模糊
   */
  public static textHaloBlur(blur: number): PaintPropertyValue<number>;
  public static textHaloBlur(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static textHaloBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-halo-blur', value);
  }

  /**
   * 文本平移 [x, y]
   */
  public static textTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static textTranslate(expression: ExpressionBuilder<number[]>): PaintPropertyValue<number[]>;
  public static textTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('text-translate', value);
  }

  /**
   * 控制 textTranslate 的参考框架
   */
  public static textTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static textTranslateAnchor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static textTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-translate-anchor', value);
  }

  /**
   * 符号放置方式
   */
  public static symbolPlacement(placement: 'point' | 'line' | 'line-center'): LayoutPropertyValue<string>;
  public static symbolPlacement(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static symbolPlacement(value: 'point' | 'line' | 'line-center' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('symbol-placement', value);
  }

  /**
   * 符号间距（仅当 symbolPlacement 为 line 时有效）
   */
  public static symbolSpacing(spacing: number): LayoutPropertyValue<number>;
  public static symbolSpacing(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static symbolSpacing(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('symbol-spacing', value);
  }

  /**
   * 符号避免边缘
   */
  public static symbolAvoidEdges(avoidEdges: boolean): LayoutPropertyValue<boolean>;
  public static symbolAvoidEdges(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static symbolAvoidEdges(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('symbol-avoid-edges', value);
  }

  /**
   * 符号排序键
   */
  public static symbolSortKey(sortKey: number): LayoutPropertyValue<number>;
  public static symbolSortKey(expression: ExpressionBuilder<number>): LayoutPropertyValue<number>;
  public static symbolSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('symbol-sort-key', value);
  }

  /**
   * 符号 Z 顺序（已弃用，使用 symbolSortKey）
   */
  public static symbolZOrder(zOrder: 'auto' | 'viewport-y' | 'source'): LayoutPropertyValue<string>;
  public static symbolZOrder(expression: ExpressionBuilder<string>): LayoutPropertyValue<string>;
  public static symbolZOrder(value: 'auto' | 'viewport-y' | 'source' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('symbol-z-order', value);
  }

  /**
   * 符号屏幕空间（已弃用）
   */
  public static symbolScreenSpace(screenSpace: boolean): LayoutPropertyValue<boolean>;
  public static symbolScreenSpace(expression: ExpressionBuilder<boolean>): LayoutPropertyValue<boolean>;
  public static symbolScreenSpace(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('symbol-screen-space', value);
  }

  // ==================== Raster 图层属性 ====================
  
  public static rasterOpacity(opacity: number): PaintPropertyValue<number>;
  public static rasterOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static rasterOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-opacity', value);
  }

  public static rasterHueRotate(hueRotate: number): PaintPropertyValue<number>;
  public static rasterHueRotate(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static rasterHueRotate(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-hue-rotate', value);
  }

  public static rasterBrightnessMin(brightnessMin: number): PaintPropertyValue<number>;
  public static rasterBrightnessMin(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static rasterBrightnessMin(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-brightness-min', value);
  }

  public static rasterBrightnessMax(brightnessMax: number): PaintPropertyValue<number>;
  public static rasterBrightnessMax(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static rasterBrightnessMax(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-brightness-max', value);
  }

  public static rasterContrast(contrast: number): PaintPropertyValue<number>;
  public static rasterContrast(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static rasterContrast(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-contrast', value);
  }

  public static rasterSaturation(saturation: number): PaintPropertyValue<number>;
  public static rasterSaturation(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static rasterSaturation(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-saturation', value);
  }

  /**
   * 栅格淡入淡出持续时间（毫秒）
   */
  public static rasterFadeDuration(fadeDuration: number): PaintPropertyValue<number>;
  public static rasterFadeDuration(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static rasterFadeDuration(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-fade-duration', value);
  }

  /**
   * 栅格重采样方式
   */
  public static rasterResampling(resampling: 'linear' | 'nearest'): PaintPropertyValue<string>;
  public static rasterResampling(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static rasterResampling(value: 'linear' | 'nearest' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('raster-resampling', value);
  }

  // ==================== Background 图层属性 ====================
  
  public static backgroundColor(color: string): PaintPropertyValue<string>;
  public static backgroundColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static backgroundColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('background-color', value);
  }

  public static backgroundOpacity(opacity: number): PaintPropertyValue<number>;
  public static backgroundOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static backgroundOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('background-opacity', value);
  }

  public static backgroundPattern(pattern: string): PaintPropertyValue<string>;
  public static backgroundPattern(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static backgroundPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('background-pattern', value);
  }

  // ==================== Heatmap 图层属性 ====================
  
  public static heatmapWeight(weight: number): PaintPropertyValue<number>;
  public static heatmapWeight(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static heatmapWeight(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-weight', value);
  }

  public static heatmapIntensity(intensity: number): PaintPropertyValue<number>;
  public static heatmapIntensity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static heatmapIntensity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-intensity', value);
  }

  public static heatmapRadius(radius: number): PaintPropertyValue<number>;
  public static heatmapRadius(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static heatmapRadius(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-radius', value);
  }

  public static heatmapOpacity(opacity: number): PaintPropertyValue<number>;
  public static heatmapOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static heatmapOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-opacity', value);
  }

  /**
   * 定义热力图的颜色渐变（仅支持 Expression）
   * 必须使用 heatmap-density 表达式
   */
  public static heatmapColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('heatmap-color', expression);
  }

  // ==================== Hillshade 图层属性 ====================
  
  public static hillshadeIlluminationDirection(direction: number): PaintPropertyValue<number>;
  public static hillshadeIlluminationDirection(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static hillshadeIlluminationDirection(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('hillshade-illumination-direction', value);
  }

  public static hillshadeIlluminationAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static hillshadeIlluminationAnchor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static hillshadeIlluminationAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-illumination-anchor', value);
  }

  public static hillshadeExaggeration(exaggeration: number): PaintPropertyValue<number>;
  public static hillshadeExaggeration(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static hillshadeExaggeration(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('hillshade-exaggeration', value);
  }

  public static hillshadeShadowColor(color: string): PaintPropertyValue<string>;
  public static hillshadeShadowColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static hillshadeShadowColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-shadow-color', value);
  }

  public static hillshadeHighlightColor(color: string): PaintPropertyValue<string>;
  public static hillshadeHighlightColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static hillshadeHighlightColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-highlight-color', value);
  }

  public static hillshadeAccentColor(color: string): PaintPropertyValue<string>;
  public static hillshadeAccentColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static hillshadeAccentColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-accent-color', value);
  }

  // ==================== FillExtrusion 图层属性 ====================
  
  public static fillExtrusionHeight(height: number): PaintPropertyValue<number>;
  public static fillExtrusionHeight(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static fillExtrusionHeight(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-height', value);
  }

  public static fillExtrusionBase(base: number): PaintPropertyValue<number>;
  public static fillExtrusionBase(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static fillExtrusionBase(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-base', value);
  }

  public static fillExtrusionColor(color: string): PaintPropertyValue<string>;
  public static fillExtrusionColor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static fillExtrusionColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-color', value);
  }

  public static fillExtrusionOpacity(opacity: number): PaintPropertyValue<number>;
  public static fillExtrusionOpacity(expression: ExpressionBuilder<number>): PaintPropertyValue<number>;
  public static fillExtrusionOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-opacity', value);
  }

  public static fillExtrusionPattern(pattern: string): PaintPropertyValue<string>;
  public static fillExtrusionPattern(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static fillExtrusionPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-pattern', value);
  }

  public static fillExtrusionTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static fillExtrusionTranslate(expression: ExpressionBuilder<number[]>): PaintPropertyValue<number[]>;
  public static fillExtrusionTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('fill-extrusion-translate', value);
  }

  /**
   * 控制 fillExtrusionTranslate 的参考框架
   * @param anchor 'map' | 'viewport'
   */
  public static fillExtrusionTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static fillExtrusionTranslateAnchor(expression: ExpressionBuilder<string>): PaintPropertyValue<string>;
  public static fillExtrusionTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-translate-anchor', value);
  }

  public static fillExtrusionVerticalGradient(verticalGradient: boolean): PaintPropertyValue<boolean>;
  public static fillExtrusionVerticalGradient(expression: ExpressionBuilder<boolean>): PaintPropertyValue<boolean>;
  public static fillExtrusionVerticalGradient(value: boolean | Expression<boolean>): PaintPropertyValue<boolean> {
    return PropertyFactory.createPaintProperty('fill-extrusion-vertical-gradient', value);
  }

  // ==================== 辅助方法 ====================

  /**
   * 创建 Paint 属性
   */
  private static createPaintProperty<T>(name: string, value: T | Expression<T>): PaintPropertyValue<T> {
    if (value instanceof ExpressionBuilder) {
      return new PaintPropertyValue<T>(name, null, value);
    } else {
      return new PaintPropertyValue<T>(name, value as T);
    }
  }

  /**
   * 创建 Layout 属性
   */
  private static createLayoutProperty<T>(name: string, value: T | Expression<T>): LayoutPropertyValue<T> {
    if (value instanceof ExpressionBuilder) {
      return new LayoutPropertyValue<T>(name, null, value);
    } else {
      return new LayoutPropertyValue<T>(name, value as T);
    }
  }
}
