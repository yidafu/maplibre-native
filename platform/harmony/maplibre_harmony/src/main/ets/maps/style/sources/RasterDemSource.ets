/**
 * RasterDemSource - 栅格 DEM 数据源
 * 
 * 直接从 NAPI 层重新导出 RasterDemSource 类
 */
import type maplibre from 'libmaplibre_native.so';

// 重新导出 NAPI 类型
export type RasterDemSource = maplibre.RasterDemSource;

/**
 * DEM编码类型
 */
export enum DemEncoding {
  /** Mapbox Terrain-RGB */
  Terrarium = 'terrarium',
  /** Mapzen Terrarium */
  Mapbox = 'mapbox'
}
