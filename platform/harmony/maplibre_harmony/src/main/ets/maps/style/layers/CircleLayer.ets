/**
 * CircleLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type {ColorValue, NumberValue, StringValue, ExpressionLiteral } from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class CircleLayer {
  private nativeInstance: maplibre.CircleLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.CircleLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.CircleLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid CircleLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): CircleLayer {
    return new CircleLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.CircleLayer): CircleLayer {
    return new CircleLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.CircleLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): CircleLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): CircleLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setFilter(filter: Object[]): CircleLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== Circle 样式属性方法 ==========

  setCircleRadius(radius: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleRadius(convertValue(radius));
    return this;
  }

  setCircleColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleColor(convertValue(color));
    return this;
  }

  setCircleOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleOpacity(convertValue(opacity));
    return this;
  }

  setCircleBlur(blur: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleBlur(convertValue(blur));
    return this;
  }

  setCircleStrokeWidth(width: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeWidth(convertValue(width));
    return this;
  }

  setCircleStrokeColor(color: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleStrokeColor(convertValue(color));
    return this;
  }

  setCircleStrokeOpacity(opacity: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleStrokeOpacity(convertValue(opacity));
    return this;
  }

  setCircleTranslate(translate: PropertyValue<number[]>): CircleLayer {
    this.nativeInstance.setCircleTranslate(convertValue(translate));
    return this;
  }

  setCircleTranslateAnchor(anchor: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCircleTranslateAnchor(convertValue(anchor));
    return this;
  }

  setCirclePitchScale(scale: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchScale(convertValue(scale));
    return this;
  }

  setCirclePitchAlignment(alignment: PropertyValue<string>): CircleLayer {
    this.nativeInstance.setCirclePitchAlignment(convertValue(alignment));
    return this;
  }

  setCircleSortKey(sortKey: PropertyValue<number>): CircleLayer {
    this.nativeInstance.setCircleSortKey(convertValue(sortKey));
    return this;
  }

  // ========== Getter 方法 ==========

  getCircleRadius(): number | undefined {
    return this.nativeInstance.getCircleRadius();
  }

  getCircleColor(): string | undefined {
    return this.nativeInstance.getCircleColor();
  }

  getCircleOpacity(): number | undefined {
    return this.nativeInstance.getCircleOpacity();
  }

  getCircleTranslate(): number[] | undefined {
    return this.nativeInstance.getCircleTranslate();
  }

  getCircleTranslateAnchor(): string | undefined {
    return this.nativeInstance.getCircleTranslateAnchor();
  }

  getCirclePitchScale(): string | undefined {
    return this.nativeInstance.getCirclePitchScale();
  }

  getCirclePitchAlignment(): string | undefined {
    return this.nativeInstance.getCirclePitchAlignment();
  }

  getCircleSortKey(): number | undefined {
    return this.nativeInstance.getCircleSortKey();
  }
}
