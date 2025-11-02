/**
 * MapLibre Layer Paint Properties
 * 图层绘制属性类型定义
 * 
 * 根据 MapLibre Style Spec 定义各图层类型的 Paint 属性
 * @see https://maplibre.org/maplibre-style-spec/layers/
 */

import type { Expression } from './Expression';
import type { ExpressionLiteral } from './PropertyTypes';

/**
 * 支持 Expression 的属性值类型
 */
export type DataDrivenProperty<T> = T | Expression | ExpressionLiteral;

/**
 * 颜色类型 - 支持 CSS 颜色字符串或 Expression
 */
export type Color = DataDrivenProperty<string>;

/**
 * 平移锚点
 */
export type TranslateAnchor = 'map' | 'viewport';

// ==================== Background Layer Paint ====================

/**
 * BackgroundPaint - 背景图层绘制属性
 */
export interface BackgroundPaint {
  /**
   * 背景颜色
   * @default "#000000"
   */
  'background-color'?: Color;

  /**
   * 背景图案
   */
  'background-pattern'?: DataDrivenProperty<string>;

  /**
   * 背景不透明度
   * @default 1
   */
  'background-opacity'?: DataDrivenProperty<number>;
}

// ==================== Fill Layer Paint ====================

/**
 * FillPaint - 填充图层绘制属性
 */
export interface FillPaint {
  /**
   * 是否启用填充抗锯齿
   * @default true
   */
  'fill-antialias'?: boolean;

  /**
   * 填充不透明度
   * @default 1
   */
  'fill-opacity'?: DataDrivenProperty<number>;

  /**
   * 填充颜色
   * @default "#000000"
   */
  'fill-color'?: Color;

  /**
   * 填充轮廓颜色
   * 如果未指定，则使用 fill-color
   */
  'fill-outline-color'?: Color;

  /**
   * 填充平移 [x, y]（像素）
   * @default [0, 0]
   */
  'fill-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * 填充平移锚点
   * @default "map"
   */
  'fill-translate-anchor'?: TranslateAnchor;

  /**
   * 填充图案
   */
  'fill-pattern'?: DataDrivenProperty<string>;
}

// ==================== Line Layer Paint ====================

/**
 * LinePaint - 线图层绘制属性
 */
export interface LinePaint {
  /**
   * 线不透明度
   * @default 1
   */
  'line-opacity'?: DataDrivenProperty<number>;

  /**
   * 线颜色
   * @default "#000000"
   */
  'line-color'?: Color;

  /**
   * 线平移 [x, y]（像素）
   * @default [0, 0]
   */
  'line-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * 线平移锚点
   * @default "map"
   */
  'line-translate-anchor'?: TranslateAnchor;

  /**
   * 线宽度（像素）
   * @default 1
   */
  'line-width'?: DataDrivenProperty<number>;

  /**
   * 线间隙宽度（像素）
   * @default 0
   */
  'line-gap-width'?: DataDrivenProperty<number>;

  /**
   * 线偏移（像素）
   * @default 0
   */
  'line-offset'?: DataDrivenProperty<number>;

  /**
   * 线模糊（像素）
   * @default 0
   */
  'line-blur'?: DataDrivenProperty<number>;

  /**
   * 线虚线图案
   * 数组指定虚线和间隔的长度（单位：线宽倍数）
   */
  'line-dasharray'?: DataDrivenProperty<number[]>;

  /**
   * 线图案
   */
  'line-pattern'?: DataDrivenProperty<string>;

  /**
   * 线渐变色
   * 仅当 source 为 geojson 且 lineMetrics 为 true 时有效
   */
  'line-gradient'?: Expression;
}

// ==================== Symbol Layer Paint ====================

/**
 * SymbolPaint - 符号图层绘制属性
 */
export interface SymbolPaint {
  // ---------- Icon Paint 属性 ----------

  /**
   * 图标不透明度
   * @default 1
   */
  'icon-opacity'?: DataDrivenProperty<number>;

  /**
   * 图标颜色
   * @default "#000000"
   */
  'icon-color'?: Color;

  /**
   * 图标光晕颜色
   * @default "rgba(0, 0, 0, 0)"
   */
  'icon-halo-color'?: Color;

  /**
   * 图标光晕宽度（像素）
   * @default 0
   */
  'icon-halo-width'?: DataDrivenProperty<number>;

  /**
   * 图标光晕模糊（像素）
   * @default 0
   */
  'icon-halo-blur'?: DataDrivenProperty<number>;

