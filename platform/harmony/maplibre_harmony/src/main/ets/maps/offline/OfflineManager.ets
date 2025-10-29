/**
 * OfflineManager - 离线地图管理器
 * 
 * 单例类，管理所有离线地图区域的创建、列表和删除
 * 对应 Android 的 OfflineManager 和 iOS 的 MLNOfflineStorage
 */

import maplibre from 'libmaplibre.so';
import common from '@ohos.app.ability.common';
import { OfflineRegion } from './OfflineRegion';
import { OfflineRegionDefinition } from './OfflineRegionDefinition';
import { OfflineRegionStatus } from './OfflineRegionStatus';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * OfflineManager 类
 * 
 * 使用示例：
 * ```typescript
 * // 获取实例
 * const offlineManager = OfflineManager.getInstance(context);
 * 
 * // 列出所有离线区域
 * const regions = await offlineManager.listOfflineRegions();
 * 
 * // 创建新的离线区域
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
 * // 开始下载
 * region.download();
 * ```
 */
export class OfflineManager {
  private static instance: OfflineManager | null = null;
  private nativeManager: maplibre.OfflineManager; // NAPI 对象
  private context: common.UIAbilityContext;
  
  /**
   * 私有构造函数（单例模式）
   */
  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    
    try {
      // 创建 NAPI 离线管理器实例
      const dbPath = context.cacheDir + '/maplibre-offline.db';
      this.nativeManager = new maplibre.OfflineManager(dbPath);
      hilog.info(DOMAIN, 'OfflineManager', 'OfflineManager instance created');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineManager', `Failed to create OfflineManager: ${errorMsg}`);
      throw new Error(`Failed to create OfflineManager: ${errorMsg}`);
    }
  }
  
  /**
   * 获取单例实例
   * 
   * @param context 应用上下文
   * @returns OfflineManager 实例
   */
  public static getInstance(context: common.UIAbilityContext): OfflineManager {
    if (!OfflineManager.instance) {
      OfflineManager.instance = new OfflineManager(context);
    }
    return OfflineManager.instance;
  }
  
  /**
   * 列出所有离线区域
   * 
   * @returns Promise<OfflineRegion[]> 离线区域列表
   */
  public async listOfflineRegions(): Promise<OfflineRegion[]> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.listOfflineRegions((result: OfflineRegion[] | string) => {
          if (typeof result === 'string') {
            // 错误情况
            hilog.error(DOMAIN, 'OfflineManager', `Failed to list offline regions: ${result}`);
            reject(new Error(result));
          } else {
            // 成功情况 - result 已经是 OfflineRegion[] 数组
            hilog.info(DOMAIN, 'OfflineManager', `Found ${result.length} offline regions`);
            resolve(result);
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
   * 创建离线区域
   * 
   * @param definition 区域定义
   * @param metadata 元数据（可选，用于存储自定义信息如区域名称）
   * @returns Promise<OfflineRegion> 创建的离线区域
   */
  public async createOfflineRegion(
    definition: maplibre.OfflineTilePyramidRegionDefinition,
    metadata: ArrayBuffer = new ArrayBuffer(0)
  ): Promise<OfflineRegion> {
    return new Promise((resolve, reject) => {
      try {
        const metadataBuffer = metadata;
        
        hilog.info(DOMAIN, 'OfflineManager', 'Creating offline region...');
        
        this.nativeManager.createOfflineRegion(
          definition,
          metadataBuffer,
          (result: OfflineRegion | string) => {
            if (typeof result === 'string') {
              hilog.error(DOMAIN, 'OfflineManager', `Failed to create offline region: ${result}`);
              reject(new Error(result));
            } else {
              // result 已经是 OfflineRegion 对象
              hilog.info(DOMAIN, 'OfflineManager', 'Offline region created successfully');
              resolve(result);
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
   * 删除离线区域
   * 
   * @param region 要删除的离线区域
   */
  public async deleteOfflineRegion(region: OfflineRegion): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
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
   * 设置离线地图瓦片数量限制
   * 
   * 用于防止下载过多数据
   * 
   * @param limit 最大瓦片数量（0 表示无限制）
   */
  public setOfflineMapboxTileCountLimit(limit: number): void {
    try {
      this.nativeManager.setOfflineMapboxTileCountLimit(limit);
      hilog.info(DOMAIN, 'OfflineManager', `Tile count limit set to: ${limit}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineManager', `Error setting tile count limit: ${errorMsg}`);
      throw new Error(errorMsg);
    }
  }
  
  /**
   * 重置数据库
   * 
   * 删除所有离线区域和缓存数据
   * ⚠️ 警告：此操作不可逆
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
   * 清理缓存
   * 
   * 删除不属于任何离线区域的缓存数据
   */
  public async clearAmbientCache(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.clearAmbientCache((error?: string) => {
          if (error) {
            hilog.error(DOMAIN, 'OfflineManager', `Failed to clear ambient cache: ${error}`);
            reject(new Error(error));
          } else {
            hilog.info(DOMAIN, 'OfflineManager', 'Ambient cache cleared successfully');
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
   * 设置最大环境缓存大小
   * 
   * @param size 最大大小（字节）
   */
  public setMaximumAmbientCacheSize(size: number): void {
    try {
      this.nativeManager.setMaximumAmbientCacheSize(size, () => {
        // 回调
      });
      hilog.info(DOMAIN, 'OfflineManager', `Maximum ambient cache size set to: ${size} bytes`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineManager', `Error setting maximum ambient cache size: ${errorMsg}`);
      throw new Error(errorMsg);
    }
  }
  
  /**
   * 使环境缓存失效
   */
  public async invalidateAmbientCache(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeManager.invalidateAmbientCache((error?: string) => {
          if (error) {
            hilog.error(DOMAIN, 'OfflineManager', `Failed to invalidate ambient cache: ${error}`);
            reject(new Error(error));
          } else {
            hilog.info(DOMAIN, 'OfflineManager', 'Ambient cache invalidated successfully');
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
}
