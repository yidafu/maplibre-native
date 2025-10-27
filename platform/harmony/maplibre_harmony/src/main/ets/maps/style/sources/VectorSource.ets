/**
 * VectorSource - 矢量瓦片数据源
 * 
 * 直接从 NAPI 层重新导出 VectorSource 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type VectorSource = maplibre.VectorSource;
