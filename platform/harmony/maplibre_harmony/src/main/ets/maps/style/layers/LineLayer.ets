/**
 * LineLayer - 线图层
 * 
 * 直接从 NAPI 层重新导出 LineLayer 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type LineLayer = maplibre.LineLayer;
