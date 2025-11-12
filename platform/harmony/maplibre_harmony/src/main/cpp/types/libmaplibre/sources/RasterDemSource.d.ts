/**
 * RasterDemSourceOptions - raster DEM source options.
 */
export interface RasterDemSourceOptions {
  /** Tile URL template. */
  url?: string;

  /** Explicit tile URL list. */
  tiles?: string[];

  /** Minimum zoom level. */
  minzoom?: number;

  /** Maximum zoom level. */
  maxzoom?: number;

  /** Tile size. */
  tileSize?: number;

  /** Tile scheme. */
  scheme?: 'xyz' | 'tms';

  /** DEM encoding. */
  encoding?: 'mapbox' | 'terrarium';
}

/**
 * RasterDemSource - loads digital elevation model (DEM) data.
 */
export class RasterDemSource {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Construct a raster DEM source.
   * @param id Source identifier.
   * @param options Optional configuration.
   */
  constructor(id: string, options?: RasterDemSourceOptions);

  /**
   * Get the source identifier.
   */
  getId(): string;

  /**
   * Reserved for internal native pointer access.
   */

  /**
   * Get the data URL.
   */
  getUrl(): string;

  /**
   * Set the data URL.
   * @param url Data URL.
   * @returns this (chainable).
   */
  setUrl(url: string): this;

  /** Set tile size in pixels. */
  setTileSize(tileSize: number): this;
}
