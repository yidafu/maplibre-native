/**
 * OfflineRegionError - 离线区域错误
 * 
 * 从 NAPI 层重新导出
 */

// 重新导出 NAPI 接口
export type { OfflineRegionError } from 'libmaplibre_native.so';

// 重新导出错误原因枚举（如果有的话）
export enum OfflineRegionErrorReason {
  Unknown = 'unknown',
  Network = 'network',
  Storage = 'storage',
  Style = 'style',
  TileCount = 'tile_count'
}
