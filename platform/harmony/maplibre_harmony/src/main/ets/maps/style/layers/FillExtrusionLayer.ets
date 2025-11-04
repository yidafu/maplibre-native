/**
 * FillExtrusionLayer - 封装类
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

export class FillExtrusionLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'FillExtrusionLayer';
  private nativeInstance: maplibre.FillExtrusionLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "",
    nativeOrNothing?: maplibre.FillExtrusionLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.FillExtrusionLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid FillExtrusionLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): FillExtrusionLayer {
    return new FillExtrusionLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.FillExtrusionLayer): FillExtrusionLayer {
    return new FillExtrusionLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.FillExtrusionLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): FillExtrusionLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): FillExtrusionLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): FillExtrusionLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * 设置图层过滤器
   * @param filter Expression 实例或表达式字面量数组
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): FillExtrusionLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  // ========== FillExtrusion 样式属性方法 ==========

  setFillExtrusionColor(color: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionColor(convertValue(color));
    return this;
  }

  setFillExtrusionOpacity(opacity: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionOpacity(convertValue(opacity));
    return this;
  }

  setFillExtrusionHeight(height: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionHeight(convertValue(height));
    return this;
  }

  setFillExtrusionBase(base: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionBase(convertValue(base));
    return this;
  }

  setFillExtrusionPattern(pattern: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionPattern(convertValue(pattern));
    return this;
  }

  setFillExtrusionTranslate(translate: PropertyValue<[number, number]>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslate(convertValue(translate) as import('libmaplibre.so').PropertyValue<[number, number]>);
    return this;
  }

  setFillExtrusionTranslateAnchor(anchor: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslateAnchor(convertValue(anchor) as string);
    return this;
  }
  // ========== 通用属性方法（Android兼容API）==========

  /**
   * 设置单个属性
   * @param propertyName 属性名称
   * @param value 属性值（常量值或Expression）
   * @returns this（支持链式调用）
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): FillExtrusionLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as ESObject);
    return this;
  }

  /**
   * 批量设置属性
   * @param properties 属性对象，键为属性名，值为属性值
   * @returns this（支持链式调用）
   * @example
   * layer.setProperties({
   *   'fill-extrusion-height': 100
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): FillExtrusionLayer {
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
