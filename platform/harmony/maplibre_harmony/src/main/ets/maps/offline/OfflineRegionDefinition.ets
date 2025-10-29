/**
 * OfflineRegionDefinition - 离线区域定义
 * 
 * 从 NAPI 层重新导出类型
 */

import maplibre from 'libmaplibre.so';
import type { LatLngBounds } from '../geometry/LatLngBounds';

// 重新导出 NAPI 类型
export type { 
  OfflineRegionDefinition,
  OfflineTilePyramidRegionDefinition,
  OfflineGeometryRegionDefinition
} from 'libmaplibre.so';

/**
 * 创建瓦片金字塔区域定义的工厂函数
 */
export function createTilePyramidRegionDefinition(
  styleURL: string,
  bounds: LatLngBounds,
  minZoom: number = 0,
  maxZoom: number = 16,
  pixelRatio: number = 1.0,
  includeIdeographs: boolean = true
): maplibre.OfflineTilePyramidRegionDefinition {
  return {
    type: 'tilePyramid',
    styleURL,
    bounds: {
      north: bounds.north,
      east: bounds.east,
      south: bounds.south,
      west: bounds.west
    },
    minZoom,
    maxZoom,
    pixelRatio,
    includeIdeographs
  };
}
