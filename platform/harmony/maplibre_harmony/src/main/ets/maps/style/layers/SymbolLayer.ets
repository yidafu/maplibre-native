/**
 * SymbolLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { ExpressionLiteral } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class SymbolLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
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

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): SymbolLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): SymbolLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): SymbolLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * 设置图层过滤器
   * @param filter Expression 实例或表达式字面量数组
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): SymbolLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): SymbolLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  setSymbolPlacement(placement: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setSymbolPlacement(convertValue(placement));
    return this;
  }

  setSymbolSpacing(spacing: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setSymbolSpacing(convertValue(spacing));
    return this;
  }

  setSymbolAvoidEdges(avoid: PropertyValue<boolean>): SymbolLayer {
    this.nativeInstance.setSymbolAvoidEdges(convertValue(avoid));
    return this;
  }

  // ========== Symbol 图标属性方法 ==========

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

  setIconAllowOverlap(allow: boolean): SymbolLayer {
    this.nativeInstance.setIconAllowOverlap(allow);
    return this;
  }

  setIconIgnorePlacement(ignore: boolean): SymbolLayer {
    this.nativeInstance.setIconIgnorePlacement(ignore);
    return this;
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

  setIconTranslate(translate: PropertyValue<number[]>): SymbolLayer {
    this.nativeInstance.setIconTranslate(convertValue(translate));
    return this;
  }

  // ========== Symbol 文本属性方法 ==========

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

  setTextAllowOverlap(allow: boolean): SymbolLayer {
    this.nativeInstance.setTextAllowOverlap(allow);
    return this;
  }

  setTextIgnorePlacement(ignore: boolean): SymbolLayer {
    this.nativeInstance.setTextIgnorePlacement(ignore);
    return this;
  }

  setTextOptional(optional: boolean): SymbolLayer {
    this.nativeInstance.setTextOptional(optional);
    return this;
  }

  setIconOptional(optional: boolean): SymbolLayer {
    this.nativeInstance.setIconOptional(optional);
    return this;
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

  setTextLineHeight(height: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextLineHeight(convertValue(height));
    return this;
  }

  setTextLetterSpacing(spacing: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextLetterSpacing(convertValue(spacing));
    return this;
  }

  setTextJustify(justify: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextJustify(convertValue(justify));
    return this;
  }

  setTextRotate(angle: PropertyValue<number>): SymbolLayer {
    this.nativeInstance.setTextRotate(convertValue(angle));
    return this;
  }

  setTextTransform(transform: PropertyValue<string>): SymbolLayer {
    this.nativeInstance.setTextTransform(convertValue(transform));
    return this;
  }

  // ========== Getter 方法 ==========

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

  getIconAllowOverlap(): boolean {
    return this.nativeInstance.getIconAllowOverlap();
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

  getTextAllowOverlap(): boolean {
    return this.nativeInstance.getTextAllowOverlap();
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

  // ========== 批量属性设置方法（参考 Android withProperties）==========

  /**
   * 批量设置文本属性
   * @param props 文本属性配置对象
   * @returns 返回 this 以支持链式调用
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
    return this;
  }

  /**
   * 批量设置图标属性
   * @param props 图标属性配置对象
   * @returns 返回 this 以支持链式调用
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
    return this;
  }

  /**
   * 批量设置所有属性（文本 + 图标）
   * @param props 完整属性配置对象
   * @returns 返回 this 以支持链式调用
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

  // ========== 通用属性方法（Android兼容API）==========

  /**
   * 设置单个属性
   * @param propertyName 属性名称（如 'text-field', 'icon-image', 'text-color'）
   * @param value 属性值（常量值或Expression）
   * @returns this（支持链式调用）
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): SymbolLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as ESObject);
    return this;
  }

  /**
   * 批量设置属性
   * @param properties 属性对象，键为属性名，值为属性值
   * @returns this（支持链式调用）
   * @example
   * layer.setProperties({
   *   'text-field': ['get', 'name'],
   *   'text-size': 16,
   *   'text-color': '#000000',
   *   'icon-image': 'marker'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): SymbolLayer {
    const convertedProps: Record<string, ESObject> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]) as ESObject;
    }
    this.nativeInstance.setProperties(convertedProps as ESObject);
    return this;
  }
}

/**
 * 文本属性接口
 */
export interface TextProperties {
  textField?: PropertyValue<string>;
  textFont?: PropertyValue<string[]>;
  textSize?: PropertyValue<number>;
  textMaxWidth?: PropertyValue<number>;
  textOffset?: PropertyValue<number[]>;
  textAnchor?: PropertyValue<string>;
  textAllowOverlap?: boolean;
  textIgnorePlacement?: boolean;
  textOptional?: boolean;
  textOpacity?: PropertyValue<number>;
  textColor?: PropertyValue<string>;
  textHaloColor?: PropertyValue<string>;
  textHaloWidth?: PropertyValue<number>;
}

/**
 * 图标属性接口
 */
export interface IconProperties {
  iconImage?: PropertyValue<string>;
  iconSize?: PropertyValue<number>;
  iconRotate?: PropertyValue<number>;
  iconOffset?: PropertyValue<number[]>;
  iconAnchor?: PropertyValue<string>;
  iconAllowOverlap?: boolean;
  iconIgnorePlacement?: boolean;
  iconOptional?: boolean;
  iconOpacity?: PropertyValue<number>;
  iconColor?: PropertyValue<string>;
  iconHaloColor?: PropertyValue<string>;
  iconHaloWidth?: PropertyValue<number>;
}

/**
 * Symbol 完整属性接口
 */
export interface SymbolProperties {
  text?: TextProperties;
  icon?: IconProperties;
}
