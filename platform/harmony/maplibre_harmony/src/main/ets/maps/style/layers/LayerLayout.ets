/**
 * MapLibre Layer Layout Properties
 * 图层布局属性类型定义
 *
 * 根据 MapLibre Style Spec 定义各图层类型的 Layout 属性
 * @see https://maplibre.org/maplibre-style-spec/layers/
 */

import type { Expression } from './Expression';
import type { ExpressionLiteral } from './PropertyTypes';
/**
 * 可见性类型
 */
export type Visibility = 'visible' | 'none';

/**
 * 支持 Expression 的属性值类型
 */
export type DataDrivenProperty<T> = T | Expression | ExpressionLiteral;

// ==================== Background Layer Layout ====================

/**
 * BackgroundLayout - 背景图层布局属性
 *
 * 背景图层只有 visibility 属性
 */
export interface BackgroundLayout {
  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Fill Layer Layout ====================

/**
 * FillLayout - 填充图层布局属性
 */
export interface FillLayout {
  /**
   * 填充排序键
   * 根据此值对要素进行排序，值越小越先渲染
   * 支持数据驱动
   */
  'fill-sort-key'?: DataDrivenProperty<number>;

  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Line Layer Layout ====================

/**
 * 线段端点样式
 */
export type LineCap = 'butt' | 'round' | 'square';

/**
 * 线段连接样式
 */
export type LineJoin = 'bevel' | 'round' | 'miter';

/**
 * LineLayout - 线图层布局属性
 */
export interface LineLayout {
  /**
   * 线段端点样式
   * @default "butt"
   */
  'line-cap'?: DataDrivenProperty<LineCap>;

  /**
   * 线段连接样式
   * @default "miter"
   */
  'line-join'?: DataDrivenProperty<LineJoin>;

  /**
   * 用于尖角连接的斜接限制
   * @default 2
   */
  'line-miter-limit'?: DataDrivenProperty<number>;

  /**
   * 用于圆角连接的圆角限制
   * @default 1.05
   */
  'line-round-limit'?: DataDrivenProperty<number>;

  /**
   * 线排序键
   * 根据此值对要素进行排序，值越小越先渲染
   * 支持数据驱动
   */
  'line-sort-key'?: DataDrivenProperty<number>;

  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Symbol Layer Layout ====================

/**
 * 符号放置方式
 */
export type SymbolPlacement = 'point' | 'line' | 'line-center';

/**
 * 文本或图标锚点位置
 */
export type Anchor =
  | 'center'
    | 'left'
    | 'right'
    | 'top'
    | 'bottom'
    | 'top-left'
    | 'top-right'
    | 'bottom-left'
    | 'bottom-right';

/**
 * 文本对齐方式
 */
export type TextJustify = 'auto' | 'left' | 'center' | 'right';

/**
 * 旋转对齐方式
 */
export type RotationAlignment = 'map' | 'viewport' | 'auto';

/**
 * 倾斜对齐方式
 */
export type PitchAlignment = 'map' | 'viewport' | 'auto';

/**
 * 图标文本适配方式
 */
export type IconTextFit = 'none' | 'width' | 'height' | 'both';

/**
 * 文本转换
 */
export type TextTransform = 'none' | 'uppercase' | 'lowercase';

/**
 * 符号 Z 顺序
 */
export type SymbolZOrder = 'auto' | 'viewport-y' | 'source';

/**
 * 重叠方式
 */
export type Overlap = 'never' | 'always' | 'cooperative';

/**
 * SymbolLayout - 符号图层布局属性
 */
export interface SymbolLayout {
  /**
   * 符号放置方式
   * @default "point"
   */
  'symbol-placement'?: SymbolPlacement;

  /**
   * 符号间距（像素）
   * 仅当 symbol-placement 为 line 时有效
   * @default 250
   */
  'symbol-spacing'?: number;

  /**
   * 是否避开边缘
   * @default false
   */
  'symbol-avoid-edges'?: boolean;

  /**
   * 符号排序键
   * 根据此值对要素进行排序，值越小越先渲染
   * 支持数据驱动
   */
  'symbol-sort-key'?: DataDrivenProperty<number>;

  /**
   * 符号 Z 顺序
   * @default "auto"
   */
  'symbol-z-order'?: SymbolZOrder;

  // ---------- Icon 属性 ----------

  /**
   * 图标是否允许重叠
   * @default false
   * @deprecated 使用 icon-overlap 代替
   */
  'icon-allow-overlap'?: DataDrivenProperty<boolean>;

  /**
   * 图标重叠方式
   * @default "never"
   */
  'icon-overlap'?: DataDrivenProperty<Overlap>;

  /**
   * 是否忽略图标放置
   * @default false
   */
  'icon-ignore-placement'?: boolean;

  /**
   * 图标是否可选
   * @default false
   */
  'icon-optional'?: boolean;

  /**
   * 图标旋转对齐方式
   * @default "auto"
   */
  'icon-rotation-alignment'?: RotationAlignment;

  /**
   * 图标大小
   * @default 1
   */
  'icon-size'?: DataDrivenProperty<number>;

  /**
   * 图标文本适配方式
   * @default "none"
   */
  'icon-text-fit'?: DataDrivenProperty<IconTextFit>;

