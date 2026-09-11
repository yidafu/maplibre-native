/**
 * CustomGeometrySource - Wrapper for custom geometry sources
 *
 * Mirrors the Android CustomGeometrySource: the application supplies tile
 * geometry itself, either through a GeometryTileProvider or through explicit
 * fetchTile/cancelTile callbacks. Core requests tiles from tile worker
 * threads; the native layer marshals those requests onto the JS thread, so
 * the callbacks here always run single-threaded.
 */

import maplibre from 'libmaplibre.so';
import type { GeoJsonData } from './GeoJsonSource';

/**
 * Internal marker used to identify the fromNative factory
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * Tile identifier (z/x/y) as delivered to the fetchTile/cancelTile callbacks
 */
export interface TileID {
  /** Tile zoom level */
  z: number;
  /** Tile X coordinate */
  x: number;
  /** Tile Y coordinate */
  y: number;
}

/**
 * Tile data provider, mirroring Android's GeometryTileProvider.
 *
 * Called synchronously on the JS thread whenever the map needs tile data;
 * the returned GeoJSON is pushed into the source automatically.
 */
export interface GeometryTileProvider {
  getFeaturesForBounds(tileID: TileID, zoomLevel: number): GeoJsonData;
}

/**
 * Explicit tile callbacks (alternative to providing a GeometryTileProvider).
 *
 * With fetchTile, the application is responsible for eventually calling
 * setTileData (possibly asynchronously); cancelTile marks a tile request as
 * cancelled so later setTileData calls for it can be dropped.
 */
export interface CustomGeometrySourceCallbacks {
  fetchTile?: (tileID: TileID) => void;
  cancelTile?: (tileID: TileID) => void;
}

/**
 * CustomGeometrySource options - keys mirror Android's
 * CustomGeometrySourceOptions builder
 */
export interface CustomGeometrySourceOptions extends CustomGeometrySourceCallbacks {
  /** Minimum zoom level for tile creation (default 0) */
  minzoom?: number;
  /** Maximum zoom level for tile creation (default 18) */
  maxzoom?: number;
  /** Tile buffer size in 1/512ths of a tile (default 128) */
  buffer?: number;
  /** Douglas-Peucker simplification tolerance (default 0.375) */
  tolerance?: number;
  /** Clip geometry to tile boundaries (default false) */
  clip?: boolean;
  /** Unwrap wrapped coordinates (default false) */
  wrap?: boolean;
  /** Tile data provider (called synchronously on the JS thread) */
  provider?: GeometryTileProvider;
}

/**
 * LatLngBounds shape accepted by invalidateRegion
 */
export interface LatLngBoundsLike {
  north: number;
  south: number;
  east: number;
  west: number;
}

/**
 * CustomGeometrySource implementation
 */
export class CustomGeometrySource {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'CustomGeometrySource';
  private nativeInstance: maplibre.CustomGeometrySource;

