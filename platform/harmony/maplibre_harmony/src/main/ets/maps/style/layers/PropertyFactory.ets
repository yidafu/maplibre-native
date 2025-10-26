import { PropertyValue } from './PropertyValue';
import { PaintPropertyValue } from './PaintPropertyValue';
import { LayoutPropertyValue } from './LayoutPropertyValue';
import { Expression } from '../expressions/Expression';

/**
 * PropertyFactory - 属性工厂类
 * 
 * 为所有图层属性提供工厂方法，支持常量值和 Expression
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
  
  public static fillColor(color: string): PaintPropertyValue<string>;
  public static fillColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static fillColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-color', value);
  }

  public static fillOpacity(opacity: number): PaintPropertyValue<number>;
  public static fillOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static fillOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-opacity', value);
  }

  public static fillOutlineColor(color: string): PaintPropertyValue<string>;
  public static fillOutlineColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static fillOutlineColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-outline-color', value);
  }

  public static fillPattern(pattern: string): PaintPropertyValue<string>;
  public static fillPattern(expression: Expression<string>): PaintPropertyValue<string>;
  public static fillPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-pattern', value);
  }

  public static fillAntialias(antialias: boolean): PaintPropertyValue<boolean>;
  public static fillAntialias(expression: Expression<boolean>): PaintPropertyValue<boolean>;
  public static fillAntialias(value: boolean | Expression<boolean>): PaintPropertyValue<boolean> {
    return PropertyFactory.createPaintProperty('fill-antialias', value);
  }

  public static fillTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static fillTranslate(expression: Expression<number[]>): PaintPropertyValue<number[]>;
  public static fillTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('fill-translate', value);
  }

  // ==================== Line 图层属性 ====================
  
  public static lineColor(color: string): PaintPropertyValue<string>;
  public static lineColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static lineColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-color', value);
  }

  public static lineWidth(width: number): PaintPropertyValue<number>;
  public static lineWidth(expression: Expression<number>): PaintPropertyValue<number>;
  public static lineWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-width', value);
  }

  public static lineOpacity(opacity: number): PaintPropertyValue<number>;
  public static lineOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static lineOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-opacity', value);
  }

  public static linePattern(pattern: string): PaintPropertyValue<string>;
  public static linePattern(expression: Expression<string>): PaintPropertyValue<string>;
  public static linePattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-pattern', value);
  }

  public static lineGapWidth(gapWidth: number): PaintPropertyValue<number>;
  public static lineGapWidth(expression: Expression<number>): PaintPropertyValue<number>;
  public static lineGapWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-gap-width', value);
  }

  public static lineDasharray(dasharray: number[]): PaintPropertyValue<number[]>;
  public static lineDasharray(expression: Expression<number[]>): PaintPropertyValue<number[]>;
  public static lineDasharray(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('line-dasharray', value);
  }

  public static lineBlur(blur: number): PaintPropertyValue<number>;
  public static lineBlur(expression: Expression<number>): PaintPropertyValue<number>;
  public static lineBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-blur', value);
  }

  public static lineCap(cap: 'butt' | 'round' | 'square'): LayoutPropertyValue<string>;
  public static lineCap(expression: Expression<string>): LayoutPropertyValue<string>;
  public static lineCap(value: 'butt' | 'round' | 'square' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('line-cap', value);
  }

  public static lineJoin(join: 'bevel' | 'round' | 'miter'): LayoutPropertyValue<string>;
  public static lineJoin(expression: Expression<string>): LayoutPropertyValue<string>;
  public static lineJoin(value: 'bevel' | 'round' | 'miter' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('line-join', value);
  }

  // ==================== Circle 图层属性 ====================
  
  public static circleRadius(radius: number): PaintPropertyValue<number>;
  public static circleRadius(expression: Expression<number>): PaintPropertyValue<number>;
  public static circleRadius(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-radius', value);
  }

  public static circleColor(color: string): PaintPropertyValue<string>;
  public static circleColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static circleColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-color', value);
  }

  public static circleOpacity(opacity: number): PaintPropertyValue<number>;
  public static circleOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static circleOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-opacity', value);
  }

  public static circleBlur(blur: number): PaintPropertyValue<number>;
  public static circleBlur(expression: Expression<number>): PaintPropertyValue<number>;
  public static circleBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-blur', value);
  }

  public static circleStrokeWidth(width: number): PaintPropertyValue<number>;
  public static circleStrokeWidth(expression: Expression<number>): PaintPropertyValue<number>;
  public static circleStrokeWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-stroke-width', value);
  }

  public static circleStrokeColor(color: string): PaintPropertyValue<string>;
  public static circleStrokeColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static circleStrokeColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-stroke-color', value);
  }

  public static circleStrokeOpacity(opacity: number): PaintPropertyValue<number>;
  public static circleStrokeOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static circleStrokeOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-stroke-opacity', value);
  }

  // ==================== Symbol 图层属性 ====================
  
  public static iconImage(iconImage: string): LayoutPropertyValue<string>;
  public static iconImage(expression: Expression<string>): LayoutPropertyValue<string>;
  public static iconImage(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-image', value);
  }

  public static iconSize(size: number): LayoutPropertyValue<number>;
  public static iconSize(expression: Expression<number>): LayoutPropertyValue<number>;
  public static iconSize(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-size', value);
  }

  public static iconRotate(rotate: number): LayoutPropertyValue<number>;
  public static iconRotate(expression: Expression<number>): LayoutPropertyValue<number>;
  public static iconRotate(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-rotate', value);
  }

  public static iconColor(color: string): PaintPropertyValue<string>;
  public static iconColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static iconColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-color', value);
  }

  public static iconOpacity(opacity: number): PaintPropertyValue<number>;
  public static iconOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static iconOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-opacity', value);
  }

  public static textField(textField: string): LayoutPropertyValue<string>;
  public static textField(expression: Expression<string>): LayoutPropertyValue<string>;
  public static textField(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-field', value);
  }

  public static textSize(size: number): LayoutPropertyValue<number>;
  public static textSize(expression: Expression<number>): LayoutPropertyValue<number>;
  public static textSize(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-size', value);
  }

  public static textFont(fonts: string[]): LayoutPropertyValue<string[]>;
  public static textFont(expression: Expression<string[]>): LayoutPropertyValue<string[]>;
  public static textFont(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-font', value);
  }

  public static textOffset(offset: number[]): LayoutPropertyValue<number[]>;
  public static textOffset(expression: Expression<number[]>): LayoutPropertyValue<number[]>;
  public static textOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('text-offset', value);
  }

  public static textAnchor(anchor: string): LayoutPropertyValue<string>;
  public static textAnchor(expression: Expression<string>): LayoutPropertyValue<string>;
  public static textAnchor(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-anchor', value);
  }

  public static textColor(color: string): PaintPropertyValue<string>;
  public static textColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static textColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-color', value);
  }

  public static textOpacity(opacity: number): PaintPropertyValue<number>;
  public static textOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static textOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-opacity', value);
  }

  public static textHaloColor(color: string): PaintPropertyValue<string>;
  public static textHaloColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static textHaloColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-halo-color', value);
  }

  public static textHaloWidth(width: number): PaintPropertyValue<number>;
  public static textHaloWidth(expression: Expression<number>): PaintPropertyValue<number>;
  public static textHaloWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-halo-width', value);
  }

  // ==================== Raster 图层属性 ====================
  
  public static rasterOpacity(opacity: number): PaintPropertyValue<number>;
  public static rasterOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static rasterOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-opacity', value);
  }

  public static rasterHueRotate(hueRotate: number): PaintPropertyValue<number>;
  public static rasterHueRotate(expression: Expression<number>): PaintPropertyValue<number>;
  public static rasterHueRotate(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-hue-rotate', value);
  }

  public static rasterBrightnessMin(brightnessMin: number): PaintPropertyValue<number>;
  public static rasterBrightnessMin(expression: Expression<number>): PaintPropertyValue<number>;
  public static rasterBrightnessMin(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-brightness-min', value);
  }

  public static rasterBrightnessMax(brightnessMax: number): PaintPropertyValue<number>;
  public static rasterBrightnessMax(expression: Expression<number>): PaintPropertyValue<number>;
  public static rasterBrightnessMax(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-brightness-max', value);
  }

  public static rasterContrast(contrast: number): PaintPropertyValue<number>;
  public static rasterContrast(expression: Expression<number>): PaintPropertyValue<number>;
  public static rasterContrast(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-contrast', value);
  }

  public static rasterSaturation(saturation: number): PaintPropertyValue<number>;
  public static rasterSaturation(expression: Expression<number>): PaintPropertyValue<number>;
  public static rasterSaturation(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-saturation', value);
  }

  // ==================== Background 图层属性 ====================
  
  public static backgroundColor(color: string): PaintPropertyValue<string>;
  public static backgroundColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static backgroundColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('background-color', value);
  }

  public static backgroundOpacity(opacity: number): PaintPropertyValue<number>;
  public static backgroundOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static backgroundOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('background-opacity', value);
  }

  public static backgroundPattern(pattern: string): PaintPropertyValue<string>;
  public static backgroundPattern(expression: Expression<string>): PaintPropertyValue<string>;
  public static backgroundPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('background-pattern', value);
  }

  // ==================== Heatmap 图层属性 ====================
  
  public static heatmapWeight(weight: number): PaintPropertyValue<number>;
  public static heatmapWeight(expression: Expression<number>): PaintPropertyValue<number>;
  public static heatmapWeight(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-weight', value);
  }

  public static heatmapIntensity(intensity: number): PaintPropertyValue<number>;
  public static heatmapIntensity(expression: Expression<number>): PaintPropertyValue<number>;
  public static heatmapIntensity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-intensity', value);
  }

  public static heatmapRadius(radius: number): PaintPropertyValue<number>;
  public static heatmapRadius(expression: Expression<number>): PaintPropertyValue<number>;
  public static heatmapRadius(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-radius', value);
  }

  public static heatmapOpacity(opacity: number): PaintPropertyValue<number>;
  public static heatmapOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static heatmapOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-opacity', value);
  }

  // ==================== Hillshade 图层属性 ====================
  
  public static hillshadeIlluminationDirection(direction: number): PaintPropertyValue<number>;
  public static hillshadeIlluminationDirection(expression: Expression<number>): PaintPropertyValue<number>;
  public static hillshadeIlluminationDirection(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('hillshade-illumination-direction', value);
  }

  public static hillshadeIlluminationAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;
  public static hillshadeIlluminationAnchor(expression: Expression<string>): PaintPropertyValue<string>;
  public static hillshadeIlluminationAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-illumination-anchor', value);
  }

  public static hillshadeExaggeration(exaggeration: number): PaintPropertyValue<number>;
  public static hillshadeExaggeration(expression: Expression<number>): PaintPropertyValue<number>;
  public static hillshadeExaggeration(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('hillshade-exaggeration', value);
  }

  public static hillshadeShadowColor(color: string): PaintPropertyValue<string>;
  public static hillshadeShadowColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static hillshadeShadowColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-shadow-color', value);
  }

  public static hillshadeHighlightColor(color: string): PaintPropertyValue<string>;
  public static hillshadeHighlightColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static hillshadeHighlightColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-highlight-color', value);
  }

  public static hillshadeAccentColor(color: string): PaintPropertyValue<string>;
  public static hillshadeAccentColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static hillshadeAccentColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-accent-color', value);
  }

  // ==================== FillExtrusion 图层属性 ====================
  
  public static fillExtrusionHeight(height: number): PaintPropertyValue<number>;
  public static fillExtrusionHeight(expression: Expression<number>): PaintPropertyValue<number>;
  public static fillExtrusionHeight(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-height', value);
  }

  public static fillExtrusionBase(base: number): PaintPropertyValue<number>;
  public static fillExtrusionBase(expression: Expression<number>): PaintPropertyValue<number>;
  public static fillExtrusionBase(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-base', value);
  }

  public static fillExtrusionColor(color: string): PaintPropertyValue<string>;
  public static fillExtrusionColor(expression: Expression<string>): PaintPropertyValue<string>;
  public static fillExtrusionColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-color', value);
  }

  public static fillExtrusionOpacity(opacity: number): PaintPropertyValue<number>;
  public static fillExtrusionOpacity(expression: Expression<number>): PaintPropertyValue<number>;
  public static fillExtrusionOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-opacity', value);
  }

  public static fillExtrusionPattern(pattern: string): PaintPropertyValue<string>;
  public static fillExtrusionPattern(expression: Expression<string>): PaintPropertyValue<string>;
  public static fillExtrusionPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-pattern', value);
  }

  public static fillExtrusionTranslate(translate: number[]): PaintPropertyValue<number[]>;
  public static fillExtrusionTranslate(expression: Expression<number[]>): PaintPropertyValue<number[]>;
  public static fillExtrusionTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('fill-extrusion-translate', value);
  }

  public static fillExtrusionVerticalGradient(verticalGradient: boolean): PaintPropertyValue<boolean>;
  public static fillExtrusionVerticalGradient(expression: Expression<boolean>): PaintPropertyValue<boolean>;
  public static fillExtrusionVerticalGradient(value: boolean | Expression<boolean>): PaintPropertyValue<boolean> {
    return PropertyFactory.createPaintProperty('fill-extrusion-vertical-gradient', value);
  }

  // ==================== 辅助方法 ====================

  /**
   * 创建 Paint 属性
   */
  private static createPaintProperty<T>(name: string, value: T | Expression<T>): PaintPropertyValue<T> {
    if (value instanceof Expression) {
      return new PaintPropertyValue<T>(name, null, value);
    } else {
      return new PaintPropertyValue<T>(name, value as T);
    }
  }

  /**
   * 创建 Layout 属性
   */
  private static createLayoutProperty<T>(name: string, value: T | Expression<T>): LayoutPropertyValue<T> {
    if (value instanceof Expression) {
      return new LayoutPropertyValue<T>(name, null, value);
    } else {
      return new LayoutPropertyValue<T>(name, value as T);
    }
  }
}
