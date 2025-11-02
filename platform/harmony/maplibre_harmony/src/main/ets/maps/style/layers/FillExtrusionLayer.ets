/**
 * FillExtrusionLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { ColorValue, NumberValue, StringValue, PropertyValue , ExpressionLiteral } from 'libmaplibre.so';
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

export class FillExtrusionLayer {
  private nativeInstance: maplibre.FillExtrusionLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.FillExtrusionLayer) {
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

  setFilter(filter: Object[]): FillExtrusionLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== FillExtrusion 样式属性方法 ==========

  setFillExtrusionColor(color: ColorValue): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionColor(color);
    return this;
  }

  setFillExtrusionOpacity(opacity: NumberValue): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionOpacity(opacity);
    return this;
  }

  setFillExtrusionHeight(height: NumberValue): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionHeight(height);
    return this;
  }

  setFillExtrusionBase(base: NumberValue): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionBase(base);
    return this;
  }

  setFillExtrusionPattern(pattern: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionPattern(pattern);
    return this;
  }

  setFillExtrusionTranslate(translate: PropertyValue<number[]>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslate(translate);
    return this;
  }

  setFillExtrusionTranslateAnchor(anchor: StringValue): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslateAnchor(anchor);
    return this;
  }
}
