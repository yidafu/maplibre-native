/**
 * MapLibre Native for HarmonyOS - SymbolLayer type definitions.
 * Symbol layer API (NAPI class).
 */

import type { PropertyValue } from '../LayerPropertyTypes';
import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';

/**
 * SymbolLayer - renders icons and text labels.
 */
export class SymbolLayer {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Create a symbol layer.
   * @param layerId Layer identifier.
   * @param sourceId Source identifier.
   */
  constructor(layerId: string, sourceId: string);

// ==================== Basic methods ====================

  /**
   * Get the layer identifier.
   */
  getId(): string;

  /**
   * Get the layer type.
   */
  getType(): string;

  /**
   * Get the source identifier.
   */
  getSourceId(): string;

  /**
   * Set the source layer.
   * @param sourceLayer Source layer name.
   * @returns this (chainable).
   */
  setSourceLayer(sourceLayer: string): SymbolLayer;

  /**
   * Get the source layer.
   */
  getSourceLayer(): string;

  /**
   * Set the minimum zoom level.
   * @param minZoom Minimum zoom.
   * @returns this (chainable).
   */
  setMinZoom(minZoom: number): SymbolLayer;

  /**
   * Get the minimum zoom level.
   */
  getMinZoom(): number;

  /**
   * Set the maximum zoom level.
   * @param maxZoom Maximum zoom.
   * @returns this (chainable).
   */
  setMaxZoom(maxZoom: number): SymbolLayer;

  /**
   * Get the maximum zoom level.
   */
  getMaxZoom(): number;

// ==================== Icon layout properties ====================

  /**
   * Set the icon image.
   * @param iconImage Image name or expression.
   * @returns this (chainable).
   */
  setIconImage(iconImage: PropertyValue<string>): SymbolLayer;

  /**
   * Get the icon image.
   */
  getIconImage(): string;

  /**
   * Set the icon size.
   * @param size Size factor or expression.
   * @returns this (chainable).
   */
  setIconSize(size: PropertyValue<number>): SymbolLayer;

  /**
   * Get the icon size.
   */
  getIconSize(): number;

  /**
   * Set the icon rotation.
   * @param rotate Rotation in degrees or expression.
   * @returns this (chainable).
   */
  setIconRotate(rotate: PropertyValue<number>): SymbolLayer;

  /**
   * Get the icon rotation.
   */
  getIconRotate(): number;

  /**
   * Set the icon offset.
   * @param offset Offset vector or expression.
   * @returns this (chainable).
   */
  setIconOffset(offset: PropertyValue<number[]>): SymbolLayer;

  /**
   * Get the icon offset.
   */
  getIconOffset(): number[];

  /**
   * Set the icon anchor.
   * @param anchor Anchor position or expression.
   * @returns this (chainable).
   */
  setIconAnchor(anchor: PropertyValue<string>): SymbolLayer;

  /**
   * Get the icon anchor.
   */
  getIconAnchor(): string;

  /**
   * Set whether icons may overlap.
   * @param allow Allow flag or expression.
   * @returns this (chainable).
   */
  setIconAllowOverlap(allow: PropertyValue<boolean>): SymbolLayer;

  /**
   * Get whether icons may overlap.
   */
  getIconAllowOverlap(): boolean;

// ==================== Text layout properties ====================

  /**
   * Set the text field.
   * @param text Text content or expression.
   * @returns this (chainable).
   */
  setTextField(text: PropertyValue<string>): SymbolLayer;

  /**
   * Get the text field.
   */
  getTextField(): string;

  /**
   * Set the text font list.
   * @param font Font names or expression.
   * @returns this (chainable).
   */
  setTextFont(font: PropertyValue<string[]>): SymbolLayer;

  /**
   * Get the text fonts.
   */
  getTextFont(): string[];

  /**
   * Set the text size.
   * @param size Size value or expression.
   * @returns this (chainable).
   */
  setTextSize(size: PropertyValue<number>): SymbolLayer;

