/**
 * GeoJsonSource - GeoJSON 数据源封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class GeoJsonSource {
  private nativeInstance: maplibre.GeoJsonSource;

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: ESObject | maplibre.GeoJsonSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.GeoJsonSource;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.GeoJsonSource(idOrMarker, optionsOrNative as ESObject);
    } else {
      throw new Error('Invalid GeoJsonSource constructor arguments');
    }
  }

  static create(id: string, options?: ESObject): GeoJsonSource {
    return new GeoJsonSource(id, options);
  }

  static fromNative(nativeInstance: maplibre.GeoJsonSource): GeoJsonSource {
    return new GeoJsonSource(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.GeoJsonSource {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setGeoJson(geojson: string): void {
    this.nativeInstance.setGeoJson(geojson);
  }

  setGeoJsonSync(geojson: ESObject): void {
    this.nativeInstance.setGeoJsonSync(geojson);
  }

  setUrl(url: string): void {
    this.nativeInstance.setUrl(url);
  }

  getUrl(): string {
    return this.nativeInstance.getUrl();
  }
}

export type GeoJsonData = Object | string | null;
