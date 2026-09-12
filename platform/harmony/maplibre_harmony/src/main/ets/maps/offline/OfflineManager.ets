/**
 * OfflineManager - offline map manager.
 *
 * Singleton class that manages creation, listing, and deletion of offline regions.
 * Mirrors Android OfflineManager and iOS MLNOfflineStorage.
 */

import maplibre from 'libmaplibre.so';
import common from '@ohos.app.ability.common';
import { OfflineRegion } from './OfflineRegion';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * Merge offline regions callback.
 * Matches Android MergeOfflineRegionsCallback.
 */
export interface MergeOfflineRegionsCallback {
  /**
   * Called when the merge succeeds.
   * @param offlineRegions Merged offline regions.
   */
  onMerge(offlineRegions: OfflineRegion[]): void;

  /**
   * Called when the merge fails.
   * @param error Error message.
   */
  onError(error: string): void;
}

/**
 * File source operation callback.
 * Matches Android FileSourceCallback.
 */
export interface FileSourceCallback {
  /**
   * Called when the operation succeeds.
   */
  onSuccess(): void;

  /**
   * Called when the operation fails.
   * @param message Error message.
   */
  onError(message: string): void;
}
/**
 * OfflineManager class.
 *
 * Usage example:
 * ```typescript
 * // Obtain the instance.
 * const offlineManager = OfflineManager.getInstance(context);
 *
 * // List all offline regions.
 * const regions = await offlineManager.listOfflineRegions();
 *
 * // Create a new offline region.
 * const definition = new OfflineTilePyramidRegionDefinition(
 *   styleURL,
 *   bounds,
 *   0,  // minZoom
 *   16  // maxZoom
 * );
 *
 * const metadata = new TextEncoder().encode('My offline map').buffer;
 * const region = await offlineManager.createOfflineRegion(definition, metadata);
 *
 * // Start downloading.
 * region.download();
 * ```
 */
export class OfflineManager {
  private static instance: OfflineManager | null = null;
  private nativeManager: maplibre.OfflineManager; // NAPI object.
  private context: common.UIAbilityContext;

  /**
   * Private constructor (singleton pattern).
   */
  private constructor(context: common.UIAbilityContext) {
    this.context = context;

    try {
      // Create the NAPI offline manager instance.
      const dbPath = context.cacheDir + '/maplibre-offline.db';
      this.nativeManager = new maplibre.OfflineManager(dbPath);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineManager', `Failed to create OfflineManager: ${errorMsg}`);
      throw new Error(`Failed to create OfflineManager: ${errorMsg}`);
    }
  }

  /**
   * Retrieve the singleton instance.
   *
   * @param context Application context.
   * @returns OfflineManager instance.
   */
  public static getInstance(context: common.UIAbilityContext): OfflineManager {
    if (!OfflineManager.instance) {
      OfflineManager.instance = new OfflineManager(context);
    }
    return OfflineManager.instance;
  }

