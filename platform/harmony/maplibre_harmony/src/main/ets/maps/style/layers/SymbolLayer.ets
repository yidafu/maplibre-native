/**
 * SymbolLayer - Wrapper class
 */
import maplibre from 'libmaplibre.so';
import type { ExpressionLiteral, PropertyValue as NativePropertyValue, JSONValue } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class SymbolLayer {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'SymbolLayer';
  private nativeInstance: maplibre.SymbolLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.SymbolLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.SymbolLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid SymbolLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): SymbolLayer {
    return new SymbolLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.SymbolLayer): SymbolLayer {
    return new SymbolLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.SymbolLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getType(): string {
    return this.nativeInstance.getType();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  getSourceLayer(): string {
    return this.nativeInstance.getSourceLayer();
  }

  setVisibility(visibility: 'visible' | 'none'): SymbolLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  getVisibility(): 'visible' | 'none' {
    return this.nativeInstance.getVisibility();
  }

  setMinZoom(zoom: number): SymbolLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  getMinZoom(): number {
    return this.nativeInstance.getMinZoom();
  }

  setMaxZoom(zoom: number): SymbolLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  getMaxZoom(): number {
    return this.nativeInstance.getMaxZoom();
  }

  /**
   * Configure the layer filter
   * @param filter Expression instance or expression literal array
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): SymbolLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  getFilter(): ExpressionLiteral | null {
    return this.nativeInstance.getFilter();
  }

  setSourceLayer(sourceLayer: string): SymbolLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
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
    if (props.textField !== undefined) {
      this.setTextField(props.textField);
    }
    if (props.textFont !== undefined) {
      this.setTextFont(props.textFont);
    }
    if (props.textSize !== undefined) {
      this.setTextSize(props.textSize);
    }
    if (props.textMaxWidth !== undefined) {
      this.setTextMaxWidth(props.textMaxWidth);
    }
    if (props.textOffset !== undefined) {
      this.setTextOffset(props.textOffset);
    }
    if (props.textAnchor !== undefined) {
      this.setTextAnchor(props.textAnchor);
    }
    if (props.textAllowOverlap !== undefined) {
      this.setTextAllowOverlap(props.textAllowOverlap);
    }
    if (props.textIgnorePlacement !== undefined) {
      this.setTextIgnorePlacement(props.textIgnorePlacement);
    }
    if (props.textOptional !== undefined) {
      this.setTextOptional(props.textOptional);
    }
    if (props.textPadding !== undefined) {
      this.setTextPadding(props.textPadding);
    }
    if (props.textKeepUpright !== undefined) {
      this.setTextKeepUpright(props.textKeepUpright);
    }
    if (props.textOpacity !== undefined) {
      this.setTextOpacity(props.textOpacity);
    }
    if (props.textColor !== undefined) {
      this.setTextColor(props.textColor);
    }
    if (props.textHaloColor !== undefined) {
      this.setTextHaloColor(props.textHaloColor);
    }
    if (props.textHaloWidth !== undefined) {
      this.setTextHaloWidth(props.textHaloWidth);
    }
    if (props.textHaloBlur !== undefined) {
      this.setTextHaloBlur(props.textHaloBlur);
    }
    if (props.textTranslate !== undefined) {
      this.setTextTranslate(props.textTranslate);
    }
    if (props.textTranslateAnchor !== undefined) {
      this.setTextTranslateAnchor(props.textTranslateAnchor);
    }
    if (props.textLineHeight !== undefined) {
      this.setTextLineHeight(props.textLineHeight);
    }
    if (props.textLetterSpacing !== undefined) {
      this.setTextLetterSpacing(props.textLetterSpacing);
    }
    if (props.textJustify !== undefined) {
      this.setTextJustify(props.textJustify);
    }
    if (props.textRotate !== undefined) {
      this.setTextRotate(props.textRotate);
    }
    if (props.textTransform !== undefined) {
      this.setTextTransform(props.textTransform);
    }
    if (props.textMaxAngle !== undefined) {
      this.setTextMaxAngle(props.textMaxAngle);
    }
    if (props.textRadialOffset !== undefined) {
      this.setTextRadialOffset(props.textRadialOffset);
    }
    if (props.textPitchAlignment !== undefined) {
      this.setTextPitchAlignment(props.textPitchAlignment);
    }
    if (props.textRotationAlignment !== undefined) {
      this.setTextRotationAlignment(props.textRotationAlignment);
    }
    if (props.textVariableAnchor !== undefined) {
      this.setTextVariableAnchor(props.textVariableAnchor);
    }
    if (props.textVariableAnchorOffset !== undefined) {
      this.setTextVariableAnchorOffset(props.textVariableAnchorOffset);
    }
    if (props.textWritingMode !== undefined) {
      this.setTextWritingMode(props.textWritingMode);
    }
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
    if (props.iconImage !== undefined) {
      this.setIconImage(props.iconImage);
    }
    if (props.iconSize !== undefined) {
      this.setIconSize(props.iconSize);
    }
    if (props.iconRotate !== undefined) {
      this.setIconRotate(props.iconRotate);
    }
    if (props.iconOffset !== undefined) {
      this.setIconOffset(props.iconOffset);
    }
    if (props.iconAnchor !== undefined) {
      this.setIconAnchor(props.iconAnchor);
    }
    if (props.iconAllowOverlap !== undefined) {
      this.setIconAllowOverlap(props.iconAllowOverlap);
    }
    if (props.iconIgnorePlacement !== undefined) {
      this.setIconIgnorePlacement(props.iconIgnorePlacement);
    }
    if (props.iconOptional !== undefined) {
      this.setIconOptional(props.iconOptional);
    }
    if (props.iconPadding !== undefined) {
      this.setIconPadding(props.iconPadding);
    }
    if (props.iconKeepUpright !== undefined) {
      this.setIconKeepUpright(props.iconKeepUpright);
    }
    if (props.iconOpacity !== undefined) {
      this.setIconOpacity(props.iconOpacity);
    }
    if (props.iconColor !== undefined) {
      this.setIconColor(props.iconColor);
    }
    if (props.iconHaloColor !== undefined) {
      this.setIconHaloColor(props.iconHaloColor);
    }
    if (props.iconHaloWidth !== undefined) {
      this.setIconHaloWidth(props.iconHaloWidth);
    }
    if (props.iconHaloBlur !== undefined) {
      this.setIconHaloBlur(props.iconHaloBlur);
    }
    if (props.iconPitchAlignment !== undefined) {
      this.setIconPitchAlignment(props.iconPitchAlignment);
    }
    if (props.iconRotationAlignment !== undefined) {
      this.setIconRotationAlignment(props.iconRotationAlignment);
    }
    if (props.iconTextFit !== undefined) {
      this.setIconTextFit(props.iconTextFit);
    }
    if (props.iconTextFitPadding !== undefined) {
      this.setIconTextFitPadding(props.iconTextFitPadding);
    }
    if (props.iconTranslate !== undefined) {
      this.setIconTranslate(props.iconTranslate);
    }
    if (props.iconTranslateAnchor !== undefined) {
      this.setIconTranslateAnchor(props.iconTranslateAnchor);
    }
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

  // ========== Generic property API (Android-compatible) ==========

  /**
   * Set a single property
   * @param propertyName Property key (for example, 'text-field', 'icon-image', 'text-color')
   * @param value Property value (constant or Expression)
   * @returns this (supports chaining)
   */
  setProperty(propertyName: string, value: PropertyValue<JSONValue>): SymbolLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as NativePropertyValue<JSONValue>);
    return this;
  }

  /**
   * Set multiple properties in batch
   * @param properties Map of property names to values
   * @returns this (supports chaining)
   * @example
   * layer.setProperties({
   *   'text-field': ['get', 'name'],
   *   'text-size': 16,
   *   'text-color': '#000000',
   *   'icon-image': 'marker'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<JSONValue>>): SymbolLayer {
    const convertedProps: Record<string, NativePropertyValue<JSONValue>> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]) as NativePropertyValue<JSONValue>;
    }
    this.nativeInstance.setProperties(convertedProps);
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
