/**
 * CustomGeometrySource option/callback interfaces.
 */
export interface TileID {
  z: number;
  x: number;
  y: number;
}

export interface CustomGeometrySourceCallbacks {
  fetchTile?: (tileID: TileID) => void;
  cancelTile?: (tileID: TileID) => void;
}

export interface CustomGeometrySourceOptions extends CustomGeometrySourceCallbacks {
  minzoom?: number;
  maxzoom?: number;
  buffer?: number;
  tolerance?: number;
  clip?: boolean;
  wrap?: boolean;
}

/**
 * CustomGeometrySource - a source whose tile geometry is supplied by the
 * application. The native layer invokes fetchTile/cancelTile on the JS
 * thread; tile data is pushed back with setTileData.
 */
export class CustomGeometrySource {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Construct a custom geometry source.
   * @param id Source identifier.
   * @param options Optional configuration (zoom range, tile options, callbacks).
   */
  constructor(id: string, options?: CustomGeometrySourceOptions);

  /**
   * Get the source identifier.
   */
  getId(): string;

  /**
   * Provide the geometry contents of a specific tile.
   * @param zoomLevel Tile zoom level.
   * @param x Tile X coordinate.
   * @param y Tile Y coordinate.
   * @param data GeoJSON payload (string or object).
   */
  setTileData(zoomLevel: number, x: number, y: number, data: string | Object): void;

  /**
   * Invalidate the geometry contents of a specific tile.
   */
  invalidateTile(zoomLevel: number, x: number, y: number): void;

  /**
   * Invalidate all tiles intersecting the given bounds.
   * @param bounds LatLngBounds-like object (north/south/east/west).
   */
  invalidateRegion(bounds: Object): void;

  /**
   * Query features from the source.
   * @param filter Optional filter expression array.
   */
  querySourceFeatures(filter?: Object[]): Object[];
}
