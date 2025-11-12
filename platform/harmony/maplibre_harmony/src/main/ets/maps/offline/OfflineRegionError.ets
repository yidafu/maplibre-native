/**
 * OfflineRegionError - offline region error.
 *
 * Re-exported from the NAPI layer.
 */

// Re-export the NAPI interface.
export type { OfflineRegionError } from 'libmaplibre.so';

// Re-export error reasons (when provided).
export enum OfflineRegionErrorReason {
  Unknown = 'unknown',
  Network = 'network',
  Storage = 'storage',
  Style = 'style',
  TileCount = 'tile_count'
}
