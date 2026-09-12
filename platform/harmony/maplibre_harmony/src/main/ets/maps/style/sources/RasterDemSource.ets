/**
 * RasterDemSource - Wrapper for digital elevation model sources
 */
import type { RasterDemSourceOptions } from 'libmaplibre.so';
import maplibre from 'libmaplibre.so';
import { BaseSource, SourceInternalTag, resolveSourceNative } from './BaseSource';

export class RasterDemSource extends BaseSource<maplibre.RasterDemSource> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'RasterDemSource';

  constructor(idOrMarker: string | SourceInternalTag, optionsOrNative?: RasterDemSourceOptions | maplibre.RasterDemSource) {
    super(resolveSourceNative(idOrMarker, optionsOrNative, 
      (id, o) => new maplibre.RasterDemSource(id, o as RasterDemSourceOptions), "RasterDemSource"));
  }

  static create(id: string, options?: RasterDemSourceOptions): RasterDemSource {
    return new RasterDemSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.RasterDemSource): RasterDemSource {
    return new RasterDemSource(SourceInternalTag.INSTANCE, nativeInstance);
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
