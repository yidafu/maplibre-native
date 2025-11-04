/**
 * BackgroundLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class BackgroundLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'BackgroundLayer';
  private nativeInstance: maplibre.BackgroundLayer;

  constructor(idOrMarker: string | InternalMarker, nativeOrNothing?: maplibre.BackgroundLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.BackgroundLayer(idOrMarker);
    } else {
      throw new Error('Invalid BackgroundLayer constructor arguments');
    }
  }

  static create(id: string): BackgroundLayer {
    return new BackgroundLayer(id);
  }

  static fromNative(nativeInstance: maplibre.BackgroundLayer): BackgroundLayer {
    return new BackgroundLayer(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.BackgroundLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setVisibility(visibility: 'visible' | 'none'): BackgroundLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setBackgroundColor(color: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundColor(convertValue(color));
    return this;
  }

  setBackgroundOpacity(opacity: PropertyValue<number>): BackgroundLayer {
    this.nativeInstance.setBackgroundOpacity(convertValue(opacity));
    return this;
  }

  setBackgroundPattern(pattern: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundPattern(convertValue(pattern));
    return this;
  }

  // ========== Getter 方法 ==========

  getBackgroundColor(): string | undefined {
    return this.nativeInstance.getBackgroundColor();
  }

  getBackgroundOpacity(): number | undefined {
    return this.nativeInstance.getBackgroundOpacity();
  }
  // ========== 通用属性方法（Android兼容API）==========

  /**
   * 设置单个属性
   * @param propertyName 属性名称
   * @param value 属性值（常量值或Expression）
   * @returns this（支持链式调用）
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): BackgroundLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value));
    return this;
  }

  /**
   * 批量设置属性
   * @param properties 属性对象，键为属性名，值为属性值
   * @returns this（支持链式调用）
   * @example
   * layer.setProperties({
   *   'background-color': '#F0E9E1'
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): BackgroundLayer {
    const convertedProps: Record<string, Object> = {};
    const keys = Object.keys(properties);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      convertedProps[key] = convertValue(properties[key]);
    }
    this.nativeInstance.setProperties(convertedProps);
    return this;
  }

}
