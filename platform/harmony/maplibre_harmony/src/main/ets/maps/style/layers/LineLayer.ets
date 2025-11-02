/**
 * LineLayer - 封装类
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

export class LineLayer {
  private nativeInstance: maplibre.LineLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.LineLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.LineLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid LineLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): LineLayer {
    return new LineLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.LineLayer): LineLayer {
    return new LineLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.LineLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): LineLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): LineLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): LineLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setFilter(filter: Object[]): LineLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  setSourceLayer(sourceLayer: string): LineLayer {
    this.nativeInstance.setSourceLayer(sourceLayer);
    return this;
  }

  // ========== Line 样式属性方法 ==========

  setLineColor(color: ColorValue): LineLayer {
    this.nativeInstance.setLineColor(convertValue(color));
    return this;
  }

  setLineWidth(width: NumberValue): LineLayer {
    this.nativeInstance.setLineWidth(convertValue(width));
    return this;
  }

  setLineOpacity(opacity: NumberValue): LineLayer {
    this.nativeInstance.setLineOpacity(convertValue(opacity));
    return this;
  }

  setLinePattern(pattern: PropertyValue<string>): LineLayer {
    this.nativeInstance.setLinePattern(convertValue(pattern));
    return this;
  }

  setLineGapWidth(gapWidth: NumberValue): LineLayer {
    this.nativeInstance.setLineGapWidth(gapWidth);
    return this;
  }

  setLineDasharray(dasharray: PropertyValue<number[]>): LineLayer {
    this.nativeInstance.setLineDasharray(dasharray);
    return this;
  }

  setLineBlur(blur: NumberValue): LineLayer {
    this.nativeInstance.setLineBlur(convertValue(blur));
    return this;
  }

  setLineOffset(offset: NumberValue): LineLayer {
    this.nativeInstance.setLineOffset(convertValue(offset));
    return this;
  }

  setLineCap(cap: StringValue): LineLayer {
    this.nativeInstance.setLineCap(convertValue(cap));
    return this;
  }

  setLineJoin(join: StringValue): LineLayer {
    this.nativeInstance.setLineJoin(convertValue(join));
    return this;
  }

  setLineTranslate(translate: PropertyValue<number[]>): LineLayer {
    this.nativeInstance.setLineTranslate(convertValue(translate));
    return this;
  }

  setLineTranslateAnchor(anchor: StringValue): LineLayer {
    this.nativeInstance.setLineTranslateAnchor(anchor);
    return this;
  }

  setLineMiterLimit(limit: NumberValue): LineLayer {
    this.nativeInstance.setLineMiterLimit(limit);
    return this;
  }

  setLineRoundLimit(limit: NumberValue): LineLayer {
    this.nativeInstance.setLineRoundLimit(limit);
    return this;
  }

  setLineGradient(gradient: Object): LineLayer {
    this.nativeInstance.setLineGradient(convertValue(gradient));
    return this;
  }

  setLineSortKey(sortKey: NumberValue): LineLayer {
    this.nativeInstance.setLineSortKey(convertValue(sortKey));
    return this;
  }

  // ========== Getter 方法 ==========

  getLineColor(): string | undefined {
    return this.nativeInstance.getLineColor();
  }

  getLineWidth(): number | undefined {
    return this.nativeInstance.getLineWidth();
  }

  getLineOpacity(): number | undefined {
    return this.nativeInstance.getLineOpacity();
  }

  getLineTranslate(): number[] | undefined {
    return this.nativeInstance.getLineTranslate();
  }

  getLineTranslateAnchor(): string | undefined {
    return this.nativeInstance.getLineTranslateAnchor();
  }

  getLineMiterLimit(): number | undefined {
    return this.nativeInstance.getLineMiterLimit();
  }

  getLineRoundLimit(): number | undefined {
    return this.nativeInstance.getLineRoundLimit();
  }

  getLineGradient(): Object | undefined {
    return this.nativeInstance.getLineGradient();
  }

  getLineSortKey(): number | undefined {
    return this.nativeInstance.getLineSortKey();
  }
}
