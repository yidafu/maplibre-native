/**
 * OfflineRegionStatus - 离线区域状态类型定义
 *
 * 提供离线区域的下载进度和状态信息
 */

/**
 * 离线区域状态
 *
 * 包含下载进度、资源统计等详细信息
 */
export interface OfflineRegionStatus {
  /**
   * 下载状态
   * 0 = INACTIVE（未激活/暂停）
   * 1 = ACTIVE（活动/下载中）
   */
  downloadState: number;

  /**
   * 已完成的资源数量
   * 包括瓦片和其他资源（如字体、图标等）
   */
  completedResourceCount: number;

  /**
   * 已完成资源的总大小（字节）
   * 可用于显示已下载数据量
   */
  completedResourceSize: number;

  /**
   * 已完成的瓦片数量
   * 仅统计地图瓦片
   */
  completedTileCount: number;

  /**
   * 已完成瓦片的总大小（字节）
   * 瓦片通常占据大部分下载量
   */
  completedTileSize: number;

  /**
   * 所需资源的总数量
   * 估计需要下载的总资源数
   * 注意：这是一个估计值，可能会随下载进度调整
   */
  requiredResourceCount: number;

  /**
   * 所需瓦片的总数量
   * 估计需要下载的总瓦片数
   */
  requiredTileCount: number;

  /**
   * 所需资源数量是否精确
   * true: requiredResourceCount 是精确值
   * false: requiredResourceCount 是估计值，可能会变化
   */
  requiredResourceCountIsPrecise: boolean;

  /**
   * 是否完成下载
   * true: 所有资源已下载完成
   * false: 还有资源未下载
   */
  complete: boolean;
}

/**
 * 下载进度计算辅助函数（供参考）
 *
 * @example
* const progress = status.requiredResourceCount > 0
 *   ? (status.completedResourceCount / status.requiredResourceCount) * 100
 *   : 0;
 */

