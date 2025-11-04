/**
 * FillLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { ExpressionLiteral } from 'libmaplibre.so';
import { PropertyValue, Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class FillLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'FillLayer';
  private nativeInstance: maplibre.FillLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.FillLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.FillLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid FillLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): FillLayer {
    return new FillLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.FillLayer): FillLayer {
    return new FillLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.FillLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): FillLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): FillLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): FillLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * 设置图层过滤器
   * @param filter Expression 实例或表达式字面量数组
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): FillLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  // ========== Fill 绘制属性方法 ==========

  setFillColor(color: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillColor(convertValue(color));
    return this;
  }

  setFillOpacity(opacity: PropertyValue<number>): FillLayer {
    this.nativeInstance.setFillOpacity(convertValue(opacity));
    return this;
  }

  setFillOutlineColor(color: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillOutlineColor(convertValue(color));
    return this;
  }

  setFillPattern(pattern: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillPattern(convertValue(pattern));
    return this;
  }

  setFillAntialias(antialias: PropertyValue<boolean>): FillLayer {
    this.nativeInstance.setFillAntialias(convertValue(antialias));
    return this;
  }

  setFillTranslate(translate: PropertyValue<number[]>): FillLayer {
    this.nativeInstance.setFillTranslate(convertValue(translate));
    return this;
  }

  setFillTranslateAnchor(anchor: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillTranslateAnchor(convertValue(anchor));
    return this;
  }

  setFillSortKey(sortKey: PropertyValue<number>): FillLayer {
    this.nativeInstance.setFillSortKey(convertValue(sortKey));
    return this;
  }

  // ========== 通用属性方法（Android兼容API）==========

  /**
   * 设置单个属性
   * @param propertyName 属性名称（如 'fill-color', 'fill-opacity'）
   * @param value 属性值（常量值或Expression）
   * @returns this（支持链式调用）
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): FillLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value));
    return this;
  }

  /**
   * 批量设置属性
   * @param properties 属性对象，键为属性名，值为属性值
   * @returns this（支持链式调用）
   * @example
   * layer.setProperties({
   *   'fill-color': '#FF0000',
   *   'fill-opacity': 0.5,
   *   'fill-outline-color': '#000000'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): FillLayer {
    const convertedProps: Record<string, Object> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]);
    }
    this.nativeInstance.setProperties(convertedProps);
    return this;
  }

  // ========== Getter 方法 ==========

  getFillColor(): string | undefined {
    return this.nativeInstance.getFillColor();
  }

  getFillOpacity(): number | undefined {
    return this.nativeInstance.getFillOpacity();
  }

  getFillTranslateAnchor(): string | undefined {
    return this.nativeInstance.getFillTranslateAnchor();
  }

  getFillSortKey(): number | undefined {
    return this.nativeInstance.getFillSortKey();
  }
}