  /**
   * List all offline regions.
   *
   * @returns Promise<OfflineRegion[]> Wrapped offline regions.
   */
  public async listOfflineRegions(): Promise<OfflineRegion[]> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.listOfflineRegions((result: maplibre.OfflineRegion[] | string) => {
          if (typeof result === 'string') {
            // Error case.
            hilog.error(DOMAIN, 'OfflineManager', `Failed to list offline regions: ${result}`);
            reject(new Error(result));
          } else {
            // Success case - convert to wrapper type.
            const wrappedRegions = result.map(nativeRegion => OfflineRegion.fromNative(nativeRegion));
            resolve(wrappedRegions);
          }
        });
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error listing offline regions: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Create an offline region.
   *
   * @param definition Region definition.
   * @param metadata Metadata (optional, e.g. region name).
   * @returns Promise<OfflineRegion> Wrapped offline region.
   */
  public async createOfflineRegion(
    definition: maplibre.OfflineTilePyramidRegionDefinition,
    metadata: ArrayBuffer = new ArrayBuffer(0)
  ): Promise<OfflineRegion> {
    return new Promise((resolve, reject) => {
      try {
        const metadataBuffer = metadata;

        this.nativeManager.createOfflineRegion(
          definition,
          metadataBuffer,
          (result: maplibre.OfflineRegion | string) => {
            if (typeof result === 'string') {
              hilog.error(DOMAIN, 'OfflineManager', `Failed to create offline region: ${result}`);
              reject(new Error(result));
            } else {
              // Convert to wrapper type.
              const wrappedRegion = OfflineRegion.fromNative(result);
              resolve(wrappedRegion);
            }
          }
        );
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error creating offline region: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Delete an offline region.
   *
   * @param region Offline region to remove (wrapped type).
   */
  public async deleteOfflineRegion(region: OfflineRegion): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        // Invoke the wrapper method directly.
        region.delete((error?: string) => {
          if (error) {
            reject(new Error(error));
          } else {
            resolve();
          }
        });
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Set the offline tile count limit.
   *
   * Helps prevent downloading excessive data.
   *
   * @param limit Maximum tile count (0 means unlimited).
   */
  public setOfflineMapboxTileCountLimit(limit: number): void {
    try {
      this.nativeManager.setOfflineMapboxTileCountLimit(limit);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineManager', `Error setting tile count limit: ${errorMsg}`);
      throw new Error(errorMsg);
    }
  }

  /**
   * Reset the database.
   *
   * Removes all offline regions and cached data.
   * Warning: this operation is irreversible.
   */
  public async resetDatabase(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.resetDatabase((error?: string) => {
          if (error) {
            hilog.error(DOMAIN, 'OfflineManager', `Failed to reset database: ${error}`);
            reject(new Error(error));
          } else {
            hilog.warn(DOMAIN, 'OfflineManager', 'Database reset successfully');
            resolve();
          }
        });
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error resetting database: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Clear the ambient cache.
   *
   * Removes cached data that does not belong to any offline region.
   */
  public async clearAmbientCache(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.clearAmbientCache((error?: string) => {
          if (error) {
            hilog.error(DOMAIN, 'OfflineManager', `Failed to clear ambient cache: ${error}`);
            reject(new Error(error));
          } else {
            resolve();
          }
        });
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error clearing ambient cache: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Set the maximum ambient cache size.
   *
   * @param size Maximum size in bytes.
   */
  public setMaximumAmbientCacheSize(size: number): void {
    try {
      this.nativeManager.setMaximumAmbientCacheSize(size, () => {
        // Callback placeholder.
      });
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineManager', `Error setting maximum ambient cache size: ${errorMsg}`);
      throw new Error(errorMsg);
    }
  }

  /**
   * Invalidate the ambient cache.
   */
  public async invalidateAmbientCache(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.invalidateAmbientCache((error?: string) => {
          if (error) {
            hilog.error(DOMAIN, 'OfflineManager', `Failed to invalidate ambient cache: ${error}`);
            reject(new Error(error));
          } else {
            resolve();
          }
        });
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error invalidating ambient cache: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Merge offline regions from a secondary database into the primary database.
   *
   * Mirrors Android OfflineManager.mergeOfflineRegions(String, MergeOfflineRegionsCallback).
   *
   * **Capabilities**:
   * - Automatically upgrades the secondary database schema.
   * - Merges identical regions into a single entry.
   * - Checks tile count limits.
   * - Handles file permission issues.
   *
   * **Use cases**:
   * - Import offline data from other devices.
   * - Distribute pre-downloaded offline maps in batches.
   * - Combine multiple offline packages.
   *
   * @param path Secondary database file path.
   * @returns Promise<OfflineRegion[]> List of merged regions.
   *
   * @example
   * ```typescript
   * const offlineManager = OfflineManager.getInstance(context);
   * const mergedRegions = await offlineManager.mergeOfflineRegions('/path/to/secondary.db');
   * hilog.info(DOMAIN, 'OfflineManager', '%{public}s', `Merged ${mergedRegions.length} offline regions`);
   * ```
   */
  public async mergeOfflineRegions(path: string): Promise<OfflineRegion[]> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.mergeOfflineRegions(path, (result: maplibre.OfflineRegion[] | string) => {
          if (typeof result === 'string') {
            // Error case.
            hilog.error(DOMAIN, 'OfflineManager', `Failed to merge offline regions: ${result}`);
            reject(new Error(result));
          } else {
            // Success case - convert to wrapper type.
            const wrappedRegions = result.map(nativeRegion => OfflineRegion.fromNative(nativeRegion));
            hilog.info(DOMAIN, 'OfflineManager', `Successfully merged ${wrappedRegions.length} offline regions`);
            resolve(wrappedRegions);
          }
        });
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error merging offline regions: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Pack the database file to compress and reclaim space.
   *
   * Mirrors Android OfflineManager.packDatabase(FileSourceCallback).
   *
   * **Capabilities**:
   * - Executes VACUUM to compact the database.
   * - Reclaims space freed after region deletions.
   * - Impacts performance; recommended for background execution.
   *
   * **Use cases**:
   * - Reclaim space after deleting offline regions.
   * - Perform periodic database maintenance.
   * - Optimize storage performance.
   *
   * @returns Promise<void>
   *
   * @example
   * ```typescript
   * const offlineManager = OfflineManager.getInstance(context);
   *
   * // Pack the database after deleting regions.
   * await offlineManager.deleteOfflineRegion(region);
   * await offlineManager.packDatabase();
   * hilog.info(DOMAIN, 'OfflineManager', '%{public}s', 'Database compressed');
   * ```
   */
  public async packDatabase(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.packDatabase((error?: string) => {
          if (error) {
            hilog.error(DOMAIN, 'OfflineManager', `Failed to pack database: ${error}`);
            reject(new Error(error));
          } else {
            hilog.info(DOMAIN, 'OfflineManager', 'Database packed successfully');
            resolve();
          }
        });
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error packing database: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Configure whether to pack the database automatically.
   *
   * Mirrors Android OfflineManager.runPackDatabaseAutomatically(Boolean).
   *
   * **Capabilities**:
   * - Enabled by default (true).
   * - Automatically compresses the database after deletions or cache clears.
   * - When disabled, packDatabase() must be called manually.
   *
   * **Performance considerations**:
   * - Auto-packing introduces latency after deletion operations.
   * - Disabling it allows batching operations before manually packing, improving performance.
   *
   * @param autopack Whether to enable automatic packing.
   *
   * @example
   * ```typescript
   * const offlineManager = OfflineManager.getInstance(context);
   *
   * // Disable auto-pack during batch deletions.
   * offlineManager.runPackDatabaseAutomatically(false);
   *
   * for (const region of regionsToDelete) {
   *   await offlineManager.deleteOfflineRegion(region);
   * }
   *
   * // Manually pack once.
   * await offlineManager.packDatabase();
   *
   * // Re-enable auto-pack.
   * offlineManager.runPackDatabaseAutomatically(true);
   * ```
   */
  public runPackDatabaseAutomatically(autopack: boolean): void {
    try {
      this.nativeManager.runPackDatabaseAutomatically(autopack);
      hilog.info(DOMAIN, 'OfflineManager', `Auto-pack database set to: ${autopack}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineManager', `Error setting auto-pack: ${errorMsg}`);
      throw new Error(errorMsg);
    }
  }
}
