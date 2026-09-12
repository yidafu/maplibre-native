/**
 * VectorSource - Wrapper for vector data sources
 */
import type { VectorSourceOptions } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';
import { BaseSource, SourceInternalTag, resolveSourceNative } from './BaseSource';

export class VectorSource extends BaseSource<maplibre.VectorSource> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'VectorSource';

  constructor(idOrMarker: string | SourceInternalTag, optionsOrNative?: VectorSourceOptions | maplibre.VectorSource) {
    super(resolveSourceNative(idOrMarker, optionsOrNative, 
      (id, o) => new maplibre.VectorSource(id, o as VectorSourceOptions), "VectorSource"));
  }

  static create(id: string, options?: VectorSourceOptions): VectorSource {
    return new VectorSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.VectorSource): VectorSource {
    return new VectorSource(SourceInternalTag.INSTANCE, nativeInstance);
  }

  setTiles(tiles: string[]): VectorSource {
    this.nativeInstance.setTiles(tiles);
    return this;
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
