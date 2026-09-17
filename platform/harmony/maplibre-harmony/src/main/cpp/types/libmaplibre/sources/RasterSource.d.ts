/**
 * Raster tile source options.
 */
export interface RasterSourceOptions {
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
}

/**
 * RasterSource - loads raster tile imagery.
 */
export class RasterSource {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Construct a raster tile source.
   * @param id Source identifier.
   * @param options Optional configuration.
   */
  constructor(id: string, options?: RasterSourceOptions);

  /**
   * Get the source identifier.
   */
  getId(): string;

  /**
   * Reserved for internal native pointer access.
   */

  /**
   * Get the tile URL.
   */
  getUrl(): string;

  /**
   * Set the tile URL.
   * @param url Tile URL template.
   * @returns this (chainable).
   */
  setUrl(url: string): this;

  /**
   * Set tile size in pixels.
   * @param tileSize Tile size (pixels).
   * @returns this (chainable).
   */
  setTileSize(tileSize: number): this;
}
