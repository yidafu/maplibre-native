/**
 * SymbolLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';

import type { PropertyValue } from '../expressions/index';

import { convertValue } from './LayerUtils';
import { LayerInternalTag, SourcedLayer, resolveLayerNative } from './BaseLayer';

/**
 * Apply an optional layer property through its setter when the value is present.
 *
 * Module-level generic helper replacing the repeated
 * `if (props.x !== undefined) { this.setX(props.x) }` boilerplate inside
 * withTextProperties()/withIconProperties(): each property becomes one call
 * pairing the value with its setter closure. The undefined check lives here so
 * the setter closure receives the narrowed, non-undefined value.
 */
function applyIfDefined<T>(value: T | undefined, setter: (v: T) => void): void {
  if (value !== undefined) {
    setter(value);
  }
}

export class SymbolLayer extends SourcedLayer<maplibre.SymbolLayer, SymbolLayer> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'SymbolLayer';

  constructor(idOrMarker: string | LayerInternalTag, sourceId: string = "", nativeOrNothing?: maplibre.SymbolLayer) {
    super(resolveLayerNative(idOrMarker, sourceId, nativeOrNothing, (id, sid) => new maplibre.SymbolLayer(id, sid), "SymbolLayer"));
  }

  static create(id: string, sourceId: string = ""): SymbolLayer {
    return new SymbolLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.SymbolLayer): SymbolLayer {
    return new SymbolLayer(LayerInternalTag.INSTANCE, "", nativeInstance);
  }

  setSymbolPlacement(placement: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setSymbolPlacement(convertValue(placement));
    return this;
  }

  getSymbolPlacement(): string {
    return this.nativeInstance.getSymbolPlacement();
  }

  setSymbolSpacing(spacing: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setSymbolSpacing(convertValue(spacing));
    return this;
  }

  getSymbolSpacing(): number {
    return this.nativeInstance.getSymbolSpacing();
  }

  setSymbolAvoidEdges(avoid: PropertyValue<boolean>): SymbolLayer {
    this.nativeInstance.setSymbolAvoidEdges(convertValue(avoid));
    return this;
  }

  getSymbolAvoidEdges(): boolean {
    return this.nativeInstance.getSymbolAvoidEdges();
  }

  setSymbolSortKey(sortKey: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setSymbolSortKey(convertValue(sortKey));
    return this;
  }

  getSymbolSortKey(): number {
    return this.nativeInstance.getSymbolSortKey();
  }

  setSymbolZOrder(zOrder: string): SymbolLayer {
    this.nativeInstance.setSymbolZOrder(zOrder);
    return this;
  }

  getSymbolZOrder(): string {
    return this.nativeInstance.getSymbolZOrder();
  }

  // ========== Symbol icon property helpers ==========

  setIconImage(iconImage: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setIconImage(convertValue(iconImage));
    return this;
  }

  setIconSize(size: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setIconSize(convertValue(size));
    return this;
  }

  setIconRotate(rotate: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setIconRotate(convertValue(rotate));
    return this;
  }

  setIconOffset(offset: PropertyValue<number[]>): SymbolLayer {
    this.nativeInstance.setIconOffset(convertValue(offset));
    return this;
  }

  setIconAnchor(anchor: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setIconAnchor(convertValue(anchor));
    return this;
  }

  setIconAllowOverlap(allow: PropertyValue<boolean>): SymbolLayer {
    this.nativeInstance.setIconAllowOverlap(convertValue(allow));
    return this;
  }

  getIconAllowOverlap(): boolean {
    return this.nativeInstance.getIconAllowOverlap();
  }

  setIconIgnorePlacement(ignore: boolean): SymbolLayer {
    this.nativeInstance.setIconIgnorePlacement(ignore);
    return this;
  }

  getIconIgnorePlacement(): boolean {
    return this.nativeInstance.getIconIgnorePlacement();
  }

  setIconOptional(optional: boolean): SymbolLayer {
    this.nativeInstance.setIconOptional(optional);
    return this;
  }

  getIconOptional(): boolean {
    return this.nativeInstance.getIconOptional();
  }

  setIconPadding(padding: number): SymbolLayer {
    this.nativeInstance.setIconPadding(padding);
    return this;
  }

  getIconPadding(): number {
    return this.nativeInstance.getIconPadding();
  }

  setIconKeepUpright(keep: boolean): SymbolLayer {
    this.nativeInstance.setIconKeepUpright(keep);
    return this;
  }

  getIconKeepUpright(): boolean {
    return this.nativeInstance.getIconKeepUpright();
  }

  setIconPitchAlignment(alignment: string): SymbolLayer {
    this.nativeInstance.setIconPitchAlignment(alignment);
    return this;
  }

  getIconPitchAlignment(): string {
    return this.nativeInstance.getIconPitchAlignment();
  }

  setIconRotationAlignment(alignment: string): SymbolLayer {
    this.nativeInstance.setIconRotationAlignment(alignment);
    return this;
  }

  getIconRotationAlignment(): string {
    return this.nativeInstance.getIconRotationAlignment();
  }

  setIconTextFit(fit: string): SymbolLayer {
    this.nativeInstance.setIconTextFit(fit);
    return this;
  }

  getIconTextFit(): string {
    return this.nativeInstance.getIconTextFit();
  }

  setIconTextFitPadding(padding: number[]): SymbolLayer {
    this.nativeInstance.setIconTextFitPadding(padding);
    return this;
  }

  getIconTextFitPadding(): number[] {
    return this.nativeInstance.getIconTextFitPadding();
  }

  setIconOpacity(opacity: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setIconOpacity(convertValue(opacity));
    return this;
  }

  setIconColor(color: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setIconColor(convertValue(color));
    return this;
  }

  setIconHaloColor(color: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setIconHaloColor(convertValue(color));
    return this;
  }

  setIconHaloWidth(width: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setIconHaloWidth(convertValue(width));
    return this;
  }

  setIconHaloBlur(blur: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setIconHaloBlur(convertValue(blur));
    return this;
  }

  setIconTranslate(translate: PropertyValue<number[]>): SymbolLayer {
    this.nativeInstance.setIconTranslate(convertValue(translate));
    return this;
  }

  getIconTranslate(): number[] {
    return this.nativeInstance.getIconTranslate();
  }

  setIconTranslateAnchor(anchor: string): SymbolLayer {
    this.nativeInstance.setIconTranslateAnchor(anchor);
    return this;
  }

  getIconTranslateAnchor(): string {
    return this.nativeInstance.getIconTranslateAnchor();
  }

  // ========== Symbol text property helpers ==========

  setTextField(text: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextField(convertValue(text));
    return this;
  }

  setTextFont(font: PropertyValue<string[]>): SymbolLayer {
    this.nativeInstance.setTextFont(convertValue(font));
    return this;
  }

  setTextSize(size: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextSize(convertValue(size));
    return this;
  }

  setTextMaxWidth(maxWidth: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextMaxWidth(convertValue(maxWidth));
    return this;
  }

  setTextOffset(offset: PropertyValue<number[]>): SymbolLayer {
    this.nativeInstance.setTextOffset(convertValue(offset));
    return this;
  }

  setTextAnchor(anchor: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextAnchor(convertValue(anchor));
    return this;
  }

  setTextAllowOverlap(allow: PropertyValue<boolean>): SymbolLayer {
    this.nativeInstance.setTextAllowOverlap(convertValue(allow));
    return this;
  }

  getTextAllowOverlap(): boolean {
    return this.nativeInstance.getTextAllowOverlap();
  }

  setTextIgnorePlacement(ignore: boolean): SymbolLayer {
    this.nativeInstance.setTextIgnorePlacement(ignore);
    return this;
  }

  getTextIgnorePlacement(): boolean {
    return this.nativeInstance.getTextIgnorePlacement();
  }

  setTextOptional(optional: boolean): SymbolLayer {
    this.nativeInstance.setTextOptional(optional);
    return this;
  }

  getTextOptional(): boolean {
    return this.nativeInstance.getTextOptional();
  }

  setTextPadding(padding: number): SymbolLayer {
    this.nativeInstance.setTextPadding(padding);
    return this;
  }

  getTextPadding(): number {
    return this.nativeInstance.getTextPadding();
  }

  setTextKeepUpright(keep: boolean): SymbolLayer {
    this.nativeInstance.setTextKeepUpright(keep);
    return this;
  }

  getTextKeepUpright(): boolean {
    return this.nativeInstance.getTextKeepUpright();
  }

  setTextOpacity(opacity: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextOpacity(convertValue(opacity));
    return this;
  }

  setTextColor(color: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextColor(convertValue(color));
    return this;
  }

  setTextHaloColor(color: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextHaloColor(convertValue(color));
    return this;
  }

  setTextHaloWidth(width: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextHaloWidth(convertValue(width));
    return this;
  }

  setTextHaloBlur(blur: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextHaloBlur(convertValue(blur));
    return this;
  }

  setTextTranslate(translate: PropertyValue<number[]>): SymbolLayer {
    this.nativeInstance.setTextTranslate(convertValue(translate));
    return this;
  }

  getTextTranslate(): number[] {
    return this.nativeInstance.getTextTranslate();
  }

  setTextTranslateAnchor(anchor: string): SymbolLayer {
    this.nativeInstance.setTextTranslateAnchor(anchor);
    return this;
  }

  getTextTranslateAnchor(): string {
    return this.nativeInstance.getTextTranslateAnchor();
  }

  setTextLineHeight(height: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextLineHeight(convertValue(height));
    return this;
  }

  getTextLineHeight(): number {
    return this.nativeInstance.getTextLineHeight();
  }

  setTextLetterSpacing(spacing: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextLetterSpacing(convertValue(spacing));
    return this;
  }

  getTextLetterSpacing(): number {
    return this.nativeInstance.getTextLetterSpacing();
  }

  setTextJustify(justify: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextJustify(convertValue(justify));
    return this;
  }

  getTextJustify(): string {
    return this.nativeInstance.getTextJustify();
  }

  setTextRotate(angle: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextRotate(convertValue(angle));
    return this;
  }

  getTextRotate(): number {
    return this.nativeInstance.getTextRotate();
  }

  setTextTransform(transform: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextTransform(convertValue(transform));
    return this;
  }

  getTextTransform(): string {
    return this.nativeInstance.getTextTransform();
  }

  setTextMaxAngle(angle: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextMaxAngle(convertValue(angle));
    return this;
  }

  getTextMaxAngle(): number {
    return this.nativeInstance.getTextMaxAngle();
  }

  setTextRadialOffset(offset: number): SymbolLayer {
    this.nativeInstance.setTextRadialOffset(offset);
    return this;
  }

  getTextRadialOffset(): number {
    return this.nativeInstance.getTextRadialOffset();
  }

  setTextPitchAlignment(alignment: string): SymbolLayer {
    this.nativeInstance.setTextPitchAlignment(alignment);
    return this;
  }

  getTextPitchAlignment(): string {
    return this.nativeInstance.getTextPitchAlignment();
  }

  setTextRotationAlignment(alignment: string): SymbolLayer {
    this.nativeInstance.setTextRotationAlignment(alignment);
    return this;
  }

  getTextRotationAlignment(): string {
    return this.nativeInstance.getTextRotationAlignment();
  }

  setTextVariableAnchor(anchors: string[]): SymbolLayer {
    this.nativeInstance.setTextVariableAnchor(anchors);
    return this;
  }

  getTextVariableAnchor(): string[] {
    return this.nativeInstance.getTextVariableAnchor();
  }

  setTextVariableAnchorOffset(offset: number[]): SymbolLayer {
    this.nativeInstance.setTextVariableAnchorOffset(offset);
    return this;
  }

  getTextVariableAnchorOffset(): number[] {
    return this.nativeInstance.getTextVariableAnchorOffset();
  }

  setTextWritingMode(modes: string[]): SymbolLayer {
    this.nativeInstance.setTextWritingMode(modes);
    return this;
  }

  getTextWritingMode(): string[] {
    return this.nativeInstance.getTextWritingMode();
  }

  // ========== Getter helpers ==========

  getIconImage(): string {
    return this.nativeInstance.getIconImage();
  }

  getIconSize(): number {
    return this.nativeInstance.getIconSize();
  }

  getIconRotate(): number {
    return this.nativeInstance.getIconRotate();
  }

  getIconOffset(): number[] {
    return this.nativeInstance.getIconOffset();
  }

  getIconAnchor(): string {
    return this.nativeInstance.getIconAnchor();
  }

  getIconOpacity(): number {
    return this.nativeInstance.getIconOpacity();
  }

  getIconColor(): string {
    return this.nativeInstance.getIconColor();
  }

  getIconHaloColor(): string {
    return this.nativeInstance.getIconHaloColor();
  }

  getIconHaloWidth(): number {
    return this.nativeInstance.getIconHaloWidth();
  }

  getIconHaloBlur(): number {
    return this.nativeInstance.getIconHaloBlur();
  }

  getTextField(): string {
    return this.nativeInstance.getTextField();
  }

  getTextFont(): string[] {
    return this.nativeInstance.getTextFont();
  }

  getTextSize(): number {
    return this.nativeInstance.getTextSize();
  }

  getTextMaxWidth(): number {
    return this.nativeInstance.getTextMaxWidth();
  }

  getTextOffset(): number[] {
    return this.nativeInstance.getTextOffset();
  }

  getTextAnchor(): string {
    return this.nativeInstance.getTextAnchor();
  }

  getTextOpacity(): number {
    return this.nativeInstance.getTextOpacity();
  }

  getTextColor(): string {
    return this.nativeInstance.getTextColor();
  }

  getTextHaloColor(): string {
    return this.nativeInstance.getTextHaloColor();
  }

  getTextHaloWidth(): number {
    return this.nativeInstance.getTextHaloWidth();
  }

  getTextHaloBlur(): number {
    return this.nativeInstance.getTextHaloBlur();
  }

  // ========== Batch property helpers (Android withProperties parity) ==========

  /**
   * Set text properties in batch
   * @param props Text property configuration
   * @returns this (supports chaining)
   * @example
   * ```typescript
   * layer.withTextProperties({
   *   textField: ['get', 'title'],
   *   textSize: 14,
   *   textColor: '#000000',
   *   textAllowOverlap: true
   * });
   * ```
   */
  withTextProperties(props: TextProperties): SymbolLayer {
    applyIfDefined(props.textField, (v: PropertyValue<string>) => this.setTextField(v));
    applyIfDefined(props.textFont, (v: PropertyValue<string[]>) => this.setTextFont(v));
    applyIfDefined(props.textSize, (v: PropertyValue<number>) => this.setTextSize(v));
    applyIfDefined(props.textMaxWidth, (v: PropertyValue<number>) => this.setTextMaxWidth(v));
    applyIfDefined(props.textOffset, (v: PropertyValue<number[]>) => this.setTextOffset(v));
    applyIfDefined(props.textAnchor, (v: PropertyValue<string>) => this.setTextAnchor(v));
    applyIfDefined(props.textAllowOverlap, (v: PropertyValue<boolean>) => this.setTextAllowOverlap(v));
    applyIfDefined(props.textIgnorePlacement, (v: boolean) => this.setTextIgnorePlacement(v));
    applyIfDefined(props.textOptional, (v: boolean) => this.setTextOptional(v));
    applyIfDefined(props.textPadding, (v: number) => this.setTextPadding(v));
    applyIfDefined(props.textKeepUpright, (v: boolean) => this.setTextKeepUpright(v));
    applyIfDefined(props.textOpacity, (v: PropertyValue<number>) => this.setTextOpacity(v));
    applyIfDefined(props.textColor, (v: PropertyValue<string>) => this.setTextColor(v));
    applyIfDefined(props.textHaloColor, (v: PropertyValue<string>) => this.setTextHaloColor(v));
    applyIfDefined(props.textHaloWidth, (v: PropertyValue<number>) => this.setTextHaloWidth(v));
    applyIfDefined(props.textHaloBlur, (v: PropertyValue<number>) => this.setTextHaloBlur(v));
    applyIfDefined(props.textTranslate, (v: PropertyValue<number[]>) => this.setTextTranslate(v));
    applyIfDefined(props.textTranslateAnchor, (v: string) => this.setTextTranslateAnchor(v));
    applyIfDefined(props.textLineHeight, (v: PropertyValue<number>) => this.setTextLineHeight(v));
    applyIfDefined(props.textLetterSpacing, (v: PropertyValue<number>) => this.setTextLetterSpacing(v));
    applyIfDefined(props.textJustify, (v: PropertyValue<string>) => this.setTextJustify(v));
    applyIfDefined(props.textRotate, (v: PropertyValue<number>) => this.setTextRotate(v));
    applyIfDefined(props.textTransform, (v: PropertyValue<string>) => this.setTextTransform(v));
    applyIfDefined(props.textMaxAngle, (v: PropertyValue<number>) => this.setTextMaxAngle(v));
    applyIfDefined(props.textRadialOffset, (v: number) => this.setTextRadialOffset(v));
    applyIfDefined(props.textPitchAlignment, (v: string) => this.setTextPitchAlignment(v));
    applyIfDefined(props.textRotationAlignment, (v: string) => this.setTextRotationAlignment(v));
    applyIfDefined(props.textVariableAnchor, (v: string[]) => this.setTextVariableAnchor(v));
    applyIfDefined(props.textVariableAnchorOffset, (v: number[]) => this.setTextVariableAnchorOffset(v));
    applyIfDefined(props.textWritingMode, (v: string[]) => this.setTextWritingMode(v));
    return this;
  }

  /**
   * Set icon properties in batch
   * @param props Icon property configuration
   * @returns this (supports chaining)
   * @example
   * ```typescript
   * layer.withIconProperties({
   *   iconImage: ['get', 'icon'],
   *   iconSize: 1.0,
   *   iconAnchor: 'bottom',
   *   iconAllowOverlap: true
   * });
   * ```
   */
  withIconProperties(props: IconProperties): SymbolLayer {
    applyIfDefined(props.iconImage, (v: PropertyValue<string>) => this.setIconImage(v));
    applyIfDefined(props.iconSize, (v: PropertyValue<number>) => this.setIconSize(v));
    applyIfDefined(props.iconRotate, (v: PropertyValue<number>) => this.setIconRotate(v));
    applyIfDefined(props.iconOffset, (v: PropertyValue<number[]>) => this.setIconOffset(v));
    applyIfDefined(props.iconAnchor, (v: PropertyValue<string>) => this.setIconAnchor(v));
    applyIfDefined(props.iconAllowOverlap, (v: PropertyValue<boolean>) => this.setIconAllowOverlap(v));
    applyIfDefined(props.iconIgnorePlacement, (v: boolean) => this.setIconIgnorePlacement(v));
    applyIfDefined(props.iconOptional, (v: boolean) => this.setIconOptional(v));
    applyIfDefined(props.iconPadding, (v: number) => this.setIconPadding(v));
    applyIfDefined(props.iconKeepUpright, (v: boolean) => this.setIconKeepUpright(v));
    applyIfDefined(props.iconOpacity, (v: PropertyValue<number>) => this.setIconOpacity(v));
    applyIfDefined(props.iconColor, (v: PropertyValue<string>) => this.setIconColor(v));
    applyIfDefined(props.iconHaloColor, (v: PropertyValue<string>) => this.setIconHaloColor(v));
    applyIfDefined(props.iconHaloWidth, (v: PropertyValue<number>) => this.setIconHaloWidth(v));
    applyIfDefined(props.iconHaloBlur, (v: PropertyValue<number>) => this.setIconHaloBlur(v));
    applyIfDefined(props.iconPitchAlignment, (v: string) => this.setIconPitchAlignment(v));
    applyIfDefined(props.iconRotationAlignment, (v: string) => this.setIconRotationAlignment(v));
    applyIfDefined(props.iconTextFit, (v: string) => this.setIconTextFit(v));
    applyIfDefined(props.iconTextFitPadding, (v: number[]) => this.setIconTextFitPadding(v));
    applyIfDefined(props.iconTranslate, (v: PropertyValue<number[]>) => this.setIconTranslate(v));
    applyIfDefined(props.iconTranslateAnchor, (v: string) => this.setIconTranslateAnchor(v));
    return this;
  }

  /**
   * Set text and icon properties together
   * @param props Combined property configuration
   * @returns this (supports chaining)
   * @example
   * ```typescript
   * layer.withProperties({
   *   text: {
   *     textField: ['get', 'title'],
   *     textSize: 14,
   *     textColor: '#000000'
   *   },
   *   icon: {
   *     iconImage: ['get', 'icon'],
   *     iconSize: 1.0,
   *     iconAnchor: 'bottom'
   *   }
   * });
   * ```
   */
  withProperties(props: SymbolProperties): SymbolLayer {
    if (props.text) {
      this.withTextProperties(props.text);
    }
    if (props.icon) {
      this.withIconProperties(props.icon);
    }
    return this;
  }

}

