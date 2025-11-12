/**
 * VectorSource - Wrapper for vector data sources
 */
import type { VectorSourceOptions } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class VectorSource {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'VectorSource';
  private nativeInstance: maplibre.VectorSource;

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: VectorSourceOptions | maplibre.VectorSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.VectorSource;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.VectorSource(idOrMarker, optionsOrNative as VectorSourceOptions);
    } else {
      throw new Error('Invalid VectorSource constructor arguments');
    }
  }

  static create(id: string, options?: VectorSourceOptions): VectorSource {
    return new VectorSource(id, options);
  }

  setTiles(tiles: string[]): VectorSource {
    this.nativeInstance.setTiles(tiles);
    return this;
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

  /**
   * Set the minimum zoom level
   */
  setMinZoom(minZoom: number): VectorSource {
    this.nativeInstance.setMinZoom(minZoom);
    return this;
  }

  /**
   * Set the maximum zoom level
   */
  setMaxZoom(maxZoom: number): VectorSource {
    this.nativeInstance.setMaxZoom(maxZoom);
    return this;
  }
}
