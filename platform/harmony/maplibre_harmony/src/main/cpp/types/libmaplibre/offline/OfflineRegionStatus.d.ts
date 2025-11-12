/**
 * OfflineRegionStatus - offline region status type definitions.
 *
 * Conveys download progress and status information for an offline region.
 */

/**
 * Offline region status details, including download progress and resource counts.
 */
export interface OfflineRegionStatus {
  /**
   * Download state (0 = INACTIVE, 1 = ACTIVE).
   */
  downloadState: number;

  /**
   * Number of completed resources (tiles plus ancillary assets such as fonts and sprites).
   */
  completedResourceCount: number;

  /**
   * Total size of completed resources in bytes (useful for displaying downloaded data volume).
   */
  completedResourceSize: number;

  /**
   * Completed tile count (map tiles only).
   */
  completedTileCount: number;

  /**
   * Total size of completed tiles in bytes (typically the bulk of the download).
   */
  completedTileSize: number;

  /**
   * Total required resource count (estimated; may adjust as downloads progress).
   */
  requiredResourceCount: number;

  /**
   * Total required tile count (estimated number of tiles to download).
   */
  requiredTileCount: number;

  /**
   * Whether the required resource count is precise.
   * true indicates an exact count; false means the value is an estimate.
   */
  requiredResourceCountIsPrecise: boolean;

  /**
   * Completion flag (true when all resources are downloaded).
   */
  complete: boolean;
}

/**
 * Example helper for computing download progress percentage.
 *
 * @example
* const progress = status.requiredResourceCount > 0
 *   ? (status.completedResourceCount / status.requiredResourceCount) * 100
 *   : 0;
 */

