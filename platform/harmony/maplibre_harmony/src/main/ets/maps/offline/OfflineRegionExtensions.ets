/**
 * OfflineRegion helper utilities.
 *
 * Provides helper methods for the NAPI OfflineRegion class.
 */

import type maplibre from 'libmaplibre.so';
import { DownloadState as OfflineRegionDownloadState } from './OfflineRegionStatus';

/**
 * OfflineRegion helper functions.
 */
export class OfflineRegionHelper {
  /**
   * Start downloading.
   */
  static download(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.ACTIVE);
  }

  /**
   * Pause downloading.
   */
  static pause(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.INACTIVE);
  }

  /**
   * Resume downloading.
   */
  static resume(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.ACTIVE);
  }

  /**
   * Retrieve the region ID.
   */
  static getId(region: maplibre.OfflineRegion): number {
    return region.id;
  }

  /**
   * Retrieve metadata.
   */
  static getMetadata(region: maplibre.OfflineRegion): ArrayBuffer {
    return region.metadata;
  }
}