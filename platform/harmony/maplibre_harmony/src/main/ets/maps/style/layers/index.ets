/**
 * Style Layers - Module exports
 */

// Layer classes
export { FillLayer } from './FillLayer';

export { LineLayer } from './LineLayer';

export { CircleLayer } from './CircleLayer';

export { SymbolLayer } from './SymbolLayer';
export type { TextProperties, IconProperties, SymbolProperties } from './SymbolLayer';

export { RasterLayer } from './RasterLayer';

export { BackgroundLayer } from './BackgroundLayer';

export { HeatmapLayer } from './HeatmapLayer';

export { HillshadeLayer } from './HillshadeLayer';

export { ColorReliefLayer } from './ColorReliefLayer';

export { FillExtrusionLayer } from './FillExtrusionLayer';

export { LocationIndicatorLayer } from './LocationIndicatorLayer';

// Property types
export { PropertyValue } from './PropertyValue';

export { PaintPropertyValue } from './PaintPropertyValue';

export { LayoutPropertyValue } from './LayoutPropertyValue';

export { PropertyFactory } from './PropertyFactory';

export { TransitionOptions } from './TransitionOptions';

// Layer interface types
export type { Layer, LayerOptions, LayerFilter, LayerLayout, LayerPaint, LayerMetadata } from './Layer';

// CustomLayer class
export { CustomLayer, createCustomLayerWithColor } from './CustomLayer';

// CustomDrawableLayer class
export { CustomDrawableLayer, DrawableLineOptions, DrawableFillOptions } from './CustomDrawableLayer';

export type { RGBAColor } from './CustomLayer';

// Property value types
export type { ColorValue, NumberValue, BooleanValue, StringValue } from './PropertyTypes';

// ==================== Expression types ====================
// Note: To avoid conflicts with the core Expression system, keep these for internal usage.
// For public use, import directly from './layers/Expression'.
export type {
  FilterExpression, MapLibreExpression
} from './Expression';

// ==================== Layout types ====================
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

// ==================== Paint types ====================
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
  HillshadeMethod,
  ColorReliefPaint
} from './LayerPaint';

