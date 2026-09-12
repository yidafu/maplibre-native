/**
 * RasterSource - Wrapper for raster data sources
 */
import type { RasterSourceOptions } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';
import { BaseSource, SourceInternalTag, resolveSourceNative } from './BaseSource';

export class RasterSource extends BaseSource<maplibre.RasterSource> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'RasterSource';

  constructor(idOrMarker: string | SourceInternalTag, optionsOrNative?: RasterSourceOptions | maplibre.RasterSource) {
    super(resolveSourceNative(idOrMarker, optionsOrNative, 
      (id, o) => new maplibre.RasterSource(id, o as RasterSourceOptions), "RasterSource"));
  }

  static create(id: string, options?: RasterSourceOptions): RasterSource {
    return new RasterSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.RasterSource): RasterSource {
    return new RasterSource(SourceInternalTag.INSTANCE, nativeInstance);
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
