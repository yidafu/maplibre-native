/**
 * HeatmapLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { ExpressionLiteral, NumberValue } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { Expression } from '../expressions/Expression';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class HeatmapLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'HeatmapLayer';
  private nativeInstance: maplibre.HeatmapLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.HeatmapLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.HeatmapLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid HeatmapLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): HeatmapLayer {
    return new HeatmapLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.HeatmapLayer): HeatmapLayer {
    return new HeatmapLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.HeatmapLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): HeatmapLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): HeatmapLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): HeatmapLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  /**
   * 设置图层过滤器
   * @param filter Expression 实例或表达式字面量数组
   */
  setFilter(filter: Expression<boolean> | ExpressionLiteral): HeatmapLayer {
    const filterArray = filter instanceof Expression ? filter.toArray() : filter;
    this.nativeInstance.setFilter(filterArray as ExpressionLiteral);
    return this;
  }

  // ========== Heatmap 样式属性方法 ==========

  setHeatmapRadius(radius: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapRadius(convertValue(radius));
    return this;
  }

  setHeatmapWeight(weight: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapWeight(convertValue(weight));
    return this;
  }

  setHeatmapIntensity(intensity: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapIntensity(convertValue(intensity));
    return this;
  }

  setHeatmapColor(color: PropertyValue<string>): HeatmapLayer {
    this.nativeInstance.setHeatmapColor(convertValue(color) as ExpressionLiteral);
    return this;
  }

  setHeatmapOpacity(opacity: PropertyValue<number>): HeatmapLayer {
    this.nativeInstance.setHeatmapOpacity(convertValue(opacity));
    return this;
  }
}
