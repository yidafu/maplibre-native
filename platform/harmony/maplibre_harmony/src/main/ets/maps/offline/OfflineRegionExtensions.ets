/**
 * OfflineRegion 辅助工具函数
 * 
 * 为 NAPI OfflineRegion 类提供辅助方法
 */

import type maplibre from 'libmaplibre.so';
import { DownloadState as OfflineRegionDownloadState } from './OfflineRegionStatus';

/**
 * OfflineRegion 辅助工具函数
 */
export class OfflineRegionHelper {
  /**
   * 开始下载
   */
  static download(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.ACTIVE);
  }
  
  /**
   * 暂停下载
   */
  static pause(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.INACTIVE);
  }
  
  /**
   * 恢复下载
   */
  static resume(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.ACTIVE);
  }
  
  /**
   * 获取 ID
   */
  static getId(region: maplibre.OfflineRegion): number {
    return region.id;
  }
  
  /**
   * 获取元数据
   */
  static getMetadata(region: maplibre.OfflineRegion): ArrayBuffer {
    return region.metadata;
  }
}