/**
 * MapLibre Layer Paint Properties
 * Layer paint property type definitions
 *
 * Paint property sets for each layer type derived from the MapLibre Style Spec
 * @see https://maplibre.org/maplibre-style-spec/layers/
 */

import type { Expression } from './Expression';
import type { ExpressionLiteral } from './PropertyTypes';
/**
 * Property value that can accept Expressions
 */
export type DataDrivenProperty<T> = T | Expression | ExpressionLiteral;

/**
 * Color type - accepts CSS color strings or Expressions
 */
export type Color = DataDrivenProperty<string>;

/**
 * Translate anchor
 */
export type TranslateAnchor = 'map' | 'viewport';

// ==================== Background Layer Paint ====================

/**
 * BackgroundPaint - Background layer paint properties
 */
export interface BackgroundPaint {
  /**
   * Background color
   * @default "#000000"
   */
  'background-color'?: Color;

  /**
   * Background pattern
   */
  'background-pattern'?: DataDrivenProperty<string>;

  /**
   * Background opacity
   * @default 1
   */
  'background-opacity'?: DataDrivenProperty<number>;
}

// ==================== Fill Layer Paint ====================

/**
 * FillPaint - Fill layer paint properties
 */
export interface FillPaint {
  /**
   * Toggle fill antialiasing
   * @default true
   */
  'fill-antialias'?: boolean;

  /**
   * Fill opacity
   * @default 1
   */
  'fill-opacity'?: DataDrivenProperty<number>;

  /**
   * Fill color
   * @default "#000000"
   */
  'fill-color'?: Color;

  /**
   * Fill outline color
   * Falls back to fill-color when unspecified
   */
  'fill-outline-color'?: Color;

  /**
   * Fill translate [x, y] in pixels
   * @default [0, 0]
   */
  'fill-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * Fill translate anchor
   * @default "map"
   */
  'fill-translate-anchor'?: TranslateAnchor;

  /**
   * Fill pattern
   */
  'fill-pattern'?: DataDrivenProperty<string>;
}

// ==================== Line Layer Paint ====================

/**
 * LinePaint - Line layer paint properties
 */
export interface LinePaint {
  /**
   * Line opacity
   * @default 1
   */
  'line-opacity'?: DataDrivenProperty<number>;

  /**
   * Line color
   * @default "#000000"
   */
  'line-color'?: Color;

  /**
   * Line translate [x, y] in pixels
   * @default [0, 0]
   */
  'line-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * Line translate anchor
   * @default "map"
   */
  'line-translate-anchor'?: TranslateAnchor;

  /**
   * Line width in pixels
   * @default 1
   */
  'line-width'?: DataDrivenProperty<number>;

  /**
   * Line gap width in pixels
   * @default 0
   */
  'line-gap-width'?: DataDrivenProperty<number>;

  /**
   * Line offset in pixels
   * @default 0
   */
  'line-offset'?: DataDrivenProperty<number>;

  /**
   * Line blur in pixels
   * @default 0
   */
  'line-blur'?: DataDrivenProperty<number>;

  /**
   * Line dash array
   * Array of dash and gap lengths (multiples of line width)
   */
  'line-dasharray'?: DataDrivenProperty<number[]>;

  /**
   * Line pattern
   */
  'line-pattern'?: DataDrivenProperty<string>;

  /**
   * Line gradient
   * Requires a GeoJSON source with lineMetrics enabled
   */
  'line-gradient'?: Expression;
}

// ==================== Symbol Layer Paint ====================

/**
 * SymbolPaint - Symbol layer paint properties
 */
export interface SymbolPaint {
  // ---------- Icon paint properties ----------

  /**
   * Icon opacity
   * @default 1
   */
  'icon-opacity'?: DataDrivenProperty<number>;

  /**
   * Icon color
   * @default "#000000"
   */
  'icon-color'?: Color;

  /**
   * Icon halo color
   * @default "rgba(0, 0, 0, 0)"
   */
  'icon-halo-color'?: Color;

  /**
   * Icon halo width in pixels
   * @default 0
   */
  'icon-halo-width'?: DataDrivenProperty<number>;

  /**
   * Icon halo blur in pixels
   * @default 0
   */
  'icon-halo-blur'?: DataDrivenProperty<number>;

