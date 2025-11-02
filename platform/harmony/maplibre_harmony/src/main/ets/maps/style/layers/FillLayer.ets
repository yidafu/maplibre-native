/**
 * FillLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { ColorValue, NumberValue, StringValue, BooleanValue, PropertyValue , ExpressionLiteral } from 'libmaplibre.so';
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

export class FillLayer {
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

  setFilter(filter: Object[]): FillLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== Fill 绘制属性方法 ==========

  setFillColor(color: ColorValue): FillLayer {
    this.nativeInstance.setFillColor(convertValue(color));
    return this;
  }

  setFillOpacity(opacity: NumberValue): FillLayer {
    this.nativeInstance.setFillOpacity(convertValue(opacity));
    return this;
  }

  setFillOutlineColor(color: ColorValue): FillLayer {
    this.nativeInstance.setFillOutlineColor(color);
    return this;
  }

  setFillPattern(pattern: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillPattern(convertValue(pattern));
    return this;
  }

  setFillAntialias(antialias: BooleanValue): FillLayer {
    this.nativeInstance.setFillAntialias(convertValue(antialias));
    return this;
  }

  setFillTranslate(translate: PropertyValue<number[]>): FillLayer {
    this.nativeInstance.setFillTranslate(convertValue(translate));
    return this;
  }

  setFillTranslateAnchor(anchor: StringValue): FillLayer {
    this.nativeInstance.setFillTranslateAnchor(anchor);
    return this;
  }

  setFillSortKey(sortKey: NumberValue): FillLayer {
    this.nativeInstance.setFillSortKey(convertValue(sortKey));
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
