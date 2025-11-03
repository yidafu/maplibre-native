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
}
