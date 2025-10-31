/**
 * FillLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

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

  setFillColor(value: Object): FillLayer {
    this.nativeInstance.setFillColor(value);
    return this;
  }

  setFillOpacity(value: Object): FillLayer {
    this.nativeInstance.setFillOpacity(value);
    return this;
  }
}
