/**
 * NativeTypes - 原生类型导出
 * 
 * 将 NAPI 提供的 maplibre namespace 重新导出，供上层模块使用
 * entry 模块通过导入 maplibre 来访问所有原生类型和构造函数
 */

import maplibre from 'libmaplibre_native.so';

// 导出整个 maplibre namespace
export { maplibre };

