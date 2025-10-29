/**
 * OfflineRegion 扩展方法
 * 
 * 为 NAPI OfflineRegion 类提供辅助方法
 */

import type maplibre from 'libmaplibre_native.so';
import { OfflineRegionDownloadState } from './OfflineRegionStatus';

/**
 * 扩展 OfflineRegion 接口
 */
declare module 'libmaplibre_native.so' {
  interface OfflineRegion {
    /**
     * 开始下载（辅助方法）
     */
    download(): void;
    
    /**
     * 暂停下载（辅助方法）
     */
    pause(): void;
    
    /**
     * 恢复下载（辅助方法）
     */
    resume(): void;
    
    /**
     * 获取 ID（辅助方法）
     */
    getId(): number;
    
    /**
     * 获取元数据（辅助方法）
     */
    getMetadata(): ArrayBuffer;
  }
}

/**
 * 添加扩展方法到 OfflineRegion 原型
 */
export function initializeOfflineRegionExtensions() {
  // 这个函数需要在应用启动时调用一次
  // 但由于 NAPI 对象无法直接扩展原型，我们使用包装函数
}

/**
 * OfflineRegion 辅助工具函数
 */
export class OfflineRegionHelper {
  /**
   * 开始下载
   */
  static download(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.Active);
  }
  
  /**
   * 暂停下载
   */
  static pause(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.Inactive);
  }
  
  /**
   * 恢复下载
   */
  static resume(region: maplibre.OfflineRegion): void {
    region.setDownloadState(OfflineRegionDownloadState.Active);
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

