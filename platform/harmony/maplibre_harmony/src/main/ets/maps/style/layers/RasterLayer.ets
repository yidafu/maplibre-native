/**
 * RasterLayer - 栅格图层
 * 
 * 直接从 NAPI 层重新导出 RasterLayer 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type RasterLayer = maplibre.RasterLayer;
