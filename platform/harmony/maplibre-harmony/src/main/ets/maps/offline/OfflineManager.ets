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
      const errorMsg = OfflineManager.describeError(error);
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
   * Extract a message from a caught NAPI exception.
   */
  private static describeError(error: Object): string {
    return error instanceof Error ? error.message : String(error);
  }

  /**
   * Shared promise wrapper for native calls that settle through a NAPI
   * callback carrying either a result payload or an error string.
   *
   * @param failLabel Callback-failure log label, e.g. 'list offline regions'.
   * @param syncErrorLabel Synchronous-exception log label, e.g. 'listing offline regions'.
   * @param invoke Invokes the native call, forwarding the result callback.
   * @param wrap Converts the native payload to the wrapper type.
   */
  private nativeStringCallback<N, R>(
    failLabel: string,
    syncErrorLabel: string,
    invoke: (onResult: (result: N | string) => void) => void,
    wrap: (native: N) => R
  ): Promise<R> {
    return new Promise((resolve, reject) => {
      try {
        invoke((result: N | string) => {
          if (typeof result === 'string') {
            // Error case.
            hilog.error(DOMAIN, 'OfflineManager', `Failed to ${failLabel}: ${result}`);
            reject(new Error(result));
          } else {
            // Success case - convert to wrapper type.
            resolve(wrap(result));
          }
        });
      } catch (error) {
        const errorMsg = OfflineManager.describeError(error);
        hilog.error(DOMAIN, 'OfflineManager', `Error ${syncErrorLabel}: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Shared promise wrapper for native calls that settle through an
   * `(error?: string)` NAPI callback.
   *
   * @param failLabel Callback-failure log label, e.g. 'pack database'; pass
   *   null to suppress the failure log (deleteOfflineRegion is silent).
   * @param syncErrorLabel Synchronous-exception log label; null suppresses.
   * @param invoke Invokes the native call, forwarding the completion callback.
   * @param onSuccess Optional success hook (extra logging, etc.).
   */
  private nativeVoidCallback(
    failLabel: string | null,
    syncErrorLabel: string | null,
    invoke: (onDone: (error?: string) => void) => void,
    onSuccess?: () => void
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        invoke((error?: string) => {
          if (error) {
            if (failLabel !== null) {
              hilog.error(DOMAIN, 'OfflineManager', `Failed to ${failLabel}: ${error}`);
            }
            reject(new Error(error));
          } else {
            if (onSuccess) {
              onSuccess();
            }
            resolve();
          }
        });
      } catch (error) {
        const errorMsg = OfflineManager.describeError(error);
        if (syncErrorLabel !== null) {
          hilog.error(DOMAIN, 'OfflineManager', `Error ${syncErrorLabel}: ${errorMsg}`);
        }
        reject(new Error(errorMsg));
      }
    });
  }

  /**
   * Shared synchronous wrapper: runs the native call and rethrows NAPI
   * exceptions with the given label.
   */
  private syncNativeCall(syncErrorLabel: string, invoke: () => void): void {
    try {
      invoke();
    } catch (error) {
      const errorMsg = OfflineManager.describeError(error);
      hilog.error(DOMAIN, 'OfflineManager', `Error ${syncErrorLabel}: ${errorMsg}`);
      throw new Error(errorMsg);
    }
  }

  /**
   * List all offline regions.
   *
   * @returns Promise<OfflineRegion[]> Wrapped offline regions.
   */
  public async listOfflineRegions(): Promise<OfflineRegion[]> {
    return this.nativeStringCallback<maplibre.OfflineRegion[], OfflineRegion[]>(
      'list offline regions',
      'listing offline regions',
      (onResult: (result: maplibre.OfflineRegion[] | string) => void) => {
        this.nativeManager.listOfflineRegions(onResult);
      },
      (nativeRegions: maplibre.OfflineRegion[]): OfflineRegion[] =>
        nativeRegions.map(nativeRegion => OfflineRegion.fromNative(nativeRegion))
    );
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
    return this.nativeStringCallback<maplibre.OfflineRegion, OfflineRegion>(
      'create offline region',
      'creating offline region',
      (onResult: (result: maplibre.OfflineRegion | string) => void) => {
        this.nativeManager.createOfflineRegion(definition, metadata, onResult);
      },
      (nativeRegion: maplibre.OfflineRegion): OfflineRegion => OfflineRegion.fromNative(nativeRegion)
    );
  }

  /**
   * Delete an offline region.
   *
   * @param region Offline region to remove (wrapped type).
   */
  public async deleteOfflineRegion(region: OfflineRegion): Promise<void> {
    return this.nativeVoidCallback(
      null,
      null,
      (onDone: (error?: string) => void) => {
        // Invoke the wrapper method directly.
        region.delete(onDone);
      }
    );
  }

  /**
   * Set the offline tile count limit.
   *
   * Helps prevent downloading excessive data.
   *
   * @param limit Maximum tile count (0 means unlimited).
   */
  public setOfflineMapboxTileCountLimit(limit: number): void {
    this.syncNativeCall('setting tile count limit', () => {
      this.nativeManager.setOfflineMapboxTileCountLimit(limit);
    });
  }

  /**
   * Reset the database.
   *
   * Removes all offline regions and cached data.
   * Warning: this operation is irreversible.
   */
  public async resetDatabase(): Promise<void> {
    return this.nativeVoidCallback(
      'reset database',
      'resetting database',
      (onDone: (error?: string) => void) => {
        this.nativeManager.resetDatabase(onDone);
      },
      (): void => {
        hilog.warn(DOMAIN, 'OfflineManager', 'Database reset successfully');
      }
    );
  }

  /**
   * Clear the ambient cache.
   *
   * Removes cached data that does not belong to any offline region.
   */
  public async clearAmbientCache(): Promise<void> {
    return this.nativeVoidCallback(
      'clear ambient cache',
      'clearing ambient cache',
      (onDone: (error?: string) => void) => {
        this.nativeManager.clearAmbientCache(onDone);
      }
    );
  }

  /**
   * Set the maximum ambient cache size.
   *
   * @param size Maximum size in bytes.
   */
  public setMaximumAmbientCacheSize(size: number): void {
    this.syncNativeCall('setting maximum ambient cache size', () => {
      this.nativeManager.setMaximumAmbientCacheSize(size, () => {
        // Callback placeholder.
      });
    });
  }

  /**
   * Invalidate the ambient cache.
   */
  public async invalidateAmbientCache(): Promise<void> {
    return this.nativeVoidCallback(
      'invalidate ambient cache',
      'invalidating ambient cache',
      (onDone: (error?: string) => void) => {
        this.nativeManager.invalidateAmbientCache(onDone);
      }
    );
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
    return this.nativeStringCallback<maplibre.OfflineRegion[], OfflineRegion[]>(
      'merge offline regions',
      'merging offline regions',
      (onResult: (result: maplibre.OfflineRegion[] | string) => void) => {
        this.nativeManager.mergeOfflineRegions(path, onResult);
      },
      (nativeRegions: maplibre.OfflineRegion[]): OfflineRegion[] => {
        const wrappedRegions = nativeRegions.map(nativeRegion => OfflineRegion.fromNative(nativeRegion));
        hilog.info(DOMAIN, 'OfflineManager', `Successfully merged ${wrappedRegions.length} offline regions`);
        return wrappedRegions;
      }
    );
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
    return this.nativeVoidCallback(
      'pack database',
      'packing database',
      (onDone: (error?: string) => void) => {
        this.nativeManager.packDatabase(onDone);
      },
      (): void => {
        hilog.info(DOMAIN, 'OfflineManager', 'Database packed successfully');
      }
    );
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
    this.syncNativeCall('setting auto-pack', () => {
      this.nativeManager.runPackDatabaseAutomatically(autopack);
    });
    hilog.info(DOMAIN, 'OfflineManager', `Auto-pack database set to: ${autopack}`);
  }
}
