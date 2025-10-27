/**
 * RasterSource - 栅格瓦片数据源
 * 
 * 直接从 NAPI 层重新导出 RasterSource 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type RasterSource = maplibre.RasterSource;
