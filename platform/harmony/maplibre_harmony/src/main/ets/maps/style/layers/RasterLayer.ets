/**
 * RasterLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class RasterLayer {
  private nativeInstance: maplibre.RasterLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.RasterLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.RasterLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid RasterLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): RasterLayer {
    return new RasterLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.RasterLayer): RasterLayer {
    return new RasterLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.RasterLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): RasterLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): RasterLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): RasterLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setFilter(filter: Object[]): RasterLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== Raster 样式属性方法 ==========

  setRasterOpacity(value: ESObject): RasterLayer {
    // TODO: 实现 setRasterOpacity
    return this;
  }
}
