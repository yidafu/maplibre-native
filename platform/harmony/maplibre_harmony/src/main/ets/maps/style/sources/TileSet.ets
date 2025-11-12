/**
 * TileSet - Configuration helper for tile sources
 *
 * Applies to both vector and raster tile sources
 */
export interface TileSetOptions {
  // Tile URL templates, supports {z}/{x}/{y} placeholders
  tiles: string[];

  // Minimum zoom level
  minzoom?: number;

  // Maximum zoom level
  maxzoom?: number;

  // Bounds [west, south, east, north]
  bounds?: number[];

  // Tile scheme: 'xyz' or 'tms'
  scheme?: string;

  // Attribution string
  attribution?: string;

  // Tile size in pixels
  tileSize?: number;

  // TileJSON specification version
  version?: string;

  // Human-readable name
  name?: string;

  // Description text
  description?: string;

  // Vector layer details
  vector_layers?: VectorLayer[];
}

/**
 * VectorLayer - Vector layer metadata
 */
export interface VectorLayer {
  id: string;
  fields?: Record<string, string>;
  description?: string;
  minzoom?: number;
  maxzoom?: number;
}

/**
 * TileSet class
 */
export class TileSet {
  private options: TileSetOptions;

  constructor(tiles: string[], minzoom?: number, maxzoom?: number) {
    this.options = {
      tiles: tiles,
      minzoom: minzoom,
      maxzoom: maxzoom
    };
  }

  /**
   * Create a TileSet from options
   */
  public static fromOptions(options: TileSetOptions): TileSet {
    const tileSet = new TileSet(options.tiles, options.minzoom, options.maxzoom);
    tileSet.options = options;
    return tileSet;
  }

  /**
   * Get tile URLs
   */
  public getTiles(): string[] {
    return this.options.tiles;
  }

  /**
   * Set bounds
   */
  public setBounds(bounds: number[]): void {
    this.options.bounds = bounds;
  }

  /**
   * Get bounds
   */
  public getBounds(): number[] | undefined {
    return this.options.bounds;
  }

  /**
   * Set the tiling scheme
   */
  public setScheme(scheme: string): void {
    this.options.scheme = scheme;
  }

  /**
   * Get the tiling scheme
   */
  public getScheme(): string | undefined {
    return this.options.scheme;
  }

  /**
   * Set attribution text
   */
  public setAttribution(attribution: string): void {
    this.options.attribution = attribution;
  }

  /**
   * Get attribution text
   */
  public getAttribution(): string | undefined {
    return this.options.attribution;
  }

  /**
   * Set tile size
   */
  public setTileSize(tileSize: number): void {
    this.options.tileSize = tileSize;
  }

  /**
   * Get tile size
   */
  public getTileSize(): number | undefined {
    return this.options.tileSize;
  }

  /**
   * Convert to a JSON-compatible object
   */
  public toJSON(): TileSetOptions {
    return this.options;
  }

  /**
   * Convert to string
   */
  public toString(): string {
    return `TileSet(tiles=${this.options.tiles.length}, minzoom=${this.options.minzoom}, maxzoom=${this.options.maxzoom})`;
  }
}

