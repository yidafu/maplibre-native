/**
 * GeoJsonSource - GeoJSON 数据源
 * 
 * 直接从 NAPI 层重新导出 GeoJsonSource 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type GeoJsonSource = maplibre.GeoJsonSource;

// 保留 GeoJSON数据类型定义供外部使用
export type GeoJsonData = Object | string | null;