  /**
   * Get the text size.
   */
  getTextSize(): number;

  /**
   * Set the text max width.
   * @param maxWidth Width value or expression.
   * @returns this (chainable).
   */
  setTextMaxWidth(maxWidth: PropertyValue<number>): SymbolLayer;

  /**
   * Get the text max width.
   */
  getTextMaxWidth(): number;

  /**
   * Set the text offset.
   * @param offset Offset vector or expression.
   * @returns this (chainable).
   */
  setTextOffset(offset: PropertyValue<number[]>): SymbolLayer;

  /**
   * Get the text offset.
   */
  getTextOffset(): number[];

  /**
   * Set the text anchor.
   * @param anchor Anchor position or expression.
   * @returns this (chainable).
   */
  setTextAnchor(anchor: PropertyValue<string>): SymbolLayer;

  /**
   * Get the text anchor.
   */
  getTextAnchor(): string;

  /**
   * Set whether text may overlap.
   * @param allow Allow flag or expression.
   * @returns this (chainable).
   */
  setTextAllowOverlap(allow: PropertyValue<boolean>): SymbolLayer;

  /**
   * Get whether text may overlap.
   */
  getTextAllowOverlap(): boolean;

// ==================== Icon paint properties ====================

  /**
   * Set icon opacity.
   * @param opacity Opacity (0-1) or expression.
   * @returns this (chainable).
   */
  setIconOpacity(opacity: PropertyValue<number>): SymbolLayer;

  /**
   * Get icon opacity.
   */
  getIconOpacity(): number;

  /**
   * Set icon color.
   * @param color Color value or expression.
   * @returns this (chainable).
   */
  setIconColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * Get icon color.
   */
  getIconColor(): string;

  /**
   * Set icon halo color.
   * @param color Color value or expression.
   * @returns this (chainable).
   */
  setIconHaloColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * Get icon halo color.
   */
  getIconHaloColor(): string;

  /**
   * Set icon halo width.
   * @param width Width value or expression.
   * @returns this (chainable).
   */
  setIconHaloWidth(width: PropertyValue<number>): SymbolLayer;

  /**
   * Get icon halo width.
   */
  getIconHaloWidth(): number;

// ==================== Text paint properties ====================

  /**
   * Set text opacity.
   * @param opacity Opacity (0-1) or expression.
   * @returns this (chainable).
   */
  setTextOpacity(opacity: PropertyValue<number>): SymbolLayer;

  /**
   * Get text opacity.
   */
  getTextOpacity(): number;

  /**
   * Set text color.
   * @param color Color value or expression.
   * @returns this (chainable).
   */
  setTextColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * Get text color.
   */
  getTextColor(): string;

  /**
   * Set text halo color.
   * @param color Color value or expression.
   * @returns this (chainable).
   */
  setTextHaloColor(color: PropertyValue<string>): SymbolLayer;

  /**
   * Get text halo color.
   */
  getTextHaloColor(): string;

  /**
   * Set text halo width.
   * @param width Width value or expression.
   * @returns this (chainable).
   */
  setTextHaloWidth(width: PropertyValue<number>): SymbolLayer;

  /**
   * Get text halo width.
   */
  getTextHaloWidth(): number;

// ==================== Additional icon layout properties ====================

  /**
   * Enable icon ignore placement.
   * @returns this (chainable).
   */
  setIconIgnorePlacement(ignore: boolean): SymbolLayer;

  getIconIgnorePlacement(): boolean;

  /**
   * Enable optional icons.
   * @returns this (chainable).
   */
  setIconOptional(optional: boolean): SymbolLayer;

  getIconOptional(): boolean;

  /**
   * Set icon padding.
   * @returns this (chainable).
   */
  setIconPadding(padding: number): SymbolLayer;

  getIconPadding(): number;

  /**
   * Set whether icons keep upright.
   * @returns this (chainable).
   */
  setIconKeepUpright(keep: boolean): SymbolLayer;