  // Tiles whose last request was cancelled by core; a later setTileData for
  // one of these tiles is dropped (mirrors the Android isCancelled check)
  private cancelledTiles: Set<string> = new Set();

  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: CustomGeometrySourceOptions |
    maplibre.CustomGeometrySource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      this.nativeInstance = optionsOrNative as maplibre.CustomGeometrySource;
    } else if (typeof idOrMarker === 'string') {
      const options = (optionsOrNative ?? {}) as CustomGeometrySourceOptions;
      const nativeOptions: CustomGeometrySourceOptions = {};

      // Zoom range / tile options are forwarded to the core converter
      nativeOptions.minzoom = options.minzoom;
      nativeOptions.maxzoom = options.maxzoom;
      nativeOptions.buffer = options.buffer;
      nativeOptions.tolerance = options.tolerance;
      nativeOptions.clip = options.clip;
      nativeOptions.wrap = options.wrap;

      if (options.provider) {
        const provider = options.provider;
        // Provider flow: fetch the data synchronously and push it back
        nativeOptions.fetchTile = (tileID: TileID): void => {
          this.cancelledTiles.delete(this.tileKey(tileID));
          const data = provider.getFeaturesForBounds(tileID, tileID.z);
          this.pushTileData(tileID, data);
        };
        nativeOptions.cancelTile = (tileID: TileID): void => {
          this.cancelledTiles.add(this.tileKey(tileID));
        };
      } else {
        // Explicit callback flow
        if (options.fetchTile) {
          const userFetch = options.fetchTile;
          nativeOptions.fetchTile = (tileID: TileID): void => {
            this.cancelledTiles.delete(this.tileKey(tileID));
            userFetch(tileID);
          };
        }
        if (options.cancelTile) {
          const userCancel = options.cancelTile;
          nativeOptions.cancelTile = (tileID: TileID): void => {
            this.cancelledTiles.add(this.tileKey(tileID));
            userCancel(tileID);
          };
        }
      }

      this.nativeInstance = new maplibre.CustomGeometrySource(idOrMarker, nativeOptions);
    } else {
      throw new Error('Invalid CustomGeometrySource constructor arguments');
    }
  }

  /**
   * Create an empty CustomGeometrySource
   * @param id Source identifier
   * @param options Optional configuration
   */
  static create(id: string, options?: CustomGeometrySourceOptions): CustomGeometrySource {
    return new CustomGeometrySource(id, options);
  }

  /**
   * Create from a native instance (internal use)
   * @param nativeInstance Native CustomGeometrySource instance
   */
  static fromNative(nativeInstance: maplibre.CustomGeometrySource): CustomGeometrySource {
    return new CustomGeometrySource(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * Get the underlying native instance
   */
  getNative(): maplibre.CustomGeometrySource {
    return this.nativeInstance;
  }

  /**
   * Get the source identifier
   */
  getId(): string {
    return this.nativeInstance.getId();
  }

  private tileKey(tileID: TileID): string {
    return `${tileID.z}/${tileID.x}/${tileID.y}`;
  }

  /**
   * Push tile data unless the request for this tile was cancelled meanwhile
   */
  private pushTileData(tileID: TileID, data: GeoJsonData): void {
    if (this.cancelledTiles.has(this.tileKey(tileID))) {
      // Request was cancelled - drop the stale data (Android isCancelled)
      this.cancelledTiles.delete(this.tileKey(tileID));
      return;
    }
    this.nativeInstance.setTileData(tileID.z, tileID.x, tileID.y, data);
  }

  /**
   * Set or update geometry contents of a specific tile.
   * Can be called from asynchronous application code after fetchTile.
   *
   * @param zoomLevel Tile zoom level
   * @param x Tile X coordinate
   * @param y Tile Y coordinate
   * @param data GeoJSON feature collection for the tile
   */
  setTileData(zoomLevel: number, x: number, y: number, data: GeoJsonData): CustomGeometrySource {
    const key = `${zoomLevel}/${x}/${y}`;
    if (this.cancelledTiles.has(key)) {
      this.cancelledTiles.delete(key);
      return this;
    }
    this.nativeInstance.setTileData(zoomLevel, x, y, data);
    return this;
  }

  /**
   * Invalidate the geometry contents of a specific tile, triggering new
   * requests for visible tiles.
   *
   * @param zoomLevel Tile zoom level
   * @param x Tile X coordinate
   * @param y Tile Y coordinate
   */
  invalidateTile(zoomLevel: number, x: number, y: number): CustomGeometrySource {
    this.nativeInstance.invalidateTile(zoomLevel, x, y);
    return this;
  }

  /**
   * Invalidate previously provided features within the given bounds at all
   * zoom levels.
   *
   * @param bounds Region in which features should be invalidated
   */
  invalidateRegion(bounds: LatLngBoundsLike): CustomGeometrySource {
    this.nativeInstance.invalidateRegion(bounds);
    return this;
  }

  /**
   * Query features from the source
   *
   * @param filter Optional expression filter array
   * @returns Array of features
   */
  querySourceFeatures(filter?: Object[]): Object[] {
    return this.nativeInstance.querySourceFeatures(filter);
  }
}
