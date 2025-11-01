/**
 * FillExtrusionLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

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

  setFillExtrusionColor(value: ESObject): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionColor(value);
    return this;
  }

  setFillExtrusionOpacity(value: ESObject): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionOpacity(value);
    return this;
  }

  setFillExtrusionHeight(value: ESObject): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionHeight(value);
    return this;
  }

  setFillExtrusionBase(value: ESObject): FillExtrusionLayer {
    this.nativeInstance.setFillExtrusionBase(value);
    return this;
  }
}
