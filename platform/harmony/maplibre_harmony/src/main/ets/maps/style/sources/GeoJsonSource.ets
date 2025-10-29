/**
 * GeoJsonSource - GeoJSON 数据源
 * 
 * 直接从 NAPI 层重新导出 GeoJsonSource 类
 */

// 重新导出 NAPI 类
export { GeoJsonSource } from 'libmaplibre_native.so';

// 保留 GeoJSON数据类型定义供外部使用
export type GeoJsonData = Object | string | null;
