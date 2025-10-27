/**
 * OfflineRegion - 离线地图区域
 * 
 * 封装 NAPI OfflineRegion，提供类型安全的接口
 */

/**
 * 下载状态枚举
 */
export enum DownloadState {
  /** 非活动状态（暂停下载） */
  INACTIVE = 0,
  /** 活动状态（正在下载） */
  ACTIVE = 1
}

/**
 * 离线区域状态
 */
export interface OfflineRegionStatus {
  /** 下载状态 */
  downloadState: DownloadState;
  
  /** 已完成的资源数量 */
  completedResourceCount: number;
  
  /** 已完成资源的总大小（字节） */
  completedResourceSize: number;
  
  /** 已完成的瓦片数量 */
  completedTileCount: number;
  
  /** 已完成瓦片的总大小（字节） */
  completedTileSize: number;
  
  /** 所需资源的总数量 */
  requiredResourceCount: number;
  
  /** 所需瓦片的总数量 */
  requiredTileCount: number;
  
  /** 所需资源数量是否精确 */
  requiredResourceCountIsPrecise: boolean;
  
  /** 是否完成 */
  complete: boolean;
}

/**
 * 离线区域错误信息
 */
export interface OfflineRegionError {
  /** 错误原因 */
  reason: string;
  /** 错误消息 */
  message: string;
}

/**
 * 离线区域观察者接口
 */
export interface OfflineRegionObserver {
  /**
   * 状态变化回调
   * @param status 新状态
   */
  onStatusChanged(status: OfflineRegionStatus): void;
  
  /**
   * 错误回调
   * @param error 错误信息
   */
  onError(error: OfflineRegionError): void;
  
  /**
   * 瓦片数量超限回调
   * @param limit 限制数量
   */
  mapboxTileCountLimitExceeded(limit: number): void;
}

/**
 * 离线区域状态回调接口
 */
export interface OfflineRegionStatusCallback {
  /**
   * 成功获取状态
   * @param status 区域状态
   */
  onStatus(status: OfflineRegionStatus): void;
  
  /**
   * 获取失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * 删除回调接口
 */
export interface OfflineRegionDeleteCallback {
  /**
   * 删除成功
   */
  onDelete(): void;
  
  /**
   * 删除失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * 失效回调接口
 */
export interface OfflineRegionInvalidateCallback {
  /**
   * 失效成功
   */
  onInvalidate(): void;
  
  /**
   * 失效失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * 更新元数据回调接口
 */
export interface OfflineRegionUpdateMetadataCallback {
  /**
   * 更新成功
   * @param metadata 新的元数据
   */
  onUpdate(metadata: ArrayBuffer): void;
  
  /**
   * 更新失败
   * @param error 错误信息
   */
  onError(error: string): void;
}

/**
 * OfflineRegion - 离线地图区域
 */
export class OfflineRegion {
  /** 区域 ID */
  public readonly id: number;
  
  /** 区域定义 */
  public readonly definition: ESObject;
  
  /** 元数据 */
  public metadata: ArrayBuffer;
  
  /** Native 对象引用 */
  private nativeRegion: ESObject;
  
  /**
   * 构造函数（由 OfflineManager 创建，不应直接调用）
   * @internal
   */
  constructor(nativeRegion: ESObject) {
    this.nativeRegion = nativeRegion;
    this.id = nativeRegion.id as number;
    this.definition = nativeRegion.definition as ESObject;
    this.metadata = nativeRegion.metadata as ArrayBuffer;
  }
  
  /**
   * 设置下载状态
   * @param state 下载状态
   */
  public setDownloadState(state: DownloadState): void {
    this.nativeRegion.setDownloadState(state);
  }
  
  /**
   * 设置观察者，监听下载进度
   * @param observer 观察者对象
   */
  public setObserver(observer: OfflineRegionObserver): void {
    this.nativeRegion.setObserver(observer);
  }
  
  /**
   * 获取区域状态
   * @param callback 简化回调函数
   */
  public getStatus(callback: (result: OfflineRegionStatus | string) => void): void {
    this.nativeRegion.getStatus(callback);
  }
  
  /**
   * 删除此离线区域
   * @param callback 简化回调函数
   */
  public delete(callback: (error?: string) => void): void {
    this.nativeRegion.delete(callback);
  }
  
  /**
   * 使区域失效（强制重新验证）
   * @param callback 简化回调函数
   */
  public invalidate(callback: (error?: string) => void): void {
    this.nativeRegion.invalidate(callback);
  }
  
  /**
   * 更新元数据
   * @param metadata 新的元数据
   * @param callback 简化回调函数
   */
  public updateMetadata(metadata: ArrayBuffer, callback: (result: ArrayBuffer | string) => void): void {
    this.nativeRegion.updateMetadata(metadata, (result: ESObject | string) => {
      if (typeof result === 'string') {
        callback(result);
      } else {
        this.metadata = result as ArrayBuffer;
        callback(result as ArrayBuffer);
      }
    });
  }
}

