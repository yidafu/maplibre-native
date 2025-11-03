/**
 * OfflineManager - 离线地图管理器类型定义
 *
 * 提供离线地图的全局管理功能
 * 包括区域创建、列表、合并、数据库维护等
 */

import type { OfflineRegion } from './OfflineRegion';
import type { OfflineRegionDefinition } from './OfflineRegionDefinition';

/**
 * 列出离线区域的回调
 *
 * @param result 成功时返回离线区域数组，失败时返回错误消息字符串
 */
export type ListOfflineRegionsCallback = (result: OfflineRegion[] | string) => void;

/**
 * 创建离线区域的回调
 *
 * @param result 成功时返回新创建的离线区域对象，失败时返回错误消息字符串
 */
export type CreateOfflineRegionCallback = (result: OfflineRegion | string) => void;

/**
 * 获取离线区域的回调
 *
 * @param result 成功时返回离线区域对象，不存在时返回 null，失败时返回错误消息字符串
 */
export type GetOfflineRegionCallback = (result: OfflineRegion | string | null) => void;

/**
 * 合并离线区域的回调
 *
 * @param result 成功时返回合并后的离线区域数组，失败时返回错误消息字符串
 */
export type MergeOfflineRegionsCallback = (result: OfflineRegion[] | string) => void;

/**
 * 文件源操作回调
 *
 * @param error 操作成功时为 undefined，失败时为错误消息字符串
 */
export type FileSourceCallback = (error?: string) => void;

/**
 * OfflineManager - 离线地图管理器
 *
 * 通过 NAPI 导出，提供离线地图的全局管理功能
 *
 * 主要功能：
 * - 创建和管理离线区域
 * - 数据库维护（压缩、清理、重置）
 * - 缓存管理
 * - 多数据库合并
 */
export class OfflineManager {
  /**
   * 构造函数
   *
   * 创建一个离线管理器实例
   *
   * @param cachePath 数据库缓存路径（完整的文件路径）
   *                  例如: "/data/storage/el2/base/files/maplibre-offline.db"
   *
   * @example
  * const manager = new OfflineManager(context.filesDir + '/offline.db');
   */
  constructor(cachePath: string);

  /**
   * 列出所有离线区域
   *
   * 异步获取数据库中存储的所有离线区域
   *
   * @param callback 回调函数，成功时返回区域数组，失败时返回错误消息
   *
   * @example
  * manager.listOfflineRegions((result) => {
   *   if (typeof result === 'string') {
   *     console.error('Error:', result);
   *   } else {
   *     console.log(`Found ${result.length} regions`);
   *   }
   * });
   */
  listOfflineRegions(callback: ListOfflineRegionsCallback): void;

  /**
   * 创建离线区域
   *
   * 在数据库中创建一个新的离线区域
   * 创建后需要调用 setDownloadState(ACTIVE) 开始下载
   *
   * @param definition 区域定义，指定地理范围、缩放级别等参数
   * @param metadata 元数据（ArrayBuffer 格式），存储区域名称、描述等自定义信息
   * @param callback 回调函数，成功时返回新创建的区域对象，失败时返回错误消息
   *
   * @example
  * const encoder = new TextEncoder();
   * const metadata = encoder.encode(JSON.stringify({ name: '北京地区' })).buffer;
   *
   * manager.createOfflineRegion(definition, metadata, (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Failed:', result);
   *   } else {
   *     console.log('Region created:', result.id);
   *     result.setDownloadState(DownloadState.ACTIVE);
   *   }
   * });
   */
  createOfflineRegion(
    definition: OfflineRegionDefinition,
    metadata: ArrayBuffer,
    callback: CreateOfflineRegionCallback
  ): void;

  /**
   * 获取指定 ID 的离线区域
   *
   * 根据区域 ID 查询离线区域对象
   *
   * @param regionId 区域 ID（创建时生成的唯一标识）
   * @param callback 回调函数，成功时返回区域对象，不存在时返回 null，失败时返回错误消息
   *
   * @example
  * manager.getOfflineRegion(123, (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Error:', result);
   *   } else if (result === null) {
   *     console.log('Region not found');
   *   } else {
   *     console.log('Found region:', result.id);
   *   }
   * });
   */
  getOfflineRegion(regionId: number, callback: GetOfflineRegionCallback): void;

