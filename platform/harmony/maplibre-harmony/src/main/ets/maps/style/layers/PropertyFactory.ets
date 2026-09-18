import { PaintPropertyValue } from './PaintPropertyValue';
import { LayoutPropertyValue } from './LayoutPropertyValue';
import { Expression } from '../expressions/Expression';

/**
 * PropertyFactory - Property factory utilities
 *
 * Provides factory helpers for every layer layout/paint property, supporting both constant
 * values and Expressions.
 *
 * Two categories of helpers are available:
 * 1. **Layout Properties** – control geometry placement and arrangement
 * 2. **Paint Properties** – control visual appearance
 *
 * Each helper accepts:
 * - Constant values: raw primitives (numbers, strings, booleans, arrays)
 * - Expressions: `Expression` instances for data- or zoom-driven styling
 *
 * @example
 * ```typescript
 * import { FillLayer } from 'libmaplibre.so';
 * import { Expression, Interpolator, Stop, PropertyFactory } from 'maplibre-harmony';
 *
 * const layer = new FillLayer("regions", "regions-source");
 *
 * // Constant value
 * layer.setFillColor(PropertyFactory.fillColor("#ff0000").getValue());
 *
 * // Data-driven expression
 * layer.setFillColor(
 *   PropertyFactory.fillColor(
 *     Expression.match(
 *       Expression.get("type"),
 *       Expression.literal("park"), Expression.literal("#00ff00"),
 *       Expression.literal("water"), Expression.literal("#0000ff"),
 *       Expression.literal("#cccccc")
 *     )
 *   ).getExpression()?.toArray()
 * );
 *
 * // Zoom-based interpolation
 * layer.setFillOpacity(
 *   PropertyFactory.fillOpacity(
 *     Expression.interpolate(
 *       Interpolator.linear(),
 *       Expression.zoom(),
 *       Stop.stop(10, Expression.literal(0.3)),
 *       Stop.stop(15, Expression.literal(0.8))
 *     )
 *   ).getExpression()?.toArray()
 * );
 * ```
 *
 * @see {@link Expression} for the Expression API
 * @see https://maplibre.org/maplibre-style-spec/ for the MapLibre Style Specification
 */
export class PropertyFactory {
  // ==================== Common properties ====================

  /**
   * Configure layer visibility
   *
   * Controls whether the layer is rendered on the map.
   *
   * @param value Visibility value
   *   - `'visible'`: layer is rendered
   *   - `'none'`: layer is hidden
   * @returns Layout property wrapper
   *
   * @example
  * ```typescript
   * layer.setVisibility(PropertyFactory.visibility('visible').getValue());
   * ```
   */
  public static visibility(value: 'visible' | 'none'): LayoutPropertyValue<string> {
    return new LayoutPropertyValue<string>('visibility', value);
  }

  // ==================== Fill layer properties ====================