  /**
   * 图标文本适配内边距 [上, 右, 下, 左]
   * @default [0, 0, 0, 0]
   */
  'icon-text-fit-padding'?: DataDrivenProperty<[number, number, number, number]>;

  /**
   * 图标图片名称
   */
  'icon-image'?: DataDrivenProperty<string>;

  /**
   * 图标旋转角度（度）
   * @default 0
   */
  'icon-rotate'?: DataDrivenProperty<number>;

  /**
   * 图标内边距（像素）
   * @default 2
   */
  'icon-padding'?: DataDrivenProperty<number>;

  /**
   * 防止图标上下颠倒
   * @default false
   */
  'icon-keep-upright'?: boolean;

  /**
   * 图标偏移 [x, y]
   * @default [0, 0]
   */
  'icon-offset'?: DataDrivenProperty<[number, number]>;

  /**
   * 图标锚点位置
   * @default "center"
   */
  'icon-anchor'?: DataDrivenProperty<Anchor>;

  /**
   * 图标倾斜对齐方式
   * @default "auto"
   */
  'icon-pitch-alignment'?: PitchAlignment;

  // ---------- Text 属性 ----------

  /**
   * 文本倾斜对齐方式
   * @default "auto"
   */
  'text-pitch-alignment'?: PitchAlignment;

  /**
   * 文本旋转对齐方式
   * @default "auto"
   */
  'text-rotation-alignment'?: RotationAlignment;

  /**
   * 文本字段
   */
  'text-field'?: DataDrivenProperty<string>;

  /**
   * 文本字体
   * @default ["Open Sans Regular", "Arial Unicode MS Regular"]
   */
  'text-font'?: DataDrivenProperty<string[]>;

  /**
   * 文本大小（像素）
   * @default 16
   */
  'text-size'?: DataDrivenProperty<number>;

  /**
   * 文本最大宽度（em）
   * @default 10
   */
  'text-max-width'?: DataDrivenProperty<number>;

  /**
   * 文本行高（em）
   * @default 1.2
   */
  'text-line-height'?: DataDrivenProperty<number>;

  /**
   * 文本字母间距（em）
   * @default 0
   */
  'text-letter-spacing'?: DataDrivenProperty<number>;

  /**
   * 文本对齐方式
   * @default "center"
   */
  'text-justify'?: DataDrivenProperty<TextJustify>;

  /**
   * 文本径向偏移（em）
   * @default 0
   */
  'text-radial-offset'?: DataDrivenProperty<number>;

  /**
   * 文本可变锚点
   */
  'text-variable-anchor'?: Anchor[];

  /**
   * 文本可变锚点偏移
   */
  'text-variable-anchor-offset'?: DataDrivenProperty<[number, number][]>;

  /**
   * 文本锚点位置
   * @default "center"
   */
  'text-anchor'?: DataDrivenProperty<Anchor>;

  /**
   * 文本最大角度（度）
   * @default 45
   */
  'text-max-angle'?: number;

  /**
   * 文本书写模式
   */
  'text-writing-mode'?: string[];

  /**
   * 文本旋转角度（度）
   * @default 0
   */
  'text-rotate'?: DataDrivenProperty<number>;

  /**
   * 文本内边距（像素）
   * @default 2
   */
  'text-padding'?: DataDrivenProperty<number>;

  /**
   * 防止文本上下颠倒
   * @default true
   */
  'text-keep-upright'?: boolean;

  /**
   * 文本转换
   * @default "none"
   */
  'text-transform'?: DataDrivenProperty<TextTransform>;

  /**
   * 文本偏移 [x, y]（em）
   * @default [0, 0]
   */
  'text-offset'?: DataDrivenProperty<[number, number]>;

  /**
   * 文本是否允许重叠
   * @default false
   * @deprecated 使用 text-overlap 代替
   */
  'text-allow-overlap'?: DataDrivenProperty<boolean>;

  /**
   * 文本重叠方式
   * @default "never"
   */
  'text-overlap'?: DataDrivenProperty<Overlap>;

  /**
   * 是否忽略文本放置
   * @default false
   */
  'text-ignore-placement'?: boolean;

  /**
   * 文本是否可选
   * @default false
   */
  'text-optional'?: boolean;

  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Circle Layer Layout ====================

/**
 * CircleLayout - 圆形图层布局属性
 */
export interface CircleLayout {
  /**
   * 圆形排序键
   * 根据此值对要素进行排序，值越小越先渲染
   * 支持数据驱动
   */
  'circle-sort-key'?: DataDrivenProperty<number>;

  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Heatmap Layer Layout ====================

/**
 * HeatmapLayout - 热力图图层布局属性
 */
export interface HeatmapLayout {
  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Fill-Extrusion Layer Layout ====================

/**
 * FillExtrusionLayout - 填充拉伸图层布局属性
 */
export interface FillExtrusionLayout {
  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Raster Layer Layout ====================

/**
 * RasterLayout - 栅格图层布局属性
 */
export interface RasterLayout {
  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Hillshade Layer Layout ====================

/**
 * HillshadeLayout - 山体阴影图层布局属性
 */
export interface HillshadeLayout {
  /**
   * 图层是否可见
   * @default "visible"
   */
  visibility?: Visibility;
}