  getIconKeepUpright(): boolean;

  /**
   * Set icon pitch alignment.
   * @returns this (chainable).
   */
  setIconPitchAlignment(alignment: string): SymbolLayer;

  getIconPitchAlignment(): string;

  /**
   * Set icon rotation alignment.
   * @returns this (chainable).
   */
  setIconRotationAlignment(alignment: string): SymbolLayer;

  getIconRotationAlignment(): string;

  /**
   * Set icon-text fit mode.
   * @returns this (chainable).
   */
  setIconTextFit(fit: string): SymbolLayer;

  getIconTextFit(): string;

  /**
   * Set icon-text fit padding.
   * @returns this (chainable).
   */
  setIconTextFitPadding(padding: number[]): SymbolLayer;

  getIconTextFitPadding(): number[];

  /**
   * Set icon translation.
   * @param translate Translation vector or expression.
   * @returns this (chainable).
   */
  setIconTranslate(translate: PropertyValue<number[]>): SymbolLayer;

  getIconTranslate(): number[];

  /**
   * Set icon translation anchor.
   * @returns this (chainable).
   */
  setIconTranslateAnchor(anchor: string): SymbolLayer;

  getIconTranslateAnchor(): string;

  /**
   * Set icon halo blur.
   * @param blur Blur radius or expression (pixels).
   * @returns this (chainable).
   */
  setIconHaloBlur(blur: PropertyValue<number>): SymbolLayer;

  getIconHaloBlur(): number;

// ==================== Additional text layout properties ====================

  /**
   * Set text letter spacing.
   * @param spacing Spacing value or expression.
   * @returns this (chainable).
   */
  setTextLetterSpacing(spacing: PropertyValue<number>): SymbolLayer;

  getTextLetterSpacing(): number;

  /**
   * Set text justification.
   * @param justify Alignment or expression ('auto' | 'left' | 'center' | 'right').
   * @returns this (chainable).
   */
  setTextJustify(justify: PropertyValue<string>): SymbolLayer;

  getTextJustify(): string;

  /**
   * Set text radial offset.
   * @returns this (chainable).
   */
  setTextRadialOffset(offset: number): SymbolLayer;

  getTextRadialOffset(): number;

  /**
   * Set text variable anchors.
   * @returns this (chainable).
   */
  setTextVariableAnchor(anchors: string[]): SymbolLayer;

  getTextVariableAnchor(): string[];

  /**
   * Set text variable anchor offsets.
   * @returns this (chainable).
   */
  setTextVariableAnchorOffset(offset: number[]): SymbolLayer;

  getTextVariableAnchorOffset(): number[];

  /**
   * Set text rotation.
   * @param rotate Rotation angle or expression (degrees).
   * @returns this (chainable).
   */
  setTextRotate(rotate: PropertyValue<number>): SymbolLayer;

  getTextRotate(): number;

  /**
   * Set text padding.
   * @returns this (chainable).
   */
  setTextPadding(padding: number): SymbolLayer;

  getTextPadding(): number;

  /**
   * Set whether text keeps upright.
   * @returns this (chainable).
   */
  setTextKeepUpright(keep: boolean): SymbolLayer;

  getTextKeepUpright(): boolean;

  /**
   * Set text transform.
   * @param transform Transform type or expression ('none' | 'uppercase' | 'lowercase').
   * @returns this (chainable).
   */
  setTextTransform(transform: PropertyValue<string>): SymbolLayer;

  getTextTransform(): string;

  /**
   * Set text maximum angle.
   * @returns this (chainable).
   */
  setTextMaxAngle(angle: PropertyValue<number>): SymbolLayer;

  getTextMaxAngle(): number;

  /**
   * Set text rotation alignment.
   * @returns this (chainable).
   */
  setTextRotationAlignment(alignment: string): SymbolLayer;

  getTextRotationAlignment(): string;

  /**
   * Set text pitch alignment.
   * @returns this (chainable).
   */
  setTextPitchAlignment(alignment: string): SymbolLayer;

