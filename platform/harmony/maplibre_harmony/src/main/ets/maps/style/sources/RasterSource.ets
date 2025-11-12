/**
 * RasterSource - Wrapper for raster data sources
 */
import type { RasterSourceOptions } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class RasterSource {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'RasterSource';
  private nativeInstance: maplibre.RasterSource;

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: RasterSourceOptions | maplibre.RasterSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.RasterSource;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.RasterSource(idOrMarker, optionsOrNative as RasterSourceOptions);
    } else {
      throw new Error('Invalid RasterSource constructor arguments');
    }
  }

  static create(id: string, options?: RasterSourceOptions): RasterSource {
    return new RasterSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.RasterSource): RasterSource {
    return new RasterSource(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.RasterSource {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setUrl(url: string): RasterSource {
    this.nativeInstance.setUrl(url);
    return this;
  }

  getUrl(): string {
    return this.nativeInstance.getUrl();
  }

  setTileSize(size: number): RasterSource {
    this.nativeInstance.setTileSize(size);
    return this;
  }
}
