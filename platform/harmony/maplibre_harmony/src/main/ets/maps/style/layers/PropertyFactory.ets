import { PropertyValue } from './PropertyValue';
import { PaintPropertyValue } from './PaintPropertyValue';
import { LayoutPropertyValue } from './LayoutPropertyValue';

/**
 * PropertyFactory - 属性工厂类
 * 
 * 为所有图层属性提供工厂方法
 */
export class PropertyFactory {
  
  // ==================== 通用属性 ====================
  
  /**
   * 设置图层可见性
   */
  public static visibility(value: 'visible' | 'none'): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('visibility', value);
  }

  // ==================== Fill 图层属性 ====================
  
  /**
   * 填充颜色
   */
  public static fillColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('fill-color', color);
  }

  /**
   * 填充透明度
   */
  public static fillOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('fill-opacity', opacity);
  }

  /**
   * 填充轮廓颜色
   */
  public static fillOutlineColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('fill-outline-color', color);
  }

  /**
   * 填充图案
   */
  public static fillPattern(pattern: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('fill-pattern', pattern);
  }

  /**
   * 填充抗锯齿
   */
  public static fillAntialias(antialias: boolean): PaintPropertyValue<boolean> {
    return new PaintPropertyValue<boolean>('fill-antialias', antialias);
  }

  /**
   * 填充偏移
   */
  public static fillTranslate(translate: number[]): PaintPropertyValue<number[]> {
    return new PaintPropertyValue<number[]>('fill-translate', translate);
  }

  // ==================== Line 图层属性 ====================
  
  /**
   * 线条颜色
   */
  public static lineColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('line-color', color);
  }

  /**
   * 线条宽度
   */
  public static lineWidth(width: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('line-width', width);
  }

  /**
   * 线条透明度
   */
  public static lineOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('line-opacity', opacity);
  }

  /**
   * 线条图案
   */
  public static linePattern(pattern: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('line-pattern', pattern);
  }

  /**
   * 线条间隙宽度
   */
  public static lineGapWidth(gapWidth: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('line-gap-width', gapWidth);
  }

  /**
   * 线条虚线数组
   */
  public static lineDasharray(dasharray: number[]): PaintPropertyValue<number[]> {
    return new PaintPropertyValue<number[]>('line-dasharray', dasharray);
  }

  /**
   * 线条模糊
   */
  public static lineBlur(blur: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('line-blur', blur);
  }

  /**
   * 线条端点样式
   */
  public static lineCap(cap: 'butt' | 'round' | 'square'): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('line-cap', cap);
  }

  /**
   * 线条连接样式
   */
  public static lineJoin(join: 'bevel' | 'round' | 'miter'): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('line-join', join);
  }

  // ==================== Circle 图层属性 ====================
  
  /**
   * 圆形半径
   */
  public static circleRadius(radius: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('circle-radius', radius);
  }

  /**
   * 圆形颜色
   */
  public static circleColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('circle-color', color);
  }

  /**
   * 圆形透明度
   */
  public static circleOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('circle-opacity', opacity);
  }

  /**
   * 圆形模糊
   */
  public static circleBlur(blur: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('circle-blur', blur);
  }

  /**
   * 圆形边框宽度
   */
  public static circleStrokeWidth(width: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('circle-stroke-width', width);
  }

  /**
   * 圆形边框颜色
   */
  public static circleStrokeColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('circle-stroke-color', color);
  }

  /**
   * 圆形边框透明度
   */
  public static circleStrokeOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('circle-stroke-opacity', opacity);
  }

  // ==================== Symbol 图层属性 ====================
  
  /**
   * 图标图片
   */
  public static iconImage(iconImage: string): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('icon-image', iconImage);
  }

  /**
   * 图标大小
   */
  public static iconSize(size: number): LayoutPropertyValue<number> {
    return new LayoutPropertyValue<number>('icon-size', size);
  }

  /**
   * 图标旋转角度
   */
  public static iconRotate(rotate: number): LayoutPropertyValue<number> {
    return new LayoutPropertyValue<number>('icon-rotate', rotate);
  }

  /**
   * 图标颜色
   */
  public static iconColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('icon-color', color);
  }

  /**
   * 图标透明度
   */
  public static iconOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('icon-opacity', opacity);
  }

  /**
   * 文本字段
   */
  public static textField(textField: string): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('text-field', textField);
  }

  /**
   * 文本大小
   */
  public static textSize(size: number): LayoutPropertyValue<number> {
    return new LayoutPropertyValue<number>('text-size', size);
  }

  /**
   * 文本字体
   */
  public static textFont(fonts: string[]): LayoutPropertyValue<string[]> {
    return new LayoutPropertyValue<string[]>('text-font', fonts);
  }

  /**
   * 文本偏移
   */
  public static textOffset(offset: number[]): LayoutPropertyValue<number[]> {
    return new LayoutPropertyValue<number[]>('text-offset', offset);
  }

  /**
   * 文本锚点
   */
  public static textAnchor(anchor: string): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('text-anchor', anchor);
  }

  /**
   * 文本颜色
   */
  public static textColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('text-color', color);
  }

  /**
   * 文本透明度
   */
  public static textOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('text-opacity', opacity);
  }

  /**
   * 文本光晕颜色
   */
  public static textHaloColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('text-halo-color', color);
  }

  /**
   * 文本光晕宽度
   */
  public static textHaloWidth(width: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('text-halo-width', width);
  }

  // ==================== Raster 图层属性 ====================
  
  /**
   * 栅格透明度
   */
  public static rasterOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('raster-opacity', opacity);
  }

  /**
   * 栅格色相旋转
   */
  public static rasterHueRotate(hueRotate: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('raster-hue-rotate', hueRotate);
  }

  /**
   * 栅格亮度最小值
   */
  public static rasterBrightnessMin(brightnessMin: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('raster-brightness-min', brightnessMin);
  }

  /**
   * 栅格亮度最大值
   */
  public static rasterBrightnessMax(brightnessMax: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('raster-brightness-max', brightnessMax);
  }

  /**
   * 栅格对比度
   */
  public static rasterContrast(contrast: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('raster-contrast', contrast);
  }

  /**
   * 栅格饱和度
   */
  public static rasterSaturation(saturation: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('raster-saturation', saturation);
  }

  // ==================== Background 图层属性 ====================
  
  /**
   * 背景颜色
   */
  public static backgroundColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('background-color', color);
  }

  /**
   * 背景透明度
   */
  public static backgroundOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('background-opacity', opacity);
  }

  /**
   * 背景图案
   */
  public static backgroundPattern(pattern: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('background-pattern', pattern);
  }

  // ==================== Heatmap 图层属性 ====================
  
  /**
   * 热力图权重
   */
  public static heatmapWeight(weight: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('heatmap-weight', weight);
  }

  /**
   * 热力图强度
   */
  public static heatmapIntensity(intensity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('heatmap-intensity', intensity);
  }

  /**
   * 热力图半径
   */
  public static heatmapRadius(radius: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('heatmap-radius', radius);
  }

  /**
   * 热力图透明度
   */
  public static heatmapOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('heatmap-opacity', opacity);
  }

  // ==================== Hillshade 图层属性 ====================
  
  /**
   * 山体阴影光照方向
   */
  public static hillshadeIlluminationDirection(direction: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('hillshade-illumination-direction', direction);
  }

  /**
   * 山体阴影光照锚点
   */
  public static hillshadeIlluminationAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('hillshade-illumination-anchor', anchor);
  }

  /**
   * 山体阴影夸张程度
   */
  public static hillshadeExaggeration(exaggeration: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('hillshade-exaggeration', exaggeration);
  }

  /**
   * 山体阴影阴影颜色
   */
  public static hillshadeShadowColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('hillshade-shadow-color', color);
  }

  /**
   * 山体阴影高光颜色
   */
  public static hillshadeHighlightColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('hillshade-highlight-color', color);
  }

  /**
   * 山体阴影强调颜色
   */
  public static hillshadeAccentColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('hillshade-accent-color', color);
  }

  // ==================== FillExtrusion 图层属性 ====================
  
  /**
   * 拉伸高度
   */
  public static fillExtrusionHeight(height: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('fill-extrusion-height', height);
  }

  /**
   * 拉伸基础高度
   */
  public static fillExtrusionBase(base: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('fill-extrusion-base', base);
  }

  /**
   * 拉伸颜色
   */
  public static fillExtrusionColor(color: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('fill-extrusion-color', color);
  }

  /**
   * 拉伸透明度
   */
  public static fillExtrusionOpacity(opacity: number): PaintPropertyValue<number> {
    return new PaintPropertyValue<number>('fill-extrusion-opacity', opacity);
  }

  /**
   * 拉伸图案
   */
  public static fillExtrusionPattern(pattern: string): PaintPropertyValue<string> {
    return new PaintPropertyValue<string>('fill-extrusion-pattern', pattern);
  }

  /**
   * 拉伸偏移
   */
  public static fillExtrusionTranslate(translate: number[]): PaintPropertyValue<number[]> {
    return new PaintPropertyValue<number[]>('fill-extrusion-translate', translate);
  }

  /**
   * 拉伸垂直渐变
   */
  public static fillExtrusionVerticalGradient(verticalGradient: boolean): PaintPropertyValue<boolean> {
    return new PaintPropertyValue<boolean>('fill-extrusion-vertical-gradient', verticalGradient);
  }
}

