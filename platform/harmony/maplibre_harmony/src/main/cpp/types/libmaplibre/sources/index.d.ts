/**
 * MapLibre Native for HarmonyOS - Sources Index
 * 数据源类型定义统一导出
 */

import { GeoJsonSource } from './GeoJsonSource';
import { ImageSource } from './ImageSource';
import { RasterDemSource } from './RasterDemSource';
import { RasterSource } from './RasterSource';
import { VectorSource } from './VectorSource';

export { GeoJsonSource, GeoJsonOptions } from './GeoJsonSource';
export { VectorSource, VectorSourceOptions } from './VectorSource';
export { RasterSource, RasterSourceOptions } from './RasterSource';
export { RasterDemSource, RasterDemSourceOptions } from './RasterDemSource';
export { ImageSource } from './ImageSource';

/**
 * Source - 所有数据源类型的联合类型
 * 用于 Style API 中的类型安全
 */
export type Source = 
    | GeoJsonSource 
    | VectorSource 
    | RasterSource 
    | RasterDemSource 
    | ImageSource;

