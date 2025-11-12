/**
 * RasterDemSource - Wrapper for digital elevation model sources
 */
import type { RasterDemSourceOptions } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class RasterDemSource {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'RasterDemSource';
  private nativeInstance: maplibre.RasterDemSource;

  constructor(idOrMarker: string | InternalMarker,
    optionsOrNative?: RasterDemSourceOptions | maplibre.RasterDemSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.RasterDemSource;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.RasterDemSource(idOrMarker, optionsOrNative as RasterDemSourceOptions);
    } else {
      throw new Error('Invalid RasterDemSource constructor arguments');
    }
  }

  static create(id: string, options?: RasterDemSourceOptions): RasterDemSource {
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

  /**
   * Configure tile size in pixels
   * @param tileSize tile size value
   */
  setTileSize(tileSize: number): RasterDemSource {
    this.nativeInstance.setTileSize(tileSize);
    return this;
  }
}

// DemEncoding type declaration
export enum DemEncoding {
  MAPBOX = 'mapbox',
  TERRARIUM = 'terrarium'
}