/**
 * Text property interface
 */
export interface TextProperties {
  textField?: PropertyValue<string>;
  textFont?: PropertyValue<string[]>;
  textSize?: PropertyValue<number>;
  textMaxWidth?: PropertyValue<number>;
  textOffset?: PropertyValue<number[]>;
  textAnchor?: PropertyValue<string>;
  textAllowOverlap?: PropertyValue<boolean>;
  textIgnorePlacement?: boolean;
  textOptional?: boolean;
  textOpacity?: PropertyValue<number>;
  textColor?: PropertyValue<string>;
  textHaloColor?: PropertyValue<string>;
  textHaloWidth?: PropertyValue<number>;
  textHaloBlur?: PropertyValue<number>;
  textPadding?: number;
  textKeepUpright?: boolean;
  textTranslate?: PropertyValue<number[]>;
  textTranslateAnchor?: string;
  textLineHeight?: PropertyValue<number>;
  textLetterSpacing?: PropertyValue<number>;
  textJustify?: PropertyValue<string>;
  textRotate?: PropertyValue<number>;
  textTransform?: PropertyValue<string>;
  textMaxAngle?: PropertyValue<number>;
  textRadialOffset?: number;
  textPitchAlignment?: string;
  textRotationAlignment?: string;
  textVariableAnchor?: string[];
  textVariableAnchorOffset?: number[];
  textWritingMode?: string[];
}

/**
 * Icon property interface
 */
export interface IconProperties {
  iconImage?: PropertyValue<string>;
  iconSize?: PropertyValue<number>;
  iconRotate?: PropertyValue<number>;
  iconOffset?: PropertyValue<number[]>;
  iconAnchor?: PropertyValue<string>;
  iconAllowOverlap?: PropertyValue<boolean>;
  iconIgnorePlacement?: boolean;
  iconOptional?: boolean;
  iconOpacity?: PropertyValue<number>;
  iconColor?: PropertyValue<string>;
  iconHaloColor?: PropertyValue<string>;
  iconHaloWidth?: PropertyValue<number>;
  iconHaloBlur?: PropertyValue<number>;
  iconPadding?: number;
  iconKeepUpright?: boolean;
  iconPitchAlignment?: string;
  iconRotationAlignment?: string;
  iconTextFit?: string;
  iconTextFitPadding?: number[];
  iconTranslate?: PropertyValue<number[]>;
  iconTranslateAnchor?: string;
}

/**
 * Combined Symbol property interface
 */
export interface SymbolProperties {
  text?: TextProperties;
  icon?: IconProperties;
}
