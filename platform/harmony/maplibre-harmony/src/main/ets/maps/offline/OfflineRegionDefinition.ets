/**
 * OfflineRegionDefinition - offline region definition.
 *
 * Re-exports types from the NAPI layer.
 */

import maplibre from 'libmaplibre.so';
import type { LatLngBounds } from '../geometry/LatLngBounds';

// Re-export NAPI types.
export type {
  OfflineRegionDefinition,
  OfflineTilePyramidRegionDefinition,
  OfflineGeometryRegionDefinition
} from 'libmaplibre.so';

/**
 * LatLngBoundsLike - boundary interface.
 */
interface LatLngBoundsLike {
  north: number;
  east: number;
  south: number;
  west: number;
}

/**
 * Factory for creating tile pyramid region definitions.
 */
export function createTilePyramidRegionDefinition(
  styleURL: string,
  bounds: LatLngBounds,
  minZoom: number = 0,
  maxZoom: number = 16,
  pixelRatio: number = 1.0,
  includeIdeographs: boolean = true
): maplibre.OfflineTilePyramidRegionDefinition {
  const boundsObj: LatLngBoundsLike = {
    north: bounds.north,
    east: bounds.east,
    south: bounds.south,
    west: bounds.west
  };

  return {
    type: 'tilePyramid',
    styleURL,
    bounds: boundsObj,
    minZoom,
    maxZoom,
    pixelRatio,
    includeIdeographs
  };
}
