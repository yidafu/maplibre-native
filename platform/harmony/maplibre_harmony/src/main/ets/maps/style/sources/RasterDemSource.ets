/**
 * RasterDemSource - 栅格 DEM 数据源
 * 
 * 直接从 NAPI 层重新导出 RasterDemSource 类
 */

// 重新导出 NAPI 类
export { RasterDemSource } from 'libmaplibre_native.so';

/**
 * DEM编码类型
 */
export enum DemEncoding {
  /** Mapbox Terrain-RGB */
  Terrarium = 'terrarium',
  /** Mapzen Terrarium */
  Mapbox = 'mapbox'
}
