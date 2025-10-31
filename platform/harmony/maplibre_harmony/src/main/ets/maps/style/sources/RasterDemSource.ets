/**
 * RasterDemSource - DEM 数据源封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class RasterDemSource {
  private nativeInstance: maplibre.RasterDemSource;

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: ESObject | maplibre.RasterDemSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.RasterDemSource;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.RasterDemSource(idOrMarker, optionsOrNative as ESObject);
    } else {
      throw new Error('Invalid RasterDemSource constructor arguments');
    }
  }

  static create(id: string, options?: ESObject): RasterDemSource {
    return new RasterDemSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.RasterDemSource): RasterDemSource {
    return new RasterDemSource(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.RasterDemSource {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setUrl(url: string): RasterDemSource {
    this.nativeInstance.setUrl(url);
    return this;
  }

  getUrl(): string {
    return this.nativeInstance.getUrl();
  }
}

// DemEncoding 类型定义
export enum DemEncoding {
  MAPBOX = 'mapbox',
  TERRARIUM = 'terrarium'
}
