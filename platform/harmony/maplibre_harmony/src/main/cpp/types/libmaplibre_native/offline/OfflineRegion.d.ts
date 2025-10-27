/**
 * OfflineRegion - 离线地图区域类型定义
 * 
 * 表示一个离线地图区域，提供下载控制、状态查询等功能
 */

import type { OfflineRegionDefinition } from './OfflineRegionDefinition';
import type { OfflineRegionStatus } from './OfflineRegionStatus';

/**
 * 下载状态枚举
 * 
 * 控制离线区域的下载行为
 */
export enum DownloadState {
  /** 
   * 非活动状态（暂停）
   * 不会下载任何资源
   */
  INACTIVE = 0,
  
  /** 
   * 活动状态（下载中）
   * 开始或继续下载资源
   */
  ACTIVE = 1
}

/**
 * 离线区域错误信息
 * 
 * 描述下载过程中发生的错误
 */
export interface OfflineRegionError {
  /** 
   * 错误原因分类
   * 例如: "network", "storage", "style"
   */
  reason: string;
  
  /** 
   * 详细错误消息
   * 包含具体的错误描述
   */
  message: string;
}

/**
 * 离线区域观察者接口
 * 
 * 用于监听离线区域的下载进度、错误和状态变化
 */
export interface OfflineRegionObserver {
  /**
   * 状态变化回调
   * 
   * 当下载进度更新时调用
   * 
   * @param status 新的状态信息，包含下载进度
   */
  onStatusChanged(status: OfflineRegionStatus): void;
  
  /**
   * 错误回调
   * 
   * 当下载过程中发生错误时调用
   * 注意：某些错误是可恢复的，下载会自动重试
   * 
   * @param error 错误信息对象
   */
  onError(error: OfflineRegionError): void;
  
  /**
   * 瓦片数量超限回调
   * 
   * 当下载的瓦片数量超过设定的限制时调用
   * 可用于提示用户或调整下载策略
   * 
   * @param limit 瓦片数量限制
   */
  mapboxTileCountLimitExceeded(limit: number): void;
}

/**
 * 获取状态的回调
 */
export type OfflineRegionStatusCallback = (result: OfflineRegionStatus | string) => void;

/**
 * 删除回调
 */
export type OfflineRegionDeleteCallback = (error?: string) => void;

/**
 * 失效回调
 */
export type OfflineRegionInvalidateCallback = (error?: string) => void;

/**
 * 更新元数据回调
 */
export type OfflineRegionUpdateMetadataCallback = (result: ArrayBuffer | string) => void;

/**
 * OfflineRegion - 离线地图区域
 * 
 * 通过 NAPI 导出，表示一个离线地图区域
 * 提供下载控制、进度查询、元数据管理等功能
 */
export class OfflineRegion {
  /** 
   * 区域 ID（只读）
   * 
   * 唯一标识此离线区域的数字 ID
   * 在数据库中持久化存储
   */
  readonly id: number;
  
  /** 
   * 区域定义（只读）
   * 
   * 包含地理范围、缩放级别等配置信息
   * 创建后不可修改
   */
  readonly definition: OfflineRegionDefinition;
  
  /** 
   * 元数据
   * 
   * 用户自定义的元数据，可以存储区域名称、描述等信息
   * 以 ArrayBuffer 格式存储，通常使用 JSON 序列化
   */
  metadata: ArrayBuffer;
  
  /**
   * 设置下载状态
   * 
   * 控制是否开始或暂停下载
   * 
   * @param state 下载状态（ACTIVE 开始下载，INACTIVE 暂停）
   * 
   * @example
   * // 开始下载
   * region.setDownloadState(DownloadState.ACTIVE);
   * 
   * // 暂停下载
   * region.setDownloadState(DownloadState.INACTIVE);
   */
  setDownloadState(state: DownloadState): void;
  
  /**
   * 设置观察者
   * 
   * 注册一个观察者以接收下载进度和错误通知
   * 
   * @param observer 观察者对象，实现 OfflineRegionObserver 接口
   * 
   * @example
   * region.setObserver({
   *   onStatusChanged: (status) => {
   *     console.log(`Progress: ${status.completedResourceCount}/${status.requiredResourceCount}`);
   *   },
   *   onError: (error) => {
   *     console.error(`Error: ${error.message}`);
   *   },
   *   mapboxTileCountLimitExceeded: (limit) => {
   *     console.warn(`Tile limit exceeded: ${limit}`);
   *   }
   * });
   */
  setObserver(observer: OfflineRegionObserver): void;
  
  /**
   * 获取区域状态
   * 
   * 异步查询当前的下载进度和状态
   * 
   * @param callback 回调函数，接收状态对象或错误消息
   * 
   * @example
   * region.getStatus((result) => {
   *   if (typeof result === 'string') {
   *     console.error('Failed to get status:', result);
   *   } else {
   *     console.log('Status:', result);
   *   }
   * });
   */
  getStatus(callback: OfflineRegionStatusCallback): void;
  
  /**
   * 删除此离线区域
   * 
   * 从数据库中删除此区域及其所有下载的资源
   * 注意：此操作不可逆
   * 
   * @param callback 回调函数，如果有错误则传递错误消息
   * 
   * @example
   * region.delete((error) => {
   *   if (error) {
   *     console.error('Failed to delete:', error);
   *   } else {
   *     console.log('Region deleted successfully');
   *   }
   * });
   */
  delete(callback: OfflineRegionDeleteCallback): void;
  
  /**
   * 使区域失效（强制重新验证）
   * 
   * 标记所有已下载的资源为过期，下次使用时会重新验证
   * 用于强制刷新离线数据
   * 
   * @param callback 回调函数，如果有错误则传递错误消息
   */
  invalidate(callback: OfflineRegionInvalidateCallback): void;
  
  /**
   * 更新元数据
   * 
   * 修改此区域的元数据
   * 
   * @param metadata 新的元数据（ArrayBuffer 格式）
   * @param callback 回调函数，返回更新后的元数据或错误消息
   * 
   * @example
   * const encoder = new TextEncoder();
   * const newMetadata = encoder.encode(JSON.stringify({ name: 'New Name' })).buffer;
   * region.updateMetadata(newMetadata, (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Failed to update:', result);
   *   } else {
   *     console.log('Metadata updated');
   *   }
   * });
   */
  updateMetadata(metadata: ArrayBuffer, callback: OfflineRegionUpdateMetadataCallback): void;
}

