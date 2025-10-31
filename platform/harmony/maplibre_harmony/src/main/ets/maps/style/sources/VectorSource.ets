/**
 * VectorSource - 矢量数据源封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class VectorSource {
  private nativeInstance: maplibre.VectorSource;

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: ESObject | maplibre.VectorSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.VectorSource;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.VectorSource(idOrMarker, optionsOrNative as ESObject);
    } else {
      throw new Error('Invalid VectorSource constructor arguments');
    }
  }

  static create(id: string, options?: ESObject): VectorSource {
    return new VectorSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.VectorSource): VectorSource {
    return new VectorSource(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.VectorSource {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setUrl(url: string): VectorSource {
    this.nativeInstance.setUrl(url);
    return this;
  }

  getUrl(): string {
    return this.nativeInstance.getUrl();
  }
}
