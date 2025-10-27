/**
 * Offline - 离线地图模块
 * 
 * 提供离线地图下载、管理和使用功能
 */

export { OfflineManager, getOfflineManager } from './OfflineManager';
export type {
  ListOfflineRegionsCallback,
  CreateOfflineRegionCallback,
  MergeOfflineRegionsCallback,
  FileSourceCallback
} from './OfflineManager';

export { OfflineRegion, DownloadState } from './OfflineRegion';
export type {
  OfflineRegionStatus,
  OfflineRegionStatusCallback,
  OfflineRegionDeleteCallback,
  OfflineRegionInvalidateCallback,
  OfflineRegionUpdateMetadataCallback,
  OfflineRegionError,
  OfflineRegionObserver
} from './OfflineRegion';

export type {
  OfflineRegionDefinition,
  OfflineTilePyramidRegionDefinition,
  OfflineGeometryRegionDefinition
} from './OfflineRegionDefinition';

export {
  createTilePyramidRegionDefinition,
  createGeometryRegionDefinition
} from './OfflineRegionDefinition';

