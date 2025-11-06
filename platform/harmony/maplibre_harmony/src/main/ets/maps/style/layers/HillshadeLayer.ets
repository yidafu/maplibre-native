/**
 * HillshadeLayer - 封装类
 */
import type { ExpressionLiteral, NumberValue } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';
import { Expression } from '../expressions/index';
import { convertValue } from './LayerUtils';
import { PropertyValue } from '../expressions/Expression';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class HillshadeLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'HillshadeLayer';
  private nativeInstance: maplibre.HillshadeLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.HillshadeLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.HillshadeLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid HillshadeLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): HillshadeLayer {
    return new HillshadeLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.HillshadeLayer): HillshadeLayer {
    return new HillshadeLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.HillshadeLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): HillshadeLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): HillshadeLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): HillshadeLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * 设置图层过滤器
   * @param filter Expression 实例或表达式字面量数组
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): HillshadeLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): HillshadeLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  // ========== Hillshade 样式属性方法 ==========

  setHillshadeIlluminationDirection(direction: PropertyValue<number>): HillshadeLayer {
    this.nativeInstance.setHillshadeIlluminationDirection(convertValue(direction));
    return this;
  }

  setHillshadeExaggeration(exaggeration: PropertyValue<number>): HillshadeLayer {
    this.nativeInstance.setHillshadeExaggeration(convertValue(exaggeration));
    return this;
  }
  // ========== 通用属性方法（Android兼容API）==========

  /**
   * 设置单个属性
   * @param propertyName 属性名称
   * @param value 属性值（常量值或Expression）
   * @returns this（支持链式调用）
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): HillshadeLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as ESObject);
    return this;
  }

  /**
   * 批量设置属性
   * @param properties 属性对象，键为属性名，值为属性值
   * @returns this（支持链式调用）
   * @example
   * layer.setProperties({
   *   'hillshade-exaggeration': 0.5
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): HillshadeLayer {
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
