/**
 * OfflineRegionStatus - 离线区域状态
 *
 * 从 NAPI 层重新导出
 */

import maplibre from 'libmaplibre.so';

// 重新导出 NAPI 枚举和接口
export { OfflineRegionStatus } from 'libmaplibre.so';

// 导出 DownloadState 枚举
export { DownloadState } from 'libmaplibre.so';
