/**
 * Style Layers - 图层模块导出
 */

// 图层类
export { FillLayer } from './FillLayer';
export { LineLayer } from './LineLayer';
export { CircleLayer } from './CircleLayer';
export { SymbolLayer } from './SymbolLayer';
export { RasterLayer } from './RasterLayer';
export { BackgroundLayer } from './BackgroundLayer';
export { HeatmapLayer } from './HeatmapLayer';
export { HillshadeLayer } from './HillshadeLayer';
export { FillExtrusionLayer } from './FillExtrusionLayer';

// 属性类型
export { PropertyValue } from './PropertyValue';
export { PaintPropertyValue } from './PaintPropertyValue';
export { LayoutPropertyValue } from './LayoutPropertyValue';
export { PropertyFactory } from './PropertyFactory';
export { TransitionOptions } from './TransitionOptions';

// Layer 接口类型
export type { Layer, LayerOptions, LayerFilter, LayerLayout, LayerPaint, LayerMetadata } from './Layer';

// CustomLayer 类
export { CustomLayer, createCustomLayerWithColor } from './CustomLayer';
export type { RGBAColor } from './CustomLayer';

// 属性值类型
export type { ColorValue, NumberValue, BooleanValue, StringValue } from './PropertyTypes';

// ==================== Expression 类型 ====================
// 注意：为避免与现有 Expression 系统冲突，这些类型主要供内部使用
// 如需使用，请从 './layers/Expression' 直接导入
export type {
  FilterExpression,
  MapLibreExpression
} from './Expression';

// ==================== Layout 类型 ====================
export type {
  Visibility,
  DataDrivenProperty,
  BackgroundLayout,
  FillLayout,
  LineLayout,
  LineCap,
  LineJoin,
  SymbolLayout,
  SymbolPlacement,
  Anchor,
  TextJustify,
  RotationAlignment,
  PitchAlignment,
  IconTextFit,
  TextTransform,
  SymbolZOrder,
  Overlap,
  CircleLayout,
  HeatmapLayout,
  FillExtrusionLayout,
  RasterLayout,
  HillshadeLayout
} from './LayerLayout';

// ==================== Paint 类型 ====================
export type {
  Color,
  TranslateAnchor,
  BackgroundPaint,
  FillPaint,
  LinePaint,
  SymbolPaint,
  CirclePaint,
  CirclePitchScale,
  CirclePitchAlignment,
  HeatmapPaint,
  FillExtrusionPaint,
  RasterPaint,
  RasterResampling,
  HillshadePaint,
  HillshadeIlluminationAnchor,
  HillshadeMethod
} from './LayerPaint';

