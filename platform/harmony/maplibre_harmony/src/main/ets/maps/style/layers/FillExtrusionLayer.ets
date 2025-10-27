/**
 * FillExtrusionLayer - 填充拉伸图层 (3D建筑)
 * 
 * 直接从 NAPI 层重新导出 FillExtrusionLayer 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type FillExtrusionLayer = maplibre.FillExtrusionLayer;
