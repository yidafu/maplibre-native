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
 * import { Expression, Interpolator, Stop, PropertyFactory } from 'maplibre_harmony';
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

  /**
   * Configure the reference frame for fillTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static fillTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static fillTranslateAnchor(expression: Expression<string>): PaintPropertyValue<string>;

  public static fillTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-translate-anchor', value);
  }

  /**
   * Fill sort key controlling draw order within the same layer
   * Smaller keys are rendered beneath larger ones
   */
  public static fillSortKey(sortKey: number): LayoutPropertyValue<number>;

  public static fillSortKey(expression: Expression<number>): LayoutPropertyValue<number>;

  public static fillSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('fill-sort-key', value);
  }

  // ==================== Line layer properties ====================

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

  /**
   * Line translation in pixels; `[x, y]`, negative values move left/up
   */
  public static lineTranslate(translate: number[]): PaintPropertyValue<number[]>;

  public static lineTranslate(expression: Expression<number[]>): PaintPropertyValue<number[]>;

  public static lineTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('line-translate', value);
  }

  /**
   * Configure the reference frame for lineTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static lineTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static lineTranslateAnchor(expression: Expression<string>): PaintPropertyValue<string>;

  public static lineTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('line-translate-anchor', value);
  }

  /**
   * Line offset in pixels; positive shifts right, negative shifts left
   */
  public static lineOffset(offset: number): PaintPropertyValue<number>;

  public static lineOffset(expression: Expression<number>): PaintPropertyValue<number>;

  public static lineOffset(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('line-offset', value);
  }

  /**
   * Miter limit that converts miter joins to bevel joins automatically
   */
  public static lineMiterLimit(limit: number): LayoutPropertyValue<number>;

  public static lineMiterLimit(expression: Expression<number>): LayoutPropertyValue<number>;

  public static lineMiterLimit(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-miter-limit', value);
  }

  /**
   * Round limit that converts round joins to miter joins automatically
   */
  public static lineRoundLimit(limit: number): LayoutPropertyValue<number>;

  public static lineRoundLimit(expression: Expression<number>): LayoutPropertyValue<number>;

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
  public static lineSortKey(sortKey: number): LayoutPropertyValue<number>;

  public static lineSortKey(expression: Expression<number>): LayoutPropertyValue<number>;

  public static lineSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('line-sort-key', value);
  }

  // ==================== Circle layer properties ====================

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

  /**
   * Circle translation in pixels; `[x, y]`, negative values move left/up
   */
  public static circleTranslate(translate: number[]): PaintPropertyValue<number[]>;

  public static circleTranslate(expression: Expression<number[]>): PaintPropertyValue<number[]>;

  public static circleTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('circle-translate', value);
  }

  /**
   * Configure the reference frame for circleTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static circleTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static circleTranslateAnchor(expression: Expression<string>): PaintPropertyValue<string>;

  public static circleTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-translate-anchor', value);
  }

  /**
   * Control how circles scale relative to the map
   * @param scale 'map' | 'viewport'
   */
  public static circlePitchScale(scale: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static circlePitchScale(expression: Expression<string>): PaintPropertyValue<string>;

  public static circlePitchScale(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-pitch-scale', value);
  }

  /**
   * Control how circles align relative to the map
   * @param alignment 'map' | 'viewport'
   */
  public static circlePitchAlignment(alignment: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static circlePitchAlignment(expression: Expression<string>): PaintPropertyValue<string>;

  public static circlePitchAlignment(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('circle-pitch-alignment', value);
  }

  /**
   * Circle sort key controlling draw order within the same layer
   */
  public static circleSortKey(sortKey: number): LayoutPropertyValue<number>;

  public static circleSortKey(expression: Expression<number>): LayoutPropertyValue<number>;

  public static circleSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('circle-sort-key', value);
  }

  // ==================== Symbol layer properties ====================

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

  /**
   * Allow icon overlap
   */
  public static iconAllowOverlap(allowOverlap: boolean): LayoutPropertyValue<boolean>;

  public static iconAllowOverlap(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static iconAllowOverlap(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-allow-overlap', value);
  }

  /**
   * Ignore icon placement
   */
  public static iconIgnorePlacement(ignorePlacement: boolean): LayoutPropertyValue<boolean>;

  public static iconIgnorePlacement(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static iconIgnorePlacement(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-ignore-placement', value);
  }

  /**
   * Icon optional flag; display text even when the icon is unavailable
   */
  public static iconOptional(optional: boolean): LayoutPropertyValue<boolean>;

  public static iconOptional(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static iconOptional(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-optional', value);
  }

  /**
   * Icon anchor position
   */
  public static iconAnchor(anchor: string): LayoutPropertyValue<string>;

  public static iconAnchor(expression: Expression<string>): LayoutPropertyValue<string>;

  public static iconAnchor(value: string | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-anchor', value);
  }

  /**
   * Icon offset [x, y]
   */
  public static iconOffset(offset: number[]): LayoutPropertyValue<number[]>;

  public static iconOffset(expression: Expression<number[]>): LayoutPropertyValue<number[]>;

  public static iconOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('icon-offset', value);
  }

  /**
   * Icon padding
   */
  public static iconPadding(padding: number): LayoutPropertyValue<number>;

  public static iconPadding(expression: Expression<number>): LayoutPropertyValue<number>;

  public static iconPadding(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('icon-padding', value);
  }

  /**
   * Keep icon upright
   */
  public static iconKeepUpright(keepUpright: boolean): LayoutPropertyValue<boolean>;

  public static iconKeepUpright(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static iconKeepUpright(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('icon-keep-upright', value);
  }

  /**
   * Icon pitch alignment
   */
  public static iconPitchAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;

  public static iconPitchAlignment(expression: Expression<string>): LayoutPropertyValue<string>;

  public static iconPitchAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-pitch-alignment', value);
  }

  /**
   * Icon rotation alignment
   */
  public static iconRotationAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;

  public static iconRotationAlignment(expression: Expression<string>): LayoutPropertyValue<string>;

  public static iconRotationAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-rotation-alignment', value);
  }

  /**
   * Icon text-fit mode
   */
  public static iconTextFit(fit: 'none' | 'width' | 'height' | 'both'): LayoutPropertyValue<string>;

  public static iconTextFit(expression: Expression<string>): LayoutPropertyValue<string>;

  public static iconTextFit(value: 'none' | 'width' | 'height' | 'both' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('icon-text-fit', value);
  }

  /**
   * Icon text-fit padding [top, right, bottom, left]
   */
  public static iconTextFitPadding(padding: number[]): LayoutPropertyValue<number[]>;

  public static iconTextFitPadding(expression: Expression<number[]>): LayoutPropertyValue<number[]>;

  public static iconTextFitPadding(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('icon-text-fit-padding', value);
  }

  /**
   * Icon translate [x, y]
   */
  public static iconTranslate(translate: number[]): PaintPropertyValue<number[]>;

  public static iconTranslate(expression: Expression<number[]>): PaintPropertyValue<number[]>;

  public static iconTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('icon-translate', value);
  }

  /**
   * Configure the reference frame for iconTranslate
   */
  public static iconTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static iconTranslateAnchor(expression: Expression<string>): PaintPropertyValue<string>;

  public static iconTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-translate-anchor', value);
  }

  /**
   * Icon halo width
   */
  public static iconHaloWidth(width: number): PaintPropertyValue<number>;

  public static iconHaloWidth(expression: Expression<number>): PaintPropertyValue<number>;

  public static iconHaloWidth(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-halo-width', value);
  }

  /**
   * Icon halo color
   */
  public static iconHaloColor(color: string): PaintPropertyValue<string>;

  public static iconHaloColor(expression: Expression<string>): PaintPropertyValue<string>;

  public static iconHaloColor(value: string | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('icon-halo-color', value);
  }

  /**
   * Icon halo blur
   */
  public static iconHaloBlur(blur: number): PaintPropertyValue<number>;

  public static iconHaloBlur(expression: Expression<number>): PaintPropertyValue<number>;

  public static iconHaloBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('icon-halo-blur', value);
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

  /**
   * Text maximum width (ems)
   */
  public static textMaxWidth(maxWidth: number): LayoutPropertyValue<number>;

  public static textMaxWidth(expression: Expression<number>): LayoutPropertyValue<number>;

  public static textMaxWidth(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-max-width', value);
  }

  /**
   * Text letter spacing (ems)
   */
  public static textLetterSpacing(letterSpacing: number): LayoutPropertyValue<number>;

  public static textLetterSpacing(expression: Expression<number>): LayoutPropertyValue<number>;

  public static textLetterSpacing(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-letter-spacing', value);
  }

  /**
   * Text justification
   */
  public static textJustify(justify: 'auto' | 'left' | 'center' | 'right'): LayoutPropertyValue<string>;

  public static textJustify(expression: Expression<string>): LayoutPropertyValue<string>;

  public static textJustify(value: 'auto' | 'left' | 'center' | 'right' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-justify', value);
  }

  /**
   * Text radial offset
   */
  public static textRadialOffset(radialOffset: number): LayoutPropertyValue<number>;

  public static textRadialOffset(expression: Expression<number>): LayoutPropertyValue<number>;

  public static textRadialOffset(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-radial-offset', value);
  }

  /**
   * Text variable anchors
   */
  public static textVariableAnchor(variableAnchor: string[]): LayoutPropertyValue<string[]>;

  public static textVariableAnchor(expression: Expression<string[]>): LayoutPropertyValue<string[]>;

  public static textVariableAnchor(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-variable-anchor', value);
  }

  /**
   * Text variable anchor offsets
   */
  public static textVariableAnchorOffset(offset: number[]): LayoutPropertyValue<number[]>;

  public static textVariableAnchorOffset(expression: Expression<number[]>): LayoutPropertyValue<number[]>;

  public static textVariableAnchorOffset(value: number[] | Expression<number[]>): LayoutPropertyValue<number[]> {
    return PropertyFactory.createLayoutProperty('text-variable-anchor-offset', value);
  }

  /**
   * Text rotation angle
   */
  public static textRotate(rotate: number): LayoutPropertyValue<number>;

  public static textRotate(expression: Expression<number>): LayoutPropertyValue<number>;

  public static textRotate(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-rotate', value);
  }

  /**
   * Text padding
   */
  public static textPadding(padding: number): LayoutPropertyValue<number>;

  public static textPadding(expression: Expression<number>): LayoutPropertyValue<number>;

  public static textPadding(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-padding', value);
  }

  /**
   * Keep text upright
   */
  public static textKeepUpright(keepUpright: boolean): LayoutPropertyValue<boolean>;

  public static textKeepUpright(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static textKeepUpright(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-keep-upright', value);
  }

  /**
   * Text transform (case)
   */
  public static textTransform(transform: 'none' | 'uppercase' | 'lowercase'): LayoutPropertyValue<string>;

  public static textTransform(expression: Expression<string>): LayoutPropertyValue<string>;

  public static textTransform(value: 'none' | 'uppercase' | 'lowercase' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-transform', value);
  }

  /**
   * Text maximum angle
   */
  public static textMaxAngle(maxAngle: number): LayoutPropertyValue<number>;

  public static textMaxAngle(expression: Expression<number>): LayoutPropertyValue<number>;

  public static textMaxAngle(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-max-angle', value);
  }

  /**
   * Text rotation alignment
   */
  public static textRotationAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;

  public static textRotationAlignment(expression: Expression<string>): LayoutPropertyValue<string>;

  public static textRotationAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-rotation-alignment', value);
  }

  /**
   * Text pitch alignment
   */
  public static textPitchAlignment(alignment: 'map' | 'viewport' | 'auto'): LayoutPropertyValue<string>;

  public static textPitchAlignment(expression: Expression<string>): LayoutPropertyValue<string>;

  public static textPitchAlignment(value: 'map' | 'viewport' | 'auto' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('text-pitch-alignment', value);
  }

  /**
   * Text line height (ems)
   */
  public static textLineHeight(lineHeight: number): LayoutPropertyValue<number>;

  public static textLineHeight(expression: Expression<number>): LayoutPropertyValue<number>;

  public static textLineHeight(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('text-line-height', value);
  }

  /**
   * Text writing mode
   */
  public static textWritingMode(writingMode: string[]): LayoutPropertyValue<string[]>;

  public static textWritingMode(expression: Expression<string[]>): LayoutPropertyValue<string[]>;

  public static textWritingMode(value: string[] | Expression<string[]>): LayoutPropertyValue<string[]> {
    return PropertyFactory.createLayoutProperty('text-writing-mode', value);
  }

  /**
   * Allow text overlap
   */
  public static textAllowOverlap(allowOverlap: boolean): LayoutPropertyValue<boolean>;

  public static textAllowOverlap(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static textAllowOverlap(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-allow-overlap', value);
  }

  /**
   * Ignore text placement
   */
  public static textIgnorePlacement(ignorePlacement: boolean): LayoutPropertyValue<boolean>;

  public static textIgnorePlacement(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static textIgnorePlacement(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-ignore-placement', value);
  }

  /**
   * Text optional flag; show icons when text is unavailable
   */
  public static textOptional(optional: boolean): LayoutPropertyValue<boolean>;

  public static textOptional(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static textOptional(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('text-optional', value);
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

  /**
   * Text halo blur
   */
  public static textHaloBlur(blur: number): PaintPropertyValue<number>;

  public static textHaloBlur(expression: Expression<number>): PaintPropertyValue<number>;

  public static textHaloBlur(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('text-halo-blur', value);
  }

  /**
   * Text translate [x, y]
   */
  public static textTranslate(translate: number[]): PaintPropertyValue<number[]>;

  public static textTranslate(expression: Expression<number[]>): PaintPropertyValue<number[]>;

  public static textTranslate(value: number[] | Expression<number[]>): PaintPropertyValue<number[]> {
    return PropertyFactory.createPaintProperty('text-translate', value);
  }

  /**
   * Configure the reference frame for textTranslate
   */
  public static textTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static textTranslateAnchor(expression: Expression<string>): PaintPropertyValue<string>;

  public static textTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('text-translate-anchor', value);
  }

  /**
   * Symbol placement mode
   */
  public static symbolPlacement(placement: 'point' | 'line' | 'line-center'): LayoutPropertyValue<string>;

  public static symbolPlacement(expression: Expression<string>): LayoutPropertyValue<string>;

  public static symbolPlacement(value: 'point' | 'line' | 'line-center' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('symbol-placement', value);
  }

  /**
   * Symbol spacing (only applies when symbolPlacement is set to line)
   */
  public static symbolSpacing(spacing: number): LayoutPropertyValue<number>;

  public static symbolSpacing(expression: Expression<number>): LayoutPropertyValue<number>;

  public static symbolSpacing(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('symbol-spacing', value);
  }

  /**
   * Avoid symbol placement near tile edges
   */
  public static symbolAvoidEdges(avoidEdges: boolean): LayoutPropertyValue<boolean>;

  public static symbolAvoidEdges(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static symbolAvoidEdges(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('symbol-avoid-edges', value);
  }

  /**
   * Symbol sort key
   */
  public static symbolSortKey(sortKey: number): LayoutPropertyValue<number>;

  public static symbolSortKey(expression: Expression<number>): LayoutPropertyValue<number>;

  public static symbolSortKey(value: number | Expression<number>): LayoutPropertyValue<number> {
    return PropertyFactory.createLayoutProperty('symbol-sort-key', value);
  }

  /**
   * Symbol Z order (deprecated; prefer symbolSortKey)
   */
  public static symbolZOrder(zOrder: 'auto' | 'viewport-y' | 'source'): LayoutPropertyValue<string>;

  public static symbolZOrder(expression: Expression<string>): LayoutPropertyValue<string>;

  public static symbolZOrder(value: 'auto' | 'viewport-y' | 'source' | Expression<string>): LayoutPropertyValue<string> {
    return PropertyFactory.createLayoutProperty('symbol-z-order', value);
  }

  /**
   * Symbol screen-space flag (deprecated)
   */
  public static symbolScreenSpace(screenSpace: boolean): LayoutPropertyValue<boolean>;

  public static symbolScreenSpace(expression: Expression<boolean>): LayoutPropertyValue<boolean>;

  public static symbolScreenSpace(value: boolean | Expression<boolean>): LayoutPropertyValue<boolean> {
    return PropertyFactory.createLayoutProperty('symbol-screen-space', value);
  }

  // ==================== Raster layer properties ====================

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

  /**
   * Raster fade duration in milliseconds
   */
  public static rasterFadeDuration(fadeDuration: number): PaintPropertyValue<number>;

  public static rasterFadeDuration(expression: Expression<number>): PaintPropertyValue<number>;

  public static rasterFadeDuration(value: number | Expression<number>): PaintPropertyValue<number> {
    return PropertyFactory.createPaintProperty('raster-fade-duration', value);
  }

  /**
   * Raster resampling mode
   */
  public static rasterResampling(resampling: 'linear' | 'nearest'): PaintPropertyValue<string>;

  public static rasterResampling(expression: Expression<string>): PaintPropertyValue<string>;

  public static rasterResampling(value: 'linear' | 'nearest' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('raster-resampling', value);
  }

  // ==================== Background layer properties ====================

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

  // ==================== Heatmap layer properties ====================

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

  /**
   * Define the heatmap color ramp (Expression only)
   * Must use the `heatmap-density` expression
   */
  public static heatmapColor(expression: Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('heatmap-color', expression);
  }

  // ==================== Hillshade layer properties ====================

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

  // ==================== FillExtrusion layer properties ====================

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

  /**
   * Configure the reference frame for fillExtrusionTranslate
   * @param anchor 'map' | 'viewport'
   */
  public static fillExtrusionTranslateAnchor(anchor: 'map' | 'viewport'): PaintPropertyValue<string>;

  public static fillExtrusionTranslateAnchor(expression: Expression<string>): PaintPropertyValue<string>;

  public static fillExtrusionTranslateAnchor(value: 'map' | 'viewport' | Expression<string>): PaintPropertyValue<string> {
    return PropertyFactory.createPaintProperty('fill-extrusion-translate-anchor', value);
  }

  public static fillExtrusionVerticalGradient(verticalGradient: boolean): PaintPropertyValue<boolean>;

  public static fillExtrusionVerticalGradient(expression: Expression<boolean>): PaintPropertyValue<boolean>;

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
