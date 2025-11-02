/**
 * FillExtrusionLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type {ColorValue, NumberValue, StringValue, ExpressionLiteral } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { convertValue } from './LayerUtils';

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

  setFillExtrusionColor(color: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionColor(convertValue(color));
    return this;
  }

  setFillExtrusionOpacity(opacity: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionOpacity(convertValue(opacity));
    return this;
  }

  setFillExtrusionHeight(height: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionHeight(convertValue(height));
    return this;
  }

  setFillExtrusionBase(base: PropertyValue<number>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionBase(convertValue(base));
    return this;
  }

  setFillExtrusionPattern(pattern: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionPattern(convertValue(pattern));
    return this;
  }

  setFillExtrusionTranslate(translate: PropertyValue<[number, number]>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslate(convertValue(translate) as import('libmaplibre.so').PropertyValue<[number, number]>);
    return this;
  }

  setFillExtrusionTranslateAnchor(anchor: PropertyValue<string>): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionTranslateAnchor(convertValue(anchor) as string);
    return this;
  }
}