  /**
   * Icon translate [x, y] in pixels
   * @default [0, 0]
   */
  'icon-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * Icon translate anchor
   * @default "map"
   */
  'icon-translate-anchor'?: TranslateAnchor;

  // ---------- Text paint properties ----------

  /**
   * Text opacity
   * @default 1
   */
  'text-opacity'?: DataDrivenProperty<number>;

  /**
   * Text color
   * @default "#000000"
   */
  'text-color'?: Color;

  /**
   * Text halo color
   * @default "rgba(0, 0, 0, 0)"
   */
  'text-halo-color'?: Color;

  /**
   * Text halo width in pixels
   * @default 0
   */
  'text-halo-width'?: DataDrivenProperty<number>;

  /**
   * Text halo blur in pixels
   * @default 0
   */
  'text-halo-blur'?: DataDrivenProperty<number>;

  /**
   * Text translate [x, y] in pixels
   * @default [0, 0]
   */
  'text-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * Text translate anchor
   * @default "map"
   */
  'text-translate-anchor'?: TranslateAnchor;
}

// ==================== Circle Layer Paint ====================

/**
 * Circle pitch scale options
 */
export type CirclePitchScale = 'map' | 'viewport';

/**
 * Circle pitch alignment
 */
export type CirclePitchAlignment = 'map' | 'viewport';

/**
 * CirclePaint - Circle layer paint properties
 */
export interface CirclePaint {
  /**
   * Circle radius in pixels
   * @default 5
   */
  'circle-radius'?: DataDrivenProperty<number>;

  /**
   * Circle color
   * @default "#000000"
   */
  'circle-color'?: Color;

  /**
   * Circle blur in pixels
   * @default 0
   */
  'circle-blur'?: DataDrivenProperty<number>;

  /**
   * Circle opacity
   * @default 1
   */
  'circle-opacity'?: DataDrivenProperty<number>;

  /**
   * Circle translate [x, y] in pixels
   * @default [0, 0]
   */
  'circle-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * Circle translate anchor
   * @default "map"
   */
  'circle-translate-anchor'?: TranslateAnchor;

  /**
   * Circle pitch scale mode
   * @default "map"
   */
  'circle-pitch-scale'?: CirclePitchScale;

  /**
   * Circle pitch alignment
   * @default "viewport"
   */
  'circle-pitch-alignment'?: CirclePitchAlignment;

  /**
   * Circle stroke width in pixels
   * @default 0
   */
  'circle-stroke-width'?: DataDrivenProperty<number>;

  /**
   * Circle stroke color
   * @default "#000000"
   */
  'circle-stroke-color'?: Color;

  /**
   * Circle stroke opacity
   * @default 1
   */
  'circle-stroke-opacity'?: DataDrivenProperty<number>;
}

// ==================== Heatmap Layer Paint ====================

/**
 * HeatmapPaint - Heatmap layer paint properties
 */
export interface HeatmapPaint {
  /**
   * Heatmap radius in pixels
   * @default 30
   */
  'heatmap-radius'?: DataDrivenProperty<number>;

  /**
   * Heatmap weight
   * Controls per-point contribution to the heatmap
   * @default 1
   */
  'heatmap-weight'?: DataDrivenProperty<number>;

  /**
   * Heatmap intensity
   * Adjusts the overall heatmap strength
   * @default 1
   */
  'heatmap-intensity'?: DataDrivenProperty<number>;

  /**
   * Heatmap color ramp
   * Defines the gradient used for the heatmap
   * Must use an interpolation expression over ["heatmap-density"]
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
   * Heatmap opacity
   * @default 1
   */
  'heatmap-opacity'?: DataDrivenProperty<number>;
}

// ==================== Fill-Extrusion Layer Paint ====================

/**
 * FillExtrusionPaint - Fill extrusion layer paint properties
 */
export interface FillExtrusionPaint {
  /**
   * Fill extrusion opacity
   * @default 1
   */
  'fill-extrusion-opacity'?: DataDrivenProperty<number>;

  /**
   * Fill extrusion color
   * @default "#000000"
   */
  'fill-extrusion-color'?: Color;

  /**
   * Fill extrusion translate [x, y] in pixels
   * @default [0, 0]
   */
  'fill-extrusion-translate'?: DataDrivenProperty<[number, number]>;

