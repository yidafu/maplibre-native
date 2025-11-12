/**
 * MapLibre Layer Layout Properties
 * Layer layout type definitions
 *
 * Layout property sets for each layer type derived from the MapLibre Style Spec
 * @see https://maplibre.org/maplibre-style-spec/layers/
 */

import type { Expression } from './Expression';
import type { ExpressionLiteral } from './PropertyTypes';
/**
 * Visibility type
 */
export type Visibility = 'visible' | 'none';

/**
 * Property value that can accept Expressions
 */
export type DataDrivenProperty<T> = T | Expression | ExpressionLiteral;

// ==================== Background Layer Layout ====================

/**
 * BackgroundLayout - Background layer layout properties
 *
 * Background layers only expose the visibility property
 */
export interface BackgroundLayout {
  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Fill Layer Layout ====================

/**
 * FillLayout - Fill layer layout properties
 */
export interface FillLayout {
  /**
   * Fill sort key
   * Features are rendered in ascending order by this value
   * Supports data-driven values
   */
  'fill-sort-key'?: DataDrivenProperty<number>;

  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Line Layer Layout ====================

/**
 * Line cap style
 */
export type LineCap = 'butt' | 'round' | 'square';

/**
 * Line join style
 */
export type LineJoin = 'bevel' | 'round' | 'miter';

/**
 * LineLayout - Line layer layout properties
 */
export interface LineLayout {
  /**
   * Line cap style
   * @default "butt"
   */
  'line-cap'?: DataDrivenProperty<LineCap>;

  /**
   * Line join style
   * @default "miter"
   */
  'line-join'?: DataDrivenProperty<LineJoin>;

  /**
   * Miter limit for sharp corners
   * @default 2
   */
  'line-miter-limit'?: DataDrivenProperty<number>;

  /**
   * Round limit for rounded joins
   * @default 1.05
   */
  'line-round-limit'?: DataDrivenProperty<number>;

  /**
   * Line sort key
   * Features are rendered in ascending order by this value
   * Supports data-driven values
   */
  'line-sort-key'?: DataDrivenProperty<number>;

  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Symbol Layer Layout ====================

/**
 * Symbol placement mode
 */
export type SymbolPlacement = 'point' | 'line' | 'line-center';

/**
 * Text or icon anchor positions
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
 * Text justification modes
 */
export type TextJustify = 'auto' | 'left' | 'center' | 'right';

/**
 * Rotation alignment options
 */
export type RotationAlignment = 'map' | 'viewport' | 'auto';

/**
 * Pitch alignment options
 */
export type PitchAlignment = 'map' | 'viewport' | 'auto';

/**
 * Icon text-fit modes
 */
export type IconTextFit = 'none' | 'width' | 'height' | 'both';

/**
 * Text transform modes
 */
export type TextTransform = 'none' | 'uppercase' | 'lowercase';

/**
 * Symbol Z ordering modes
 */
export type SymbolZOrder = 'auto' | 'viewport-y' | 'source';

/**
 * Overlap behavior
 */
export type Overlap = 'never' | 'always' | 'cooperative';

/**
 * SymbolLayout - Symbol layer layout properties
 */
export interface SymbolLayout {
  /**
   * Symbol placement mode
   * @default "point"
   */
  'symbol-placement'?: SymbolPlacement;

  /**
   * Symbol spacing in pixels
   * Applies only when symbol-placement is set to line
   * @default 250
   */
  'symbol-spacing'?: number;

  /**
   * Avoid edges
   * @default false
   */
  'symbol-avoid-edges'?: boolean;

  /**
   * Symbol sort key
   * Features are rendered in ascending order by this value
   * Supports data-driven values
   */
  'symbol-sort-key'?: DataDrivenProperty<number>;

  /**
   * Symbol Z order
   * @default "auto"
   */
  'symbol-z-order'?: SymbolZOrder;

  // ---------- Icon properties ----------

  /**
   * Icon overlap mode
   * @default "never"
   */
  'icon-overlap'?: DataDrivenProperty<Overlap>;

  /**
   * Ignore icon placement
   * @default false
   */
  'icon-ignore-placement'?: boolean;

  /**
   * Icon optional flag
   * @default false
   */
  'icon-optional'?: boolean;

  /**
   * Icon rotation alignment
   * @default "auto"
   */
  'icon-rotation-alignment'?: RotationAlignment;

  /**
   * Icon size
   * @default 1
   */
  'icon-size'?: DataDrivenProperty<number>;

  /**
   * Icon text-fit mode
   * @default "none"
   */
  'icon-text-fit'?: DataDrivenProperty<IconTextFit>;

  /**
   * Icon text-fit padding [top, right, bottom, left]
   * @default [0, 0, 0, 0]
   */
  'icon-text-fit-padding'?: DataDrivenProperty<[number, number, number, number]>;