  /**
   * 合并其他数据库的离线区域
   *
   * 将另一个数据库文件中的离线区域导入到当前数据库
   * 用于数据迁移或多设备同步
   *
   * @param path 要合并的数据库文件的完整路径
   * @param callback 回调函数，成功时返回合并后的所有区域，失败时返回错误消息
   *
   * @example
  * manager.mergeOfflineRegions('/path/to/other.db', (result) => {
   *   if (typeof result === 'string') {
   *     console.error('Merge failed:', result);
   *   } else {
   *     console.log(`Merged ${result.length} regions`);
   *   }
   * });
   */
  mergeOfflineRegions(path: string, callback: MergeOfflineRegionsCallback): void;

  /**
   * 重置数据库（删除所有数据）
   *
   * 清空数据库，删除所有离线区域和下载的资源
   * 警告：此操作不可逆，请谨慎使用
   *
   * @param callback 回调函数，成功时 error 为 undefined，失败时为错误消息
   *
   * @example
  * manager.resetDatabase((error) => {
   *   if (error) {
   *     console.error('Reset failed:', error);
   *   } else {
   *     console.log('Database reset successfully');
   *   }
   * });
   */
  resetDatabase(callback: FileSourceCallback): void;

  /**
   * 压缩数据库以节省空间
   *
   * 执行 VACUUM 操作，回收已删除数据占用的空间
   * 建议定期执行或在删除大量数据后执行
   *
   * @param callback 回调函数，成功时 error 为 undefined，失败时为错误消息
   *
   * @example
  * manager.packDatabase((error) => {
   *   if (error) {
   *     console.error('Pack failed:', error);
   *   } else {
   *     console.log('Database packed successfully');
   *   }
   * });
   */
  packDatabase(callback: FileSourceCallback): void;

  /**
   * 使缓存失效（强制重新验证）
   *
   * 标记环境缓存中的所有资源为过期
   * 下次使用时会重新验证资源的有效性
   *
   * @param callback 回调函数，成功时 error 为 undefined，失败时为错误消息
   */
  invalidateAmbientCache(callback: FileSourceCallback): void;

  /**
   * 清除环境缓存
   *
   * 删除环境缓存中的所有资源
   * 注意：这不会影响离线区域中明确下载的资源
   *
   * @param callback 回调函数，成功时 error 为 undefined，失败时为错误消息
   *
   * @example
  * manager.clearAmbientCache((error) => {
   *   if (error) {
   *     console.error('Clear failed:', error);
   *   } else {
   *     console.log('Ambient cache cleared');
   *   }
   * });
   */
  clearAmbientCache(callback: FileSourceCallback): void;

  /**
   * 设置最大环境缓存大小
   *
   * 限制环境缓存占用的最大磁盘空间
   * 超过限制时会自动删除最旧的资源
   *
   * @param size 大小（字节），例如 50 * 1024 * 1024 表示 50MB
   * @param callback 回调函数，成功时 error 为 undefined，失败时为错误消息
   *
   * @example
  * // 设置为 50MB
   * manager.setMaximumAmbientCacheSize(50 * 1024 * 1024, (error) => {
   *   if (error) {
   *     console.error('Set size failed:', error);
   *   }
   * });
   */
  setMaximumAmbientCacheSize(size: number, callback: FileSourceCallback): void;

  /**
   * 设置离线瓦片数量限制
   *
   * 限制单个离线区域可以下载的最大瓦片数量
   * 超过限制时会触发观察者的 mapboxTileCountLimitExceeded 回调
   *
   * @param limit 限制数量，例如 6000
   *
   * @example
  * // 限制为 6000 个瓦片
   * manager.setOfflineMapboxTileCountLimit(6000);
   */
  setOfflineMapboxTileCountLimit(limit: number): void;

  /**
   * 设置是否自动压缩数据库
   *
   * 启用后，系统会在适当的时候自动执行数据库压缩
   * 建议启用以保持最佳性能
   *
   * @param autopack true 启用自动压缩，false 禁用
   *
   * @example
  * // 启用自动压缩
   * manager.runPackDatabaseAutomatically(true);
   */
  runPackDatabaseAutomatically(autopack: boolean): void;
}

