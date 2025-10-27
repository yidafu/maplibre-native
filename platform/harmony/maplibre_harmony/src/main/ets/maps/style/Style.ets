/**
 * Style - 样式管理类
 * 
 * 从 NAPI 层重新导出 Style 和 StyleBuilder 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type Style = maplibre.Style;
export type StyleBuilder = maplibre.StyleBuilder;