  /**
   * Fill extrusion translate anchor
   * @default "map"
   */
  'fill-extrusion-translate-anchor'?: TranslateAnchor;

  /**
   * Fill extrusion pattern
   */
  'fill-extrusion-pattern'?: DataDrivenProperty<string>;

  /**
   * Fill extrusion height in meters
   * @default 0
   */
  'fill-extrusion-height'?: DataDrivenProperty<number>;

  /**
   * Fill extrusion base height in meters
   * @default 0
   */
  'fill-extrusion-base'?: DataDrivenProperty<number>;

  /**
   * Apply vertical gradient
   * @default true
   */
  'fill-extrusion-vertical-gradient'?: boolean;
}

// ==================== Raster Layer Paint ====================

/**
 * Raster resampling modes
 */
export type RasterResampling = 'linear' | 'nearest';

/**
 * RasterPaint - Raster layer paint properties
 */
export interface RasterPaint {
  /**
   * Raster opacity
   * @default 1
   */
  'raster-opacity'?: DataDrivenProperty<number>;

  /**
   * Raster hue rotation in degrees
   * @default 0
   */
  'raster-hue-rotate'?: DataDrivenProperty<number>;

  /**
   * Raster minimum brightness
   * @default 0
   */
  'raster-brightness-min'?: DataDrivenProperty<number>;

  /**
   * Raster maximum brightness
   * @default 1
   */
  'raster-brightness-max'?: DataDrivenProperty<number>;

  /**
   * Raster saturation
   * @default 0
   */
  'raster-saturation'?: DataDrivenProperty<number>;

  /**
   * Raster contrast
   * @default 0
   */
  'raster-contrast'?: DataDrivenProperty<number>;

  /**
   * Raster resampling mode
   * @default "linear"
   */
  'raster-resampling'?: RasterResampling;

  /**
   * Raster fade duration in milliseconds
   * @default 300
   */
  'raster-fade-duration'?: number;
}

// ==================== Hillshade Layer Paint ====================

/**
 * Hillshade illumination anchor
 */
export type HillshadeIlluminationAnchor = 'map' | 'viewport';

/**
 * Hillshade rendering method
 */
export type HillshadeMethod = 'standard' | 'basic' | 'combined' | 'igor' | 'multidirectional';

/**
 * HillshadePaint - Hillshade layer paint properties
 */
export interface HillshadePaint {
  /**
   * Illumination direction in degrees
   * 0 = north, 90 = east
   * @default 335
   *
   * Accepts multiple directions when hillshade-method is multidirectional
   */
  'hillshade-illumination-direction'?: DataDrivenProperty<number | number[]>;

  /**
   * Illumination altitude in degrees
  * 0 = sunset, 90 = noon
   * @default 45
   *
   * Accepts multiple altitudes when hillshade-method is multidirectional
   */
  'hillshade-illumination-altitude'?: DataDrivenProperty<number | number[]>;

  /**
   * Illumination anchor
   * @default "viewport"
   */
  'hillshade-illumination-anchor'?: HillshadeIlluminationAnchor;

  /**
   * Hillshade exaggeration
   * @default 0.5
   */
  'hillshade-exaggeration'?: DataDrivenProperty<number>;

  /**
   * Hillshade shadow color
   * @default "#000000"
   *
   * Accepts multiple colors when hillshade-method is multidirectional
   */
  'hillshade-shadow-color'?: DataDrivenProperty<string | string[]>;

  /**
   * Hillshade highlight color
   * @default "#FFFFFF"
   *
   * Accepts multiple colors when hillshade-method is multidirectional
   */
  'hillshade-highlight-color'?: DataDrivenProperty<string | string[]>;

  /**
   * Hillshade accent color
   * Emphasizes steep terrain
   * @default "#000000"
   */
  'hillshade-accent-color'?: Color;

  /**
   * Hillshade method
   * @default "standard"
   */
  'hillshade-method'?: HillshadeMethod;
}

/**
 * ColorReliefPaint - ColorRelief layer paint properties
 */
export interface ColorReliefPaint {
  /**
   * The color value for steep terrain color stops
   * Uses ColorRampPropertyValue (interpolate expression with stops over elevation)
   */
  'color-relief-color'?: DataDrivenProperty<string>;

  /**
   * ColorRelief opacity
   * @default 1
   */
  'color-relief-opacity'?: DataDrivenProperty<number>;
}

