/**
 * FillLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type {ColorValue, NumberValue, StringValue, BooleanValue, ExpressionLiteral } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { convertValue } from './LayerUtils';

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

  setFillColor(color: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillColor(convertValue(color));
    return this;
  }

  setFillOpacity(opacity: PropertyValue<number>): FillLayer {
    this.nativeInstance.setFillOpacity(convertValue(opacity));
    return this;
  }

  setFillOutlineColor(color: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillOutlineColor(convertValue(color));
    return this;
  }

  setFillPattern(pattern: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillPattern(convertValue(pattern));
    return this;
  }

  setFillAntialias(antialias: PropertyValue<boolean>): FillLayer {
    this.nativeInstance.setFillAntialias(convertValue(antialias));
    return this;
  }

  setFillTranslate(translate: PropertyValue<number[]>): FillLayer {
    this.nativeInstance.setFillTranslate(convertValue(translate));
    return this;
  }

  setFillTranslateAnchor(anchor: PropertyValue<string>): FillLayer {
    this.nativeInstance.setFillTranslateAnchor(convertValue(anchor));
    return this;
  }

  setFillSortKey(sortKey: PropertyValue<number>): FillLayer {
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