  /**
   * Icon image name
   */
  'icon-image'?: DataDrivenProperty<string>;

  /**
   * Icon rotation angle in degrees
   * @default 0
   */
  'icon-rotate'?: DataDrivenProperty<number>;

  /**
   * Icon padding in pixels
   * @default 2
   */
  'icon-padding'?: DataDrivenProperty<number>;

  /**
   * Keep icon upright
   * @default false
   */
  'icon-keep-upright'?: boolean;

  /**
   * Icon offset [x, y]
   * @default [0, 0]
   */
  'icon-offset'?: DataDrivenProperty<[number, number]>;

  /**
   * Icon anchor position
   * @default "center"
   */
  'icon-anchor'?: DataDrivenProperty<Anchor>;

  /**
   * Icon pitch alignment
   * @default "auto"
   */
  'icon-pitch-alignment'?: PitchAlignment;

  // ---------- Text properties ----------

  /**
   * Text pitch alignment
   * @default "auto"
   */
  'text-pitch-alignment'?: PitchAlignment;

  /**
   * Text rotation alignment
   * @default "auto"
   */
  'text-rotation-alignment'?: RotationAlignment;

  /**
   * Text field
   */
  'text-field'?: DataDrivenProperty<string>;

  /**
   * Text font family list
   * @default ["HarmonyOS Sans", "HarmonyOS Sans SC", "Noto Sans CJK SC", "Noto Sans", "sans-serif"]
   * @platform Harmony: Uses official HarmonyOS font family names (with spaces), automatically mapped to font files
   */
  'text-font'?: DataDrivenProperty<string[]>;

  /**
   * Text size in pixels
   * @default 16
   */
  'text-size'?: DataDrivenProperty<number>;

  /**
   * Text maximum width in em
   * @default 10
   */
  'text-max-width'?: DataDrivenProperty<number>;

  /**
   * Text line height in em
   * @default 1.2
   */
  'text-line-height'?: DataDrivenProperty<number>;

  /**
   * Text letter spacing in em
   * @default 0
   */
  'text-letter-spacing'?: DataDrivenProperty<number>;

  /**
   * Text justification
   * @default "center"
   */
  'text-justify'?: DataDrivenProperty<TextJustify>;

  /**
   * Text radial offset in em
   * @default 0
   */
  'text-radial-offset'?: DataDrivenProperty<number>;

  /**
   * Text variable anchor choices
   */
  'text-variable-anchor'?: Anchor[];

  /**
   * Text variable anchor offsets
   */
  'text-variable-anchor-offset'?: DataDrivenProperty<[number, number][]>;

  /**
   * Text anchor position
   * @default "center"
   */
  'text-anchor'?: DataDrivenProperty<Anchor>;

  /**
   * Text maximum angle in degrees
   * @default 45
   */
  'text-max-angle'?: number;

  /**
   * Text writing mode
   */
  'text-writing-mode'?: string[];

  /**
   * Text rotation angle in degrees
   * @default 0
   */
  'text-rotate'?: DataDrivenProperty<number>;

  /**
   * Text padding in pixels
   * @default 2
   */
  'text-padding'?: DataDrivenProperty<number>;

  /**
   * Keep text upright
   * @default true
   */
  'text-keep-upright'?: boolean;

  /**
   * Text transform
   * @default "none"
   */
  'text-transform'?: DataDrivenProperty<TextTransform>;

  /**
   * Text offset [x, y] in em
   * @default [0, 0]
   */
  'text-offset'?: DataDrivenProperty<[number, number]>;

  /**
   * Text overlap mode
   * @default "never"
   */
  'text-overlap'?: DataDrivenProperty<Overlap>;

  /**
   * Ignore text placement
   * @default false
   */
  'text-ignore-placement'?: boolean;

  /**
   * Optional text flag
   * @default false
   */
  'text-optional'?: boolean;

  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Circle Layer Layout ====================

/**
 * CircleLayout - Circle layer layout properties
 */
export interface CircleLayout {
  /**
   * Circle sort key
   * Features are rendered in ascending order by this value
   * Supports data-driven values
   */
  'circle-sort-key'?: DataDrivenProperty<number>;

  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Heatmap Layer Layout ====================

/**
 * HeatmapLayout - Heatmap layer layout properties
 */
export interface HeatmapLayout {
  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Fill-Extrusion Layer Layout ====================

/**
 * FillExtrusionLayout - Fill extrusion layer layout properties
 */
export interface FillExtrusionLayout {
  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Raster Layer Layout ====================

/**
 * RasterLayout - Raster layer layout properties
 */
export interface RasterLayout {
  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

// ==================== Hillshade Layer Layout ====================

/**
 * HillshadeLayout - Hillshade layer layout properties
 */
export interface HillshadeLayout {
  /**
   * Layer visibility
   * @default "visible"
   */
  visibility?: Visibility;
}

