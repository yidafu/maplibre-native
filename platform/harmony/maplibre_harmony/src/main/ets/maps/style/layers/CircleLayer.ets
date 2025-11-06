/**
 * CircleLayer - 封装类
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

export class CircleLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'CircleLayer';
  private nativeInstance: maplibre.CircleLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.CircleLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.CircleLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid CircleLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): CircleLayer {
    return new CircleLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.CircleLayer): CircleLayer {
    return new CircleLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.CircleLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): CircleLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * 设置图层过滤器
   * @param filter Expression 实例或表达式字面量数组
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): CircleLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): CircleLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  // ========== Circle 样式属性方法 ==========

  setCircleRadius(radius: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleRadius(convertValue(radius));
    return this;
  }

  setCircleColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleColor(convertValue(color));
    return this;
  }

  setCircleOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleOpacity(convertValue(opacity));
    return this;
  }

  setCircleBlur(blur: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleBlur(convertValue(blur));
    return this;
  }

  setCircleStrokeWidth(width: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeWidth(convertValue(width));
    return this;
  }

  setCircleStrokeColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleStrokeColor(convertValue(color));
    return this;
  }

  setCircleStrokeOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeOpacity(convertValue(opacity));
    return this;
  }

  setCircleTranslate(translate: PropertyValue<number[]>): CircleLayer {
    this.nativeInstance.setCircleTranslate(convertValue(translate));
    return this;
  }

  setCircleTranslateAnchor(anchor: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleTranslateAnchor(convertValue(anchor));
    return this;
  }

  setCirclePitchScale(scale: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchScale(convertValue(scale));
    return this;
  }

  setCirclePitchAlignment(alignment: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchAlignment(convertValue(alignment));
    return this;
  }

  setCircleSortKey(sortKey: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleSortKey(convertValue(sortKey));
    return this;
  }

  // ========== 通用属性方法（Android兼容API）==========

  /**
   * 设置单个属性
   * @param propertyName 属性名称（如 'circle-color', 'circle-radius'）
   * @param value 属性值（常量值或Expression）
   * @returns this（支持链式调用）
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): CircleLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as ESObject);
    return this;
  }

  /**
   * 批量设置属性
   * @param properties 属性对象，键为属性名，值为属性值
   * @returns this（支持链式调用）
   * @example
   * layer.setProperties({
   *   'circle-color': '#00FF00',
   *   'circle-radius': 10,
   *   'circle-stroke-width': 2
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): CircleLayer {
    const convertedProps: Record<string, ESObject> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]) as ESObject;
    }
    this.nativeInstance.setProperties(convertedProps as ESObject);
    return this;
  }

  // ========== Getter 方法 ==========

  getCircleRadius(): number | undefined {
    return this.nativeInstance.getCircleRadius();
  }

  getCircleColor(): string | undefined {
    return this.nativeInstance.getCircleColor();
  }

  getCircleOpacity(): number | undefined {
    return this.nativeInstance.getCircleOpacity();
  }

  getCircleTranslate(): number[] | undefined {
    return this.nativeInstance.getCircleTranslate();
  }

  getCircleTranslateAnchor(): string | undefined {
    return this.nativeInstance.getCircleTranslateAnchor();
  }

  getCirclePitchScale(): string | undefined {
    return this.nativeInstance.getCirclePitchScale();
  }

  getCirclePitchAlignment(): string | undefined {
    return this.nativeInstance.getCirclePitchAlignment();
  }

  getCircleSortKey(): number | undefined {
    return this.nativeInstance.getCircleSortKey();
  }
}
