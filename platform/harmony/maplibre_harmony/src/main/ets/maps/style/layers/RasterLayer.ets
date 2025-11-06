/**
 * RasterLayer - 封装类
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

export class RasterLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'RasterLayer';
  private nativeInstance: maplibre.RasterLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.RasterLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.RasterLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid RasterLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): RasterLayer {
    return new RasterLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.RasterLayer): RasterLayer {
    return new RasterLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.RasterLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): RasterLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): RasterLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): RasterLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * 设置图层过滤器
   * @param filter Expression 实例或表达式字面量数组
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): RasterLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  setSourceLayer(sourceLayer: string): RasterLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  // ========== Raster 样式属性方法 ==========

  setRasterOpacity(opacity: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterOpacity(convertValue(opacity));
    return this;
  }

  setRasterHueRotate(hueRotate: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterHueRotate(convertValue(hueRotate));
    return this;
  }

  setRasterBrightnessMin(brightnessMin: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterBrightnessMin(convertValue(brightnessMin));
    return this;
  }

  setRasterBrightnessMax(brightnessMax: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterBrightnessMax(convertValue(brightnessMax));
    return this;
  }

  setRasterSaturation(saturation: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterSaturation(convertValue(saturation));
    return this;
  }

  setRasterContrast(contrast: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterContrast(convertValue(contrast));
    return this;
  }

  setRasterResampling(resampling: PropertyValue<string>): RasterLayer {
    this.nativeInstance.setRasterResampling(convertValue(resampling));
    return this;
  }

  setRasterFadeDuration(duration: PropertyValue<number>): RasterLayer {
    this.nativeInstance.setRasterFadeDuration(convertValue(duration));
    return this;
  }
  // ========== 通用属性方法（Android兼容API）==========

  /**
   * 设置单个属性
   * @param propertyName 属性名称
   * @param value 属性值（常量值或Expression）
   * @returns this（支持链式调用）
   */
  setProperty(propertyName: string, value: PropertyValue<Object>): RasterLayer {
    this.nativeInstance.setProperty(propertyName, convertValue(value) as ESObject);
    return this;
  }

  /**
   * 批量设置属性
   * @param properties 属性对象，键为属性名，值为属性值
   * @returns this（支持链式调用）
   * @example
   * layer.setProperties({
   *   'raster-opacity': 0.8
   * });
   */
  setProperties(properties: Record<string, PropertyValue<Object>>): RasterLayer {
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
