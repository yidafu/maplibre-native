/**
 * OfflineManager - offline map manager type definitions.
 *
 * Provides global management for offline maps, including region creation/listing/merging and database maintenance.
 */

import type { OfflineRegion } from './OfflineRegion';
import type { OfflineRegionDefinition } from './OfflineRegionDefinition';

/**
 * Callback for listing offline regions.
 *
 * @param result Offline region array on success, or an error message string on failure.
 */
export type ListOfflineRegionsCallback = (result: OfflineRegion[] | string) => void;

/**
 * Callback for creating an offline region.
 *
 * @param result Newly created offline region on success, or an error message string on failure.
 */
export type CreateOfflineRegionCallback = (result: OfflineRegion | string) => void;

/**
 * Callback for fetching a single offline region.
 *
 * @param result Offline region on success, null if not found, or an error message string on failure.
 */
export type GetOfflineRegionCallback = (result: OfflineRegion | string | null) => void;

/**
 * Callback for merging offline regions.
 *
 * @param result Merged offline region array on success, or an error message string on failure.
 */
export type MergeOfflineRegionsCallback = (result: OfflineRegion[] | string) => void;

/**
 * Callback for file source operations.
 *
 * @param error Undefined on success, or an error message string on failure.
 */
export type FileSourceCallback = (error?: string) => void;

/**
 * OfflineManager - offline map manager.
 *
 * Exposed via NAPI, providing global management for offline maps:
 * - Create and manage offline regions.
 * - Database maintenance (pack, clear, reset).
 * - Ambient cache management.
 * - Merge multiple offline databases.
 */
export class OfflineManager {
  /**
   * Constructor.
   *
   * Creates an offline manager instance.
   *
   * @param cachePath Database cache file path (absolute path), e.g. "/data/storage/el2/base/files/maplibre-offline.db".
   *
   * @example
* const manager = new OfflineManager(context.filesDir + '/offline.db');
   */
  constructor(cachePath: string);

  /**
   * List all offline regions.
   *
   * Fetch every offline region stored in the database asynchronously.
   *
   * @param callback Receives the region array on success, or an error message string on failure.
   *
   * @example
* manager.listOfflineRegions((result) => {
   *   if (typeof result === 'string') {
   *     console.error('Error:', result);
   *   } else {
   *     console.log(`Found ${result.length} regions`);
   *   }
   * });
   */
  listOfflineRegions(callback: ListOfflineRegionsCallback): void;

  /**
   * Create an offline region.
   *
   * Inserts a new offline region into the database.
   * Invoke setDownloadState(ACTIVE) afterwards to begin downloading.
   *
   * @param definition Region definition specifying bounds, zoom range, etc.
   * @param metadata Metadata (ArrayBuffer) storing region name, description, or other custom info.
   * @param callback Receives the newly created region on success, or an error message on failure.
   *
   * @example
* const encoder = new TextEncoder();
   * const metadata = encoder.encode(JSON.stringify({ name: 'Beijing Area' })).buffer;
   *
   * manager.createOfflineRegion(definition, metadata, (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Failed:', result);
   *   } else {
   *     console.log('Region created:', result.id);
   *     result.setDownloadState(DownloadState.ACTIVE);
   *   }
   * });
   */
  createOfflineRegion(
    definition: OfflineRegionDefinition,
    metadata: ArrayBuffer,
    callback: CreateOfflineRegionCallback
  ): void;

  /**
   * Fetch an offline region by ID.
   *
   * @param regionId Unique region identifier (assigned at creation).
   * @param callback Receives the region on success, null when not found, or an error message on failure.
   *
   * @example
* manager.getOfflineRegion(123, (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Error:', result);
   *   } else if (result === null) {
   *     console.log('Region not found');
   *   } else {
   *     console.log('Found region:', result.id);
   *   }
   * });
   */
  getOfflineRegion(regionId: number, callback: GetOfflineRegionCallback): void;

  /**
   * Merge offline regions from another database.
   *
   * Imports regions from a separate database file into the current database, useful for migration or syncing devices.
   *
   * @param path Absolute path to the database file to merge.
   * @param callback Receives the merged region list on success, or an error message on failure.
   *
   * @example
* manager.mergeOfflineRegions('/path/to/other.db', (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Merge failed:', result);
   *   } else {
   *     console.log(`Merged ${result.length} regions`);
   *   }
   * });
   */
  mergeOfflineRegions(path: string, callback: MergeOfflineRegionsCallback): void;

  /**
   * Reset the database (removes all data).
   *
   * Clears the database, deleting every offline region and downloaded resource.
   * Warning: irreversible operation.
   *
   * @param callback Called with undefined on success or an error message string on failure.
   *
   * @example
* manager.resetDatabase((error) => {
   *   if (error) {
   *     console.error('Reset failed:', error);
   *   } else {
   *     console.log('Database reset successfully');
   *   }
   * });
   */
  resetDatabase(callback: FileSourceCallback): void;

  /**
   * Pack the database to reclaim space.
   *
   * Executes a VACUUM operation to recover space from deleted data.
   * Recommended periodically or after removing large datasets.
   *
   * @param callback Called with undefined on success or an error message string on failure.
   *
   * @example
* manager.packDatabase((error) => {
   *   if (error) {
   *     console.error('Pack failed:', error);
   *   } else {
   *     console.log('Database packed successfully');
   *   }
   * });
   */
  packDatabase(callback: FileSourceCallback): void;

  /**
   * Invalidate the ambient cache (force revalidation).
   *
   * Marks all ambient cache entries as expired so they are revalidated on next use.
   *
   * @param callback Called with undefined on success or an error message string on failure.
   */
  invalidateAmbientCache(callback: FileSourceCallback): void;

  /**
   * Clear the ambient cache.
   *
   * Removes every resource stored in the ambient cache.
   * Note: does not affect resources explicitly downloaded for offline regions.
   *
   * @param callback Called with undefined on success or an error message string on failure.
   *
   * @example
* manager.clearAmbientCache((error) => {
   *   if (error) {
   *     console.error('Clear failed:', error);
   *   } else {
   *     console.log('Ambient cache cleared');
   *   }
   * });
   */
  clearAmbientCache(callback: FileSourceCallback): void;

  /**
   * Set the maximum ambient cache size.
   *
   * Limits the disk space used by the ambient cache; oldest resources are evicted when exceeded.
   *
   * @param size Size in bytes (e.g. 50 * 1024 * 1024 for 50 MB).
   * @param callback Called with undefined on success or an error message string on failure.
   *
   * @example
* // Set to 50 MB
   * manager.setMaximumAmbientCacheSize(50 * 1024 * 1024, (error) => {
   *   if (error) {
   *     console.error('Set size failed:', error);
   *   }
   * });
   */
  setMaximumAmbientCacheSize(size: number, callback: FileSourceCallback): void;

  /**
   * Set the offline tile count limit.
   *
   * Restricts how many tiles a single offline region may download.
   * When exceeded, observers receive the mapboxTileCountLimitExceeded callback.
   *
   * @param limit Tile limit (e.g. 6000).
   *
   * @example
* // Limit to 6000 tiles.
   * manager.setOfflineMapboxTileCountLimit(6000);
   */
  setOfflineMapboxTileCountLimit(limit: number): void;

  /**
   * Enable or disable automatic database packing.
   *
   * When enabled, the system performs database packing at suitable times to maintain performance.
   *
   * @param autopack True to enable automatic packing, false to disable.
   *
   * @example
* // Enable automatic packing
   * manager.runPackDatabaseAutomatically(true);
   */
  runPackDatabaseAutomatically(autopack: boolean): void;
}

