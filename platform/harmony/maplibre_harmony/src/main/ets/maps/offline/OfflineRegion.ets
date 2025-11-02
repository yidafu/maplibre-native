/**
 * OfflineRegion - 离线区域封装类
 * 
 * 封装 NAPI 层的 OfflineRegion 类，提供离线地图下载和管理功能
 */
import maplibre from 'libmaplibre.so';
import { OfflineRegionDefinition } from './OfflineRegionDefinition';
import { OfflineRegionStatus } from './OfflineRegionStatus';
import type { OfflineRegionObserver } from './OfflineRegionObserver';
import type { OfflineRegionError } from './OfflineRegionError';

/**
 * 下载状态枚举
 */
export enum DownloadState {
  /** 非活动状态（暂停） */
  INACTIVE = 0,
  /** 活动状态（下载中） */
  ACTIVE = 1
}

/**
 * 回调类型定义
 */
export type OfflineRegionStatusCallback = (result: OfflineRegionStatus | string) => void;
export type OfflineRegionDeleteCallback = (error?: string) => void;
export type OfflineRegionInvalidateCallback = (error?: string) => void;
export type OfflineRegionUpdateMetadataCallback = (result: ArrayBuffer | string) => void;

/**
 * OfflineRegion 封装类
 */
export class OfflineRegion {
  private nativeInstance: maplibre.OfflineRegion;

  /**
   * 私有构造函数
   * 由 OfflineManager 创建实例
   */
  private constructor(nativeInstance: maplibre.OfflineRegion) {
    this.nativeInstance = nativeInstance;
  }

  /**
   * 从 NAPI 实例创建封装类（内部使用）
   */
  static fromNative(nativeInstance: maplibre.OfflineRegion): OfflineRegion {
    return new OfflineRegion(nativeInstance);
  }

  /**
   * 获取 NAPI 实例（内部使用）
   */
  getNative(): maplibre.OfflineRegion {
    return this.nativeInstance;
  }

  /**
   * 获取区域 ID
   */
  get id(): number {
    return this.nativeInstance.id;
  }

  /**
   * 获取区域定义
   */
  get definition(): OfflineRegionDefinition {
    return this.nativeInstance.definition;
  }

  /**
   * 获取元数据
   */
  get metadata(): ArrayBuffer {
    return this.nativeInstance.metadata;
  }

  /**
   * 设置元数据
   */
  set metadata(value: ArrayBuffer) {
    this.nativeInstance.metadata = value;
  }

  /**
   * 设置下载状态
   * 
   * @param state 下载状态（ACTIVE 开始下载，INACTIVE 暂停）
   */
  setDownloadState(state: DownloadState): void {
    this.nativeInstance.setDownloadState(state);
  }

  /**
   * 设置观察者
   * 
   * @param observer 观察者对象
   */
  setObserver(observer: OfflineRegionObserver): void {
    this.nativeInstance.setObserver(observer);
  }

  /**
   * 获取区域状态
   * 
   * @param callback 回调函数
   */
  getStatus(callback: OfflineRegionStatusCallback): void {
    this.nativeInstance.getStatus(callback);
  }

  /**
   * 删除此离线区域
   * 
   * @param callback 回调函数
   */
  delete(callback: OfflineRegionDeleteCallback): void {
    this.nativeInstance.delete(callback);
  }

  /**
   * 使区域失效（强制重新验证）
   * 
   * @param callback 回调函数
   */
  invalidate(callback: OfflineRegionInvalidateCallback): void {
    this.nativeInstance.invalidate(callback);
  }

  /**
   * 更新元数据
   * 
   * @param metadata 新的元数据
   * @param callback 回调函数
   */
  updateMetadata(metadata: ArrayBuffer, callback: OfflineRegionUpdateMetadataCallback): void {
    this.nativeInstance.updateMetadata(metadata, callback);
  }

  /**
   * 转换为字符串
   */
  toString(): string {
    return `OfflineRegion(id=${this.id})`;
  }
}