  getTextPitchAlignment(): string;

  /**
   * Set text line height.
   * @param lineHeight Line height value or expression (em units).
   * @returns this (chainable).
   */
  setTextLineHeight(lineHeight: PropertyValue<number>): SymbolLayer;

  getTextLineHeight(): number;

  /**
   * Set text writing mode.
   * @returns this (chainable).
   */
  setTextWritingMode(mode: string[]): SymbolLayer;

  getTextWritingMode(): string[];

  /**
   * Enable text ignore placement.
   * @returns this (chainable).
   */
  setTextIgnorePlacement(ignore: boolean): SymbolLayer;

  getTextIgnorePlacement(): boolean;

  /**
   * Enable optional text.
   * @returns this (chainable).
   */
  setTextOptional(optional: boolean): SymbolLayer;

  getTextOptional(): boolean;

// ==================== Additional text paint properties ====================

  /**
   * Set text halo blur.
   * @param blur Blur radius or expression (pixels).
   * @returns this (chainable).
   */
  setTextHaloBlur(blur: PropertyValue<number>): SymbolLayer;

  getTextHaloBlur(): number;

  /**
   * Set text translation.
   * @param translate Translation vector or expression ([x, y] pixels).
   * @returns this (chainable).
   */
  setTextTranslate(translate: PropertyValue<number[]>): SymbolLayer;

  getTextTranslate(): number[];

  /**
   * Set text translation anchor.
   * @returns this (chainable).
   */
  setTextTranslateAnchor(anchor: string): SymbolLayer;

  getTextTranslateAnchor(): string;

// ==================== Symbol general properties ====================

  /**
   * Set symbol placement.
   * @param placement Placement mode or expression ('point' | 'line' | 'line-center').
   * @returns this (chainable).
   */
  setSymbolPlacement(placement: PropertyValue<string>): SymbolLayer;

  getSymbolPlacement(): string;

  /**
   * Set symbol spacing.
   * @param spacing Spacing value or expression (pixels).
   * @returns this (chainable).
   */
  setSymbolSpacing(spacing: PropertyValue<number>): SymbolLayer;

  getSymbolSpacing(): number;

  /**
   * Set whether symbols avoid edges.
   * @param avoid Boolean flag or expression.
   * @returns this (chainable).
   */
  setSymbolAvoidEdges(avoid: PropertyValue<boolean>): SymbolLayer;

  getSymbolAvoidEdges(): boolean;

  /**
   * Set symbol sort key.
   * @returns this (chainable).
   */
  setSymbolSortKey(sortKey: PropertyValue<number>): SymbolLayer;

  getSymbolSortKey(): number;

  /**
   * Set symbol Z-order.
   * @returns this (chainable).
   */
  setSymbolZOrder(zOrder: string): SymbolLayer;

  getSymbolZOrder(): string;

// ==================== Common layer methods ====================

  /**
   * Set layer visibility.
   * @returns this (chainable).
   */
  setVisibility(visibility: 'visible' | 'none'): SymbolLayer;

  getVisibility(): 'visible' | 'none';

  /**
   * Set the layer filter.
   * @param filter Filter expression literal (JSON array form).
   * @returns this (chainable).
   */
  setFilter(filter: ExpressionLiteral): SymbolLayer;

  /**
   * Get the layer filter.
   * @returns Filter expression literal or null.
   */
  getFilter(): ExpressionLiteral | null;

  /**
   * Set a single property (generic helper).
   * @param propertyName Property name (e.g. 'icon-image', 'text-field', 'text-color').
   * @param value Property value (literal or expression).
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): this;

  /**
   * Set multiple properties (generic helper).
   * @param properties Object whose keys are property names and values are property payloads.
   * @example
   * layer.setProperties({
   *   'icon-image': 'marker',
   *   'icon-size': 1.5,
   *   'text-field': ['get', 'name'],
   *   'text-color': '#000000'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): this;
}
