/**
 * OfflineRegion - offline map region type definitions.
 *
 * Represents an offline map region, exposing download control and status query capabilities.
 */

import type { OfflineRegionDefinition } from './OfflineRegionDefinition';
import type { OfflineRegionStatus } from './OfflineRegionStatus';

/**
 * Download state enum controlling offline region behavior.
 */
export enum DownloadState {
  /**
   * Inactive state (paused) — no resources are downloaded.
   */
  INACTIVE = 0,

  /**
   * Active state (downloading) — start or resume downloading resources.
   */
  ACTIVE = 1
}

/**
 * Offline region error details describing download failures.
 */
export interface OfflineRegionError {
  /**
   * Error reason category, e.g. "network", "storage", "style".
   */
  reason: string;

  /**
   * Detailed error message describing the failure.
   */
  message: string;
}

/**
 * Offline region observer interface.
 *
 * Receives download progress, error, and state change notifications.
 */
export interface OfflineRegionObserver {
  /**
   * Status change callback, invoked when download progress updates.
   *
   * @param status Latest status information including progress metrics.
   */
  onStatusChanged(status: OfflineRegionStatus): void;

  /**
   * Error callback, fired when a download error occurs.
   * Some errors are recoverable and downloads may retry automatically.
   *
   * @param error Error descriptor.
   */
  onError(error: OfflineRegionError): void;

  /**
   * Tile count limit callback, triggered when the downloaded tile count exceeds the configured limit.
   *
   * @param limit Tile count limit.
   */
  mapboxTileCountLimitExceeded(limit: number): void;
}

/**
 * Callback for retrieving region status.
 */
export type OfflineRegionStatusCallback = (result: OfflineRegionStatus | string) => void;

/**
 * Callback for delete operations.
 */
export type OfflineRegionDeleteCallback = (error?: string) => void;

/**
 * Callback for invalidate operations.
 */
export type OfflineRegionInvalidateCallback = (error?: string) => void;

/**
 * Callback for metadata updates.
 */
export type OfflineRegionUpdateMetadataCallback = (result: ArrayBuffer | string) => void;

/**
 * OfflineRegion - offline map region instance.
 *
 * Exposed via NAPI; manages download control, progress queries, and metadata for a region.
 */
export class OfflineRegion {
  /**
   * Region identifier (read-only).
   *
   * Unique numeric ID persisted in the database.
   */
  readonly id: number;

  /**
   * Region definition (read-only).
   *
   * Contains bounds, zoom range, and related configuration; immutable after creation.
   */
  readonly definition: OfflineRegionDefinition;

  /**
   * Metadata.
   *
   * Custom user data such as region name or description, stored as an ArrayBuffer (often JSON-encoded).
   */
  metadata: ArrayBuffer;

  /**
   * Set the download state.
   *
   * Controls whether downloading is active or paused.
   *
   * @param state Download state (ACTIVE to start/resume, INACTIVE to pause).
   *
   * @example
* // Start download
   * region.setDownloadState(DownloadState.ACTIVE);
   *
   * // Pause download
   * region.setDownloadState(DownloadState.INACTIVE);
   */
  setDownloadState(state: DownloadState): void;

  /**
   * Set the offline region observer.
   *
   * Registers an observer to receive progress and error notifications.
   *
   * @param observer Object implementing the OfflineRegionObserver interface.
   *
   * @example
* region.setObserver({
   *   onStatusChanged: (status) => {
   *     console.log(`Progress: ${status.completedResourceCount}/${status.requiredResourceCount}`);
   *   },
   *   onError: (error) => {
   *     console.error(`Error: ${error.message}`);
   *   },
   *   mapboxTileCountLimitExceeded: (limit) => {
   *     console.warn(`Tile limit exceeded: ${limit}`);
   *   }
   * });
   */
  setObserver(observer: OfflineRegionObserver): void;

  /**
   * Retrieve the region status asynchronously.
   *
   * @param callback Receives the status object on success or an error message string on failure.
   *
   * @example
* region.getStatus((result) => {
   *   if (typeof result === 'string') {
   *     console.error('Failed to get status:', result);
   *   } else {
   *     console.log('Status:', result);
   *   }
   * });
   */
  getStatus(callback: OfflineRegionStatusCallback): void;

  /**
   * Delete this offline region.
   *
   * Removes the region and all downloaded resources from the database.
   * Warning: irreversible.
   *
   * @param callback Receives an error message string if deletion fails.
   *
   * @example
* region.delete((error) => {
   *   if (error) {
   *     console.error('Failed to delete:', error);
   *   } else {
   *     console.log('Region deleted successfully');
   *   }
   * });
   */
  delete(callback: OfflineRegionDeleteCallback): void;

  /**
   * Invalidate the region (force revalidation).
   *
   * Marks all downloaded resources as expired so they will be revalidated on next use.
   *
   * @param callback Receives an error message string when invalidation fails.
   */
  invalidate(callback: OfflineRegionInvalidateCallback): void;

  /**
   * Update region metadata.
   *
   * @param metadata New metadata in ArrayBuffer form.
   * @param callback Returns the updated metadata on success, or an error message string.
   *
   * @example
* const encoder = new TextEncoder();
   * const newMetadata = encoder.encode(JSON.stringify({ name: 'New Name' })).buffer;
   * region.updateMetadata(newMetadata, (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Failed to update:', result);
   *   } else {
   *     console.log('Metadata updated');
   *   }
   * });
   */
  updateMetadata(metadata: ArrayBuffer, callback: OfflineRegionUpdateMetadataCallback): void;
}

