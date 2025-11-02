/**
 * HillshadeLayer - 封装类
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

export class HillshadeLayer {
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

  setFilter(filter: Object[]): HillshadeLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== Hillshade 样式属性方法 ==========

  setHillshadeIlluminationDirection(direction: NumberValue): HillshadeLayer {
    this.nativeInstance.setHillshadeIlluminationDirection(direction);
    return this;
  }

  setHillshadeExaggeration(exaggeration: NumberValue): HillshadeLayer {
    this.nativeInstance.setHillshadeExaggeration(convertValue(exaggeration));
    return this;
  }
}
