/**
 * Offline - offline map module.
 *
 * Exports offline map-related classes and interfaces.
 */

export { OfflineManager } from './OfflineManager';

export type {
  MergeOfflineRegionsCallback,
  FileSourceCallback
} from './OfflineManager';

export { OfflineRegion } from './OfflineRegion';

export { createTilePyramidRegionDefinition } from './OfflineRegionDefinition';

export type {
  OfflineRegionDefinition, OfflineTilePyramidRegionDefinition
} from './OfflineRegionDefinition';

export { DownloadState, OfflineRegionStatus } from './OfflineRegionStatus';

export type { OfflineRegionObserver } from './OfflineRegionObserver';

export type { OfflineRegionError } from './OfflineRegionError';

export { OfflineRegionErrorReason } from './OfflineRegionError';
