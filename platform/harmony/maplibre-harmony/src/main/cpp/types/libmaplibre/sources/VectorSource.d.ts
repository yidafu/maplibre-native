/**
 * Vector tile source options.
 */
export interface VectorSourceOptions {
  /** Tile URL template. */
  url?: string;

  /** Explicit tile URL list. */
  tiles?: string[];

  /** Minimum zoom level. */
  minzoom?: number;

  /** Maximum zoom level. */
  maxzoom?: number;

  /** Tile scheme. */
  scheme?: 'xyz' | 'tms';

  /** Bounds [west, south, east, north]. */
  bounds?: [number, number, number, number];
}

/**
 * VectorSource - loads Mapbox Vector Tiles (MVT) data.
 */
export class VectorSource {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Construct a vector tile source.
   * @param id Source identifier.
   * @param options Optional configuration.
   */
  constructor(id: string, options?: VectorSourceOptions);

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
   * Set the tile URL array.
   * @param tiles Tile URL list.
   * @returns this (chainable).
   */
  setTiles(tiles: string[]): this;

  /** Set minimum zoom level. */
  setMinZoom(minZoom: number): this;

  /** Set maximum zoom level. */
  setMaxZoom(maxZoom: number): this;
}