  /**
   * 图标平移 [x, y]（像素）
   * @default [0, 0]
   */
  'icon-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * 图标平移锚点
   * @default "map"
   */
  'icon-translate-anchor'?: TranslateAnchor;

  // ---------- Text Paint 属性 ----------

  /**
   * 文本不透明度
   * @default 1
   */
  'text-opacity'?: DataDrivenProperty<number>;

  /**
   * 文本颜色
   * @default "#000000"
   */
  'text-color'?: Color;

  /**
   * 文本光晕颜色
   * @default "rgba(0, 0, 0, 0)"
   */
  'text-halo-color'?: Color;

  /**
   * 文本光晕宽度（像素）
   * @default 0
   */
  'text-halo-width'?: DataDrivenProperty<number>;

  /**
   * 文本光晕模糊（像素）
   * @default 0
   */
  'text-halo-blur'?: DataDrivenProperty<number>;

  /**
   * 文本平移 [x, y]（像素）
   * @default [0, 0]
   */
  'text-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * 文本平移锚点
   * @default "map"
   */
  'text-translate-anchor'?: TranslateAnchor;
}

// ==================== Circle Layer Paint ====================

/**
 * 圆形缩放方式
 */
export type CirclePitchScale = 'map' | 'viewport';

/**
 * 圆形对齐方式
 */
export type CirclePitchAlignment = 'map' | 'viewport';

/**
 * CirclePaint - 圆形图层绘制属性
 */
export interface CirclePaint {
  /**
   * 圆形半径（像素）
   * @default 5
   */
  'circle-radius'?: DataDrivenProperty<number>;

  /**
   * 圆形颜色
   * @default "#000000"
   */
  'circle-color'?: Color;

  /**
   * 圆形模糊（像素）
   * @default 0
   */
  'circle-blur'?: DataDrivenProperty<number>;

  /**
   * 圆形不透明度
   * @default 1
   */
  'circle-opacity'?: DataDrivenProperty<number>;

  /**
   * 圆形平移 [x, y]（像素）
   * @default [0, 0]
   */
  'circle-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * 圆形平移锚点
   * @default "map"
   */
  'circle-translate-anchor'?: TranslateAnchor;

  /**
   * 圆形缩放方式
   * @default "map"
   */
  'circle-pitch-scale'?: CirclePitchScale;

  /**
   * 圆形对齐方式
   * @default "viewport"
   */
  'circle-pitch-alignment'?: CirclePitchAlignment;

  /**
   * 圆形描边宽度（像素）
   * @default 0
   */
  'circle-stroke-width'?: DataDrivenProperty<number>;

  /**
   * 圆形描边颜色
   * @default "#000000"
   */
  'circle-stroke-color'?: Color;

  /**
   * 圆形描边不透明度
   * @default 1
   */
  'circle-stroke-opacity'?: DataDrivenProperty<number>;
}

// ==================== Heatmap Layer Paint ====================

/**
 * HeatmapPaint - 热力图图层绘制属性
 */
export interface HeatmapPaint {
  /**
   * 热力图半径（像素）
   * @default 30
   */
  'heatmap-radius'?: DataDrivenProperty<number>;

  /**
   * 热力图权重
   * 用于设置每个点对热力图的贡献程度
   * @default 1
   */
  'heatmap-weight'?: DataDrivenProperty<number>;

  /**
   * 热力图强度
   * 控制全局热力图强度
   * @default 1
   */
  'heatmap-intensity'?: DataDrivenProperty<number>;

  /**
   * 热力图颜色
   * 定义热力图的颜色渐变
   * 必须使用插值表达式，输入为 ["heatmap-density"]
   * @example
   * [
   *   "interpolate",
   *   ["linear"],
   *   ["heatmap-density"],
   *   0, "rgba(0, 0, 255, 0)",
   *   0.1, "royalblue",
   *   0.3, "cyan",
   *   0.5, "lime",
   *   0.7, "yellow",
   *   1, "red"
   * ]
   */
  'heatmap-color'?: Expression;

  /**
   * 热力图不透明度
   * @default 1
   */
  'heatmap-opacity'?: DataDrivenProperty<number>;
}

// ==================== Fill-Extrusion Layer Paint ====================

/**
 * FillExtrusionPaint - 填充拉伸图层绘制属性
 */
export interface FillExtrusionPaint {
  /**
   * 填充拉伸不透明度
   * @default 1
   */
  'fill-extrusion-opacity'?: DataDrivenProperty<number>;

