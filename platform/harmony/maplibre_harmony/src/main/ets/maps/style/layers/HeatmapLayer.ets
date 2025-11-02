/**
 * HeatmapLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { NumberValue , ExpressionLiteral } from 'libmaplibre.so';
import { Expression } from '../expressions/index';


/**
 * 转换属性值 - 将 Expression 对象转为数组
 * @param value 属性值（常量、Expression 对象或字面量数组）
 * @returns 转换后的值（常量或数组）
 */
function convertValue<T>(value: T | Expression | ExpressionLiteral): T | ExpressionLiteral {
  if (value instanceof Expression) {
    return value.toArray();
  }
  return value as T | ExpressionLiteral;
}

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class HeatmapLayer {
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

  setFilter(filter: Object[]): HeatmapLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== Heatmap 样式属性方法 ==========

  setHeatmapRadius(radius: NumberValue): HeatmapLayer {
    this.nativeInstance.setHeatmapRadius(convertValue(radius));
    return this;
  }

  setHeatmapWeight(weight: NumberValue): HeatmapLayer {
    this.nativeInstance.setHeatmapWeight(convertValue(weight));
    return this;
  }

  setHeatmapIntensity(intensity: NumberValue): HeatmapLayer {
    this.nativeInstance.setHeatmapIntensity(convertValue(intensity));
    return this;
  }

  setHeatmapColor(color: Object): HeatmapLayer {
    this.nativeInstance.setHeatmapColor(convertValue(color));
    return this;
  }

  setHeatmapOpacity(opacity: NumberValue): HeatmapLayer {
    this.nativeInstance.setHeatmapOpacity(convertValue(opacity));
    return this;
  }
}
