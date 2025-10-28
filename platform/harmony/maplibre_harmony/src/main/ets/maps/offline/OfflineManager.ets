/**
 * OfflineManager - 离线地图管理器
 * 
 * 封装 NAPI OfflineManager，提供类型安全的接口
 */
import maplibre from 'libmaplibre_native.so';
import { OfflineRegion } from './OfflineRegion';
import { OfflineRegionDefinition } from './OfflineRegionDefinition';
import common from '@ohos.app.ability.common';

/**
 * 列出离线区域的回调接口
 */
export interface ListOfflineRegionsCallback {
  /**
   * 成功获取离线区域列表
   * @param regions 离线区域数组
   */
  onList(regions: Array<OfflineRegion>): void;
  
  /**
   * 获取失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * 创建离线区域的回调接口
 */
export interface CreateOfflineRegionCallback {
  /**
   * 成功创建离线区域
   * @param region 新创建的离线区域
   */
  onCreate(region: OfflineRegion): void;
  
  /**
   * 创建失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * 合并离线区域的回调接口
 */
export interface MergeOfflineRegionsCallback {
  /**
   * 成功合并离线区域
   * @param regions 合并后的离线区域数组
   */
  onMerge(regions: Array<OfflineRegion>): void;
  
  /**
   * 合并失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * 数据库操作回调接口
 */
export interface FileSourceCallback {
  /**
   * 操作成功
   */
  onSuccess(): void;
  
  /**
   * 操作失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * OfflineManager - 离线地图管理器
 */
export class OfflineManager {
  private nativeManager: ESObject;
  
  /**
   * 构造函数
   * @param cachePath 数据库路径
   */
  constructor(cachePath: string) {
    this.nativeManager = new maplibre.OfflineManager(cachePath) as ESObject;
  }
  
  /**
   * 列出所有离线区域
   * @param callback 简化回调函数
   */
  public listOfflineRegions(callback: (result: OfflineRegion[] | string) => void): void {
    this.nativeManager.listOfflineRegions((result: ESObject | string) => {
      if (typeof result === 'string') {
        callback(result);
      } else if (Array.isArray(result)) {
        const regions: OfflineRegion[] = (result as ESObject[]).map((r: ESObject) => new OfflineRegion(r));
        callback(regions);
      } else {
        callback('Unknown error occurred');
      }
    });
  }
  
  /**
   * 创建离线区域
   * @param definition 区域定义
   * @param metadata 元数据
   * @param callback 简化回调函数
   */
  public createOfflineRegion(
    definition: OfflineRegionDefinition,
    metadata: ArrayBuffer,
    callback: CreateOfflineRegionCallback
  ): void {
    this.nativeManager.createOfflineRegion(
      definition,
      metadata,
      (result: ESObject | string) => {
        if (typeof result === 'string') {
          callback.onError(result);
        } else {
          callback.onCreate(new OfflineRegion(result));
        }
      }
    );
  }
  
  /**
   * 获取指定 ID 的离线区域
   * @param regionId 区域 ID
   * @param callback 回调函数
   */
  public getOfflineRegion(regionId: number, callback: (region: OfflineRegion | null, error?: string) => void): void {
    this.nativeManager.getOfflineRegion(regionId, (result: ESObject | string | null) => {
      if (typeof result === 'string') {
        callback(null, result);
      } else if (result === null) {
        callback(null);
      } else {
        callback(new OfflineRegion(result));
      }
    });
  }
  
  /**
   * 合并其他数据库的离线区域
   * @param path 数据库文件路径
   * @param callback 回调接口
   */
  public mergeOfflineRegions(path: string, callback: MergeOfflineRegionsCallback): void {
    this.nativeManager.mergeOfflineRegions(path, (result: ESObject | string) => {
      if (typeof result === 'string') {
        callback.onError(result);
      } else if (Array.isArray(result)) {
        const regions: OfflineRegion[] = (result as ESObject[]).map((r: ESObject) => new OfflineRegion(r));
        callback.onMerge(regions);
      } else {
        callback.onError('Unknown error occurred');
      }
    });
  }
  
  /**
   * 重置数据库（删除所有数据）
   * @param callback 回调接口
   */
  public resetDatabase(callback: FileSourceCallback): void {
    this.nativeManager.resetDatabase((error: string | undefined) => {
      if (error) {
        callback.onError(error);
      } else {
        callback.onSuccess();
      }
    });
  }
  
  /**
   * 压缩数据库以节省空间
   * @param callback 回调接口
   */
  public packDatabase(callback: FileSourceCallback): void {
    this.nativeManager.packDatabase((error: string | undefined) => {
      if (error) {
        callback.onError(error);
      } else {
        callback.onSuccess();
      }
    });
  }
  
  /**
   * 使缓存失效（强制重新验证）
   * @param callback 回调接口
   */
  public invalidateAmbientCache(callback: FileSourceCallback): void {
    this.nativeManager.invalidateAmbientCache((error: string | undefined) => {
      if (error) {
        callback.onError(error);
      } else {
        callback.onSuccess();
      }
    });
  }
  
  /**
   * 清除环境缓存
   * @param callback 回调接口
   */
  public clearAmbientCache(callback: FileSourceCallback): void {
    this.nativeManager.clearAmbientCache((error: string | undefined) => {
      if (error) {
        callback.onError(error);
      } else {
        callback.onSuccess();
      }
    });
  }
  
  /**
   * 设置最大环境缓存大小
   * @param size 大小（字节）
   * @param callback 回调接口
   */
  public setMaximumAmbientCacheSize(size: number, callback: FileSourceCallback): void {
    this.nativeManager.setMaximumAmbientCacheSize(size, (error: string | undefined) => {
      if (error) {
        callback.onError(error);
      } else {
        callback.onSuccess();
      }
    });
  }
  
  /**
   * 设置离线瓦片数量限制
   * @param limit 限制数量
   */
  public setOfflineMapboxTileCountLimit(limit: number): void {
    this.nativeManager.setOfflineMapboxTileCountLimit(limit);
  }
  
  /**
   * 设置是否自动压缩数据库
   * @param autopack 是否自动压缩
   */
  public runPackDatabaseAutomatically(autopack: boolean): void {
    this.nativeManager.runPackDatabaseAutomatically(autopack);
  }
}

// 单例实例
let offlineManagerInstance: OfflineManager | null = null;

/**
 * 获取 OfflineManager 单例实例
 * @param context 应用上下文
 * @returns OfflineManager 实例
 */
export function getOfflineManager(context: common.UIAbilityContext): OfflineManager {
  if (!offlineManagerInstance) {
    // 使用统一的缓存目录（与 NativeMapView 主缓存相同）
    const cachePath = context.cacheDir + '/maplibre/offline.db';
    offlineManagerInstance = new OfflineManager(cachePath);
  }
  return offlineManagerInstance;
}