  /**
   * 填充拉伸颜色
   * @default "#000000"
   */
  'fill-extrusion-color'?: Color;

  /**
   * 填充拉伸平移 [x, y]（像素）
   * @default [0, 0]
   */
  'fill-extrusion-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * 填充拉伸平移锚点
   * @default "map"
   */
  'fill-extrusion-translate-anchor'?: TranslateAnchor;

  /**
   * 填充拉伸图案
   */
  'fill-extrusion-pattern'?: DataDrivenProperty<string>;

  /**
   * 填充拉伸高度（米）
   * @default 0
   */
  'fill-extrusion-height'?: DataDrivenProperty<number>;

  /**
   * 填充拉伸基础高度（米）
   * @default 0
   */
  'fill-extrusion-base'?: DataDrivenProperty<number>;

  /**
   * 是否应用垂直渐变
   * @default true
   */
  'fill-extrusion-vertical-gradient'?: boolean;
}

// ==================== Raster Layer Paint ====================

/**
 * 栅格重采样方式
 */
export type RasterResampling = 'linear' | 'nearest';

/**
 * RasterPaint - 栅格图层绘制属性
 */
export interface RasterPaint {
  /**
   * 栅格不透明度
   * @default 1
   */
  'raster-opacity'?: DataDrivenProperty<number>;

  /**
   * 栅格色相旋转（度）
   * @default 0
   */
  'raster-hue-rotate'?: DataDrivenProperty<number>;

  /**
   * 栅格最小亮度
   * @default 0
   */
  'raster-brightness-min'?: DataDrivenProperty<number>;

  /**
   * 栅格最大亮度
   * @default 1
   */
  'raster-brightness-max'?: DataDrivenProperty<number>;

  /**
   * 栅格饱和度
   * @default 0
   */
  'raster-saturation'?: DataDrivenProperty<number>;

  /**
   * 栅格对比度
   * @default 0
   */
  'raster-contrast'?: DataDrivenProperty<number>;

  /**
   * 栅格重采样方式
   * @default "linear"
   */
  'raster-resampling'?: RasterResampling;

  /**
   * 栅格淡入淡出持续时间（毫秒）
   * @default 300
   */
  'raster-fade-duration'?: number;
}

// ==================== Hillshade Layer Paint ====================

/**
 * 山体阴影光照锚点
 */
export type HillshadeIlluminationAnchor = 'map' | 'viewport';

/**
 * 山体阴影算法
 */
export type HillshadeMethod = 'standard' | 'basic' | 'combined' | 'igor' | 'multidirectional';

/**
 * HillshadePaint - 山体阴影图层绘制属性
 */
export interface HillshadePaint {
  /**
   * 山体阴影光照方向（度）
   * 0 表示正北，90 表示正东
   * @default 335
   * 
   * 当 hillshade-method 为 multidirectional 时，可以指定多个光源方向
   */
  'hillshade-illumination-direction'?: DataDrivenProperty<number | number[]>;

  /**
   * 山体阴影光照高度（度）
   * 0 表示日落，90 表示正午
   * @default 45
   * 
   * 当 hillshade-method 为 multidirectional 时，可以指定多个光源高度
   */
  'hillshade-illumination-altitude'?: DataDrivenProperty<number | number[]>;

  /**
   * 山体阴影光照锚点
   * @default "viewport"
   */
  'hillshade-illumination-anchor'?: HillshadeIlluminationAnchor;

  /**
   * 山体阴影夸张程度
   * @default 0.5
   */
  'hillshade-exaggeration'?: DataDrivenProperty<number>;

  /**
   * 山体阴影阴影颜色
   * @default "#000000"
   * 
   * 当 hillshade-method 为 multidirectional 时，可以指定多个颜色
   */
  'hillshade-shadow-color'?: DataDrivenProperty<string | string[]>;

  /**
   * 山体阴影高光颜色
   * @default "#FFFFFF"
   * 
   * 当 hillshade-method 为 multidirectional 时，可以指定多个颜色
   */
  'hillshade-highlight-color'?: DataDrivenProperty<string | string[]>;

  /**
   * 山体阴影强调颜色
   * 用于强调陡峭的地形特征
   * @default "#000000"
   */
  'hillshade-accent-color'?: Color;

  /**
   * 山体阴影算法
   * @default "standard"
   */
  'hillshade-method'?: HillshadeMethod;
}