  /**
   * Configure fill color
   *
   * Defines the fill’s color. RGBA values are supported; the alpha channel does not affect the
   * opacity of the 1 px outline.
   *
   * @param color CSS color string (e.g. `"#ff0000"`, `"rgba(255,0,0,0.5)"`, `"red"`)
   * @returns Paint property wrapper
   *
   * @example
  * ```typescript
   * // Constant color
   * layer.setFillColor(PropertyFactory.fillColor("#ff0000").getValue());
   *
   * // Data-driven color
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
   * // Zoom-level interpolation
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
  public static fillColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-color', value);
  }

  public static fillOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-opacity', value);
  }

  public static fillOutlineColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-outline-color', value);
  }

  public static fillPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-pattern', value);
  }

  public static fillAntialias(value: boolean | Expression<boolean>): PaintPropertyValue<boolean> {
    return PropertyFactory.createPaintProperty('fill-antialias', value);
  }

  public static fillTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('fill-translate', value);
  }

  /**
   * Configure the reference frame for fillTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static fillTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-translate-anchor', value);
  }

  /**
   * Fill sort key controlling draw order within the same layer
   * Smaller keys are rendered beneath larger ones
   */
  public static fillSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('fill-sort-key', value);
  }

  // ==================== Line layer properties ====================

  public static lineColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-color', value);
  }

  public static lineWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-width', value);
  }

  public static lineOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-opacity', value);
  }

  public static linePattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-pattern', value);
  }

  public static lineGapWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-gap-width', value);
  }

  public static lineDasharray(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('line-dasharray', value);
  }

  public static lineBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-blur', value);
  }

  public static lineCap(value: 'butt' | 'round' | 'square' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('line-cap', value);
  }

  public static lineJoin(value: 'bevel' | 'round' | 'miter' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('line-join', value);
  }

  /**
   * Line translation in pixels; `[x, y]`, negative values move left/up
   */
  public static lineTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('line-translate', value);
  }

  /**
   * Configure the reference frame for lineTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static lineTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-translate-anchor', value);
  }

  /**
   * Line offset in pixels; positive shifts right, negative shifts left
   */
  public static lineOffset(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-offset', value);
  }

  /**
   * Miter limit that converts miter joins to bevel joins automatically
   */
  public static lineMiterLimit(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-miter-limit', value);
  }

  /**
   * Round limit that converts round joins to miter joins automatically
   */
  public static lineRoundLimit(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-round-limit', value);
  }

  /**
   * Define gradient colors along the line (Expression only)
   * Must rely on the `line-progress` expression
   */
  public static lineGradient(expression: Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-gradient', expression);
  }

  /**
   * Line sort key controlling draw order within the same layer
   */
  public static lineSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-sort-key', value);
  }

  // ==================== Circle layer properties ====================

  public static circleRadius(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-radius', value);
  }

  public static circleColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-color', value);
  }

  public static circleOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-opacity', value);
  }

  public static circleBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-blur', value);
  }

  public static circleStrokeWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-stroke-width', value);
  }

  public static circleStrokeColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-stroke-color', value);
  }

  public static circleStrokeOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('circle-stroke-opacity', value);
  }

  /**
   * Circle translation in pixels; `[x, y]`, negative values move left/up
   */
  public static circleTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('circle-translate', value);
  }

  /**
   * Configure the reference frame for circleTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static circleTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-translate-anchor', value);
  }

  /**
   * Control how circles scale relative to the map
   * @param scale 'map' | 'viewport'
   */
  public static circlePitchScale(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-pitch-scale', value);
  }

  /**
   * Control how circles align relative to the map
   * @param alignment 'map' | 'viewport'
   */
  public static circlePitchAlignment(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-pitch-alignment', value);
  }

  /**
   * Circle sort key controlling draw order within the same layer
   */
  public static circleSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('circle-sort-key', value);
  }

  // ==================== Symbol layer properties ====================

  public static iconImage(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-image', value);
  }

  public static iconSize(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-size', value);
  }

  public static iconRotate(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-rotate', value);
  }

  /**
   * Allow icon overlap
   */
  public static iconAllowOverlap(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-allow-overlap', value);
  }

  /**
   * Ignore icon placement
   */
  public static iconIgnorePlacement(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-ignore-placement', value);
  }

  /**
   * Icon optional flag; display text even when the icon is unavailable
   */
  public static iconOptional(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-optional', value);
  }

  /**
   * Icon anchor position
   */
  public static iconAnchor(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-anchor', value);
  }

  /**
   * Icon offset [x, y]
   */
  public static iconOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('icon-offset', value);
  }

  /**
   * Icon padding
   */
  public static iconPadding(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-padding', value);
  }

  /**
   * Keep icon upright
   */
  public static iconKeepUpright(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-keep-upright', value);
  }

  /**
   * Icon pitch alignment
   */
  public static iconPitchAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-pitch-alignment', value);
  }

  /**
   * Icon rotation alignment
   */
  public static iconRotationAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-rotation-alignment', value);
  }

  /**
   * Icon text-fit mode
   */
  public static iconTextFit(value: 'none' | 'width' | 'height' | 'both' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-text-fit', value);
  }

  /**
   * Icon text-fit padding [top, right, bottom, left]
   */
  public static iconTextFitPadding(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('icon-text-fit-padding', value);
  }

  /**
   * Icon translate [x, y]
   */
  public static iconTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('icon-translate', value);
  }

  /**
   * Configure the reference frame for iconTranslate
   */
  public static iconTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-translate-anchor', value);
  }

  /**
   * Icon halo width
   */
  public static iconHaloWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-halo-width', value);
  }

  /**
   * Icon halo color
   */
  public static iconHaloColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-halo-color', value);
  }

  /**
   * Icon halo blur
   */
  public static iconHaloBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-halo-blur', value);
  }

  public static iconColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-color', value);
  }

  public static iconOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-opacity', value);
  }

  public static textField(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-field', value);
  }

  public static textSize(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-size', value);
  }

  public static textFont(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-font', value);
  }

  public static textOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('text-offset', value);
  }

  public static textAnchor(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-anchor', value);
  }

  /**
   * Text maximum width (ems)
   */
  public static textMaxWidth(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-max-width', value);
  }

  /**
   * Text letter spacing (ems)
   */
  public static textLetterSpacing(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-letter-spacing', value);
  }

  /**
   * Text justification
   */
  public static textJustify(value: 'auto' | 'left' | 'center' | 'right' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-justify', value);
  }

  /**
   * Text radial offset
   */
  public static textRadialOffset(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-radial-offset', value);
  }

  /**
   * Text variable anchors
   */
  public static textVariableAnchor(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-variable-anchor', value);
  }

  /**
   * Text variable anchor offsets
   */
  public static textVariableAnchorOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('text-variable-anchor-offset', value);
  }

  /**
   * Text rotation angle
   */
  public static textRotate(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-rotate', value);
  }

  /**
   * Text padding
   */
  public static textPadding(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-padding', value);
  }

  /**
   * Keep text upright
   */
  public static textKeepUpright(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-keep-upright', value);
  }

  /**
   * Text transform (case)
   */
  public static textTransform(value: 'none' | 'uppercase' | 'lowercase' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-transform', value);
  }

  /**
   * Text maximum angle
   */
  public static textMaxAngle(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-max-angle', value);
  }

  /**
   * Text rotation alignment
   */
  public static textRotationAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-rotation-alignment', value);
  }

  /**
   * Text pitch alignment
   */
  public static textPitchAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-pitch-alignment', value);
  }

  /**
   * Text line height (ems)
   */
  public static textLineHeight(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-line-height', value);
  }

  /**
   * Text writing mode
   */
  public static textWritingMode(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-writing-mode', value);
  }

  /**
   * Allow text overlap
   */
  public static textAllowOverlap(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-allow-overlap', value);
  }

  /**
   * Ignore text placement
   */
  public static textIgnorePlacement(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-ignore-placement', value);
  }

  /**
   * Text optional flag; show icons when text is unavailable
   */
  public static textOptional(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-optional', value);
  }

  public static textColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-color', value);
  }

  public static textOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-opacity', value);
  }

  public static textHaloColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-halo-color', value);
  }

  public static textHaloWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-halo-width', value);
  }

  /**
   * Text halo blur
   */
  public static textHaloBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-halo-blur', value);
  }

  /**
   * Text translate [x, y]
   */
  public static textTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('text-translate', value);
  }

  /**
   * Configure the reference frame for textTranslate
   */
  public static textTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-translate-anchor', value);
  }

  /**
   * Symbol placement mode
   */
  public static symbolPlacement(value: 'point' | 'line' | 'line-center' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('symbol-placement', value);
  }

  /**
   * Symbol spacing (only applies when symbolPlacement is set to line)
   */
  public static symbolSpacing(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('symbol-spacing', value);
  }

  /**
   * Avoid symbol placement near tile edges
   */
  public static symbolAvoidEdges(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('symbol-avoid-edges', value);
  }

  /**
   * Symbol sort key
   */
  public static symbolSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('symbol-sort-key', value);
  }

  /**
   * Symbol Z order (deprecated; prefer symbolSortKey)
   */
  public static symbolZOrder(value: 'auto' | 'viewport-y' | 'source' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('symbol-z-order', value);
  }

  /**
   * Symbol screen-space flag (deprecated)
   */
  public static symbolScreenSpace(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('symbol-screen-space', value);
  }

  // ==================== Raster layer properties ====================

  public static rasterOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-opacity', value);
  }

  public static rasterHueRotate(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-hue-rotate', value);
  }

  public static rasterBrightnessMin(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-brightness-min', value);
  }

  public static rasterBrightnessMax(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-brightness-max', value);
  }

  public static rasterContrast(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-contrast', value);
  }

  public static rasterSaturation(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-saturation', value);
  }

  /**
   * Raster fade duration in milliseconds
   */
  public static rasterFadeDuration(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-fade-duration', value);
  }

  /**
   * Raster resampling mode
   */
  public static rasterResampling(value: 'linear' | 'nearest' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('raster-resampling', value);
  }

  // ==================== Background layer properties ====================

  public static backgroundColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('background-color', value);
  }

  public static backgroundOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('background-opacity', value);
  }

  public static backgroundPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('background-pattern', value);
  }

  // ==================== Heatmap layer properties ====================

  public static heatmapWeight(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-weight', value);
  }

  public static heatmapIntensity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-intensity', value);
  }

  public static heatmapRadius(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-radius', value);
  }

  public static heatmapOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('heatmap-opacity', value);
  }

  /**
   * Define the heatmap color ramp (Expression only)
   * Must use the `heatmap-density` expression
   */
  public static heatmapColor(expression: Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('heatmap-color', expression);
  }

  // ==================== Hillshade layer properties ====================

  public static hillshadeIlluminationDirection(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('hillshade-illumination-direction', value);
  }

  public static hillshadeIlluminationAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-illumination-anchor', value);
  }

  public static hillshadeExaggeration(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('hillshade-exaggeration', value);
  }

  public static hillshadeShadowColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-shadow-color', value);
  }

  public static hillshadeHighlightColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-highlight-color', value);
  }

  public static hillshadeAccentColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('hillshade-accent-color', value);
  }

  // ==================== FillExtrusion layer properties ====================

  public static fillExtrusionHeight(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-height', value);
  }

  public static fillExtrusionBase(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-base', value);
  }

  public static fillExtrusionColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-color', value);
  }

  public static fillExtrusionOpacity(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('fill-extrusion-opacity', value);
  }

  public static fillExtrusionPattern(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-pattern', value);
  }

  public static fillExtrusionTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('fill-extrusion-translate', value);
  }

  /**
   * Configure the reference frame for fillExtrusionTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static fillExtrusionTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-translate-anchor', value);
  }

  public static fillExtrusionVerticalGradient(value: boolean | Expression<boolean>): PaintPropertyValue<boolean> {
    return PropertyFactory.createPaintProperty('fill-extrusion-vertical-gradient', value);
  }

  // ==================== Helper methods ====================

  /**
   * Create a paint property wrapper
   */
  private static createPaintProperty<T>(name: string, value: T | Expression<T>): PaintPropertyValue<T> {
    if (value instanceof Expression) {
      return new PaintPropertyValue<T>(name, null, value);
    } else {
      return new PaintPropertyValue<T>(name, value as T);
    }
  }

  /**
   * Create a layout property wrapper
   */
  private static createLayoutProperty<T>(name: string, value: T | Expression<T>): LayoutPropertyValue<T> {
    if (value instanceof Expression) {
      return new LayoutPropertyValue<T>(name, null, value);
    } else {
      return new LayoutPropertyValue<T>(name, value as T);
    }
  }
}
