/**
 * OfflineRegion - offline region wrapper.
 *
 * Wraps the NAPI OfflineRegion class, providing offline map download and management functionality.
 */
import maplibre from 'libmaplibre.so';
import { OfflineRegionDefinition } from './OfflineRegionDefinition';
import { OfflineRegionStatus } from './OfflineRegionStatus';
import type { OfflineRegionObserver } from './OfflineRegionObserver';
/**
 * Download state enumeration.
 */
export enum DownloadState {
  /** Inactive state (paused). */
  INACTIVE = 0,
  /** Active state (downloading). */
  ACTIVE = 1
}

/**
 * Callback type definitions.
 */
export type OfflineRegionStatusCallback = (result: OfflineRegionStatus | string) => void;

export type OfflineRegionDeleteCallback = (error?: string) => void;

export type OfflineRegionInvalidateCallback = (error?: string) => void;

export type OfflineRegionUpdateMetadataCallback = (result: ArrayBuffer | string) => void;

/**
 * OfflineRegion wrapper class.
 */
export class OfflineRegion {
  private nativeInstance: maplibre.OfflineRegion;

  /**
   * Private constructor.
   * Instances are created by OfflineManager.
   */
  private constructor(nativeInstance: maplibre.OfflineRegion) {
    this.nativeInstance = nativeInstance;
  }

  /**
   * Create a wrapper from a NAPI instance (internal use).
   */
  static fromNative(nativeInstance: maplibre.OfflineRegion): OfflineRegion {
    return new OfflineRegion(nativeInstance);
  }

  /**
   * Retrieve the underlying NAPI instance (internal use).
   */
  getNative(): maplibre.OfflineRegion {
    return this.nativeInstance;
  }

  /**
   * Get the region ID.
   */
  get id(): number {
    return this.nativeInstance.id;
  }

  /**
   * Get the region definition.
   */
  get definition(): OfflineRegionDefinition {
    return this.nativeInstance.definition;
  }

  /**
   * Get region metadata.
   */
  get metadata(): ArrayBuffer {
    return this.nativeInstance.metadata;
  }

  /**
   * Set region metadata.
   */
  set metadata(value: ArrayBuffer) {
    this.nativeInstance.metadata = value;
  }

  /**
   * Set the download state.
   *
   * @param state Download state (ACTIVE starts downloading, INACTIVE pauses).
   */
  setDownloadState(state: DownloadState): void {
    this.nativeInstance.setDownloadState(state);
  }

  /**
   * Attach an observer.
   *
   * @param observer Observer instance.
   */
  setObserver(observer: OfflineRegionObserver): void {
    this.nativeInstance.setObserver(observer);
  }

  /**
   * Retrieve region status.
   *
   * @param callback Callback function.
   */
  getStatus(callback: OfflineRegionStatusCallback): void {
    this.nativeInstance.getStatus(callback);
  }

  /**
   * Delete this offline region.
   *
   * @param callback Callback function.
   */
  delete(callback: OfflineRegionDeleteCallback): void {
    this.nativeInstance.delete(callback);
  }

  /**
   * Invalidate the region (force revalidation).
   *
   * @param callback Callback function.
   */
  invalidate(callback: OfflineRegionInvalidateCallback): void {
    this.nativeInstance.invalidate(callback);
  }

  /**
   * Update metadata.
   *
   * @param metadata New metadata.
   * @param callback Callback function.
   */
  updateMetadata(metadata: ArrayBuffer, callback: OfflineRegionUpdateMetadataCallback): void {
    this.nativeInstance.updateMetadata(metadata, callback);
  }

  /**
   * Convert to string.
   */
  toString(): string {
    return `OfflineRegion(id=${this.id})`;
  }
}
